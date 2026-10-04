import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/clinic/domain/doctor.dart';
import 'package:dental_plus/features/clinic/presentation/doctor_avatar.dart';

import '../../clinic/presentation/clinic_providers.dart';

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

class AdminDoctorScreen extends ConsumerWidget {
  const AdminDoctorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allDoctorsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hekim Bilgileri', style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (list) => _DoctorForm(initial: list.isEmpty ? null : list.first),
      ),
    );
  }
}

class _DoctorForm extends ConsumerStatefulWidget {
  final Doctor? initial;
  const _DoctorForm({required this.initial});

  @override
  ConsumerState<_DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends ConsumerState<_DoctorForm> {
  final _form = GlobalKey<FormState>();
  late final Doctor? _i = widget.initial;
  late final _name = TextEditingController(text: _i?.name ?? '');
  late final _specialty = TextEditingController(text: _i?.specialty ?? '');
  late final _years = TextEditingController(text: (_i?.experienceYears ?? 0) == 0 ? '' : '${_i!.experienceYears}');
  late final _bio = TextEditingController(text: _i?.bio ?? '');
  late String? _photo = _i?.photo;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _specialty, _years, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked == null) return;
      final b64 = base64Encode(await picked.readAsBytes());
      if (b64.length >= 95000) {
        if (mounted) _snack(context, 'Fotoğraf çok büyük, daha küçük bir fotoğraf seçin.');
        return;
      }
      setState(() => _photo = b64);
    } catch (_) {
      if (mounted) _snack(context, 'Fotoğrafa erişilemedi. Uygulama izinlerini kontrol edin.');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final d = Doctor(
      id: _i?.id ?? '',
      name: _name.text.trim(),
      specialty: _specialty.text.trim(),
      experienceYears: int.tryParse(_years.text.trim()) ?? 0,
      bio: _bio.text.trim(),
      photo: _photo,
      active: _i?.active ?? true,
      sortOrder: _i?.sortOrder ?? 0,
    );
    try {
      await ref.read(clinicRepositoryProvider).saveDoctor(d);
      if (mounted) _snack(context, 'Hekim bilgileri kaydedildi');
    } catch (_) {
      if (mounted) _snack(context, 'Kaydedilemedi, tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Center(
          child: GestureDetector(
            onTap: _saving ? null : _pickPhoto,
            child: Stack(children: [
              DoctorAvatar(photo: _photo, name: _name.text, radius: 56),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
        if (_photo != null)
          Center(
            child: TextButton(
              onPressed: _saving ? null : () => setState(() => _photo = null),
              child: Text('Fotoğrafı kaldır', style: tx(12, w: FontWeight.w600, c: AppColors.danger)),
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Ad Soyad (unvanıyla)', helperText: 'Örn: Dt. Mustafa Erkan'),
          validator: (v) => (v == null || v.trim().length < 2) ? 'Ad soyad girin' : null,
        ),
        TextFormField(
          controller: _specialty,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Uzmanlık / Unvan', helperText: 'Örn: Diş Hekimi'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Uzmanlık girin' : null,
        ),
        TextFormField(
          controller: _years,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tecrübe (yıl, opsiyonel)',
            helperText: 'Boş bırakırsanız gösterilmez',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bio,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Hakkında (opsiyonel)'),
        ),
        const SizedBox(height: 16),
        PillButton(label: _saving ? 'Kaydediliyor...' : 'Kaydet', onPressed: _saving ? null : _save),
      ]),
    );
  }
}