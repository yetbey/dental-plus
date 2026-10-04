import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/presentation/profile_providers.dart';

const kShadow = [
  BoxShadow(color: Color(0x0D0F2B48), blurRadius: 16, offset: Offset(0, 4), spreadRadius: -2),
  BoxShadow(color: Color(0x050F2B48), blurRadius: 6, offset: Offset(0, 2), spreadRadius: -1),
];

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Border? border;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16),
    this.color = Colors.white, this.border, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: const Color(0x0A0F2B48)),
        boxShadow: kShadow,
      ),
      child: child,
    ),
  );
}

class UserAvatar extends StatelessWidget {
  final String? photo;
  final double radius;
  const UserAvatar({super.key, this.photo, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photo == null
            ? Container(
          color: const Color(0xFFE5EEFF),
          alignment: Alignment.center,
          child: Icon(Icons.person_rounded, size: radius * 1.2, color: AppColors.mutedLight),
        )
            : Image.memory(base64Decode(photo!), fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  const AppTopBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarProvider).value;
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Row(children: [
        Image.asset('assets/images/logo.png', width: 36, height: 36),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Mustafa Erkan Dental', style: tx(11, w: FontWeight.w600, c: AppColors.secondary)),
          Text(title, style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
        ]),
      ]),
      actions: [
        Stack(alignment: Alignment.center, children: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary)),
          Positioned(
              top: 12,
              right: 12,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle))),
        ]),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: UserAvatar(photo: avatar, radius: 18),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
          if (subtitle != null) Text(subtitle!, style: tx(12, c: AppColors.muted)),
        ]),
      ),
      if (action != null)
        GestureDetector(onTap: onAction,
            child: Text(action!, style: tx(13, w: FontWeight.w600, c: AppColors.secondary))),
    ],
  );
}

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color bg, fg;
  final bool outlined;
  const PillButton({super.key, required this.label, this.icon, this.onPressed,
    this.bg = AppColors.primary, this.fg = Colors.white, this.outlined = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, foregroundColor: fg, elevation: 0,
        shape: const StadiumBorder(),
        side: outlined ? const BorderSide(color: Color(0x260F2B48)) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
            style: tx(14, w: FontWeight.w600, c: fg))),
      ]),
    ),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const Tag(this.text, {super.key, this.bg = AppColors.chipTint, this.fg = AppColors.secondary});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: tx(11, w: FontWeight.w600, c: fg)),
  );
}

class PhotoBox extends StatelessWidget {
  final String url;
  final double? w, h;
  final double radius;
  const PhotoBox(this.url, {super.key, this.w, this.h, this.radius = 12});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.network(url, width: w, height: h, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
            width: w, height: h, color: const Color(0xFFE5EEFF),
            child: const Icon(Icons.image_outlined, color: AppColors.mutedLight))),
  );
}