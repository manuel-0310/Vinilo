import 'rating.dart';

/// Datos mínimos de una persona, denormalizados dentro de los seguimientos,
/// las listas y las notificaciones para pintarlos sin leer su perfil.
class PersonInfo {
  const PersonInfo({
    required this.uid,
    required this.name,
    required this.colorValue,
    this.username,
    this.avatarUrl,
  });

  final String uid;
  final String name;
  final int colorValue;
  final String? username;
  final String? avatarUrl;

  String get handle => username == null ? '' : '@$username';

  RaterInfo get rater => RaterInfo(
        uid: uid,
        name: name,
        colorValue: colorValue,
        avatarUrl: avatarUrl,
      );

  factory PersonInfo.fromMap(String uid, Map<String, dynamic> m) => PersonInfo(
        uid: uid,
        name: (m['name'] ?? 'Alguien') as String,
        colorValue: (m['color'] as num?)?.toInt() ?? 0xFFE8A04B,
        username: m['username'] as String?,
        avatarUrl: m['avatarUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': colorValue,
        'username': username,
        'avatarUrl': avatarUrl,
      };
}

/// Un seguimiento: `follower` sigue a `followed`. El documento se llama
/// `{follower}_{followed}`, así comprobar si sigo a alguien es una lectura.
class FollowEdge {
  const FollowEdge({
    required this.follower,
    required this.followed,
    required this.createdAt,
    required this.followerInfo,
    required this.followedInfo,
  });

  final String follower;
  final String followed;
  final DateTime createdAt;
  final PersonInfo followerInfo;
  final PersonInfo followedInfo;

  static String docId(String follower, String followed) => '${follower}_$followed';

  factory FollowEdge.fromMap(Map<String, dynamic> d) {
    final follower = (d['follower'] ?? '') as String;
    final followed = (d['followed'] ?? '') as String;
    return FollowEdge(
      follower: follower,
      followed: followed,
      createdAt: dateFrom(d['createdAt']),
      followerInfo: PersonInfo.fromMap(
        follower,
        Map<String, dynamic>.from((d['followerInfo'] as Map?) ?? {}),
      ),
      followedInfo: PersonInfo.fromMap(
        followed,
        Map<String, dynamic>.from((d['followedInfo'] as Map?) ?? {}),
      ),
    );
  }
}

/// Qué hay que escribir para seguir o dejar de seguir, según si el
/// seguimiento ya existe. Los contadores se mueven en la misma transacción
/// que crea o borra el documento, y solo cuando de verdad cambia algo.
class FollowDelta {
  const FollowDelta._({
    required this.createEdge,
    required this.deleteEdge,
    required this.followersDelta,
    required this.followingDelta,
  });

  /// Nada que hacer (ya estaba en el estado pedido).
  static const FollowDelta none = FollowDelta._(
    createEdge: false,
    deleteEdge: false,
    followersDelta: 0,
    followingDelta: 0,
  );

  final bool createEdge;
  final bool deleteEdge;

  /// Cambio en `followersCount` de la persona seguida.
  final int followersDelta;

  /// Cambio en `followingCount` de quien sigue.
  final int followingDelta;

  bool get isNoop => !createEdge && !deleteEdge;
}

/// Decide el cambio. Seguirse a uno mismo nunca hace nada.
FollowDelta followDelta({
  required String me,
  required String other,
  required bool exists,
  required bool follow,
}) {
  if (me == other) return FollowDelta.none;
  if (follow && !exists) {
    return const FollowDelta._(
      createEdge: true,
      deleteEdge: false,
      followersDelta: 1,
      followingDelta: 1,
    );
  }
  if (!follow && exists) {
    return const FollowDelta._(
      createEdge: false,
      deleteEdge: true,
      followersDelta: -1,
      followingDelta: -1,
    );
  }
  return FollowDelta.none;
}

/// Un contador nunca baja de cero aunque los datos vengan desparejados.
int applyCounter(int current, int delta) {
  final next = current + delta;
  return next < 0 ? 0 : next;
}
