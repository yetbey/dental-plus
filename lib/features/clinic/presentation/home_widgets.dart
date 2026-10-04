import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/auth/presentation/auth_providers.dart';

import '../../../core/utils/launcher.dart';
import '../../appointments/appointment_providers.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/clinic_schedule.dart';
import '../../content/content_providers.dart';
import '../../content/presentation/article_card.dart';
import '../domain/treatment.dart';
import 'clinic_providers.dart';
import 'doctor_avatar.dart';

const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz',
  'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const _weekFull = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

class HomeGreeting extends ConsumerWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUserProvider).value?.fullName.trim() ?? '';
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            first.isEmpty ? 'Merhaba 👋' : 'Merhaba, $first 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tx(26, w: FontWeight.w700, c: AppColors.primary),
          ),
          Text('Bugün gülüşünüz için ne yapabiliriz?', style: tx(14, c: AppColors.muted)),
        ]),
      ),
      const SizedBox(width: 12),
      Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: AppColors.chipTint, shape: BoxShape.circle),
        child: const Icon(Icons.health_and_safety_outlined, color: AppColors.secondary),
      ),
    ]);
  }
}

class UpcomingAppointmentCard extends ConsumerWidget {
  const UpcomingAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(myAppointmentsProvider).asData?.value;
    if (list == null) return const SizedBox.shrink();

    final upcoming = list.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B48), Color(0xFF1B4A73)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x240F2B48), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: upcoming.isEmpty ? _empty(context) : _filled(context, upcoming.first),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Yaklaşan randevunuz yok', style: tx(18, w: FontWeight.w700, c: Colors.white)),
      const SizedBox(height: 4),
      Text('Size uygun saati seçip hemen randevu talebi oluşturun.',
          style: tx(13, c: Colors.white70, h: 1.4)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: PillButton(
          label: 'Randevu Al',
          icon: Icons.edit_calendar_rounded,
          bg: const Color(0xFF39B8FD),
          fg: AppColors.primaryDark,
          onPressed: () => context.go('/appointment'),
        ),
      ),
    ]);
  }

  Widget _filled(BuildContext context, Appointment a) {
    final code = a.id.length >= 6 ? a.id.substring(0, 6).toUpperCase() : a.id.toUpperCase();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.circle, size: 8, color: AppColors.secondary),
            const SizedBox(width: 6),
            Text(a.status.label.toUpperCase(), style: tx(11, w: FontWeight.w700, c: Colors.white)),
          ]),
        ),
        const Spacer(),
        Text('Kayıt: #$code', style: tx(12, c: Colors.white70)),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.medical_services_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.treatment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tx(17, w: FontWeight.w700, c: Colors.white)),
            Text(a.doctorName ?? 'En erken müsait uzman hekim',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: Colors.white70)),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, color: AppColors.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${a.start.day} ${_months[a.start.month - 1]} ${_weekFull[a.start.weekday - 1]}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tx(14, w: FontWeight.w600, c: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.access_time, color: AppColors.secondary, size: 18),
          const SizedBox(width: 6),
          Text(ClinicSchedule.timeLabel(a.start), style: tx(14, w: FontWeight.w600, c: Colors.white)),
        ]),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: PillButton(
          label: 'Randevuyu Görüntüle',
          icon: Icons.arrow_forward,
          bg: Colors.white12,
          onPressed: () => context.go('/profile'),
        ),
      ),
    ]);
  }
}

class HomeDoctorSection extends ConsumerWidget {
  const HomeDoctorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(doctorsProvider).asData?.value;
    if (doctors == null || doctors.isEmpty) return const SizedBox.shrink();
    final d = doctors.first;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Hekimimiz', subtitle: 'Size özel ilgilenecek uzman hekim'),
      const SizedBox(height: 14),
      AppCard(
        child: Column(children: [
          Row(children: [
            DoctorAvatar(photo: d.photo, name: d.name, radius: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tx(17, w: FontWeight.w700, c: AppColors.primary)),
                const SizedBox(height: 2),
                Text(d.specialty, style: tx(13, w: FontWeight.w600, c: AppColors.secondary)),
                if (d.experienceYears > 0) ...[
                  const SizedBox(height: 8),
                  Tag('${d.experienceYears}+ Yıl Tecrübe', bg: const Color(0xFFE5EEFF), fg: AppColors.primary),
                ],
              ]),
            ),
          ]),
          if (d.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(d.bio,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: tx(12, c: AppColors.muted, h: 1.5)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: 'Randevu Al',
              icon: Icons.edit_calendar_rounded,
              onPressed: () => context.go('/appointment'),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class HomeArticlesSection extends ConsumerWidget {
  const HomeArticlesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(articlesProvider).asData?.value;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
        title: 'Gülüş İpuçları & Rehber',
        action: list.length > 3 ? 'Daha Fazla' : null,
        onAction: () => context.push('/articles'),
      ),
      const SizedBox(height: 14),
      for (final a in list.take(3)) ...[
        ArticleCard(a),
        const SizedBox(height: 12),
      ],
    ]);
  }
}

class HomeServicesSection extends ConsumerWidget {
  const HomeServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(treatmentsProvider).asData?.value;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final items = list.take(6).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
        title: 'Hizmetlerimiz',
        action: 'Tümünü Gör',
        onAction: () => context.go('/clinic'),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
        children: [for (final t in items) _ServiceTile(t)],
      ),
    ]);
  }
}

class _ServiceTile extends ConsumerWidget {
  final Treatment t;
  const _ServiceTile(this.t);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = t.urgent ? AppColors.danger : AppColors.primary;
    return AppCard(
      onTap: () {
        ref.read(preselectedTreatmentProvider.notifier).set(t.id);
        context.go('/appointment');
      },
      padding: const EdgeInsets.all(8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: t.urgent ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(t.icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(t.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tx(12, w: FontWeight.w700, c: color, h: 1.2)),
      ]),
    );
  }
}

class HomeHelpCard extends ConsumerWidget {
  const HomeHelpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(clinicInfoProvider).asData?.value;
    if (info == null || info.phone.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFDCE9FF),
          child: Icon(Icons.headset_mic_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sorunuz mu var?', style: tx(13, w: FontWeight.w600, c: AppColors.primary)),
            Text('Kliniğimizi hemen arayın', style: tx(12, c: AppColors.muted)),
          ]),
        ),
        OutlinedButton.icon(
          onPressed: () => callPhone(context, info.phone),
          icon: const Icon(Icons.phone_outlined, size: 16),
          label: Text('Ara', style: tx(13, w: FontWeight.w600, c: AppColors.secondary)),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            backgroundColor: Colors.white,
            side: BorderSide.none,
            foregroundColor: AppColors.secondary,
          ),
        ),
      ]),
    );
  }
}