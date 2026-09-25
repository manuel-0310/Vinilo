import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/follow.dart';
import '../models/notification.dart';
import '../models/rating.dart';
import '../models/reply.dart';
import '../models/user_profile.dart';
import 'notifications_repo.dart';

/// Respuestas a las notas: `ratings/{ratingId}/replies/{id}`.
///
/// Cada respuesta se crea o se borra en un lote junto con el contador
/// `repliesCount` de la nota y sus notificaciones ("respondió a tu nota"
/// para la dueña, "te respondió" para quien se menciona), así el número del
/// hilo siempre cuadra.
class RepliesRepo {
  RepliesRepo(this._db, this._notifications);

  final FirebaseFirestore _db;
  final NotificationsRepo _notifications;

  DocumentReference<Map<String, dynamic>> _rating(String ratingId) =>
      _db.collection('ratings').doc(ratingId);

  CollectionReference<Map<String, dynamic>> _replies(String ratingId) =>
      _rating(ratingId).collection('replies');

  /// El hilo de una nota, de la más antigua a la más reciente.
  Stream<List<Reply>> watch(String ratingId) => _replies(ratingId)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Reply.fromDoc).toList());

  /// La nota del hilo, en vivo (null si ya no existe).
  Stream<RatingEntry?> watchRating(String ratingId) => _rating(ratingId)
      .snapshots()
      .map((s) => s.exists ? RatingEntry.fromDoc(s) : null);

  /// Responde a la nota `entry`. `mentioned` son las personas a las que se
  /// les contestó en el hilo; solo se avisa a las que siguen mencionadas en
  /// el texto.
  Future<void> add({
    required RatingEntry entry,
    required UserProfile me,
    required String text,
    Iterable<PersonInfo> mentioned = const [],
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final ref = _replies(entry.id).doc();
    final mentions = mentionsIn(clean, mentioned);
    final reply = Reply(
      id: ref.id,
      ratingId: entry.id,
      ratingUid: entry.uid,
      uid: me.uid,
      user: me.person,
      text: clean.length > replyMaxLength ? clean.substring(0, replyMaxLength) : clean,
      createdAt: DateTime.now(),
      mentions: mentions,
    );
    final batch = _db.batch();
    batch.set(ref, reply.toMap());
    batch.update(_rating(entry.id), {'repliesCount': FieldValue.increment(1)});
    for (final target in replyNotificationTargets(
      from: me.uid,
      ratingUid: entry.uid,
      mentions: mentions,
    )) {
      _notifications.putInBatch(
        batch,
        AppNotification(
          id: _notificationId(target.to, target.type, me.uid, entry.id),
          to: target.to,
          from: me.person,
          type: target.type,
          createdAt: DateTime.now(),
          read: false,
          album: entry.album,
          ratingId: entry.id,
          snippet: replySnippet(reply.text),
        ),
      );
    }
    await batch.commit();
  }

  /// Borra una respuesta (la autora o la dueña de la nota). Si la borra su
  /// autora y no le queda otra en el hilo, también quita los avisos que
  /// había provocado (hay uno solo por persona y nota).
  Future<void> delete(Reply reply, {required String me}) async {
    final batch = _db.batch();
    batch.delete(_replies(reply.ratingId).doc(reply.id));
    batch.update(_rating(reply.ratingId), {'repliesCount': FieldValue.increment(-1)});
    final others = me == reply.uid
        ? await _replies(reply.ratingId)
            .where('uid', isEqualTo: reply.uid)
            .limit(2)
            .get()
        : null;
    if (others != null && others.docs.every((d) => d.id == reply.id)) {
      for (final target in replyNotificationTargets(
        from: reply.uid,
        ratingUid: reply.ratingUid,
        mentions: reply.mentions,
      )) {
        _notifications.removeInBatch(
          batch,
          _notificationId(target.to, target.type, reply.uid, reply.ratingId),
        );
      }
    }
    await batch.commit();
  }

  /// Borra todo el hilo de una nota (antes de borrar la nota misma: las
  /// reglas dejan a su dueña borrar cualquier respuesta).
  Future<void> deleteAllFor(String ratingId) async {
    final snap = await _replies(ratingId).get();
    for (var i = 0; i < snap.docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in snap.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Copia el nombre, la foto y el @ nuevos de una persona en sus
  /// respuestas (índice de grupo de colecciones sobre `replies.uid`). Si el
  /// índice aún no existe, lo deja para la próxima vez sin fallar.
  Future<void> propagateAuthor(PersonInfo person) async {
    try {
      final snap = await _db
          .collectionGroup('replies')
          .where('uid', isEqualTo: person.uid)
          .get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final batch = _db.batch();
        for (final doc in snap.docs.skip(i).take(400)) {
          batch.update(doc.reference, {'user': person.toMap()});
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      debugPrint('No se pudieron actualizar las respuestas: ${e.code}');
    }
  }

  /// Un aviso por persona, tipo y nota: una segunda respuesta lo refresca
  /// (sube arriba y vuelve a "sin leer") en vez de acumular avisos.
  static String _notificationId(
    String to,
    NotificationType type,
    String from,
    String ratingId,
  ) =>
      AppNotification.idFor(to: to, type: type, from: from, target: ratingId);
}
