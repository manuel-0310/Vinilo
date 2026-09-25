import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/notification.dart';

AppNotification notif(NotificationType type, {Album? album, String? listName, String? snippet}) {
  return AppNotification(
    id: 'n',
    to: 'yo',
    from: const PersonInfo(uid: 'c', name: 'Camila Duarte', colorValue: 0xFFFFFFFF),
    type: type,
    createdAt: DateTime(2026, 9, 24),
    read: false,
    album: album,
    listName: listName,
    snippet: snippet,
  );
}

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));
  const album = Album(id: 'a', name: 'Hail to the Thief', artist: 'Radiohead');

  test('en negrita quien la provocó y el disco', () {
    final n = notif(NotificationType.likeRating, album: album);
    expect(n.parts(es), [
      ('A ', false),
      ('Camila Duarte', true),
      (' le gustó tu nota de ', false),
      ('Hail to the Thief', true),
    ]);
    expect(n.parts(en).where((p) => p.$2).map((p) => p.$1), ['Camila Duarte', 'Hail to the Thief']);
  });

  test('los trozos arman la misma frase que text()', () {
    for (final n in [
      notif(NotificationType.follow),
      notif(NotificationType.likeRating, album: album),
      notif(NotificationType.saveList, listName: 'Para llover'),
      notif(NotificationType.reply, album: album, snippet: 'De acuerdo'),
      notif(NotificationType.mention),
    ]) {
      for (final l in [es, en]) {
        expect(n.parts(l).map((p) => p.$1).join(), n.text(l));
      }
    }
  });

  test('un seguimiento solo resalta el nombre', () {
    expect(notif(NotificationType.follow).parts(es), [
      ('Camila Duarte', true),
      (' empezó a seguirte', false),
    ]);
  });
}
