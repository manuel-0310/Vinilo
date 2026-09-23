import 'package:flutter/cupertino.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/music_list.dart';
import '../models/rating.dart';
import '../services/services.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'comments_screen.dart';
import 'diary_screen.dart';
import 'follow_list_screen.dart';
import 'list_screen.dart';
import 'notifications_screen.dart';
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

/// Seguidores (`followers: true`) o seguidos de una persona.
Future<void> openFollowList(
  BuildContext context, {
  required String uid,
  required String name,
  required bool followers,
}) {
  final me = CurrentUser.maybeOf(context);
  return Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => FollowListScreen(
        uid: uid,
        name: name,
        isMe: me?.uid == uid,
        followers: followers,
      ),
    ),
  );
}

/// Una lista o ranking. `initial` evita el parpadeo mientras llega el
/// documento.
Future<void> openList(
  BuildContext context, {
  required String listId,
  MusicList? initial,
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => ListScreen(listId: listId, initial: initial),
    ),
  );
}

Future<void> openNotifications(BuildContext context) {
  return Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => const NotificationsScreen()),
  );
}
