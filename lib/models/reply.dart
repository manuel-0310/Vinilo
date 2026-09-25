import 'package:cloud_firestore/cloud_firestore.dart';

import 'follow.dart';
import 'notification.dart';
import 'rating.dart';

/// Largo máximo de una respuesta.
const int replyMaxLength = 280;

/// Una respuesta a una nota (a su comentario). Vive en
/// `ratings/{ratingId}/replies/{id}`, de un solo nivel como en Instagram:
/// para contestarle a alguien del hilo se le menciona con su @.
class Reply {
  const Reply({
    required this.id,
    required this.ratingId,
    required this.ratingUid,
    required this.uid,
    required this.user,
    required this.text,
    required this.createdAt,
    this.mentions = const [],
  });

  final String id;
  final String ratingId;

  /// Dueña de la nota: puede borrar cualquier respuesta de su hilo.
  final String ratingUid;

  /// Quien la escribió.
  final String uid;
  final PersonInfo user;
  final String text;
  final DateTime createdAt;

  /// Personas mencionadas con su @ (se les avisa).
  final List<String> mentions;

  factory Reply.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final uid = (d['uid'] ?? '') as String;
    return Reply(
      id: doc.id,
      ratingId: doc.reference.parent.parent?.id ?? '',
      ratingUid: (d['ratingUid'] ?? '') as String,
      uid: uid,
      user: PersonInfo.fromMap(
        uid,
        Map<String, dynamic>.from((d['user'] as Map?) ?? {}),
      ),
      text: (d['text'] ?? '') as String,
      createdAt: dateFrom(d['createdAt']),
      mentions: List<String>.from((d['mentions'] as List?) ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'user': user.toMap(),
        'ratingUid': ratingUid,
        'text': text,
        'mentions': mentions,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Puede borrarla quien la escribió o la dueña de la nota.
  bool canDelete(String me) => me == uid || me == ratingUid;
}

/// Texto con el que empieza una respuesta dirigida a alguien: "@usuario ".
String replyPrefix(PersonInfo to) =>
    to.username == null || to.username!.isEmpty ? '' : '@${to.username} ';

/// Las personas de `candidates` cuyo @ sigue escrito en `text` (como palabra
/// completa: "@ana" no cuenta dentro de "@anabel"). Si alguien borra la
/// mención antes de enviar, no se le avisa.
List<String> mentionsIn(String text, Iterable<PersonInfo> candidates) {
  final handles = {
    for (final piece in splitMentions(text))
      if (piece.handle != null) piece.handle!,
  };
  return [
    for (final p in candidates)
      if (p.username != null && handles.contains(p.username!.toLowerCase())) p.uid,
  ];
}

/// Un @usuario dentro de un texto (mismas letras que admite el @usuario).
/// La @ no puede ir pegada a una palabra, así un correo no cuenta.
final RegExp mentionPattern =
    RegExp(r'(?<![a-zA-Z0-9_.])@([a-zA-Z0-9._]{3,20})(?![a-zA-Z0-9_])');

/// Un trozo de texto: normal o un @usuario.
typedef TextPiece = ({String text, String? handle});

/// Parte un texto en trozos normales y menciones, para pintar las menciones
/// en otro color y abrir su perfil al tocarlas. Un punto final pegado a la
/// mención ("@ana.") no forma parte del @usuario.
List<TextPiece> splitMentions(String text) {
  final out = <TextPiece>[];
  var last = 0;
  for (final m in mentionPattern.allMatches(text)) {
    var handle = m.group(1)!;
    var end = m.end;
    while (handle.endsWith('.')) {
      handle = handle.substring(0, handle.length - 1);
      end--;
    }
    if (handle.length < 3) continue;
    if (m.start > last) out.add((text: text.substring(last, m.start), handle: null));
    out.add((text: text.substring(m.start, end), handle: handle.toLowerCase()));
    last = end;
  }
  if (last < text.length) out.add((text: text.substring(last), handle: null));
  return out;
}

/// A quién avisar de una respuesta nueva: a la dueña de la nota ("respondió
/// a tu nota") y a cada persona mencionada ("te respondió"). Nunca a quien
/// escribe y nunca dos avisos a la misma persona: si mencionan a la dueña,
/// le llega solo el de la nota.
List<({String to, NotificationType type})> replyNotificationTargets({
  required String from,
  required String ratingUid,
  required List<String> mentions,
}) {
  final out = <({String to, NotificationType type})>[];
  if (ratingUid != from) out.add((to: ratingUid, type: NotificationType.reply));
  final seen = {from, ratingUid};
  for (final uid in mentions) {
    if (seen.add(uid)) out.add((to: uid, type: NotificationType.mention));
  }
  return out;
}

/// Un trozo corto de la respuesta para la notificación.
String replySnippet(String text, {int max = 80}) {
  final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.length <= max) return clean;
  return '${clean.substring(0, max - 1).trimRight()}…';
}
