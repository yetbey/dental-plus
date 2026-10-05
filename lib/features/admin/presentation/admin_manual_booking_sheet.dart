import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';

import '../../appointments/appointment_providers.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/clinic_schedule.dart';
import '../../clinic/presentation/clinic_providers.dart';

const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos',
  'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const _weekShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> showManualBookingSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const _ManualBookingSheet(),
  );
}

class _ManualBookingSheet extends ConsumerStatefulWidget {
  const _ManualBookingSheet();

  @override
  ConsumerState<_ManualBookingSheet> createState() => _ManualBookingSheetState();
}

class _ManualBookingSheetState extends ConsumerState<_ManualBookingSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  String? _treatment;
  DateTime? _day;
  DateTime? _slot;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  String _clean(String raw) {
    final t = raw.trim();
    final digits = t.replaceAll(RegExp(r'\D'), '');
    return (t.startsWith('+') ? '+' : '') + digits;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final slot = _slot;
    if (slot == null) {
      _snack(context, 'Lütfen bir saat seçin.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(appointmentRepositoryProvider).bookByAdmin(
        patientName: _name.text,
        patientPhone: _clean(_phone.text),
        treatment: _treatment!,
        start: slot,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _snack(context, 'Randevu eklendi');
    } on AppointmentException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, 'Kaydedilemedi, tekrar deneyin.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ClinicSchedule.bookableDays();
    final treatments = ref.watch(treatmentsProvider).asData?.value ?? const [];
    if (days.isEmpty) {
      return const Padding(padding: EdgeInsets.all(32), child: Text('Uygun gün bulunmuyor.'));
    }
    final day = (_day != null && days.contains(_day)) ? _day! : days.first;
    final booked = ref.watch(bookedSlotsProvider(day)).asData?.value;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Randevu Ekle', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
            Text('Telefonla veya yüz yüze gelen hasta için', style: tx(12, c: AppColors.muted)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Hasta adı soyadı'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Ad soyad girin' : null,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 20,
              decoration: const InputDecoration(labelText: 'Telefon'),
              validator: (v) {
                final digits = _clean(v ?? '').replaceAll('+', '').length;
                return (digits < 10 || digits > 13) ? 'Geçerli bir telefon numarası girin' : null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _treatment,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tedavi'),
              items: [
                for (final t in treatments) DropdownMenuItem(value: t.title, child: Text(t.title, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _treatment = v),
              validator: (v) => v == null ? 'Tedavi seçin' : null,
            ),
            const SizedBox(height: 16),
            Text('Tarih', style: tx(13, w: FontWeight.w600, c: AppColors.muted)),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final active = DateUtils.isSameDay(d, day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _day = d;
                      _slot = null;
                    }),
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
            const SizedBox(height: 16),
            Text('Saat', style: tx(13, w: FontWeight.w600, c: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in ClinicSchedule.slotsFor(day)) _slotChip(s, booked),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              maxLength: 250,
              decoration: const InputDecoration(labelText: 'Not (opsiyonel)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PillButton(label: _saving ? 'Kaydediliyor...' : 'Randevuyu Kaydet', onPressed: _saving ? null : _save),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _slotChip(DateTime s, Set<String>? booked) {
    final isBooked = booked?.contains(ClinicSchedule.slotId(s)) ?? false;
    final unavailable = booked == null || isBooked || !s.isAfter(DateTime.now());
    final active = _slot != null && _slot == s;
    return GestureDetector(
      onTap: unavailable ? null : () => setState(() => _slot = s),
      child: Container(
        width: 64,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : (unavailable ? const Color(0xFFF1F5F9) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.secondary : (unavailable ? Colors.transparent : AppColors.border),
          ),
        ),
        child: Text(
          ClinicSchedule.timeLabel(s),
          style: tx(13, w: FontWeight.w600, c: active ? Colors.white : (unavailable ? AppColors.mutedLight : AppColors.primary))
              .copyWith(decoration: isBooked ? TextDecoration.lineThrough : null),
        ),
      ),
    );
  }
}