import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/follow.dart';
import '../models/moderation.dart';
import '../models/notification.dart';
import '../models/user_profile.dart';
import '../util/streams.dart';
import 'notifications_repo.dart';

/// El número que se le muestra a quien reporta ("Reporte Nº 4821"): cuatro
/// cifras al azar. El id de verdad es el del documento.
int reportNumber([math.Random? random]) => 1000 + (random ?? math.Random()).nextInt(9000);

/// Reportar, bloquear, silenciar y ocultar.
///
/// - `blocks/{quien}_{aQuien}`: los bloqueos. Bloquear borra además los
///   seguimientos entre las dos personas (con sus contadores) en la misma
///   transacción.
/// - `users/{uid}/mutes/{otro}`: a quién silencié.
/// - `users/{uid}/hidden/{id}`: las notas y respuestas que oculté.
/// - `reports/{id}`: los reportes; reportar un comentario lo oculta en el
///   mismo lote.
/// - `admins/{uid}`: quién puede revisar reportes.
class ModerationRepo {
  ModerationRepo(this._db, this._notifications);

  final FirebaseFirestore _db;
  final NotificationsRepo _notifications;

  CollectionReference<Map<String, dynamic>> get _blocks => _db.collection('blocks');
  CollectionReference<Map<String, dynamic>> get _reports => _db.collection('reports');
  CollectionReference<Map<String, dynamic>> get _follows => _db.collection('follows');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  CollectionReference<Map<String, dynamic>> _mutes(String uid) =>
      _users.doc(uid).collection('mutes');

  CollectionReference<Map<String, dynamic>> _hidden(String uid) =>
      _users.doc(uid).collection('hidden');

  /// Todo lo que hay que esconderle a `uid`, en vivo. El filtro de palabras
  /// vive en su perfil: lo suma quien pinta (`main.dart`).
  Stream<ModerationState> watch(String uid) {
    final blocked = _blocks.where('blocker', isEqualTo: uid).snapshots().map<Object>((s) {
      final edges = s.docs.map((d) => BlockEdge.fromMap(d.data()));
      return <String, BlockEdge>{for (final e in edges) e.blocked: e};
    });
    final blockedBy = _blocks.where('blocked', isEqualTo: uid).snapshots().map<Object>(
          (s) => <String>{
            for (final d in s.docs) (d.data()['blocker'] ?? '') as String,
          },
        );
    final muted = _mutes(uid).snapshots().map<Object>(
          (s) => <String, MutedPerson>{
            for (final d in s.docs) d.id: MutedPerson.fromDoc(d),
          },
        );
    final hidden = _hidden(uid).snapshots().map<Object>(
          (s) => <String>{for (final d in s.docs) d.id},
        );
    return combineLatestAll<Object>([blocked, blockedBy, muted, hidden]).map(
      (v) => ModerationState(
        blocked: v[0] as Map<String, BlockEdge>,
        blockedBy: v[1] as Set<String>,
        muted: v[2] as Map<String, MutedPerson>,
        hidden: v[3] as Set<String>,
      ),
    );
  }

  /// Bloquea a `other`: crea el bloqueo y, en la misma transacción, borra
  /// los seguimientos que hubiera entre las dos personas, baja los cuatro
  /// contadores y quita los avisos de "empezó a seguirte". No le avisa.
  Future<void> block({required UserProfile me, required PersonInfo other}) async {
    if (me.uid == other.uid) return;
    final blockRef = _blocks.doc(BlockEdge.docId(me.uid, other.uid));
    final mine = _follows.doc(FollowEdge.docId(me.uid, other.uid));
    final theirs = _follows.doc(FollowEdge.docId(other.uid, me.uid));
    await _db.runTransaction((tx) async {
      final mineSnap = await tx.get(mine);
      final theirsSnap = await tx.get(theirs);
      final delta = BlockFollowDelta(
        iFollowed: mineSnap.exists,
        theyFollowed: theirsSnap.exists,
      );
      tx.set(blockRef, {
        'blocker': me.uid,
        'blocked': other.uid,
        'blockedInfo': other.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (delta.iFollowed) {
        tx.delete(mine);
        _notifications.removeIn(
          tx,
          AppNotification.idFor(to: other.uid, type: NotificationType.follow, from: me.uid),
        );
      }
      if (delta.theyFollowed) {
        tx.delete(theirs);
        _notifications.removeIn(
          tx,
          AppNotification.idFor(to: me.uid, type: NotificationType.follow, from: other.uid),
        );
      }
      if (delta.touchesMe) {
        tx.set(
          _users.doc(me.uid),
          {
            if (delta.myFollowing != 0) 'followingCount': FieldValue.increment(delta.myFollowing),
            if (delta.myFollowers != 0) 'followersCount': FieldValue.increment(delta.myFollowers),
          },
          SetOptions(merge: true),
        );
      }
      if (delta.touchesThem) {
        tx.set(
          _users.doc(other.uid),
          {
            if (delta.theirFollowers != 0)
              'followersCount': FieldValue.increment(delta.theirFollowers),
            if (delta.theirFollowing != 0)
              'followingCount': FieldValue.increment(delta.theirFollowing),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  /// Quita el bloqueo. No vuelve a seguir a nadie: eso lo decide cada quien.
  Future<void> unblock({required String me, required String other}) =>
      _blocks.doc(BlockEdge.docId(me, other)).delete();

  Future<void> mute({required String me, required PersonInfo other}) {
    if (me == other.uid) return Future.value();
    return _mutes(me).doc(other.uid).set({
      'info': other.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unmute({required String me, required String other}) =>
      _mutes(me).doc(other).delete();

  /// Oculta una nota o una respuesta solo para `me`.
  Future<void> hide({
    required String me,
    required String contentId,
    required ReportTarget kind,
    String? ratingId,
  }) {
    return _hidden(me).doc(contentId).set(_hiddenData(kind, ratingId));
  }

  Future<void> unhide({required String me, required String contentId}) =>
      _hidden(me).doc(contentId).delete();

  static Map<String, dynamic> _hiddenData(ReportTarget kind, String? ratingId) => {
        'kind': kind.key,
        'ratingId': ratingId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Manda un reporte. Si es de un comentario (nota o respuesta), queda
  /// oculto para quien reporta en el mismo lote.
  Future<Report> report({
    required String reporter,
    required ReportTarget type,
    required String targetId,
    required PersonInfo target,
    required ReportReason reason,
    String? ratingId,
    String details = '',
    String excerpt = '',
  }) async {
    final ref = _reports.doc();
    final cleanDetails = details.trim();
    final cleanExcerpt = excerpt.trim();
    final report = Report(
      id: ref.id,
      reporter: reporter,
      targetType: type,
      targetId: targetId,
      target: target,
      ratingId: ratingId,
      reason: reason,
      details: cleanDetails.length > reportDetailsMaxLength
          ? cleanDetails.substring(0, reportDetailsMaxLength)
          : cleanDetails,
      excerpt: cleanExcerpt.length > 280 ? cleanExcerpt.substring(0, 280) : cleanExcerpt,
      number: reportNumber(),
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    batch.set(ref, report.toMap());
    if (type.isContent) {
      batch.set(_hidden(reporter).doc(targetId), _hiddenData(type, ratingId));
    }
    await batch.commit();
    return report;
  }

  List<Report> _newestFirst(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(Report.fromDoc).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Los reportes que mandó `uid`, del más reciente al más antiguo.
  Stream<List<Report>> myReports(String uid) =>
      _reports.where('reporter', isEqualTo: uid).snapshots().map(_newestFirst);

  /// Si `uid` puede revisar reportes (tiene su documento en `admins`). Si no
  /// se puede leer, no.
  Stream<bool> isAdmin(String uid) => _db
      .collection('admins')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists)
      .handleError((Object _) {});

  /// Los reportes sin revisar (solo quien modera puede leerlos).
  Stream<List<Report>> openReports() =>
      _reports.where('status', isEqualTo: 'open').snapshots().map(_newestFirst);

  /// Cierra un reporte con lo que se decidió (`dismissed` o `removed`).
  Future<void> resolve(Report report, {required String outcome, required String by}) {
    return _reports.doc(report.id).update({
      'status': 'resolved',
      'outcome': outcome,
      'resolvedBy': by,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
