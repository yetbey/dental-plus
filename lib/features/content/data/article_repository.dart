import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/article.dart';

class ArticleRepository {
  ArticleRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('articles');

  List<Article> _mapSorted(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs.map((d) => Article.fromMap(d.data(), d.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<Article>> watchActive() =>
      _col.where('active', isEqualTo: true).snapshots().map(_mapSorted);

  Stream<List<Article>> watchAll() => _col.snapshots().map(_mapSorted);

  Stream<Article?> watchOne(String id) => _col
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Article.fromMap(s.data()!, s.id) : null);

  Future<void> save(Article a) async {
    final data = a.toMap();
    if (a.id.isEmpty) {
      await _col.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _col.doc(a.id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> setActive(String id, bool active) =>
      _col.doc(id).update({'active': active, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> delete(String id) => _col.doc(id).delete();
}