import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/features/content/content_providers.dart';
import 'package:dental_plus/features/content/presentation/article_card.dart';

class ArticlesPage extends ConsumerWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articlesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Gülüş İpuçları & Rehber', style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Yazılar yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (items) => items.isEmpty
            ? Center(child: Text('Henüz yazı yok.', style: tx(14, c: AppColors.muted)))
            : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => ArticleCard(items[i]),
        ),
      ),
    );
  }
}