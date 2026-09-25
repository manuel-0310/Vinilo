import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n.dart';
import 'album.dart';
import 'follow.dart';
import 'rating.dart';

/// Qué pasó: alguien empezó a seguirme, le gustó mi nota, le gustó mi lista,
/// guardó mi lista, respondió a mi nota o me respondió (me mencionó) en el
/// hilo de una nota.
enum NotificationType {
  follow('follow'),
  likeRating('likeRating'),
  likeList('likeList'),
  saveList('saveList'),
  reply('reply'),
  mention('mention');

  const NotificationType(this.key);

  final String key;

  static NotificationType? fromKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Una notificación dentro de la app. Vive en `notifications/{id}` con el
/// destinatario en `to` y quien la provocó en `from`; el id es determinista
/// (`{to}_{tipo}_{from}_{objetivo}`) para que dar y quitar un "me gusta" no
/// acumule entradas repetidas.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.to,
    required this.from,
    required this.type,
    required this.createdAt,
    required this.read,
    this.album,
    this.ratingId,
    this.listId,
    this.listName,
    this.snippet,
  });

  final String id;
  final String to;
  final PersonInfo from;
  final NotificationType type;
  final DateTime createdAt;
  final bool read;

  /// Disco de la nota (para `likeRating`, `reply` y `mention`).
  final Album? album;
  final String? ratingId;

  /// Un trozo de la respuesta (para `reply` y `mention`).
  final String? snippet;

  /// Lista (para `likeList` y `saveList`).
  final String? listId;
  final String? listName;

  static String idFor({
    required String to,
    required NotificationType type,
    required String from,
    String target = '',
  }) =>
      [to, type.key, from, if (target.isNotEmpty) target].join('_');

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final from = (d['from'] ?? '') as String;
    final albumMap = d['album'] as Map?;
    return AppNotification(
      id: doc.id,
      to: (d['to'] ?? '') as String,
      from: PersonInfo.fromMap(
        from,
        Map<String, dynamic>.from((d['fromInfo'] as Map?) ?? {}),
      ),
      type: NotificationType.fromKey(d['type'] as String?) ??
          NotificationType.follow,
      createdAt: dateFrom(d['createdAt']),
      read: d['read'] == true,
      album: albumMap == null
          ? null
          : Album.fromMap(Map<String, dynamic>.from(albumMap)),
      ratingId: d['ratingId'] as String?,
      listId: d['listId'] as String?,
      listName: d['listName'] as String?,
      snippet: d['text'] as String?,
    );
  }

  /// Datos para crear (o refrescar) la notificación. `createdAt` lo pone el
  /// servidor y `read` vuelve a false: si alguien quita y vuelve a dar su
  /// "me gusta", la notificación sube arriba otra vez.
  Map<String, dynamic> toMap() => {
        'to': to,
        'from': from.uid,
        'fromInfo': from.toMap(),
        'type': type.key,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        if (album != null) 'album': album!.toMap(),
        if (ratingId != null) 'ratingId': ratingId,
        if (listId != null) 'listId': listId,
        if (listName != null) 'listName': listName,
        if (snippet != null) 'text': snippet,
      };

  /// Frase completa, con el nombre de quien la provocó, en el idioma de
  /// quien la lee.
  String text(AppLocalizations l) => _sentence(l, from.name, _target(l));

  /// La misma frase en trozos, para pintar en negrita a quien la provocó y
  /// el disco o la lista: `(texto, resaltado)`.
  List<(String, bool)> parts(AppLocalizations l) {
    const nameMark = '\u{E000}';
    const targetMark = '\u{E001}';
    final out = <(String, bool)>[];
    final plain = StringBuffer();
    void flush() {
      if (plain.isEmpty) return;
      out.add((plain.toString(), false));
      plain.clear();
    }

    for (final rune in _sentence(l, nameMark, targetMark).runes) {
      final ch = String.fromCharCode(rune);
      if (ch == nameMark || ch == targetMark) {
        flush();
        final value = ch == nameMark ? from.name : _target(l);
        if (value.isNotEmpty) out.add((value, true));
      } else {
        plain.write(ch);
      }
    }
    flush();
    return out;
  }

  /// El disco o la lista de la que se habla (nada en un seguimiento).
  String _target(AppLocalizations l) => switch (type) {
        NotificationType.follow => '',
        NotificationType.likeList || NotificationType.saveList => listName ?? '',
        NotificationType.likeRating ||
        NotificationType.reply ||
        NotificationType.mention =>
          album?.name ?? l.notifSomeAlbum,
      };

  String _sentence(AppLocalizations l, String name, String target) => switch (type) {
        NotificationType.follow => l.notifFollow(name),
        NotificationType.likeRating => l.notifLikeRating(name, target),
        NotificationType.likeList => l.notifLikeList(name, target),
        NotificationType.saveList => l.notifSaveList(name, target),
        NotificationType.reply => l.notifReply(name, target, snippet ?? ''),
        NotificationType.mention => l.notifMention(name, target, snippet ?? ''),
      };

  /// Las que llevan al hilo de una nota.
  bool get opensThread =>
      type == NotificationType.reply || type == NotificationType.mention;
}
