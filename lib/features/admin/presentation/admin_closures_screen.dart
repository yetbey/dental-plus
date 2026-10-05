import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';

import '../../appointments/appointment_providers.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/clinic_schedule.dart';

const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos',
  'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const _weekShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const _weekFull = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

class AdminClosuresScreen extends ConsumerWidget {
  const AdminClosuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockedSlotsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Kapalı Günler', style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: Colors.white,
          builder: (_) => const _ClosureSheet(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Kapatma Ekle', style: tx(13, w: FontWeight.w600, c: Colors.white)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text('Kapalı gün veya saat yok.', style: tx(14, c: AppColors.muted)));
          }
          final groups = <DateTime, List<BlockedSlot>>{};
          for (final s in list) {
            final key = DateTime(s.start.year, s.start.month, s.start.day);
            groups.putIfAbsent(key, () => []).add(s);
          }
          final days = groups.keys.toList()..sort();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ClosureCard(days[i], groups[days[i]]!),
          );
        },
      ),
    );
  }
}

class _ClosureCard extends ConsumerWidget {
  final DateTime day;
  final List<BlockedSlot> slots;
  const _ClosureCard(this.day, this.slots);

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kapatma kaldırılsın mı?'),
        content: Text('${day.day} ${_months[day.month - 1]} için kapatılan saatler tekrar açılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaldır')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(appointmentRepositoryProvider).reopenSlots(slots.map((s) => s.id).toList());
      if (context.mounted) _snack(context, 'Saatler tekrar açıldı');
    } catch (_) {
      if (context.mounted) _snack(context, 'İşlem başarısız, tekrar deneyin.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ClinicSchedule.lastHour - ClinicSchedule.firstHour + 1;
    final reason = slots.map((s) => s.reason).firstWhere((r) => r.isNotEmpty, orElse: () => '');
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${day.day} ${_months[day.month - 1]} ${_weekFull[day.weekday - 1]}',
                style: tx(15, w: FontWeight.w700, c: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => _remove(context, ref),
            child: Text('Kaldır', style: tx(12, w: FontWeight.w600, c: AppColors.danger)),
          ),
        ]),
        if (reason.isNotEmpty) Text(reason, style: tx(12, c: AppColors.muted)),
        const SizedBox(height: 8),
        if (slots.length >= total)
          const Tag('Tüm gün kapalı', bg: Color(0xFFFEE2E2), fg: AppColors.danger)
        else
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in slots)
              Tag(ClinicSchedule.timeLabel(s.start), bg: const Color(0xFFFEE2E2), fg: AppColors.danger),
          ]),
      ]),
    );
  }
}

class _ClosureSheet extends ConsumerStatefulWidget {
  const _ClosureSheet();

  @override
  ConsumerState<_ClosureSheet> createState() => _ClosureSheetState();
}

class _ClosureSheetState extends ConsumerState<_ClosureSheet> {
  final _reason = TextEditingController();
  DateTime? _day;
  bool _allDay = true;
  final Set<int> _hours = {};
  bool _saving = false;

  late final List<DateTime> _days = () {
    final now = DateTime.now();
    final list = <DateTime>[];
    for (var i = 0; list.length < 45 && i < 90; i++) {
      final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      if (ClinicSchedule.isOpenDay(d)) list.add(d);
    }
    return list;
  }();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final day = _day ?? _days.first;
    final hours = _allDay
        ? {for (var h = ClinicSchedule.firstHour; h <= ClinicSchedule.lastHour; h++) h}
        : _hours;
    if (hours.isEmpty) {
      _snack(context, 'Lütfen kapatılacak saatleri seçin.');
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await ref.read(appointmentRepositoryProvider).closeSlots(day, hours, _reason.text);
      if (!mounted) return;
      Navigator.pop(context);
      final skip = r.skipped > 0 ? ' ${r.skipped} saat zaten dolu veya kapalı olduğu için atlandı.' : '';
      _snack(context, '${r.closed} saat kapatıldı.$skip');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, 'Kaydedilemedi, tekrar deneyin.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _day ?? _days.first;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Kapatma Ekle', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _days[i];
                final active = DateUtils.isSameDay(d, day);
                return GestureDetector(
                  onTap: () => setState(() => _day = d),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.secondary : AppColors.border),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_months[d.month - 1].substring(0, 3),
                          style: tx(10, c: active ? Colors.white70 : AppColors.muted)),
                      Text('${d.day}',
                          style: tx(18, w: FontWeight.w700, c: active ? Colors.white : AppColors.primary)),
                      Text(_weekShort[d.weekday - 1],
                          style: tx(10, c: active ? Colors.white70 : AppColors.muted)),
                    ]),
                  ),
                );
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tüm gün kapalı'),
            value: _allDay,
            activeColor: AppColors.secondary,
            onChanged: (v) => setState(() => _allDay = v),
          ),
          if (!_allDay)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var h = ClinicSchedule.firstHour; h <= ClinicSchedule.lastHour; h++)
                FilterChip(
                  label: Text('${h.toString().padLeft(2, '0')}:00'),
                  selected: _hours.contains(h),
                  onSelected: (v) => setState(() => v ? _hours.add(h) : _hours.remove(h)),
                ),
            ]),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Neden (opsiyonel)', helperText: 'Örn: Resmî tatil'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PillButton(label: _saving ? 'Kaydediliyor...' : 'Kapat', onPressed: _saving ? null : _save),
          ),
        ]),
      ),
    );
  }
}