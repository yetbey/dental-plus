import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.createdAt,
    this.cover,
    this.active = true,
  });

  final String id;
  final String title;
  final String category;
  final String content;
  final String? cover; // küçültülmüş JPEG, base64
  final bool active;
  final DateTime createdAt;

  int get readMinutes {
    final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return max(1, (words / 180).ceil());
  }

  factory Article.fromMap(Map<String, dynamic> m, String id) {
    return Article(
      id: id,
      title: m['title'] as String? ?? '',
      category: m['category'] as String? ?? '',
      content: m['content'] as String? ?? '',
      cover: m['cover'] as String?,
      active: m['active'] as bool? ?? true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'content': content,
    'cover': cover,
    'active': active,
  };
}