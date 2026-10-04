import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dental_plus/core/theme/app_colors.dart';
import 'package:dental_plus/core/theme/app_theme.dart';
import 'package:dental_plus/core/widgets/common.dart';
import 'package:dental_plus/features/content/content_providers.dart';
import 'package:dental_plus/features/content/domain/article.dart';

const articleCategories = ['Koruyucu Diş', 'Ortodonti', 'Estetik', 'Çocuk Diş', 'Cerrahi', 'Genel'];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

void _openForm(BuildContext context, Article? initial) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _ArticleForm(initial: initial),
  );
}

class AdminArticlesScreen extends ConsumerWidget {
  const AdminArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allArticlesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Rehber Yazıları', style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Yazı Ekle', style: tx(13, w: FontWeight.w600, c: Colors.white)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Yazılar yüklenemedi.', style: tx(14, c: AppColors.muted))),
        data: (items) => items.isEmpty
            ? Center(child: Text('Henüz yazı yok.', style: tx(14, c: AppColors.muted)))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ArticleTile(items[i]),
        ),
      ),
    );
  }
}

class _ArticleTile extends ConsumerWidget {
  final Article a;
  const _ArticleTile(this.a);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = a.cover;
    return AppCard(
      onTap: () => _openForm(context, a),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 56,
            child: (cover == null || cover.isEmpty)
                ? Container(
              color: const Color(0xFFE5EEFF),
              child: const Icon(Icons.article_outlined, color: AppColors.primary),
            )
                : Image.memory(base64Decode(cover), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tx(14, w: FontWeight.w700, c: a.active ? AppColors.primary : AppColors.mutedLight)),
            Text('${a.category} • ${a.readMinutes} dk okuma', style: tx(12, c: AppColors.muted)),
          ]),
        ),
        Switch(
          value: a.active,
          activeColor: AppColors.secondary,
          onChanged: (v) async {
            try {
              await ref.read(articleRepositoryProvider).setActive(a.id, v);
            } catch (_) {
              if (context.mounted) _snack(context, 'Güncellenemedi, tekrar deneyin.');
            }
          },
        ),
      ]),
    );
  }
}

class _ArticleForm extends ConsumerStatefulWidget {
  final Article? initial;
  const _ArticleForm({required this.initial});

  @override
  ConsumerState<_ArticleForm> createState() => _ArticleFormState();
}

class _ArticleFormState extends ConsumerState<_ArticleForm> {
  final _form = GlobalKey<FormState>();
  late final Article? _i = widget.initial;
  late final _title = TextEditingController(text: _i?.title ?? '');
  late final _content = TextEditingController(text: _i?.content ?? '');
  late String _category = _i?.category.isNotEmpty == true ? _i!.category : articleCategories.first;
  late String? _cover = _i?.cover;
  late bool _active = _i?.active ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 560,
        maxHeight: 560,
        imageQuality: 60,
      );
      if (picked == null) return;
      final b64 = base64Encode(await picked.readAsBytes());
      if (b64.length >= 95000) {
        if (mounted) _snack(context, 'Fotoğraf çok büyük, daha küçük bir fotoğraf seçin.');
        return;
      }
      setState(() => _cover = b64);
    } catch (_) {
      if (mounted) _snack(context, 'Fotoğrafa erişilemedi. Uygulama izinlerini kontrol edin.');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final a = Article(
      id: _i?.id ?? '',
      title: _title.text.trim(),
      category: _category,
      content: _content.text.trim(),
      cover: _cover,
      active: _active,
      createdAt: _i?.createdAt ?? DateTime.now(),
    );
    try {
      await ref.read(articleRepositoryProvider).save(a);
      if (!mounted) return;
      Navigator.pop(context);
      _snack(context, 'Yazı kaydedildi');
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
        title: const Text('Yazı silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
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
      await ref.read(articleRepositoryProvider).delete(_i!.id);
      if (!mounted) return;
      Navigator.pop(context);
      _snack(context, 'Yazı silindi');
    } catch (_) {
      if (mounted) _snack(context, 'Silinemedi, tekrar deneyin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = {...articleCategories, _category}.toList();
    final cover = _cover;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_i == null ? 'Yeni Yazı' : 'Yazıyı Düzenle',
                style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _saving ? null : _pickCover,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: const Color(0xFFE5EEFF),
                  child: (cover == null || cover.isEmpty)
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 32),
                    const SizedBox(height: 6),
                    Text('Kapak fotoğrafı ekle', style: tx(12, w: FontWeight.w600, c: AppColors.primary)),
                  ])
                      : Image.memory(base64Decode(cover), fit: BoxFit.cover),
                ),
              ),
            ),
            if (cover != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saving ? null : () => setState(() => _cover = null),
                  child: Text('Fotoğrafı kaldır', style: tx(12, w: FontWeight.w600, c: AppColors.danger)),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _title,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Başlık'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Başlık girin' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _content,
              maxLines: 10,
              maxLength: 5000,
              decoration: const InputDecoration(labelText: 'Yazı metni', alignLabelWithHint: true),
              validator: (v) => (v == null || v.trim().length < 20) ? 'Yazı metnini girin' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hastalara görünür'),
              value: _active,
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PillButton(label: _saving ? 'Kaydediliyor...' : 'Kaydet', onPressed: _saving ? null : _save),
            ),
            if (_i != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _delete,
                  child: Text('Yazıyı Sil', style: tx(13, w: FontWeight.w600, c: AppColors.danger)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}