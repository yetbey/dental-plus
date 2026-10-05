import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/utils/launcher.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/auth/data/auth_repository.dart';
import 'package:dental_plus/features/auth/domain/app_user.dart';

import '../../appointments/appointment_providers.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/clinic_schedule.dart';
import '../../appointments/presentation/status_style.dart';

const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos',
  'Eylül', 'Ekim', 'Kasım', 'Aralık'];

String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

final _patientProvider = StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).watchUser(uid);
});

Future<void> showPatientSheet(BuildContext context, Appointment a) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _PatientSheet(a),
  );
}

class _PatientSheet extends ConsumerWidget {
  final Appointment a;
  const _PatientSheet(this.a);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manual = a.patientId.isEmpty;
    final userAsync = manual ? null : ref.watch(_patientProvider(a.patientId));
    final all = ref.watch(allAppointmentsProvider).asData?.value ?? const <Appointment>[];

    final history = all.where((x) {
      if (x.id == a.id) return false;
      return manual
          ? (x.patientId.isEmpty && x.patientPhone == a.patientPhone)
          : x.patientId == a.patientId;
    }).toList()
      ..sort((p, q) => q.start.compareTo(p.start));

    final phone = a.patientPhone ?? '';
    final note = a.note;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE5EEFF),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.patientName.isEmpty ? 'İsimsiz Hasta' : a.patientName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
              if (phone.isNotEmpty) Text(phone, style: tx(13, c: AppColors.muted)),
            ]),
          ),
          if (phone.isNotEmpty)
            IconButton.filled(
              onPressed: () => callPhone(context, phone),
              style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
              icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
            ),
        ]),
        const SizedBox(height: 16),
        if (manual)
          const Tag('Uygulamada kayıtlı değil', bg: Color(0xFFF1F5F9), fg: AppColors.muted)
        else
          userAsync!.when(
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text('Hasta bilgisi yüklenemedi.', style: tx(13, c: AppColors.muted)),
            data: (u) => u == null
                ? Text('Hasta profili bulunamadı (hesap silinmiş olabilir).',
                style: tx(13, c: AppColors.muted))
                : _health(u),
          ),
        const SizedBox(height: 20),
        Text('Bu Randevu', style: tx(15, w: FontWeight.w700, c: AppColors.primary)),
        const SizedBox(height: 8),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.treatment, style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
            const SizedBox(height: 4),
            Text('${_fmt(a.start)} • ${ClinicSchedule.timeLabel(a.start)}',
                style: tx(12, c: AppColors.muted)),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Hasta notu: $note', style: tx(12, c: AppColors.text, h: 1.4)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        Text('Geçmiş Randevular', style: tx(15, w: FontWeight.w700, c: AppColors.primary)),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Text('Başka randevusu yok.', style: tx(13, c: AppColors.muted))
        else
          for (final h in history.take(10)) ...[
            _historyRow(h),
            const SizedBox(height: 8),
          ],
      ]),
    );
  }

  Widget _health(AppUser u) {
    final hasAllergy = u.allergies.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _info('Kan Grubu', u.bloodType ?? 'Belirtilmedi'),
        const SizedBox(width: 10),
        _info('Kayıt Yılı', '${u.createdAt.year}'),
      ]),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasAllergy ? const Color(0xFFFEE2E2) : const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(hasAllergy ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 20, color: hasAllergy ? AppColors.danger : AppColors.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Alerjiler',
                  style: tx(12, w: FontWeight.w700, c: hasAllergy ? AppColors.danger : AppColors.primary)),
              const SizedBox(height: 2),
              Text(hasAllergy ? u.allergies.join(', ') : 'Bildirilmiş alerji yok',
                  style: tx(13, w: hasAllergy ? FontWeight.w700 : FontWeight.w400,
                      c: hasAllergy ? AppColors.danger : AppColors.text)),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _info(String l, String v) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(l, style: tx(11, c: AppColors.muted)),
        const SizedBox(height: 2),
        Text(v, style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
      ]),
    ),
  );

  Widget _historyRow(Appointment h) {
    final (bg, fg) = appointmentStatusColors(h.status);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h.treatment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tx(13, w: FontWeight.w600, c: AppColors.primary)),
          Text('${_fmt(h.start)} • ${ClinicSchedule.timeLabel(h.start)}',
              style: tx(11, c: AppColors.muted)),
        ]),
      ),
      const SizedBox(width: 8),
      Tag(h.status.label, bg: bg, fg: fg),
    ]);
  }
}