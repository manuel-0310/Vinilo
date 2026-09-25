import '../l10n/l10n.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../models/user_profile.dart';

/// Lo que se comparte: una frase en el idioma de quien comparte y el enlace.
typedef ShareMessage = ({String text, Uri url});

/// Enlaces públicos de Vinilo. Abren la página web (Firebase Hosting, función
/// `web`), que muestra lo compartido a quien no tiene la app y la invita a
/// descargarla.
///
/// | Qué | Ruta |
/// |---|---|
/// | Lista o ranking | `/l/{listId}` |
/// | Disco (promedio de la comunidad) | `/d/{albumId}` |
/// | Una nota (disco, nota, comentario) | `/n/{uid}_{albumId}` |
/// | Artista | `/a/{artistId}` |
/// | Perfil | `/u/{usuario}` (o `/u/{uid}` si no tiene @) |
class ShareLinks {
  ShareLinks._();

  static const String host = 'red-social-c786b.web.app';

  static Uri list(String listId) => _uri(['l', listId]);
  static Uri album(String albumId) => _uri(['d', albumId]);
  static Uri rating(String ratingId) => _uri(['n', ratingId]);
  static Uri artist(String artistId) => _uri(['a', artistId]);
  static Uri profile({String? username, required String uid}) =>
      _uri(['u', username == null || username.isEmpty ? uid : username]);

  static Uri _uri(List<String> segments) =>
      Uri(scheme: 'https', host: host, pathSegments: segments);
}

ShareMessage shareListMessage(MusicList list, AppLocalizations l, {required bool mine}) {
  final ranking = list.kind == ListKind.ranking;
  final text = mine
      ? (ranking ? l.shareRankingMine(list.name) : l.shareListMine(list.name))
      : (ranking
          ? l.shareRankingOf(list.name, list.owner.name)
          : l.shareListOf(list.name, list.owner.name));
  return (text: text, url: ShareLinks.list(list.id));
}

ShareMessage shareAlbumMessage(Album album, AppLocalizations l) =>
    (text: l.shareAlbum(album.name, album.artist), url: ShareLinks.album(album.id));

/// Una nota: la mía ("Le di 8/10 a …") o la de otra persona.
ShareMessage shareRatingMessage(RatingEntry entry, AppLocalizations l, {required bool mine}) {
  final text = mine
      ? l.shareRatingMine(entry.score, entry.album.name, entry.album.artist)
      : l.shareRatingOf(entry.user.name, entry.score, entry.album.name);
  return (text: text, url: ShareLinks.rating(entry.id));
}

ShareMessage shareArtistMessage(Artist artist, AppLocalizations l) =>
    (text: l.shareArtist(artist.name), url: ShareLinks.artist(artist.id));

ShareMessage shareProfileMessage(UserProfile profile, AppLocalizations l, {required bool mine}) => (
      text: mine ? l.shareProfileMine : l.shareProfileOf(profile.name),
      url: ShareLinks.profile(username: profile.username, uid: profile.uid),
    );
