import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

import '../models/user_profile.dart';
import 'account_service.dart';
import 'auth_service.dart';
import 'follow_repo.dart';
import 'lists_repo.dart';
import 'notifications_repo.dart';
import 'palette.dart';
import 'ratings_repo.dart';
import 'spotify_api.dart';
import 'user_repo.dart';

class Services {
  Services._({
    required this.auth,
    required this.spotify,
    required this.users,
    required this.ratings,
    required this.palette,
    required this.follows,
    required this.notifications,
    required this.lists,
    required this.account,
  });

  factory Services.create() {
    final auth = AuthService();
    final db = FirebaseFirestore.instance;
    final notifications = NotificationsRepo(db);
    final follows = FollowRepo(db, notifications);
    final lists = ListsRepo(db, notifications);
    return Services._(
      auth: auth,
      spotify: SpotifyApi(
        baseUrl: SpotifyApi.configuredUrl,
        idToken: auth.idToken,
      ),
      users: UserRepo(db, FirebaseStorage.instance, follows: follows, lists: lists),
      ratings: RatingsRepo(db, notifications),
      palette: PaletteService(),
      follows: follows,
      notifications: notifications,
      lists: lists,
      account: AccountService(auth: auth, spotifyUrl: SpotifyApi.configuredUrl),
    );
  }

  final AuthService auth;
  final SpotifyApi spotify;
  final UserRepo users;
  final RatingsRepo ratings;
  final PaletteService palette;
  final FollowRepo follows;
  final NotificationsRepo notifications;
  final ListsRepo lists;
  final AccountService account;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      services != oldWidget.services;
}

/// Perfil de la persona que usa la app, disponible en todo el árbol
/// (incluidas las rutas que se empujan sobre el shell).
class CurrentUser extends InheritedWidget {
  const CurrentUser({super.key, required this.profile, required super.child});

  final UserProfile? profile;

  static UserProfile? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CurrentUser>()?.profile;

  static UserProfile of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(CurrentUser oldWidget) => profile != oldWidget.profile;
}
