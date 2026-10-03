import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _services = [
    (Icons.hardware_rounded, 'İmplant', 'Kalıcı Çözüm', false),
    (Icons.cruelty_free_outlined, 'Ortodonti', 'Şeffaf Plak', false),
    (Icons.light_mode_outlined, 'Beyazlatma', 'Lazer Bakımı', false),
    (Icons.sentiment_satisfied_alt_rounded, 'Gülüş Tasarımı', 'Hollywood Smile', false),
    (Icons.child_care_rounded, 'Pedodonti', 'Çocuk Diş', false),
    (Icons.emergency_outlined, '24/7 Acil Diş', 'Hızlı Müdahale', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Ana Sayfa'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Merhaba, Selin ', style: tx(26, w: FontWeight.w700, c: AppColors.primary)),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ]),
                Text('Bugün gülüşünüz için ne yapabiliriz?', style: tx(14, c: AppColors.muted)),
              ]),
            ),
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: AppColors.chipTint, shape: BoxShape.circle),
              child: const Icon(Icons.health_and_safety_outlined, color: AppColors.secondary),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tedavi, hekim veya hizmet ara...',
              hintStyle: tx(14, c: AppColors.mutedLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.secondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 20),
          _nextAppointment(context),
          const SizedBox(height: 28),
          SectionHeader(title: 'Hizmetlerimiz', action: 'Tümünü Gör', onAction: () => context.go('/clinic')),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82,
            children: _services.map((s) => _ServiceTile(icon: s.$1, title: s.$2, sub: s.$3, danger: s.$4)).toList(),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Uzman Hekimlerimiz', subtitle: 'Alanında lider akademik kadromuz',
              action: 'Kadroyu Gör'),
          const SizedBox(height: 14),
          SizedBox(
            height: 128,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              _doctorCard(context, 'Doç. Dr. Zeynep Kaya', 'Ortodonti Uzmanı', '4.9', '142', '12+ Yıl Tecrübe',
                  'https://i.pravatar.cc/200?img=47'),
              const SizedBox(width: 12),
              _doctorCard(context, 'Dr. Dt. Emre Yılmaz', 'Çene Cerrahisi', '5.0', '98', '15+ Yıl Tecrübe',
                  'https://i.pravatar.cc/200?img=12'),
            ]),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Gülüş İpuçları & Rehber', action: 'Daha Fazla'),
          const SizedBox(height: 14),
          _article('Koruyucu Diş', '3 dk okuma', 'Ağız ve Diş Sağlığında Doğru Fırçalama Teknikleri',
              'https://images.unsplash.com/photo-1609840114035-3c981b782dfe?w=400'),
          const SizedBox(height: 12),
          _article('Ortodonti', '5 dk okuma', 'Şeffaf Plak Tedavisi Hakkında Merak Edilenler',
              'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=400'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const CircleAvatar(backgroundColor: Color(0xFFDCE9FF),
                  child: Icon(Icons.headset_mic_outlined, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sorunuz mu var?', style: tx(13, w: FontWeight.w600, c: AppColors.primary)),
                Text('Danışmanımızla anında görüşün', style: tx(12, c: AppColors.muted)),
              ])),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: Text('Ara', style: tx(13, w: FontWeight.w600, c: AppColors.secondary)),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder(),
                    backgroundColor: Colors.white, side: BorderSide.none, foregroundColor: AppColors.secondary),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _nextAppointment(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(colors: [Color(0xFF0F2B48), Color(0xFF1B4A73)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: const [BoxShadow(color: Color(0x240F2B48), blurRadius: 24, offset: Offset(0, 10))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.circle, size: 8, color: AppColors.secondary),
            const SizedBox(width: 6),
            Text('YAKLAŞAN RANDEVU', style: tx(11, w: FontWeight.w700, c: Colors.white)),
          ]),
        ),
        const Spacer(),
        Text('Kayıt: #DN-824', style: tx(12, c: Colors.white70)),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        const PhotoBox('https://i.pravatar.cc/200?img=12', w: 56, h: 56, radius: 12),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dr. Dt. Emre Yılmaz', style: tx(18, w: FontWeight.w700, c: Colors.white)),
          Text('Rutin Kontrol & Diş Temizliği', style: tx(12, c: Colors.white70)),
        ]),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, color: AppColors.secondary, size: 18),
          const SizedBox(width: 8),
          Text('24 Mayıs Cuma', style: tx(14, w: FontWeight.w600, c: Colors.white)),
          const Spacer(),
          Container(width: 1, height: 16, color: Colors.white24),
          const Spacer(),
          const Icon(Icons.access_time, color: AppColors.secondary, size: 18),
          const SizedBox(width: 8),
          Text('14:30', style: tx(14, w: FontWeight.w600, c: Colors.white)),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(flex: 5, child: PillButton(label: 'Kliniğe Yol Tarifi', icon: Icons.directions_outlined,
            bg: const Color(0xFF39B8FD), fg: AppColors.primaryDark, onPressed: () {})),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: PillButton(label: 'Detayları Gör', bg: Colors.white12, onPressed: () {})),
      ]),
    ]),
  );

  Widget _doctorCard(BuildContext c, String name, String spec, String rate, String n, String exp, String img) =>
      SizedBox(
        width: 300,
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              PhotoBox(img, w: 64, h: 64, radius: 16),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.star_border_rounded, size: 16, color: AppColors.secondary),
                  Text(' $rate ', style: tx(12, w: FontWeight.w700)),
                  Text('($n)', style: tx(12, c: AppColors.muted)),
                ]),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: tx(15, w: FontWeight.w700, c: AppColors.primary)),
                Text(spec, style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
              ])),
            ]),
            const Spacer(),
            Row(children: [
              Tag(exp, bg: const Color(0xFFE5EEFF), fg: AppColors.primary),
              const Spacer(),
              SizedBox(height: 36, child: PillButton(label: 'Randevu', onPressed: () => c.go('/appointment'))),
            ]),
          ]),
        ),
      );

  Widget _article(String cat, String read, String title, String img) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      PhotoBox(img, w: 96, h: 80, radius: 12),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$cat  •  $read', style: tx(11, w: FontWeight.w600, c: AppColors.secondary)),
        const SizedBox(height: 4),
        Text(title, style: tx(14, w: FontWeight.w700, c: AppColors.primary, h: 1.3)),
        const SizedBox(height: 6),
        Text('Yazıyı Oku →', style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
      ])),
    ]),
  );
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool danger;
  const _ServiceTile({required this.icon, required this.title, required this.sub, required this.danger});

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.danger : AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: danger ? AppColors.danger : AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: tx(12, w: FontWeight.w700, c: c)),
        Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: tx(10, c: danger ? AppColors.danger : AppColors.muted)),
      ]),
    );
  }
}