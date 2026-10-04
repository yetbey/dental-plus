import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/clinic/domain/treatment.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../clinic/presentation/clinic_providers.dart';
import '../appointment_providers.dart';
import '../data/appointment_repository.dart';
import '../domain/clinic_schedule.dart';

const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos',
  'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const _weekShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const _weekFull = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

BoxDecoration _chipDeco(bool active, {bool disabled = false}) => BoxDecoration(
  color: active ? AppColors.primary : (disabled ? const Color(0xFFF1F5F9) : Colors.white),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: active ? AppColors.secondary : (disabled ? Colors.transparent : AppColors.border),
    width: active ? 2 : 1,
  ),
);

class AppointmentPage extends ConsumerStatefulWidget {
  const AppointmentPage({super.key});

  @override
  ConsumerState<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends ConsumerState<AppointmentPage> {
  String? _treatmentId;
  DateTime? _day;
  DateTime? _slot;
  bool _submitting = false;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPreselected());
  }

  void _applyPreselected() {
    if (!mounted) return;
    final id = ref.read(preselectedTreatmentProvider);
    if (id == null) return;
    setState(() => _treatmentId = id);
    ref.read(preselectedTreatmentProvider.notifier).clear();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _snack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  Future<void> _submit(DateTime slot, Treatment treatment) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    if ((user.phone ?? '').isEmpty) {
      _snack(
        'Randevu için profilinize telefon numarası ekleyin.',
        action: SnackBarAction(label: 'Profile Git', onPressed: () => context.go('/profile')),
      );
      return;
    }

    final doctors = ref.read(doctorsProvider).asData?.value;
    final doctorName = (doctors == null || doctors.isEmpty) ? null : doctors.first.name;

    setState(() => _submitting = true);
    try {
      await ref.read(appointmentRepositoryProvider).book(
        patientId: user.uid,
        patientName: user.fullName,
        patientPhone: user.phone,
        treatment: treatment.title,
        doctorName: doctorName,
        start: slot,
        note: _note.text,
      );
      if (!mounted) return;
      setState(() => _slot = null);
      _note.clear();
      await _showSuccess();
    } on AppointmentException catch (e) {
      if (mounted) _snack(e.message);
    } on FirebaseException catch (e) {
      if (mounted) {
        _snack(e.code == 'permission-denied'
            ? 'Randevu oluşturulamadı. Lütfen tekrar deneyin.'
            : 'İnternet bağlantınızı kontrol edip tekrar deneyin.');
      }
    } catch (_) {
      if (mounted) _snack('Bir hata oluştu, tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccess() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.tertiary, size: 48),
        title: const Text('Talebiniz alındı'),
        content: const Text(
          'Randevu talebiniz kliniğimize iletildi. Onaylandığında durumu profilinizden takip edebilirsiniz.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/profile');
            },
            child: const Text('Profilime Git'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(preselectedTreatmentProvider, (_, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _applyPreselected());
      }
    });
    final days = ClinicSchedule.bookableDays();
    if (days.isEmpty) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Randevu AI'),
        body: Center(child: Text('Şu an uygun gün bulunmuyor.', style: tx(14, c: AppColors.muted))),
      );
    }

    final treatmentsAsync = ref.watch(treatmentsProvider);
    final treatments = treatmentsAsync.asData?.value ?? const <Treatment>[];
    final selected = treatments.isEmpty
        ? null
        : treatments.firstWhere((t) => t.id == _treatmentId, orElse: () => treatments.first);

    final day = (_day != null && days.contains(_day)) ? _day! : days.first;
    final bookedIds = ref.watch(bookedSlotsProvider(day)).asData?.value;
    final slot = (_slot != null &&
        DateUtils.isSameDay(_slot, day) &&
        !(bookedIds?.contains(ClinicSchedule.slotId(_slot!)) ?? true))
        ? _slot
        : null;

    final slots = ClinicSchedule.slotsFor(day);
    final morning = slots.where((s) => s.hour < 12).toList();
    final afternoon = slots.where((s) => s.hour >= 12).toList();

    return Scaffold(
      appBar: const AppTopBar(title: 'Randevu AI'),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
            _title(Icons.medical_services_outlined, '1. Tedavi Türü', 'Zorunlu'),
            const SizedBox(height: 12),
            treatmentsAsync.when(
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
              ),
              error: (_, _) => Text('Tedaviler yüklenemedi.', style: tx(13, c: AppColors.muted)),
              data: (list) => list.isEmpty
                  ? Text('Henüz tedavi eklenmemiş.', style: tx(13, c: AppColors.muted))
                  : Column(children: [
                for (final t in list) ...[
                  _Option(
                    selected: selected?.id == t.id,
                    onTap: () => setState(() => _treatmentId = t.id),
                    icon: t.icon,
                    title: t.title,
                    subtitle: t.subtitle,
                    danger: t.urgent,
                    badge: t.urgent ? 'Öncelikli' : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            _title(Icons.calendar_month_outlined, '2. Randevu Tarihi', _months[day.month - 1]),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final active = DateUtils.isSameDay(d, day);
                  final isToday = DateUtils.isSameDay(d, DateTime.now());
                  final sub = active ? Colors.white70 : AppColors.muted;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _day = d;
                      _slot = null;
                    }),
                    child: Container(
                      width: 68,
                      decoration: _chipDeco(active),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(isToday ? 'Bugün' : _months[d.month - 1].substring(0, 3),
                            style: tx(11, c: sub)),
                        Text('${d.day}',
                            style: tx(22, w: FontWeight.w700, c: active ? Colors.white : AppColors.primary)),
                        Text(_weekShort[d.weekday - 1], style: tx(11, c: sub)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _title(Icons.schedule, '3. Saat Dilimi',
                '${day.day} ${_months[day.month - 1]} ${_weekFull[day.weekday - 1]}'),
            const SizedBox(height: 12),
            _slotGroup('Sabah Kuşağı', Icons.wb_sunny_outlined, morning, slot, bookedIds),
            const SizedBox(height: 14),
            _slotGroup('Öğleden Sonra Kuşağı', Icons.wb_twilight, afternoon, slot, bookedIds),
            const SizedBox(height: 20),
            Text('Şikayet & Not', style: tx(16, w: FontWeight.w700, c: AppColors.primary)),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 4,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: 'Şikayetiniz, mevcut alerjileriniz veya hekime önceden iletmek istediğiniz durumlar (opsiyonel)...',
                hintStyle: tx(13, c: AppColors.mutedLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Randevu Bilgilendirmesi', style: tx(13, w: FontWeight.w700, c: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(
                      'Randevu talebiniz kliniğimiz tarafından onaylandığında kesinleşir. '
                          'Çalışma saatlerimiz Pazartesi-Cumartesi 09:00-18:00, Pazar günü kapalıyız.',
                      style: tx(12, c: AppColors.muted, h: 1.4),
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        _confirmBar(selected, slot),
      ]),
    );
  }

  Widget _confirmBar(Treatment? treatment, DateTime? slot) {
    final summary = slot == null
        ? 'Lütfen bir saat seçin'
        : '${slot.day} ${_months[slot.month - 1]} ${_weekFull[slot.weekday - 1]}, ${ClinicSchedule.timeLabel(slot)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1464748B))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(treatment?.title ?? 'Tedavi seçin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
            Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: AppColors.muted)),
          ]),
        ),
        const SizedBox(width: 12),
        PillButton(
          label: _submitting ? 'Gönderiliyor...' : 'Randevu Talep Et',
          icon: _submitting ? null : Icons.arrow_forward,
          onPressed: (slot == null || treatment == null || _submitting) ? null : () => _submit(slot, treatment),
        ),
      ]),
    );
  }

  Widget _title(IconData i, String t, String trailing) => Row(children: [
    Icon(i, color: AppColors.primary, size: 20),
    const SizedBox(width: 8),
    Text(t, style: tx(16, w: FontWeight.w700, c: AppColors.primary)),
    const Spacer(),
    Flexible(
      child: Text(trailing,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
    ),
  ]);

  Widget _slotGroup(String label, IconData icon, List<DateTime> list, DateTime? selected, Set<String>? bookedIds) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(label, style: tx(13, w: FontWeight.w600, c: AppColors.muted)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final s in list) _slotChip(s, selected, bookedIds),
      ]),
    ]);
  }

  Widget _slotChip(DateTime s, DateTime? selected, Set<String>? bookedIds) {
    final isBooked = bookedIds?.contains(ClinicSchedule.slotId(s)) ?? false;
    final unavailable = bookedIds == null || isBooked || !ClinicSchedule.isBookableTime(s);
    final active = selected != null && selected == s;
    return GestureDetector(
      onTap: unavailable ? null : () => setState(() => _slot = s),
      child: Container(
        width: 76,
        height: 48,
        alignment: Alignment.center,
        decoration: _chipDeco(active, disabled: unavailable),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            ClinicSchedule.timeLabel(s),
            style: tx(14, w: FontWeight.w600, c: active ? Colors.white : (unavailable ? AppColors.mutedLight : AppColors.primary))
                .copyWith(decoration: isBooked ? TextDecoration.lineThrough : null),
          ),
          if (isBooked) Text('Dolu', style: tx(9, w: FontWeight.w700, c: AppColors.danger)),
        ]),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final bool selected, danger;
  final VoidCallback onTap;
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  const _Option({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.secondary : AppColors.border, width: selected ? 2 : 1),
          boxShadow: kShadow,
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: danger ? AppColors.danger : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Tag(badge!,
                      bg: danger ? const Color(0xFFFEE2E2) : AppColors.chipTint,
                      fg: danger ? AppColors.danger : AppColors.secondary),
                ],
              ]),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: tx(12, c: AppColors.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.secondary : Colors.transparent,
              border: selected ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}