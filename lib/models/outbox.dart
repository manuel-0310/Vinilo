import 'package:cloud_firestore/cloud_firestore.dart';

import 'album.dart';
import 'rating.dart';

/// Una nota que no se pudo guardar por falta de conexión. Vive en
/// `users/{uid}/outbox/{albumId}`: Firestore la deja en el teléfono hasta
/// que vuelve la señal y entonces la app la guarda de verdad (con sus
/// agregados) y la borra de la cola. Una por disco: volver a calificar el
/// mismo disco sin conexión la reemplaza.
class PendingRating {
  const PendingRating({
    required this.album,
    required this.score,
    required this.note,
    required this.createdAt,
  });

  final Album album;
  final int score;
  final String note;
  final DateTime createdAt;

  String get albumId => album.id;

  factory PendingRating.fromMap(Map<String, dynamic> m) => PendingRating(
        album: Album.fromMap(Map<String, dynamic>.from((m['album'] as Map?) ?? const {})),
        score: (m['score'] as num?)?.toInt() ?? 0,
        note: (m['note'] ?? '') as String,
        createdAt: dateFrom(m['createdAt']),
      );

  factory PendingRating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      PendingRating.fromMap(doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'score': score,
        'note': note,
        'album': album.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Sirve para subirse: una nota del 1 al 10 de un disco con id (las
  /// reglas rechazarían lo demás y la cola se quedaría atascada).
  bool get isValid => album.id.isNotEmpty && score >= 1 && score <= 10;
}
