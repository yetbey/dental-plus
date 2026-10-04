import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'home_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Ana Sayfa'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const HomeGreeting(),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tedavi, hekim veya hizmet ara...',
              hintStyle: tx(14, c: AppColors.mutedLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.secondary),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 20),
          const UpcomingAppointmentCard(),
          const SizedBox(height: 28),
          const HomeServicesSection(),
          const SizedBox(height: 28),
          const HomeDoctorSection(),
          const SizedBox(height: 28),
          const HomeArticlesSection(),
          const SizedBox(height: 20),
          const HomeHelpCard(),
        ],
      ),
    );
  }

  Widget _doctorCard(BuildContext c, String name, String spec, String rate, String n, String exp, String img) =>
      SizedBox(
        width: 300,
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              PhotoBox(img, w: 64, h: 64, radius: 16),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.star_border_rounded, size: 16, color: AppColors.secondary),
                      Text(' $rate ', style: tx(12, w: FontWeight.w700)),
                      Text('($n)', style: tx(12, c: AppColors.muted)),
                    ]),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$cat • $read', style: tx(11, w: FontWeight.w600, c: AppColors.secondary)),
            const SizedBox(height: 4),
            Text(title, style: tx(14, w: FontWeight.w700, c: AppColors.primary, h: 1.3)),
            const SizedBox(height: 6),
            Text('Yazıyı Oku →', style: tx(12, w: FontWeight.w600, c: AppColors.secondary)),
          ])),
    ]),
  );
}