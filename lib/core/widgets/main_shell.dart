import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: _BottomBar(
      index: shell.currentIndex,
      onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
    ),
  );
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

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
            _item(0, Icons.home_outlined, Icons.home_rounded, 'Ana Sayfa'),
            _item(1, Icons.workspace_premium_outlined, Icons.workspace_premium, 'Tedaviler'),
            _center(),
            _item(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
          ]),
        ),
      ),
    );
  }

  Widget _item(int i, IconData off, IconData on, String label) {
    final active = index == i;
    final color = active ? AppColors.secondary : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(active ? on : off, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: tx(11, w: FontWeight.w600, c: color)),
        ]),
      ),
    );
  }

  Widget _center() {
    final active = index == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(2),
        behavior: HitTestBehavior.opaque,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned(
            top: -22,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(color: Color(0x4D0F2B48), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 24),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text('Randevu AI',
                style: tx(11, w: FontWeight.w600, c: active ? AppColors.secondary : AppColors.muted)),
          ),
        ]),
      ),
    );
  }
}