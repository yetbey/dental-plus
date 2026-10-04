import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/clinic/domain/clinic_info.dart';

import '../../clinic/presentation/clinic_providers.dart';

class AdminClinicScreen extends ConsumerWidget {
  const AdminClinicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clinicInfoProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Klinik Bilgileri', style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (info) => _ClinicForm(initial: info),
      ),
    );
  }
}

class _ClinicForm extends ConsumerStatefulWidget {
  final ClinicInfo initial;
  const _ClinicForm({required this.initial});

  @override
  ConsumerState<_ClinicForm> createState() => _ClinicFormState();
}

class _ClinicFormState extends ConsumerState<_ClinicForm> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _address = TextEditingController(text: widget.initial.address);
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String _clean(String raw) {
    final t = raw.trim();
    final digits = t.replaceAll(RegExp(r'\D'), '');
    return (t.startsWith('+') ? '+' : '') + digits;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(clinicRepositoryProvider).saveInfo(
        ClinicInfo(phone: _clean(_phone.text), address: _address.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Klinik bilgileri kaydedildi')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Kaydedilemedi, tekrar deneyin.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: 'Klinik telefonu',
            helperText: 'Örn: 0212 123 45 67 veya +90 212 123 45 67',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (v) {
            final c = _clean(v ?? '');
            if (c.isEmpty) return null;
            final digits = c.replaceAll('+', '').length;
            return (digits < 10 || digits > 13) ? 'Geçerli bir telefon numarası girin' : null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _address,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Adres',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),
        PillButton(label: _saving ? 'Kaydediliyor...' : 'Kaydet', onPressed: _saving ? null : _save),
      ]),
    );
  }
}