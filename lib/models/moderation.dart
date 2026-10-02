import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n.dart';
import '../util/offensive.dart';
import 'follow.dart';
import 'notification.dart';
import 'rating.dart';
import 'reply.dart';

/// Por qué se reporta algo, en el orden de la pantalla "Reportar".
enum ReportReason {
  spam('spam'),
  harassment('harassment'),
  hate('hate'),
  sexual('sexual'),
  impersonation('impersonation'),
  violence('violence'),
  other('other');

  const ReportReason(this.key);

  final String key;

  static ReportReason fromKey(String? key) {
    for (final r in values) {
      if (r.key == key) return r;
    }
    return ReportReason.other;
  }

  /// "Acoso o bullying".
  String title(AppLocalizations l) => switch (this) {
        ReportReason.spam => l.reportReasonSpam,
        ReportReason.harassment => l.reportReasonHarassment,
        ReportReason.hate => l.reportReasonHate,
        ReportReason.sexual => l.reportReasonSexual,
        ReportReason.impersonation => l.reportReasonImpersonation,
        ReportReason.violence => l.reportReasonViolence,
        ReportReason.other => l.reportReasonOther,
      };

  /// "Ataques o insultos a alguien".
  String hint(AppLocalizations l) => switch (this) {
        ReportReason.spam => l.reportReasonSpamHint,
        ReportReason.harassment => l.reportReasonHarassmentHint,
        ReportReason.hate => l.reportReasonHateHint,
        ReportReason.sexual => l.reportReasonSexualHint,
        ReportReason.impersonation => l.reportReasonImpersonationHint,
        ReportReason.violence => l.reportReasonViolenceHint,
        ReportReason.other => l.reportReasonOtherHint,
      };

  /// La versión corta del encabezado del reporte enviado ("Acoso").
  String short(AppLocalizations l) => switch (this) {
        ReportReason.spam => l.reportReasonSpam,
        ReportReason.harassment => l.reportReasonHarassmentShort,
        ReportReason.hate => l.reportReasonHateShort,
        ReportReason.sexual => l.reportReasonSexualShort,
        ReportReason.impersonation => l.reportReasonImpersonation,
        ReportReason.violence => l.reportReasonViolenceShort,
        ReportReason.other => l.reportReasonOther,
      };
}

/// Qué se reporta: a una persona, una calificación (con o sin comentario) o
/// una respuesta de un hilo.
enum ReportTarget {
  user('user'),
  rating('rating'),
  reply('reply');

  const ReportTarget(this.key);

  final String key;

  static ReportTarget fromKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return ReportTarget.user;
  }

  /// Si es contenido (algo que se oculta al reportarlo), no una persona.
  bool get isContent => this != ReportTarget.user;
}

/// Largo máximo de los detalles de un reporte.
const int reportDetailsMaxLength = 500;

/// En qué va un reporte.
enum ReportStatus { open, resolved }

/// Un reporte (`reports/{id}`). Lo lee quien lo mandó ("Mis reportes") y
/// quien modera.
class Report {
  const Report({
    required this.id,
    required this.reporter,
    required this.targetType,
    required this.targetId,
    required this.target,
    required this.reason,
    required this.details,
    required this.number,
    required this.createdAt,
    this.ratingId,
    this.excerpt = '',
    this.status = ReportStatus.open,
    this.outcome,
  });

  final String id;
  final String reporter;
  final ReportTarget targetType;

  /// El uid, el id de la nota o el id de la respuesta.
  final String targetId;

  /// La persona reportada (o la autora de lo reportado).
  final PersonInfo target;

  /// La nota de la que cuelga la respuesta (o la nota misma).
  final String? ratingId;
  final ReportReason reason;
  final String details;

  /// Lo que decía el comentario cuando se reportó.
  final String excerpt;

  /// El número que se le muestra a la persona ("Reporte Nº 4821").
  final int number;
  final ReportStatus status;

  /// Lo que decidió quien lo revisó (`dismissed` | `removed`).
  final String? outcome;
  final DateTime createdAt;

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final targetUid = (d['targetUid'] ?? '') as String;
    return Report(
      id: doc.id,
      reporter: (d['reporter'] ?? '') as String,
      targetType: ReportTarget.fromKey(d['targetType'] as String?),
      targetId: (d['targetId'] ?? '') as String,
      target: PersonInfo.fromMap(
        targetUid,
        Map<String, dynamic>.from((d['targetInfo'] as Map?) ?? {}),
      ),
      ratingId: d['ratingId'] as String?,
      reason: ReportReason.fromKey(d['reason'] as String?),
      details: (d['details'] ?? '') as String,
      excerpt: (d['excerpt'] ?? '') as String,
      number: (d['number'] as num?)?.toInt() ?? 0,
      status: d['status'] == 'resolved' ? ReportStatus.resolved : ReportStatus.open,
      outcome: d['outcome'] as String?,
      createdAt: dateFrom(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'reporter': reporter,
        'targetType': targetType.key,
        'targetId': targetId,
        'targetUid': target.uid,
        'targetInfo': target.toMap(),
        'ratingId': ratingId,
        'reason': reason.key,
        'details': details,
        'excerpt': excerpt,
        'number': number,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Un bloqueo: `blocker` bloqueó a `blocked`. El documento se llama
/// `{blocker}_{blocked}`; lo leen las dos partes (así la app de la persona
/// bloqueada también deja de mostrar a quien la bloqueó).
class BlockEdge {
  const BlockEdge({
    required this.blocker,
    required this.blocked,
    required this.blockedInfo,
    required this.createdAt,
  });

  final String blocker;
  final String blocked;
  final PersonInfo blockedInfo;
  final DateTime createdAt;

  static String docId(String blocker, String blocked) => '${blocker}_$blocked';

  factory BlockEdge.fromMap(Map<String, dynamic> d) {
    final blocked = (d['blocked'] ?? '') as String;
    return BlockEdge(
      blocker: (d['blocker'] ?? '') as String,
      blocked: blocked,
      blockedInfo: PersonInfo.fromMap(
        blocked,
        Map<String, dynamic>.from((d['blockedInfo'] as Map?) ?? {}),
      ),
      createdAt: dateFrom(d['createdAt']),
    );
  }
}

/// Alguien a quien silencié (`users/{yo}/mutes/{uid}`): sigo siguiéndole,
/// pero su actividad no sale en mi inicio.
class MutedPerson {
  const MutedPerson({required this.info, required this.createdAt});

  final PersonInfo info;
  final DateTime createdAt;

  factory MutedPerson.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return MutedPerson(
      info: PersonInfo.fromMap(
        doc.id,
        Map<String, dynamic>.from((d['info'] as Map?) ?? {}),
      ),
      createdAt: dateFrom(d['createdAt']),
    );
  }
}

/// Todo lo que la app tiene que esconderle a quien la usa: a quién bloqueó,
/// quién la bloqueó, a quién silenció, qué comentarios ocultó y si quiere
/// las palabras ofensivas tapadas. Las listas de la app pasan por aquí
/// antes de pintarse.
class ModerationState {
  const ModerationState({
    this.blocked = const {},
    this.blockedBy = const {},
    this.muted = const {},
    this.hidden = const {},
    this.filterOffensive = true,
  });

  /// A quién bloqueé (uid → el bloqueo, con sus datos para Ajustes).
  final Map<String, BlockEdge> blocked;

  /// Quién me bloqueó.
  final Set<String> blockedBy;

  /// A quién silencié.
  final Map<String, MutedPerson> muted;

  /// Notas y respuestas que oculté (o reporté), por id.
  final Set<String> hidden;
  final bool filterOffensive;

  bool isBlocked(String uid) => blocked.containsKey(uid);

  bool blocksMe(String uid) => blockedBy.contains(uid);

  /// Bloqueo en cualquiera de los dos sentidos: no se ve nada de esa
  /// persona.
  bool hidesUser(String uid) => isBlocked(uid) || blocksMe(uid);

  bool isMuted(String uid) => muted.containsKey(uid);

  bool hidesContent(String id) => hidden.contains(id);

  /// La actividad del inicio: sin bloqueados, sin silenciados y sin lo que
  /// oculté.
  List<RatingEntry> feed(Iterable<RatingEntry> entries) => [
        for (final e in entries)
          if (!hidesUser(e.uid) && !isMuted(e.uid) && !hidesContent(e.id)) e,
      ];

  /// Notas de otras personas fuera del inicio (comentarios de un disco,
  /// "Calificado por"): sin bloqueados y sin lo que oculté. A quien silencié
  /// se le sigue viendo ahí.
  List<RatingEntry> ratings(Iterable<RatingEntry> entries) => [
        for (final e in entries)
          if (!hidesUser(e.uid) && !hidesContent(e.id)) e,
      ];

  List<Reply> replies(Iterable<Reply> replies) => [
        for (final r in replies)
          if (!hidesUser(r.uid) && !hidesContent(r.id)) r,
      ];

  List<PersonInfo> people(Iterable<PersonInfo> people) => [
        for (final p in people)
          if (!hidesUser(p.uid)) p,
      ];

  List<AppNotification> notifications(Iterable<AppNotification> items) => [
        for (final n in items)
          if (!hidesUser(n.from.uid)) n,
      ];

  /// Un comentario tal como hay que mostrarlo: con las palabras ofensivas
  /// tapadas si el filtro está encendido.
  String text(String value) => filterOffensive ? maskOffensive(value) : value;

  ModerationState copyWith({
    Map<String, BlockEdge>? blocked,
    Set<String>? blockedBy,
    Map<String, MutedPerson>? muted,
    Set<String>? hidden,
    bool? filterOffensive,
  }) =>
      ModerationState(
        blocked: blocked ?? this.blocked,
        blockedBy: blockedBy ?? this.blockedBy,
        muted: muted ?? this.muted,
        hidden: hidden ?? this.hidden,
        filterOffensive: filterOffensive ?? this.filterOffensive,
      );
}

/// Qué seguimientos y contadores hay que mover al bloquear a alguien:
/// dejan de seguirse en los dos sentidos.
class BlockFollowDelta {
  const BlockFollowDelta({required this.iFollowed, required this.theyFollowed});

  /// Yo le seguía: se borra mi seguimiento.
  final bool iFollowed;

  /// Me seguía: se borra el suyo.
  final bool theyFollowed;

  int get myFollowing => iFollowed ? -1 : 0;
  int get myFollowers => theyFollowed ? -1 : 0;
  int get theirFollowers => iFollowed ? -1 : 0;
  int get theirFollowing => theyFollowed ? -1 : 0;

  bool get touchesMe => iFollowed || theyFollowed;
  bool get touchesThem => iFollowed || theyFollowed;
}
