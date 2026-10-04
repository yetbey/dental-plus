import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/content/content_providers.dart';

class ArticleDetailPage extends ConsumerWidget {
  final String id;
  const ArticleDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articleProvider(id));
    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Yazı yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (a) {
          if (a == null || !a.active) {
            return Center(child: Text('Bu yazı bulunamadı.', style: tx(14, c: AppColors.muted)));
          }
          final cover = a.cover;
          final paragraphs = a.content
              .split(RegExp(r'\n\s*\n'))
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          return ListView(children: [
            if (cover != null && cover.isNotEmpty)
              Image.memory(base64Decode(cover),
                  width: double.infinity, height: 220, fit: BoxFit.cover, gaplessPlayback: true),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Tag(a.category),
                  const SizedBox(width: 10),
                  Text('${a.readMinutes} dk okuma', style: tx(12, c: AppColors.muted)),
                ]),
                const SizedBox(height: 14),
                Text(a.title, style: tx(24, w: FontWeight.w700, c: AppColors.primary, h: 1.3)),
                const SizedBox(height: 18),
                for (final p in paragraphs) ...[
                  Text(p, style: tx(15, c: AppColors.text, h: 1.7)),
                  const SizedBox(height: 14),
                ],
              ]),
            ),
          ]);
        },
      ),
    );
  }
}