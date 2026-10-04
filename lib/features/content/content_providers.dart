import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/article_repository.dart';
import 'domain/article.dart';

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepository(FirebaseFirestore.instance);
});

final articlesProvider = StreamProvider.autoDispose<List<Article>>((ref) {
  return ref.watch(articleRepositoryProvider).watchActive();
});

final allArticlesProvider = StreamProvider.autoDispose<List<Article>>((ref) {
  return ref.watch(articleRepositoryProvider).watchAll();
});

final articleProvider = StreamProvider.autoDispose.family<Article?, String>((ref, id) {
  return ref.watch(articleRepositoryProvider).watchOne(id);
});