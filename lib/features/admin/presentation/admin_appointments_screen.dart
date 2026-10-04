import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/auth/presentation/auth_controller.dart';

import '../../appointments/appointment_providers.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/clinic_schedule.dart';
import '../../clinic/presentation/clinic_providers.dart';

const _monthNames = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _fmtDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

(Color, Color) _statusColors(AppointmentStatus s) => switch (s) {
  AppointmentStatus.pending => (
    const Color(0xFFFEF3C7),
    const Color(0xFFB45309),
  ),
  AppointmentStatus.confirmed => (
    const Color(0xFFD1FAE5),
    const Color(0xFF047857),
  ),
  AppointmentStatus.rejected => (
    const Color(0xFFFEE2E2),
    const Color(0xFFB91C1C),
  ),
  AppointmentStatus.cancelled => (
    const Color(0xFFF1F5F9),
    const Color(0xFF64748B),
  ),
  AppointmentStatus.completed => (
    const Color(0xFFE5EEFF),
    const Color(0xFF0F2B48),
  ),
};

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

class AdminAppointmentsScreen extends ConsumerWidget {
  const AdminAppointmentsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allAppointmentsProvider);
    final list = async.asData?.value ?? const <Appointment>[];

    final pending =
        list.where((a) => a.status == AppointmentStatus.pending).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final confirmed =
        list.where((a) => a.status == AppointmentStatus.confirmed).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final history = list.where((a) => !a.isActive).toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Yönetim Paneli',
            style: tx(18, w: FontWeight.w700, c: AppColors.primary),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.primary,
              ),
              onSelected: (v) async {
                switch (v) {
                  case 'treatments':
                    context.push('/admin/treatments');
                  case 'doctor':
                    context.push('/admin/doctor');
                  case 'articles':
                    context.push('/admin/articles');
                  case 'clinic':
                    context.push('/admin/clinic');
                  case 'seed':
                    try {
                      final done = await ref
                          .read(clinicRepositoryProvider)
                          .seedDefaults();
                      if (context.mounted) {
                        _snack(
                          context,
                          done
                              ? 'Örnek hekim ve tedaviler yüklendi'
                              : 'Veriler zaten mevcut',
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        _snack(context, 'Yükleme başarısız.');
                      }
                    }
                  case 'account':
                    context.push('/account');
                  case 'logout':
                    await _signOut(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'treatments', child: Text('Tedaviler')),
                PopupMenuItem(value: 'doctor', child: Text('Hekim bilgileri')),
                PopupMenuItem(
                  value: 'articles',
                  child: Text('Rehber yazıları'),
                ),
                PopupMenuItem(
                  value: 'seed',
                  child: Text('Örnek verileri yükle'),
                ),
                PopupMenuItem(value: 'clinic', child: Text('Klinik bilgileri')),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'account',
                  child: Text('Hesap & Güvenlik'),
                ),
                PopupMenuItem(value: 'logout', child: Text('Çıkış Yap')),
              ],
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.secondary,
            labelStyle: tx(13, w: FontWeight.w700),
            tabs: [
              Tab(text: 'Bekleyen (${pending.length})'),
              Tab(text: 'Onaylı (${confirmed.length})'),
              const Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              'Randevular yüklenemedi.',
              style: tx(14, c: AppColors.muted),
            ),
          ),
          data: (_) => TabBarView(
            children: [
              _AdminList(
                items: pending,
                emptyText: 'Onay bekleyen randevu yok.',
              ),
              _AdminList(
                items: confirmed,
                emptyText: 'Onaylanmış randevu yok.',
              ),
              _AdminList(items: history, emptyText: 'Geçmiş randevu yok.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminList extends StatelessWidget {
  final List<Appointment> items;
  final String emptyText;
  const _AdminList({required this.items, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText, style: tx(14, c: AppColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _AdminCard(items[i]),
    );
  }
}

class _AdminCard extends ConsumerWidget {
  final Appointment a;
  const _AdminCard(this.a);

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    AppointmentStatus to,
    String title,
  ) async {
    if (to == AppointmentStatus.completed && a.start.isAfter(DateTime.now())) {
      _snack(
        context,
        'Randevu saati gelmeden tamamlandı olarak işaretlenemez.',
      );
      return;
    }
    String? note = '';
    if (to != AppointmentStatus.confirmed) {
      note = await showDialog<String>(
        context: context,
        builder: (_) => _NoteDialog(title: title),
      );
      if (note == null) return;
    }
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .setStatus(a, to, adminNote: note);
      if (context.mounted) _snack(context, 'Randevu güncellendi');
    } on AppointmentException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (_) {
      if (context.mounted) _snack(context, 'İşlem başarısız, tekrar deneyin.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (bg, fg) = _statusColors(a.status);
    final phone = a.patientPhone;
    final note = a.note;
    final adminNote = a.adminNote;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.patientName.isEmpty ? 'İsimsiz Hasta' : a.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tx(16, w: FontWeight.w700, c: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Tag(a.status.label, bg: bg, fg: fg),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(phone, style: tx(12, c: AppColors.muted)),
          ],
          const SizedBox(height: 10),
          Text(a.treatment, style: tx(13, w: FontWeight.w600)),
          Text(
            a.doctorName ?? 'Hekim tercihi yok',
            style: tx(12, c: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(_fmtDate(a.start), style: tx(12, c: AppColors.muted)),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                ClinicSchedule.timeLabel(a.start),
                style: tx(12, c: AppColors.muted),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Hasta notu: $note',
                style: tx(12, c: AppColors.text, h: 1.4),
              ),
            ),
          ],
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Klinik notu: $adminNote',
              style: tx(12, c: AppColors.primary, h: 1.4),
            ),
          ],
          if (a.status == AppointmentStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _outlined(
                    'Reddet',
                    () => _act(
                      context,
                      ref,
                      AppointmentStatus.rejected,
                      'Randevu reddedilsin mi?',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filled(
                    'Onayla',
                    () => _act(context, ref, AppointmentStatus.confirmed, ''),
                  ),
                ),
              ],
            ),
          ],
          if (a.status == AppointmentStatus.confirmed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _outlined(
                    'İptal Et',
                    () => _act(
                      context,
                      ref,
                      AppointmentStatus.cancelled,
                      'Randevu iptal edilsin mi?',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filled(
                    'Tamamlandı',
                    () => _act(
                      context,
                      ref,
                      AppointmentStatus.completed,
                      'Randevu tamamlandı olarak işaretlensin mi?',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _filled(String label, VoidCallback onTap) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      shape: const StadiumBorder(),
      minimumSize: const Size.fromHeight(44),
    ),
    child: Text(
      label,
      style: tx(13, w: FontWeight.w600, c: Colors.white),
    ),
  );

  Widget _outlined(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.danger,
      shape: const StadiumBorder(),
      side: const BorderSide(color: Color(0x40EF4444)),
      minimumSize: const Size.fromHeight(44),
    ),
    child: Text(
      label,
      style: tx(13, w: FontWeight.w600, c: AppColors.danger),
    ),
  );
}

class _NoteDialog extends StatefulWidget {
  final String title;
  const _NoteDialog({required this.title});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'Hastaya not (opsiyonel)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: const Text('Onayla'),
        ),
      ],
    );
  }
}
