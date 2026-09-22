import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'album.dart';
import 'rating.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.avatarUrl,
    this.ratingsCount = 0,
    this.ratingsSum = 0,
    this.favorites = const [],
    this.recentSearches = const [],
  });

  final String uid;
  final String name;
  final int colorValue;
  final String? avatarUrl;
  final DateTime createdAt;
  final int ratingsCount;
  final num ratingsSum;
  final List<Album> favorites;
  final List<String> recentSearches;

  Color get color => Color(colorValue);
  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();
  double? get average => ratingsCount == 0 ? null : ratingsSum / ratingsCount;

  RaterInfo get rater => RaterInfo(
        uid: uid,
        name: name,
        colorValue: colorValue,
        avatarUrl: avatarUrl,
      );

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      name: (d['name'] ?? '') as String,
      colorValue: (d['color'] as num?)?.toInt() ?? 0xFFE8A04B,
      avatarUrl: d['avatarUrl'] as String?,
      createdAt: dateFrom(d['createdAt']),
      ratingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
      ratingsSum: (d['ratingsSum'] as num?) ?? 0,
      favorites: ((d['favorites'] as List?) ?? const [])
          .map((m) => Album.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      recentSearches:
          List<String>.from((d['recentSearches'] as List?) ?? const []),
    );
  }
}
