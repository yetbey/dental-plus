import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../router/shell_index.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellIndexProvider.notifier).set(shell.currentIndex);
    });
    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomBar(
        index: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Ana Sayfa'),
    (Icons.workspace_premium_outlined, Icons.workspace_premium, 'Tedaviler'),
    (Icons.edit_calendar_outlined, Icons.edit_calendar_rounded, 'Randevu AI'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1464748B))),
        boxShadow: [BoxShadow(color: Color(0x140F2B48), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavItem(
                  off: _items[i].$1,
                  on: _items[i].$2,
                  label: _items[i].$3,
                  active: index == i,
                  onTap: () => onTap(i),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData off, on;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.off,
    required this.on,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 250);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOutCubic,
            top: active ? -14 : 12,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: active ? 52 : 28,
              height: active ? 52 : 28,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: active ? Border.all(color: Colors.white, width: 4) : null,
                boxShadow: active
                    ? const [BoxShadow(color: Color(0x4D0F2B48), blurRadius: 16, offset: Offset(0, 8))]
                    : null,
              ),
              child: Icon(
                active ? on : off,
                size: 24,
                color: active ? Colors.white : AppColors.muted,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text(
              label,
              style: tx(11, w: FontWeight.w600, c: active ? AppColors.secondary : AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}