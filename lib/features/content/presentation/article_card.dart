import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/content/domain/article.dart';

class ArticleCard extends StatelessWidget {
  final Article a;
  const ArticleCard(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    final cover = a.cover;
    return AppCard(
      onTap: () => context.push('/article/${a.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 80,
            child: (cover == null || cover.isEmpty)
                ? Container(
              color: const Color(0xFFE5EEFF),
              child: const Icon(Icons.article_outlined, color: AppColors.primary, size: 28),
            )
                : Image.memory(base64Decode(cover), fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${a.category} • ${a.readMinutes} dk okuma',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(11, w: FontWeight.w600, c: AppColors.secondary)),
            const SizedBox(height: 4),
            Text(a.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tx(14, w: FontWeight.w700, c: AppColors.primary, h: 1.3)),
            const SizedBox(height: 6),
            Text('Yazıyı Oku →', style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
          ]),
        ),
      ]),
    );
  }
}