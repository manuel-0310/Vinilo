import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/follow.dart';
import '../models/music_list.dart';
import '../models/notification.dart';
import '../models/user_profile.dart';
import 'notifications_repo.dart';

/// Listas y rankings en `lists/{id}`, con los elementos copiados dentro.
class ListsRepo {
  ListsRepo(this._db, this._notifications);

  final FirebaseFirestore _db;
  final NotificationsRepo _notifications;

  CollectionReference<Map<String, dynamic>> get _lists =>
      _db.collection('lists');

  List<MusicList> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = snap.docs.map(MusicList.fromDoc).toList();
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  /// Las listas de una persona, la editada más recientemente primero.
  Stream<List<MusicList>> ownedBy(String uid) => _lists
      .where('ownerUid', isEqualTo: uid)
      .snapshots()
      .map(_sorted);

  Future<List<MusicList>> fetchOwnedBy(String uid) async =>
      _sorted(await _lists.where('ownerUid', isEqualTo: uid).get());

  /// Las listas que guardó `uid` (de otras personas). Si su autora borra
  /// una, simplemente deja de aparecer.
  Stream<List<MusicList>> savedBy(String uid) => _lists
      .where('savedBy', arrayContains: uid)
      .snapshots()
      .map(_sorted);

  Stream<MusicList?> watch(String id) => _lists
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? MusicList.fromDoc(s) : null);

  Future<MusicList?> fetch(String id) async {
    final snap = await _lists.doc(id).get();
    return snap.exists ? MusicList.fromDoc(snap) : null;
  }

  /// Crea la lista con los elementos iniciales (ya sin repetidos) y la
  /// devuelve tal como quedó.
  Future<MusicList> create({
    required UserProfile owner,
    required String name,
    required String description,
    required ListKind kind,
    required ListItemType itemType,
    List<ListItem> items = const [],
  }) async {
    final ref = _lists.doc();
    final clean = addItems(const [], items).items;
    await ref.set({
      'ownerUid': owner.uid,
      'owner': owner.person.toMap(),
      'name': name.trim(),
      'description': description.trim(),
      'kind': kind.key,
      'itemType': itemType.key,
      'items': clean.map((i) => i.toMap()).toList(),
      'likedBy': <String>[],
      'savedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final now = DateTime.now();
    return MusicList(
      id: ref.id,
      ownerUid: owner.uid,
      owner: owner.person,
      name: name.trim(),
      description: description.trim(),
      kind: kind,
      itemType: itemType,
      items: clean,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateMeta(String id, {required String name, required String description}) {
    return _lists.doc(id).update({
      'name': name.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reemplaza los elementos (reordenar, quitar).
  Future<void> setItems(String id, List<ListItem> items) {
    return _lists.doc(id).update({
      'items': items.take(MusicList.maxItems).map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Agrega sin repetir, leyendo el estado actual dentro de la transacción
  /// para no pisar cambios hechos desde otro dispositivo. Devuelve qué pasó
  /// para contárselo a la persona.
  Future<AddOutcome> addTo(String listId, Iterable<ListItem> incoming) {
    final ref = _lists.doc(listId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('La lista ya no existe.');
      final current = MusicList.fromDoc(snap);
      final outcome = addItems(current.items, incoming);
      if (outcome.added > 0) {
        tx.update(ref, {
          'items': outcome.items.map((i) => i.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return outcome;
    });
  }

  Future<void> delete(String id) => _lists.doc(id).delete();

  String _notificationId(MusicList list, NotificationType type, String me) =>
      AppNotification.idFor(to: list.ownerUid, type: type, from: me, target: list.id);

  /// Dar o quitar mi "me gusta" a la lista de otra persona (nunca a la
  /// propia), con su notificación en el mismo lote.
  Future<void> toggleLike(MusicList list, UserProfile me) =>
      _toggle(list, me, field: 'likedBy', on: !list.likedByMe(me.uid), type: NotificationType.likeList);

  /// Guardar o dejar de guardar la lista de otra persona.
  Future<void> toggleSave(MusicList list, UserProfile me) =>
      _toggle(list, me, field: 'savedBy', on: !list.savedByMe(me.uid), type: NotificationType.saveList);

  Future<void> _toggle(
    MusicList list,
    UserProfile me, {
    required String field,
    required bool on,
    required NotificationType type,
  }) {
    if (list.isMine(me.uid)) return Future.value();
    final batch = _db.batch();
    batch.update(_lists.doc(list.id), {
      field: on ? FieldValue.arrayUnion([me.uid]) : FieldValue.arrayRemove([me.uid]),
    });
    final id = _notificationId(list, type, me.uid);
    if (on) {
      _notifications.putInBatch(
        batch,
        AppNotification(
          id: id,
          to: list.ownerUid,
          from: me.person,
          type: type,
          createdAt: DateTime.now(),
          read: false,
          listId: list.id,
          listName: list.name,
        ),
      );
    } else {
      _notifications.removeInBatch(batch, id);
    }
    return batch.commit();
  }

  /// Copia el nombre, color, foto y @usuario nuevos en todas las listas de
  /// la persona.
  Future<void> propagateOwner(PersonInfo person) async {
    final snap = await _lists.where('ownerUid', isEqualTo: person.uid).get();
    if (snap.docs.isEmpty) return;
    var batch = _db.batch();
    var pending = 0;
    for (final d in snap.docs) {
      batch.update(d.reference, {'owner': person.toMap()});
      if (++pending == 400) {
        await batch.commit();
        batch = _db.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();
  }
}
