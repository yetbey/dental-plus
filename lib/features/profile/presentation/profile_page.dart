import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/widgets/common.dart';
import '../../appointments/appointment_providers.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/domain/clinic_schedule.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_providers.dart';

const _bloodTypes = ['A Rh+', 'A Rh-', 'B Rh+', 'B Rh-', 'AB Rh+', 'AB Rh-', '0 Rh+', '0 Rh-'];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: const AppTopBar(title: 'Profil'),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Profil yüklenemedi', style: tx(14, c: AppColors.muted))),
        data: (user) {
          if (user == null) {
            return Center(child: Text('Profil bulunamadı', style: tx(14, c: AppColors.muted)));
          }
          return _ProfileBody(user: user);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final AppUser user;
  const _ProfileBody({required this.user});

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final hasPhoto = ref.read(avatarProvider).value != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeriden seç'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Fotoğraf çek'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Fotoğrafı kaldır', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
        ]),
      ),
    );
    if (action == null) return;

    final ctrl = ref.read(profileControllerProvider.notifier);
    try {
      bool ok;
      if (action == 'remove') {
        ok = await ctrl.removeAvatar();
      } else {
        final picked = await ImagePicker().pickImage(
          source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 384,
          maxHeight: 384,
          imageQuality: 70,
        );
        if (picked == null) return;
        ok = await ctrl.uploadAvatar(picked);
      }
      if (!context.mounted) return;
      _snack(
        context,
        ok
            ? 'Profil fotoğrafı güncellendi'
            : profileErrorMessage(ref.read(profileControllerProvider).error),
      );
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, 'Fotoğrafa erişilemedi. Uygulama izinlerini kontrol edin.');
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Oturumunuz bu cihazda sonlandırılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).signOut();
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _EditSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarProvider).value;
    final uploading = ref.watch(profileControllerProvider).isLoading;
    final allergyText = user.allergies.isEmpty ? 'Yok' : user.allergies.join(', ');

    final steps = <(String, bool)>[
      ('Profil fotoğrafı', avatar != null),
      ('Telefon Numarası', (user.phone ?? '').isNotEmpty),
      ('Kan Grubu', user.bloodType != null),
    ];

    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
      AppCard(
        child: Column(children: [
          GestureDetector(
            onTap: uploading ? null : () => _changePhoto(context, ref),
            child: Stack(children: [
              UserAvatar(photo: avatar, radius: 46),
              if (uploading)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Text(
            user.fullName.isEmpty ? 'İsimsiz Hasta' : user.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tx(22, w: FontWeight.w700, c: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(user.email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tx(13, c: AppColors.muted)),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(formatTrPhone(user.phone!), style: tx(13, c: AppColors.muted)),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _openEdit(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('Profili Düzenle', style: tx(13, w: FontWeight.w600, c: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: const StadiumBorder(),
              side: const BorderSide(color: Color(0x260F2B48)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _stat('Kan Grubu', user.bloodType ?? 'Belirtilmedi', AppColors.primary),
            const SizedBox(width: 10),
            _stat('Alerji', allergyText, AppColors.secondary),
            const SizedBox(width: 10),
            _stat('Kayıt Yılı', '${user.createdAt.year}', AppColors.primary),
          ]),
        ]),
      ),
      if (steps.any((s) => !s.$2)) ...[
        const SizedBox(height: 16),
        _CompletionCard(steps: steps, onTap: () => _openEdit(context)),
      ],
      const SizedBox(height: 24),
      const _AppointmentsSection(),
      const SizedBox(height: 24),
      const SectionHeader(title: 'Dijital Röntgen & Radyoloji', subtitle: 'Radyolojik görüntü arşiviniz'),
      const SizedBox(height: 12),
      const _EmptyCard(
        icon: Icons.medical_information_outlined,
        text: 'Kliniğimizde çekilen röntgenler hekiminiz yüklediğinde burada listelenir.',
      ),
      const SizedBox(height: 24),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _menu(Icons.lock_outline_rounded, 'Hesap & Güvenlik', 'Şifre değiştirme ve hesap silme',
              onTap: () => context.push(AppRoutes.accountSecurity)),
          _menu(Icons.shield_outlined, 'Diş Sigortası & Anlaşmalı Kurumlar', 'Yakında',
              onTap: () => _snack(context, 'Bu özellik yakında eklenecek')),
          _menu(Icons.receipt_long_outlined, 'Ödeme Geçmişi ve Faturalar', 'Yakında',
              onTap: () => _snack(context, 'Bu özellik yakında eklenecek')),
          _menu(Icons.notifications_active_outlined, 'Hatırlatıcılar & İlaç Alarmları', 'Yakında',
              onTap: () => _snack(context, 'Bu özellik yakında eklenecek')),
          _menu(Icons.logout_rounded, 'Çıkış Yap', 'Oturumu güvenle sonlandır',
              danger: true, last: true, onTap: () => _confirmSignOut(context, ref)),
        ]),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          'Sağlık verileriniz KVKK kapsamında korunmaktadır.\nMustafa Erkan Dental Klinik',
          textAlign: TextAlign.center,
          style: tx(11, c: AppColors.mutedLight, h: 1.5),
        ),
      ),
    ]);
  }

  Widget _stat(String l, String v, Color vc) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11, c: AppColors.muted)),
        const SizedBox(height: 2),
        Text(v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tx(14, w: FontWeight.w700, c: vc)),
      ]),
    ),
  );

  Widget _menu(IconData i, String t, String s,
      {bool danger = false, bool last = false, required VoidCallback onTap}) {
    final c = danger ? AppColors.danger : AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: Color(0x0F64748B)))),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(i, color: c, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, w: FontWeight.w700, c: c)),
              Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11, c: AppColors.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: danger ? AppColors.danger : AppColors.muted),
        ]),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyCard({required this.icon, required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(children: [
      Icon(icon, size: 32, color: AppColors.mutedLight),
      const SizedBox(height: 8),
      Text(text, textAlign: TextAlign.center, style: tx(12, c: AppColors.muted, h: 1.5)),
      if (actionLabel != null) ...[
        const SizedBox(height: 12),
        PillButton(label: actionLabel!, onPressed: onAction),
      ],
    ]),
  );
}

class _EditSheet extends ConsumerStatefulWidget {
  final AppUser user;
  const _EditSheet({required this.user});

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(
    text: widget.user.phone == null ? '' : formatTrPhone(widget.user.phone!),
  );
  late final _allergies = TextEditingController(text: widget.user.allergies.join(', '));
  late String? _blood = _bloodTypes.contains(widget.user.bloodType) ? widget.user.bloodType : null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final list = _allergies.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final ok = await ref.read(profileControllerProvider.notifier).updateProfile(
      fullName: _name.text,
      phone: normalizeTrPhone(_phone.text) ?? '',
      bloodType: _blood,
      allergies: list,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      _snack(context, 'Profil bilgileriniz güncellendi');
    } else {
      _snack(context, profileErrorMessage(ref.read(profileControllerProvider).error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(profileControllerProvider).isLoading;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Profili Düzenle', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Ad soyad girin' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()]')),
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                labelText: 'Cep Telefonu',
                hintText: '05XX XXX XX XX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                return normalizeTrPhone(t) == null
                    ? 'Geçerli bir cep numarası girin (05XX XXX XX XX)'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _blood,
              decoration: const InputDecoration(labelText: 'Kan Grubu'),
              items: [for (final b in _bloodTypes) DropdownMenuItem(value: b, child: Text(b))],
              onChanged: (v) => setState(() => _blood = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergies,
              decoration: const InputDecoration(
                labelText: 'Alerjiler',
                helperText: 'Virgülle ayırın: Penisilin, Lateks',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PillButton(label: loading ? 'Kaydediliyor...' : 'Kaydet', onPressed: loading ? null : _save),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final List<(String, bool)> steps;
  final VoidCallback onTap;
  const _CompletionCard({required this.steps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = steps.where((s) => s.$2).length;
    final missing = steps.where((s) => !s.$2).map((s) => s.$1).join(', ');
    return AppCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Profilini tamamla',
                style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
          ),
          Text('$done/${steps.length}',
              style: tx(12, w: FontWeight.w700, c: AppColors.secondary)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: done / steps.length,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5EEFF),
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Text('Eksik: $missing', style: tx(12, c: AppColors.muted)),
      ]),
    );
  }
}

const _monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz',
  'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

String _fmtDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

(Color, Color) _statusColors(AppointmentStatus s) => switch (s) {
  AppointmentStatus.pending => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
  AppointmentStatus.confirmed => (const Color(0xFFD1FAE5), const Color(0xFF047857)),
  AppointmentStatus.rejected => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
  AppointmentStatus.cancelled => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
  AppointmentStatus.completed => (const Color(0xFFE5EEFF), const Color(0xFF0F2B48)),
};

class _AppointmentsSection extends ConsumerWidget {
  const _AppointmentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAppointmentsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(
        title: 'Tedavi & Randevu Geçmişi',
        subtitle: 'Klinik kayıtlarınız ve hekim notları',
      ),
      const SizedBox(height: 12),
      async.when(
        loading: () => const Center(
          child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
        ),
        error: (_, _) => const _EmptyCard(
          icon: Icons.error_outline,
          text: 'Randevularınız yüklenemedi. Lütfen daha sonra tekrar deneyin.',
        ),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyCard(
              icon: Icons.medical_services_outlined,
              text: 'Henüz randevunuz bulunmuyor.',
              actionLabel: 'Randevu Al',
              onAction: () => context.go(AppRoutes.appointment),
            );
          }
          final upcoming = list.where((a) => a.isUpcoming).toList()
            ..sort((a, b) => a.start.compareTo(b.start));
          final others = list.where((a) => !a.isUpcoming).toList();
          final sorted = [...upcoming, ...others];
          return Column(children: [
            for (final a in sorted) ...[
              _AppointmentCard(a),
              const SizedBox(height: 12),
            ],
          ]);
        },
      ),
    ]);
  }
}

class _AppointmentCard extends ConsumerWidget {
  final Appointment a;
  const _AppointmentCard(this.a);

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Randevu iptal edilsin mi?'),
        content: Text(
          '${_fmtDate(a.start)} ${ClinicSchedule.timeLabel(a.start)} tarihli randevunuz iptal edilecek.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İptal Et', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(appointmentRepositoryProvider).cancel(a);
      if (context.mounted) _snack(context, 'Randevunuz iptal edildi');
    } on AppointmentException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (_) {
      if (context.mounted) _snack(context, 'İptal edilemedi, tekrar deneyin.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (bg, fg) = _statusColors(a.status);
    final adminNote = a.adminNote;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.treatment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
              Text(a.doctorName ?? 'Hekim: En erken müsait uzman',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(11, c: AppColors.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Tag(a.status.label, bg: bg, fg: fg),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(_fmtDate(a.start), style: tx(12, c: AppColors.muted)),
          const SizedBox(width: 14),
          const Icon(Icons.access_time, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(ClinicSchedule.timeLabel(a.start), style: tx(12, c: AppColors.muted)),
        ]),
        if (adminNote != null && adminNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12)),
            child: Text('Klinik notu: $adminNote', style: tx(12, c: AppColors.primary, h: 1.4)),
          ),
        ],
        if (a.isUpcoming) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _cancel(context, ref),
              child: Text('Randevuyu İptal Et', style: tx(12, w: FontWeight.w600, c: AppColors.danger)),
            ),
          ),
        ],
      ]),
    );
  }
}
