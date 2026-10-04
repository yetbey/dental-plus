import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/clinic/domain/treatment.dart';

import '../../clinic/presentation/clinic_providers.dart';

const _categories = ['Genel', 'Acil', 'Estetik', 'Restoratif', 'Ortodonti', 'Cerrahi', 'Koruyucu', 'Pedodonti'];
const _iconKeys = ['checkup', 'emergency', 'smile', 'whitening', 'crown', 'invisible', 'implant', 'ortho', 'child', 'default'];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

void _openForm(BuildContext context, Treatment? initial, int nextOrder) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _TreatmentForm(initial: initial, nextOrder: nextOrder),
  );
}

class AdminTreatmentsScreen extends ConsumerWidget {
  const AdminTreatmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allTreatmentsProvider);
    final list = async.asData?.value ?? const <Treatment>[];
    final nextOrder = list.isEmpty ? 0 : list.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tedaviler', style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null, nextOrder),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Tedavi Ekle', style: tx(13, w: FontWeight.w600, c: Colors.white)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('Tedaviler yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (items) => items.isEmpty
            ? Center(child: Text('Henüz tedavi yok.', style: tx(14, c: AppColors.muted)))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _TreatmentTile(items[i], nextOrder),
        ),
      ),
    );
  }
}

class _TreatmentTile extends ConsumerWidget {
  final Treatment t;
  final int nextOrder;
  const _TreatmentTile(this.t, this.nextOrder);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => _openForm(context, t, nextOrder),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: t.urgent ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(t.icon, color: t.urgent ? AppColors.danger : AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(14, w: FontWeight.w700, c: t.active ? AppColors.primary : AppColors.mutedLight)),
            Text('${t.category} • ${t.subtitle}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(12, c: AppColors.muted)),
          ]),
        ),
        Switch(
          value: t.active,
          activeColor: AppColors.secondary,
          onChanged: (v) async {
            try {
              await ref.read(clinicRepositoryProvider).setTreatmentActive(t.id, v);
            } catch (_) {
              if (context.mounted) _snack(context, 'Güncellenemedi, tekrar deneyin.');
            }
          },
        ),
      ]),
    );
  }
}

class _TreatmentForm extends ConsumerStatefulWidget {
  final Treatment? initial;
  final int nextOrder;
  const _TreatmentForm({required this.initial, required this.nextOrder});

  @override
  ConsumerState<_TreatmentForm> createState() => _TreatmentFormState();
}

class _TreatmentFormState extends ConsumerState<_TreatmentForm> {
  final _form = GlobalKey<FormState>();
  late final Treatment? _i = widget.initial;
  late final _title = TextEditingController(text: _i?.title ?? '');
  late final _subtitle = TextEditingController(text: _i?.subtitle ?? '');
  late final _desc = TextEditingController(text: _i?.description ?? '');
  late final _badge = TextEditingController(text: _i?.badge ?? '');
  late final _perks = TextEditingController(text: _i?.perks.join(', ') ?? '');
  late final _order = TextEditingController(text: '${_i?.sortOrder ?? widget.nextOrder}');
  late String _category = _i?.category.isNotEmpty == true ? _i!.category : 'Genel';
  late String _iconKey = _i?.iconKey ?? 'default';
  late bool _urgent = _i?.urgent ?? false;
  late bool _active = _i?.active ?? true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _desc, _badge, _perks, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final perks = _perks.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(5)
        .toList();
    final badge = _badge.text.trim();
    final t = Treatment(
      id: _i?.id ?? '',
      title: _title.text.trim(),
      category: _category,
      subtitle: _subtitle.text.trim(),
      description: _desc.text.trim(),
      badge: badge.isEmpty ? null : badge,
      perks: perks,
      iconKey: _iconKey,
      urgent: _urgent,
      active: _active,
      sortOrder: int.tryParse(_order.text.trim()) ?? (_i?.sortOrder ?? widget.nextOrder),
    );
    try {
      await ref.read(clinicRepositoryProvider).saveTreatment(t);
      if (!mounted) return;
      Navigator.pop(context);
      _snack(context, 'Tedavi kaydedildi');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, 'Kaydedilemedi, tekrar deneyin.');
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tedavi silinsin mi?'),
        content: const Text('Geçmiş randevulardaki tedavi adı korunur. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clinicRepositoryProvider).deleteTreatment(_i!.id);
      if (!mounted) return;
      Navigator.pop(context);
      _snack(context, 'Tedavi silindi');
    } catch (_) {
      if (mounted) _snack(context, 'Silinemedi, tekrar deneyin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = {..._categories, _category}.toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_i == null ? 'Yeni Tedavi' : 'Tedaviyi Düzenle',
                style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Başlık'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Başlık girin' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitle,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Kısa açıklama',
                helperText: 'Randevu listesinde başlığın altında görünür',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Kısa açıklama girin' : null,
            ),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Detaylı açıklama (opsiyonel)'),
            ),
            TextFormField(
              controller: _badge,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Rozet (opsiyonel)', helperText: 'Örn: 2-3 Seans'),
            ),
            TextFormField(
              controller: _perks,
              decoration: const InputDecoration(
                labelText: 'Özellikler (opsiyonel)',
                helperText: 'Virgülle ayırın, en fazla 5 adet',
              ),
            ),
            const SizedBox(height: 16),
            Text('İkon', style: tx(13, w: FontWeight.w600, c: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final k in _iconKeys)
                GestureDetector(
                  onTap: () => setState(() => _iconKey = k),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _iconKey == k ? AppColors.primary : const Color(0xFFE5EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(treatmentIcon(k), color: _iconKey == k ? Colors.white : AppColors.primary),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acil / öncelikli tedavi'),
              value: _urgent,
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _urgent = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hastalara görünür'),
              value: _active,
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _active = v),
            ),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sıra', helperText: 'Küçük sayı listede önce görünür'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PillButton(label: _saving ? 'Kaydediliyor...' : 'Kaydet', onPressed: _saving ? null : _save),
            ),
            if (_i != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _delete,
                  child: Text('Tedaviyi Sil', style: tx(13, w: FontWeight.w600, c: AppColors.danger)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}