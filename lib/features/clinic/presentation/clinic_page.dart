import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class _Treatment {
  final IconData icon;
  final String category, title, desc, badge, b1, b2, cta;
  final bool primaryCta;
  const _Treatment(this.icon, this.category, this.title, this.desc, this.badge, this.b1, this.b2, this.cta,
      this.primaryCta);
}

const _treatments = [
  _Treatment(Icons.sentiment_satisfied_alt_outlined, 'GÜLÜŞ TASARIMI', 'Estetik Gülüş Tasarımı',
      'Yapay zeka destekli dijital prova ile nihai gülüşünüzü işleme başlamadan önce 3D olarak görün ve onaylayın.',
      '2-3 Seans', 'Ücretsiz Dijital Mock-Up', 'Kişiye Özel Planlama', 'Detayları İncele', true),
  _Treatment(Icons.diamond_outlined, 'RESTORATİF', 'Zirkonyum & Porselen Kaplama',
      'Yüksek biyouyumluluk ve biyoestetik doku entegrasyonu ile diğinde moraşma yapmayan, tamamen doğal görünüm.',
      '3-5 Gün', '10 Yıl Garanti Belgesi', 'Cad/Cam Üretim', 'Tedavi Sürecini Gör', false),
  _Treatment(Icons.visibility_off_outlined, 'TELSİZ ORTODONTİ', 'Şeffaf Plak (Invisalign)',
      'Klasik metal tellerin aksine çıkarılabilir, yemek yerken kısıtlama yaratmayan, neredeyse görünmez plaklar.',
      'Konforlu', '6-12 Ay Ortalama', 'Online Kontrol', 'Simülasyonu İncele', false),
  _Treatment(Icons.hardware_rounded, 'İLERİ CERRAHİ', 'Lazer Destekli İmplant',
      'Dikişsiz lazer kesi tekniğiyle kanamasız, hızlı iyileşme periyodu ve ayrıca geçici koltukta yüksek konfor.',
      'Ağrısız', 'İsviçre Menşe Titanyum', 'Ömür Boyu Garanti', 'İmplant Kılavuzunu İncele', false),
  _Treatment(Icons.auto_awesome_outlined, 'KORUYUCU & ESTETİK', 'Ofis Tipi Diş Beyazlatma',
      'Diş minesine zarar vermeden, hassasiyet önleyici özel jel ve soğuk ışık ile 45 dakikada bir ton ağartma.',
      '45 Dakika', 'Anında Görünür Etki', 'Hassasiyetsiz Formül', 'Hemen Randevu Seç', false),
];

class ClinicPage extends StatefulWidget {
  const ClinicPage({super.key});
  @override
  State<ClinicPage> createState() => _ClinicPageState();
}

class _ClinicPageState extends State<ClinicPage> {
  int _cat = 0;
  static const _cats = ['Tümü', 'Estetik', 'Ortodonti', 'Cerrahi'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Tedaviler'),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('YENİ NESİL DİJİTAL DİŞ HEKİMLİĞİ', style: tx(11, w: FontWeight.w700, c: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Son Teknoloji & Uzman Kadro ile Sağlıklı Gülüşler', style: tx(30, w: FontWeight.w700, c: AppColors.primary, h: 1.2)),
        const SizedBox(height: 8),
        Text('DentNova, dijital görüntüleme ve ileri cerrahi protokolleriyle diş hekimliğini kaygısız, konforlu ve estetik bir deneyime dönüştürür.',
            style: tx(13, c: AppColors.muted, h: 1.5)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _metric(Icons.workspace_premium_outlined, '15+ Yıl', 'Klinik Tecrübe')),
          const SizedBox(width: 12),
          Expanded(child: _metric(Icons.sentiment_satisfied_alt_outlined, '25.000+', 'Mutlu Gülüş')),
        ]),
        const SizedBox(height: 16),
        _tech(),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Klinik Standartlarımız', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
            Text('Konfor ve sterilizasyonda sıfır tolerans', style: tx(12, c: AppColors.muted)),
          ])),
          Text('360° Tur', style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          const PhotoBox('https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
              w: double.infinity, h: 180, radius: 16),
          Positioned(bottom: 12, left: 12, child: Row(children: [
            _glass(Icons.chair_outlined, 'VIP Salonu'),
            const SizedBox(width: 8),
            _glass(Icons.sanitizer_outlined, 'Steril Lab'),
          ])),
        ]),
        const SizedBox(height: 24),
        Text('Kapsamlı Tedavilerimiz', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
        Text('Size özel hazırlanan tedavi planları', style: tx(12, c: AppColors.muted)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _cat = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _cat == i ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cat == i ? AppColors.primary : AppColors.border),
                ),
                child: Text(_cats[i], style: tx(13, w: FontWeight.w600, c: _cat == i ? Colors.white : AppColors.primary)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final t in _treatments) ...[_treatmentCard(context, t), const SizedBox(height: 14)],
        const SizedBox(height: 10),
        _beforeAfter(),
        const SizedBox(height: 24),
        _reviews(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sorularınız mı var?', style: tx(15, w: FontWeight.w700, c: AppColors.primary)),
              Text('Uzman danışmanımız anında yanıtlasın.', style: tx(12, c: AppColors.muted)),
            ])),
            PillButton(label: 'Bizi Arayın', icon: Icons.headset_mic_outlined,
                bg: const Color(0xFF39B8FD), fg: AppColors.primaryDark, onPressed: () {}),
          ]),
        ),
      ]),
    );
  }

  Widget _metric(IconData i, String v, String l) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
          decoration: const BoxDecoration(color: AppColors.chipTint, shape: BoxShape.circle),
          child: Icon(i, size: 18, color: AppColors.secondary)),
      const SizedBox(height: 8),
      Text(v, style: tx(22, w: FontWeight.w700, c: AppColors.primary)),
      Text(l, style: tx(12, c: AppColors.muted)),
    ]),
  );

  Widget _tech() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.biotech_outlined, color: AppColors.secondary, size: 18),
        const SizedBox(width: 8),
        Text('DİJİTAL ALTYAPI DONANIMI', style: tx(11, w: FontWeight.w700, c: const Color(0xFF39B8FD))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _techItem(Icons.view_in_ar_outlined, '3D Tomografi', 'Mikron hassasiyetli gene tarama')),
        const SizedBox(width: 12),
        Expanded(child: _techItem(Icons.document_scanner_outlined, 'Ağız İçi Tarayıcı', 'Macunsuz, dijital ölçüm')),
      ]),
    ]),
  );

  Widget _techItem(IconData i, String t, String s) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(i, size: 16, color: Colors.white), const SizedBox(width: 6),
        Flexible(child: Text(t, style: tx(12, w: FontWeight.w700, c: Colors.white)))]),
      const SizedBox(height: 4),
      Text(s, style: tx(11, c: Colors.white70)),
    ]),
  );

  Widget _glass(IconData i, String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
    child: Row(children: [Icon(i, size: 14, color: AppColors.primary), const SizedBox(width: 4),
      Text(t, style: tx(11, w: FontWeight.w600, c: AppColors.primary))]),
  );

  Widget _treatmentCard(BuildContext ctx, _Treatment t) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(10)),
            child: Icon(t.icon, size: 18, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: Text(t.category, style: tx(11, w: FontWeight.w700, c: AppColors.secondary))),
        Tag(t.badge),
      ]),
      const SizedBox(height: 10),
      Text(t.title, style: tx(18, w: FontWeight.w700, c: AppColors.primary)),
      const SizedBox(height: 6),
      Text(t.desc, style: tx(12, c: AppColors.muted, h: 1.5)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _check(t.b1)),
        Expanded(child: _check(t.b2)),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: PillButton(
          label: t.cta,
          icon: t.primaryCta ? Icons.arrow_forward : null,
          bg: t.primaryCta ? AppColors.primary : AppColors.chipTint,
          fg: t.primaryCta ? Colors.white : AppColors.secondary,
          onPressed: () => ctx.go('/appointment'),
        ),
      ),
    ]),
  );

  Widget _check(String t) => Row(children: [
    const Icon(Icons.check_circle_outline, size: 14, color: AppColors.tertiary),
    const SizedBox(width: 4),
    Flexible(child: Text(t, style: tx(11, w: FontWeight.w600, c: AppColors.primary))),
  ]);

  Widget _beforeAfter() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Öncesi & Sonrası', style: tx(20, w: FontWeight.w700, c: AppColors.primary)),
        Text('Doğallığıyla ödüle değer estetik gülüşler', style: tx(12, c: AppColors.muted)),
      ])),
      const Tag('Vaka: #4152', bg: Color(0xFFE5EEFF), fg: AppColors.primary),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: Stack(children: [
        const PhotoBox('https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=400',
            h: 160, w: double.infinity, radius: 16),
        Positioned(bottom: 8, left: 8, child: _glass(Icons.history, 'Önce')),
      ])),
      const SizedBox(width: 8),
      Expanded(child: Stack(children: [
        const PhotoBox('https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=400',
            h: 160, w: double.infinity, radius: 16),
        Positioned(bottom: 8, right: 8, child: _glass(Icons.auto_awesome, 'Sonra')),
      ])),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: Text('Tedavi: 8 Üye E-Max Lamina', style: tx(11, c: AppColors.muted))),
      Text('Toplam: 4 Gün', style: tx(11, c: AppColors.muted)),
    ]),
  ]);

  Widget _reviews() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text('Hasta Deneyimleri', style: tx(20, w: FontWeight.w700, c: AppColors.primary))),
      const Icon(Icons.star_rounded, size: 16, color: AppColors.secondary),
      Text(' 4.9/5', style: tx(12, w: FontWeight.w700)),
    ]),
    Text('Google Haritalar 4.9/5Puan (750+ Değerlendirme)', style: tx(11, c: AppColors.muted)),
    const SizedBox(height: 12),
    SizedBox(
      height: 150,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        _review('Ece Sözeri', 'Hollywood Smile Tedavisi',
            'Diş hekimi korkumu DentNova sayesinde yendim. Dijital tasarım aşamasında gülüşümü görüp karar vermek inanılmaz güvendi.'),
        const SizedBox(width: 12),
        _review('Burak K.', 'İmplant Tedavisi',
            'Lazerli implant sonrası neredeyse hiç ağrı hissetmedim. Ekip çok ilgili ve süreç şeffaftı.'),
      ]),
    ),
  ]);

  Widget _review(String name, String treat, String text) => SizedBox(
    width: 290,
    child: AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary))),
        const SizedBox(height: 8),
        Expanded(child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis,
            style: tx(12, c: AppColors.muted, h: 1.5))),
        Row(children: [
          CircleAvatar(radius: 14, backgroundColor: const Color(0xFFE5EEFF),
              child: Text(name.substring(0, 1), style: tx(11, w: FontWeight.w700, c: AppColors.primary))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: tx(12, w: FontWeight.w700, c: AppColors.primary)),
            Text(treat, style: tx(10, c: AppColors.muted)),
          ]),
        ]),
      ]),
    ),
  );
}