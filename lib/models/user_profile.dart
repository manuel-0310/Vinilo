import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'album.dart';
import 'artist.dart';
import 'follow.dart';
import 'rating.dart';

/// Preferencia de apariencia guardada en el documento del usuario.
ThemeMode themeModeFrom(String? raw) => switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

String themeModeKey(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };

/// Idiomas de la app. `null` (o "system" en Firestore) sigue al teléfono.
const List<String> appLanguages = ['es', 'en'];

String? languageFrom(String? raw) => appLanguages.contains(raw) ? raw : null;

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.username,
    this.avatarUrl,
    this.bannerUrl,
    this.ratingsCount = 0,
    this.ratingsSum = 0,
    this.favorites = const [],
    this.favoriteArtists = const [],
    this.recentSearches = const [],
    this.themeMode = ThemeMode.dark,
    this.language,
    this.followersCount = 0,
    this.followingCount = 0,
    this.nameLower,
    this.bio,
  });

  final String uid;
  final String name;
  final int colorValue;

  /// @usuario único (minúsculas, 3 a 20, letras, números, punto y guion
  /// bajo). Null solo en perfiles creados antes de que existiera: la app
  /// pide elegirlo antes de entrar.
  final String? username;
  final String? avatarUrl;

  /// Foto de fondo del perfil (como en X). Null: degradado del color.
  final String? bannerUrl;
  final DateTime createdAt;
  final int ratingsCount;
  final num ratingsSum;

  /// Hasta 3 discos (los perfiles viejos pueden traer 4; se muestran 3).
  final List<Album> favorites;
  final List<Artist> favoriteArtists;
  final List<String> recentSearches;
  final ThemeMode themeMode;

  /// "es" o "en"; null sigue el idioma del teléfono.
  final String? language;

  Locale? get locale => language == null ? null : Locale(language!);

  /// Biografía corta (hasta 160 caracteres); null o vacía si no tiene.
  final String? bio;
  final int followersCount;
  final int followingCount;

  /// Nombre en minúsculas para buscar personas por prefijo. Null en los
  /// perfiles de antes: la app lo completa al entrar.
  final String? nameLower;

  Color get color => Color(colorValue);

  /// "@usuario", o vacío si todavía no lo eligió.
  String get handle => username == null ? '' : '@$username';
  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();
  double? get average => ratingsCount == 0 ? null : ratingsSum / ratingsCount;

  RaterInfo get rater => RaterInfo(
        uid: uid,
        name: name,
        colorValue: colorValue,
        avatarUrl: avatarUrl,
      );

  PersonInfo get person => PersonInfo(
        uid: uid,
        name: name,
        colorValue: colorValue,
        username: username,
        avatarUrl: avatarUrl,
      );

  /// Con qué texto se busca a esta persona por nombre.
  static String searchKey(String name) => name.trim().toLowerCase();

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      name: (d['name'] ?? '') as String,
      colorValue: (d['color'] as num?)?.toInt() ?? 0xFFE8A04B,
      username: d['username'] as String?,
      avatarUrl: d['avatarUrl'] as String?,
      bannerUrl: d['bannerUrl'] as String?,
      createdAt: dateFrom(d['createdAt']),
      ratingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
      ratingsSum: (d['ratingsSum'] as num?) ?? 0,
      favorites: ((d['favorites'] as List?) ?? const [])
          .map((m) => Album.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      favoriteArtists: ((d['favoriteArtists'] as List?) ?? const [])
          .map((m) => Artist.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      recentSearches:
          List<String>.from((d['recentSearches'] as List?) ?? const []),
      themeMode: themeModeFrom(d['theme'] as String?),
      language: languageFrom(d['language'] as String?),
      bio: d['bio'] as String?,
      followersCount: (d['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (d['followingCount'] as num?)?.toInt() ?? 0,
      nameLower: d['nameLower'] as String?,
    );
  }
}
