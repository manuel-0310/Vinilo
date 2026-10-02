import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

import '../models/moderation.dart';
import '../models/user_profile.dart';
import 'account_service.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'follow_repo.dart';
import 'lists_repo.dart';
import 'moderation_repo.dart';
import 'notifications_repo.dart';
import 'palette.dart';
import 'ratings_repo.dart';
import 'recovery_service.dart';
import 'replies_repo.dart';
import 'spotify_api.dart';
import 'support_repo.dart';
import 'user_repo.dart';
import 'web_service.dart';

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
    required this.replies,
    required this.account,
    required this.web,
    required this.moderation,
    required this.recovery,
    required this.connectivity,
    required this.support,
  });

  factory Services.create() {
    final auth = AuthService();
    final db = FirebaseFirestore.instance;
    final notifications = NotificationsRepo(db);
    final follows = FollowRepo(db, notifications);
    final lists = ListsRepo(db, notifications);
    final replies = RepliesRepo(db, notifications);
    final connectivity = ConnectivityService();
    return Services._(
      auth: auth,
      spotify: SpotifyApi(
        baseUrl: SpotifyApi.configuredUrl,
        idToken: auth.idToken,
        onReachable: (ok) => ok ? connectivity.reportSuccess() : connectivity.reportFailure(),
      ),
      users: UserRepo(
        db,
        FirebaseStorage.instance,
        follows: follows,
        lists: lists,
        replies: replies,
      ),
      ratings: RatingsRepo(db, notifications, replies: replies),
      palette: PaletteService(),
      follows: follows,
      notifications: notifications,
      lists: lists,
      replies: replies,
      account: AccountService(auth: auth, spotifyUrl: SpotifyApi.configuredUrl),
      web: WebService(spotifyUrl: SpotifyApi.configuredUrl),
      moderation: ModerationRepo(db, notifications),
      recovery: RecoveryService(spotifyUrl: SpotifyApi.configuredUrl),
      connectivity: connectivity,
      support: SupportRepo(db),
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
  final RepliesRepo replies;
  final AccountService account;
  final WebService web;
  final ModerationRepo moderation;
  final RecoveryService recovery;

  /// Si hay conexión: el aviso de "Sin conexión" y la cola de notas.
  final ConnectivityService connectivity;

  /// Problemas reportados y discos que faltan.
  final SupportRepo support;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) => maybeOf(context)!;

  static Services? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ServicesScope>()?.services;

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

/// Lo que hay que esconderle a quien usa la app (bloqueos, silenciados,
/// comentarios ocultos y el filtro de palabras), disponible en todo el
/// árbol como `CurrentUser`. Sin sesión, o mientras carga, no esconde nada.
class Moderation extends InheritedWidget {
  const Moderation({super.key, required this.state, required super.child});

  final ModerationState state;

  static ModerationState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Moderation>()?.state ??
      const ModerationState();

  @override
  bool updateShouldNotify(Moderation oldWidget) => state != oldWidget.state;
}
