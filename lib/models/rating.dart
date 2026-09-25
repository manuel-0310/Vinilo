import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'album.dart';

DateTime dateFrom(dynamic value) =>
    value is Timestamp ? value.toDate() : DateTime.now();

/// Datos mínimos de quien califica, denormalizados dentro de cada nota
/// para poder pintar el feed sin leer el perfil.
class RaterInfo {
  const RaterInfo({
    required this.uid,
    required this.name,
    required this.colorValue,
    this.avatarUrl,
  });

  final String uid;
  final String name;
  final int colorValue;
  final String? avatarUrl;

  Color get color => Color(colorValue);

  factory RaterInfo.fromMap(String uid, Map<String, dynamic> m) => RaterInfo(
        uid: uid,
        name: (m['name'] ?? 'Alguien') as String,
        colorValue: (m['color'] as num?)?.toInt() ?? 0xFFE8A04B,
        avatarUrl: m['avatarUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': colorValue,
        'avatarUrl': avatarUrl,
      };
}

/// Una nota en el diario: quién, qué álbum, qué puntaje y una línea opcional.
class RatingEntry {
  const RatingEntry({
    required this.id,
    required this.uid,
    required this.albumId,
    required this.score,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.album,
    required this.user,
    this.likedBy = const [],
    this.repliesCount = 0,
  });

  final String id;
  final String uid;
  final String albumId;
  final int score;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Album album;
  final RaterInfo user;
  final List<String> likedBy;

  /// Cuántas respuestas tiene su hilo (`ratings/{id}/replies`).
  final int repliesCount;

  static String docId(String uid, String albumId) => '${uid}_$albumId';

  factory RatingEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final uid = (d['uid'] ?? '') as String;
    return RatingEntry(
      id: doc.id,
      uid: uid,
      albumId: (d['albumId'] ?? '') as String,
      score: (d['score'] as num?)?.toInt() ?? 0,
      note: (d['note'] ?? '') as String,
      createdAt: dateFrom(d['createdAt']),
      updatedAt: dateFrom(d['updatedAt']),
      album: Album.fromMap(Map<String, dynamic>.from((d['album'] as Map?) ?? {})),
      user: RaterInfo.fromMap(
        uid,
        Map<String, dynamic>.from((d['user'] as Map?) ?? {}),
      ),
      likedBy: List<String>.from((d['likedBy'] as List?) ?? const []),
      repliesCount: (d['repliesCount'] as num?)?.toInt() ?? 0,
    );
  }

  int get likes => likedBy.length;
  bool likedByMe(String me) => likedBy.contains(me);
  bool get hasNote => note.trim().isNotEmpty;
}

/// Agregados de un álbum: cuánta gente lo calificó y cómo se reparten las notas.
class AlbumStats {
  const AlbumStats({
    required this.album,
    required this.count,
    required this.sum,
    required this.hist,
    this.lastRatedAt,
  });

  final Album album;
  final int count;
  final num sum;
  final Map<int, int> hist;
  final DateTime? lastRatedAt;

  double get average => count == 0 ? 0 : sum / count;

  factory AlbumStats.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawHist = Map<String, dynamic>.from((d['hist'] as Map?) ?? {});
    return AlbumStats(
      album: Album.fromMap(d),
      count: (d['ratingsCount'] as num?)?.toInt() ?? 0,
      sum: (d['ratingsSum'] as num?) ?? 0,
      hist: {
        for (var i = 1; i <= 10; i++) i: (rawHist['$i'] as num?)?.toInt() ?? 0,
      },
      lastRatedAt:
          d['lastRatedAt'] is Timestamp ? (d['lastRatedAt'] as Timestamp).toDate() : null,
    );
  }
}
