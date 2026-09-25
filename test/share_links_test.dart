import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/l10n/app_localizations.dart';
import 'package:no_retiene/models/album.dart';
import 'package:no_retiene/models/artist.dart';
import 'package:no_retiene/models/follow.dart';
import 'package:no_retiene/models/music_list.dart';
import 'package:no_retiene/models/rating.dart';
import 'package:no_retiene/models/user_profile.dart';
import 'package:no_retiene/util/share_links.dart';

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  const album = Album(id: 'alb1', name: 'OK Computer', artist: 'Radiohead');
  const owner = PersonInfo(uid: 'u1', name: 'Vale Ríos', colorValue: 0xFF5FA8D3, username: 'vale.rios');

  MusicList list(ListKind kind) => MusicList(
        id: 'lista9',
        ownerUid: 'u1',
        owner: owner,
        name: 'Para llover',
        description: '',
        kind: kind,
        itemType: ListItemType.albums,
        items: const [],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  final entry = RatingEntry(
    id: 'u1_alb1',
    uid: 'u1',
    albumId: 'alb1',
    score: 9,
    note: '',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    album: album,
    user: owner.rater,
  );

  group('ShareLinks', () {
    test('cada tipo tiene su ruta en la web de Firebase', () {
      expect(ShareLinks.list('abc').toString(), 'https://red-social-c786b.web.app/l/abc');
      expect(ShareLinks.album('4LH4d3cOWNNsVw41Gqt2kv').toString(),
          'https://red-social-c786b.web.app/d/4LH4d3cOWNNsVw41Gqt2kv');
      expect(ShareLinks.rating('u1_alb1').toString(), 'https://red-social-c786b.web.app/n/u1_alb1');
      expect(ShareLinks.artist('art').toString(), 'https://red-social-c786b.web.app/a/art');
    });

    test('el perfil usa el @usuario y, sin él, el uid', () {
      expect(ShareLinks.profile(username: 'vale.rios', uid: 'u1').toString(),
          'https://red-social-c786b.web.app/u/vale.rios');
      expect(ShareLinks.profile(username: null, uid: 'u1').toString(),
          'https://red-social-c786b.web.app/u/u1');
      expect(ShareLinks.profile(username: '', uid: 'u1').path, '/u/u1');
    });
  });

  group('mensajes', () {
    test('lista y ranking, propios y ajenos', () {
      expect(shareListMessage(list(ListKind.list), es, mine: true).text, 'Mira mi lista «Para llover» en Vinilo');
      expect(shareListMessage(list(ListKind.ranking), es, mine: false).text,
          'Mira el ranking «Para llover» de Vale Ríos en Vinilo');
      expect(shareListMessage(list(ListKind.list), en, mine: false).text,
          'Check out “Para llover”, a list by Vale Ríos on Vinilo');
      expect(shareListMessage(list(ListKind.list), es, mine: true).url.path, '/l/lista9');
    });

    test('disco y nota', () {
      expect(shareAlbumMessage(album, es).text, 'OK Computer de Radiohead, en Vinilo');
      expect(shareAlbumMessage(album, es).url.path, '/d/alb1');
      expect(shareRatingMessage(entry, es, mine: true).text, 'Le di 9/10 a OK Computer de Radiohead en Vinilo');
      expect(shareRatingMessage(entry, en, mine: false).text, 'Vale Ríos gave OK Computer a 9/10 on Vinilo');
      expect(shareRatingMessage(entry, es, mine: false).url.path, '/n/u1_alb1');
    });

    test('artista y perfil', () {
      const artist = Artist(id: 'art', name: 'Radiohead');
      expect(shareArtistMessage(artist, es).url.path, '/a/art');
      final profile = UserProfile(
        uid: 'u1',
        name: 'Vale Ríos',
        colorValue: 0xFF5FA8D3,
        createdAt: DateTime(2026),
        username: 'vale.rios',
      );
      expect(shareProfileMessage(profile, es, mine: true).text, 'Sigue mi diario de discos en Vinilo');
      expect(shareProfileMessage(profile, en, mine: false).text, "Check out Vale Ríos's album diary on Vinilo");
      expect(shareProfileMessage(profile, es, mine: false).url.path, '/u/vale.rios');
    });
  });
}
