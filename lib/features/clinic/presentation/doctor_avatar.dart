import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';

class DoctorAvatar extends StatelessWidget {
  final String? photo;
  final String name;
  final double radius;
  const DoctorAvatar({super.key, this.photo, required this.name, this.radius = 32});

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !w.endsWith('.'))
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final second = words.length > 1 ? words.last[0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final p = photo;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (p == null || p.isEmpty)
            ? Container(
          color: const Color(0xFFE5EEFF),
          alignment: Alignment.center,
          child: Text(_initials, style: tx(radius * 0.7, w: FontWeight.w700, c: AppColors.primary)),
        )
            : Image.memory(base64Decode(p), fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}