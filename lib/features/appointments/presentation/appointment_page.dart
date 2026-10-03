import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class BookingState {
  final int treatment, doctor, dateIndex;
  final String? time;
  const BookingState({this.treatment = 0, this.doctor = 1, this.dateIndex = 3, this.time = '14:45'});
  BookingState copy({int? treatment, int? doctor, int? dateIndex, String? time}) => BookingState(
      treatment: treatment ?? this.treatment, doctor: doctor ?? this.doctor,
      dateIndex: dateIndex ?? this.dateIndex, time: time ?? this.time);
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();
  void setTreatment(int i) => state = state.copy(treatment: i);
  void setDoctor(int i) => state = state.copy(doctor: i);
  void setDate(int i) => state = state.copy(dateIndex: i);
  void setTime(String t) => state = state.copy(time: t);
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);

const _treatments = [
  (Icons.fact_check_outlined, 'İlk Muayene & Kontrol', 'Genel ağız ve diş muayenesi (Ücretsiz)', false),
  (Icons.emergency, 'Diş Ağrısı / Acil Girişim', 'Akut ağrı veya acil durum müdahalesi', true),
  (Icons.auto_awesome_outlined, 'Diş Beyazlatma (Bleaching)', 'Lazerli estetik klinik beyazlatma', false),
  (Icons.hardware_rounded, 'İmplant Danışmanlığı', '3D Tomografi & çene kemiği analizi', false),
  (Icons.cruelty_free_outlined, 'Ortodonti & Şeffaf Plak', 'Telsiz diş düzeltme ve kontrol', false),
];

const _doctors = [
  (null, 'Farketmez', 'En erken müsaitlikteki uzman hekimimiz', '', ''),
  ('https://i.pravatar.cc/200?img=47', 'Dr. Dt. Aylin Kaya', 'Estetik Diş Hekimi & Gülüş Tasarımı', '4.9', '142'),
  ('https://i.pravatar.cc/200?img=12', 'Dr. Dt. Emre Yılmaz', 'Ağız, Diş ve Çene Cerrahisi / İmplantoloji', '5.0', '98'),
];

const _morning = ['09:30', '10:15', '11:00', '11:45'];
const _afternoon = ['14:00', '14:45', '15:30', '16:15', '17:00'];

class AppointmentPage extends ConsumerWidget {
  const AppointmentPage({super.key});

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos',
    'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _daysFull = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bookingProvider);
    final n = ref.read(bookingProvider.notifier);
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));
    final sel = dates[s.dateIndex];
    final selLabel = '${sel.day} ${_months[sel.month - 1]} ${_daysFull[sel.weekday - 1]}';

    return Scaffold(
      appBar: const AppTopBar(title: 'Randevu AI'),
      body: Column(children: [
        _Stepper(),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
            _title(Icons.medical_services_outlined, '1. Tedavi Türü', 'Zorunlu'),
            const SizedBox(height: 12),
            for (var i = 0; i < _treatments.length; i++) ...[
              _OptionTile(
                selected: s.treatment == i,
                onTap: () => n.setTreatment(i),
                leading: _iconBox(_treatments[i].$1, _treatments[i].$4),
                title: _treatments[i].$2,
                subtitle: _treatments[i].$3,
                badge: _treatments[i].$4 ? 'Öncelikli' : null,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            _title(Icons.badge_outlined, '2. Hekim Tercihi', 'Opsiyonel'),
            const SizedBox(height: 12),
            for (var i = 0; i < _doctors.length; i++) ...[
              _OptionTile(
                selected: s.doctor == i,
                onTap: () => n.setDoctor(i),
                leading: _doctors[i].$1 == null
                    ? Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFE5EEFF), shape: BoxShape.circle),
                    child: const Icon(Icons.bolt_rounded, color: AppColors.primary))
                    : PhotoBox(_doctors[i].$1!, w: 48, h: 48, radius: 24),
                title: _doctors[i].$2,
                subtitle: _doctors[i].$3,
                badge: i == 0 ? 'Hızlı Randevu' : null,
                rating: i == 0 ? null : '${_doctors[i].$4} (${_doctors[i].$5} değerlendirme)',
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            _title(Icons.calendar_month_outlined, '3. Randevu Tarihi', '${_months[sel.month - 1]} ${sel.year}'),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final d = dates[i];
                  final active = i == s.dateIndex;
                  return GestureDetector(
                    onTap: () => n.setDate(i),
                    child: Container(
                      width: 68,
                      decoration: _chipDeco(active),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(i == 0 ? 'Bugün' : _months[d.month - 1].substring(0, 3),
                            style: tx(11, c: active ? Colors.white70 : AppColors.muted)),
                        Text('${d.day}', style: tx(22, w: FontWeight.w700, c: active ? Colors.white : AppColors.primary)),
                        Text(_days[d.weekday - 1], style: tx(11, c: active ? Colors.white70 : AppColors.muted)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _title(Icons.schedule, '4. Saat Dilimi', selLabel),
            const SizedBox(height: 12),
            _slotGroup(Icons.wb_sunny_outlined, 'Sabah Kuşağı', _morning, s.time, n.setTime),
            const SizedBox(height: 14),
            _slotGroup(Icons.wb_twilight, 'Öğleden Sonra Kuşağı', _afternoon, s.time, n.setTime),
            const SizedBox(height: 20),
            Text('Şikayet & Not', style: tx(16, w: FontWeight.w700, c: AppColors.primary)),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4, maxLength: 250,
              decoration: InputDecoration(
                hintText: 'Şikayetiniz, mevcut alerjileriniz veya hekime önceden iletmek istediğiniz durumlar (opsiyonel)...',
                hintStyle: tx(13, c: AppColors.mutedLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sterilizasyon & Güven Standartları', style: tx(13, w: FontWeight.w700, c: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('DentNova kliniğimizde tüm cerrahi aletler otoklav ve UV-C döngüsüyle dezenfekte edilmektedir. '
                      'Randevunuz SMS ve WhatsApp ile onaylanacaktır.', style: tx(12, c: AppColors.muted, h: 1.4)),
                ])),
              ]),
            ),
          ]),
        ),
        _confirmBar(context, s, sel),
      ]),
    );
  }

  Widget _confirmBar(BuildContext context, BookingState s, DateTime sel) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    decoration: const BoxDecoration(color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1464748B)))),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('DANIŞMANLIK', style: tx(10, w: FontWeight.w700, c: AppColors.secondary)),
          Text(_treatments[s.treatment].$2, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: tx(14, w: FontWeight.w700, c: AppColors.primary)),
          Text('${sel.day} ${_months[sel.month - 1]}, ${s.time ?? '--:--'}',
              style: tx(11, c: AppColors.muted)),
        ]),
      ),
      const SizedBox(width: 12),
      PillButton(
        label: 'Randevuyu Onayla',
        icon: Icons.arrow_forward,
        onPressed: s.time == null ? null : () {
          // TODO: Firestore'a yaz (appointments koleksiyonu)
        },
      ),
    ]),
  );

  Widget _title(IconData i, String t, String trailing) => Row(children: [
    Icon(i, color: AppColors.primary, size: 20),
    const SizedBox(width: 8),
    Text(t, style: tx(16, w: FontWeight.w700, c: AppColors.primary)),
    const Spacer(),
    Text(trailing, style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
  ]);

  Widget _iconBox(IconData i, bool danger) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
        color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFE5EEFF),
        borderRadius: BorderRadius.circular(12)),
    child: Icon(i, color: danger ? AppColors.danger : AppColors.primary, size: 22),
  );

  BoxDecoration _chipDeco(bool active) => BoxDecoration(
    color: active ? AppColors.primary : Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: active ? AppColors.secondary : AppColors.border, width: active ? 2 : 1),
    boxShadow: active ? const [BoxShadow(color: Color(0x4D0F2B48), blurRadius: 12, offset: Offset(0, 4))] : null,
  );

  Widget _slotGroup(IconData i, String label, List<String> slots, String? sel, ValueChanged<String> on) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(i, size: 18, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(label, style: tx(13, w: FontWeight.w600, c: AppColors.muted)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final t in slots)
            GestureDetector(
              onTap: () => on(t),
              child: Container(
                width: 76, height: 44, alignment: Alignment.center,
                decoration: _chipDeco(sel == t),
                child: Text(t, style: tx(14, w: FontWeight.w600, c: sel == t ? Colors.white : AppColors.primary)),
              ),
            ),
        ]),
      ]);
}

class _Stepper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget dot(int n, String label, int current) {
      final done = n < current, active = n == current;
      return Column(children: [
        Container(
          width: 28, height: 28, alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.secondary : active ? AppColors.primary : const Color(0xFFE5EEFF),
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('$n', style: tx(12, w: FontWeight.w700, c: active ? Colors.white : AppColors.muted)),
        ),
        const SizedBox(height: 4),
        Text(label, style: tx(11, w: FontWeight.w600, c: active || done ? AppColors.primary : AppColors.muted)),
      ]);
    }

    Widget line() => Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18),
        color: const Color(0xFFD3E4FE)));

    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [dot(1, 'Tedavi & Hekim', 2), line(), dot(2, 'Tarih & Saat', 2), line(), dot(3, 'Onay', 2)]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title, subtitle;
  final String? badge, rating;
  const _OptionTile({required this.selected, required this.onTap, required this.leading,
    required this.title, required this.subtitle, this.badge, this.rating});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.secondary : AppColors.border, width: selected ? 2 : 1),
        boxShadow: kShadow,
      ),
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(title, style: tx(14, w: FontWeight.w700, c: AppColors.primary))),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Tag(badge!,
                  bg: badge == 'Öncelikli' ? const Color(0xFFFEE2E2) : AppColors.chipTint,
                  fg: badge == 'Öncelikli' ? AppColors.danger : AppColors.secondary),
            ],
          ]),
          const SizedBox(height: 2),
          Text(subtitle, style: tx(12, c: AppColors.muted)),
          if (rating != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
              Text(' $rating', style: tx(11, w: FontWeight.w600, c: AppColors.muted)),
            ]),
          ],
        ])),
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.secondary : Colors.transparent,
            border: selected ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
      ]),
    ),
  );
}