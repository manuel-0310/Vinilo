import 'package:cloud_firestore/cloud_firestore.dart';

/// Lo que la app le manda al equipo de Vinilo:
///
/// - `problems/{id}`: "Reportar el problema" desde "Se rayó el disco" (el
///   código que vio la persona y qué falló).
/// - `requests/{id}`: "Pídenos que lo agreguemos" cuando una búsqueda no
///   encuentra un disco.
///
/// Los dos solo los lee quien modera (`admins/{uid}`).
class SupportRepo {
  SupportRepo(this._db);

  final FirebaseFirestore _db;

  /// Largo máximo del detalle de un problema (lo mismo exigen las reglas).
  static const int detailMaxLength = 500;

  /// Largo máximo de una petición de disco.
  static const int queryMaxLength = 120;

  Future<void> reportProblem({
    required String uid,
    required String code,
    required String detail,
  }) {
    return _db.collection('problems').add({
      'uid': uid,
      'code': code.length > 40 ? code.substring(0, 40) : code,
      'detail': clip(detail, detailMaxLength),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestAlbum({required String uid, required String query}) {
    return _db.collection('requests').add({
      'uid': uid,
      'query': clip(query.trim(), queryMaxLength),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Recorta un texto a `max` caracteres.
  static String clip(String text, int max) => text.length > max ? text.substring(0, max) : text;
}
