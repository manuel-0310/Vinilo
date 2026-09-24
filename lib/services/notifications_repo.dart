import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification.dart';

/// Notificaciones dentro de la app (`notifications/{id}`).
///
/// Las crean los mismos lotes o transacciones que provocan el hecho (seguir,
/// dar "me gusta", guardar una lista), siempre con `from` = quien actúa, y
/// las reglas no dejan crearlas a nombre de otra persona ni para uno mismo.
class NotificationsRepo {
  NotificationsRepo(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  DocumentReference<Map<String, dynamic>> doc(String id) => _col.doc(id);

  /// Las últimas notificaciones de una persona, de la más reciente a la más
  /// antigua (índice compuesto `to` + `createdAt`).
  Stream<List<AppNotification>> watch(String uid, {int limit = 60}) => _col
      .where('to', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Future<void> markRead(Iterable<AppNotification> items) async {
    final unread = items.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final n in unread) {
      batch.update(_col.doc(n.id), {'read': true});
    }
    await batch.commit();
  }

  /// Borra una notificación (deslizar para borrar).
  Future<void> delete(String id) => _col.doc(id).delete();

  /// Borra todas las notificaciones de una persona, en lotes de 400.
  Future<int> deleteAll(String uid) async {
    final snap = await _col.where('to', isEqualTo: uid).get();
    for (var i = 0; i < snap.docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in snap.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    return snap.docs.length;
  }

  /// Escribe la notificación dentro de una transacción. Nunca para uno mismo.
  void putIn(Transaction tx, AppNotification n) {
    if (n.to == n.from.uid) return;
    tx.set(_col.doc(n.id), n.toMap());
  }

  void removeIn(Transaction tx, String id) => tx.delete(_col.doc(id));

  /// Igual que `putIn`, pero en un lote.
  void putInBatch(WriteBatch batch, AppNotification n) {
    if (n.to == n.from.uid) return;
    batch.set(_col.doc(n.id), n.toMap());
  }

  void removeInBatch(WriteBatch batch, String id) => batch.delete(_col.doc(id));
}
