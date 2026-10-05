import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dental_plus/core/router/shell_index.dart';
import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/utils/launcher.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/clinic/domain/treatment.dart';
import 'package:dental_plus/features/clinic/presentation/home_widgets.dart';

import '../../appointments/appointment_providers.dart';
import 'clinic_providers.dart';

class ClinicPage extends ConsumerStatefulWidget {
  const ClinicPage({super.key});

  @override
  ConsumerState<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends ConsumerState<ClinicPage> {
  final _scroll = ScrollController();
  String? _category;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sekmeye her girişte sayfa başa dönsün.
    ref.listen<int>(shellIndexProvider, (prev, next) {
      if (next == 1 && prev != 1 && _scroll.hasClients) _scroll.jumpTo(0);
    });

    final treatmentsAsync = ref.watch(treatmentsProvider);
    final info = ref.watch(clinicInfoProvider).asData?.value;

    return Scaffold(
      appBar: const AppTopBar(title: 'Tedaviler'),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text('Mustafa Erkan Dental', style: tx(28, w: FontWeight.w700, c: AppColors.primary, h: 1.2)),
          const SizedBox(height: 8),
          Text(
            'Tedavilerimizi inceleyin, size uygun olanı seçip hemen randevu talebi oluşturun.',
            style: tx(14, c: AppColors.muted, h: 1.5),
          ),
          if (info != null && (info.phone.isNotEmpty || info.address.isNotEmpty)) ...[
            const SizedBox(height: 16),
            _contactCard(context, info.phone, info.address),
          ],
          const SizedBox(height: 28),
          const HomeDoctorSection(),
          const SizedBox(height: 28),
          Text('Tedavilerimiz', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
          Text('Size özel hazırlanan tedavi planları', style: tx(12, c: AppColors.muted)),
          const SizedBox(height: 14),
          treatmentsAsync.when(
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text('Tedaviler yüklenemedi.', style: tx(13, c: AppColors.muted)),
            data: (list) {
              if (list.isEmpty) {
                return Text('Henüz tedavi eklenmemiş.', style: tx(13, c: AppColors.muted));
              }
              final categories = <String>[];
              for (final t in list) {
                if (t.category.isNotEmpty && !categories.contains(t.category)) categories.add(t.category);
              }
              final selected = categories.contains(_category) ? _category : null;
              final filtered = selected == null ? list : list.where((t) => t.category == selected).toList();

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _chip('Tümü', selected == null, () => setState(() => _category = null)),
                    for (final c in categories) ...[
                      const SizedBox(width: 8),
                      _chip(c, selected == c, () => setState(() => _category = c)),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                for (final t in filtered) ...[
                  _TreatmentCard(t),
                  const SizedBox(height: 14),
                ],
              ]);
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.primary : AppColors.border),
      ),
      child: Text(label, style: tx(13, w: FontWeight.w600, c: active ? Colors.white : AppColors.primary)),
    ),
  );

  Widget _contactCard(BuildContext context, String phone, String address) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (address.isNotEmpty)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on_outlined, size: 20, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(child: Text(address, style: tx(13, c: AppColors.text, h: 1.4))),
        ]),
      if (address.isNotEmpty && phone.isNotEmpty) const SizedBox(height: 12),
      if (phone.isNotEmpty)
        Row(children: [
          const Icon(Icons.phone_outlined, size: 20, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(child: Text(phone, style: tx(13, w: FontWeight.w600, c: AppColors.primary))),
          PillButton(label: 'Ara', onPressed: () => callPhone(context, phone)),
        ]),
    ]),
  );
}

class _TreatmentCard extends ConsumerWidget {
  final Treatment t;
  const _TreatmentCard(this.t);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = t.urgent ? AppColors.danger : AppColors.primary;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.urgent ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(t.icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.category.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(11, w: FontWeight.w700, c: AppColors.secondary)),
          ),
          if (t.badge != null && t.badge!.isNotEmpty) Tag(t.badge!),
        ]),
        const SizedBox(height: 10),
        Text(t.title, style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
        if (t.description.isNotEmpty || t.subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(t.description.isNotEmpty ? t.description : t.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: tx(12, c: AppColors.muted, h: 1.5)),
        ],
        if (t.perks.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 6, children: [
            for (final p in t.perks)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.tertiary),
                const SizedBox(width: 4),
                Text(p, style: tx(11, w: FontWeight.w600, c: AppColors.primary)),
              ]),
          ]),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: PillButton(
              label: 'Detay',
              bg: AppColors.chipTint,
              fg: AppColors.secondary,
              onPressed: () => context.push('/treatment/${t.id}'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PillButton(
              label: 'Randevu Al',
              onPressed: () {
                ref.read(preselectedTreatmentProvider.notifier).set(t.id);
                context.go('/appointment');
              },
            ),
          ),
        ]),
      ]),
    );
  }
}