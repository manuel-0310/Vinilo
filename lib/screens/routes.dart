import 'package:flutter/cupertino.dart';

import '../models/album.dart';
import '../services/services.dart';
import 'album_screen.dart';
import 'profile_screen.dart';

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
