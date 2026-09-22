import 'package:flutter/cupertino.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/rating.dart';
import '../services/services.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'comments_screen.dart';
import 'diary_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

Future<void> openAlbum(
  BuildContext context,
  Album album, {
  required String heroTag,
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => AlbumScreen(album: album, heroTag: heroTag),
    ),
  );
}

Future<void> openUser(BuildContext context, String uid) {
  final me = CurrentUser.maybeOf(context);
  return Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => ProfileScreen(
        uid: uid,
        isMe: me?.uid == uid,
        standalone: true,
      ),
    ),
  );
}

Future<void> openDiary(
  BuildContext context, {
  required String uid,
  required String name,
  required bool isMe,
  required List<RatingEntry> initial,
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => DiaryScreen(
        uid: uid,
        name: name,
        isMe: isMe,
        initial: initial,
      ),
    ),
  );
}

Future<void> openComments(
  BuildContext context, {
  required Album album,
  required List<RatingEntry> initial,
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => CommentsScreen(album: album, initial: initial),
    ),
  );
}

Future<void> openSettings(BuildContext context) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => const SettingsScreen()),
  );
}

Future<void> openArtist(BuildContext context, Artist artist) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => ArtistScreen(artist: artist)),
  );
}
