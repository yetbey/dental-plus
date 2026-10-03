import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/appointments/presentation/appointment_page.dart';
import '../../features/auth/presentation/account_security_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/clinic/presentation/clinic_page.dart';
import '../../features/clinic/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../widgets/main_shell.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String home = '/';
  static const String clinic = '/clinic';
  static const String appointment = '/appointment';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String accountSecurity = '/account';
  static const String changePassword = '/account/change-password';

  /// Sadece oturum açmamış kullanıcıların görebileceği ekranlar.
  static const authRoutes = {login, register, forgotPassword};
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(currentUserProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      String? goTo(String target) => location == target ? null : target;

      final authState = ref.read(authStateProvider);
      final userState = ref.read(currentUserProvider);

      // 1) Firebase oturumu henüz yüklenmediyse splash'te bekle.
      if (!authState.hasValue) return goTo(AppRoutes.splash);

      // 2) Giriş yapılmamışsa sadece auth ekranlarına izin ver.
      final firebaseUser = authState.value;
      if (firebaseUser == null) {
        return AppRoutes.authRoutes.contains(location) ? null : AppRoutes.login;
      }

      // 3) E-posta doğrulanmamışsa doğrulama ekranına gönder.
      // Google ve Apple hesaplarının e-postası zaten doğrulanmış gelir.
      if (!firebaseUser.emailVerified) return goTo(AppRoutes.verifyEmail);

      // 4) Profil (rol) henüz yüklenmediyse bekle.
      final appUser = userState.value;
      if (appUser == null) return goTo(AppRoutes.splash);

      // 5) Rol bazlı yönlendirme. Hesap ekranları her iki rol için de açık.
      final inAdminArea = location.startsWith(AppRoutes.admin);
      final inAccountArea = location.startsWith(AppRoutes.accountSecurity);
      if (appUser.isAdmin) {
        return inAdminArea || inAccountArea ? null : AppRoutes.admin;
      }

      if (inAdminArea ||
          location == AppRoutes.splash ||
          location == AppRoutes.verifyEmail ||
          AppRoutes.authRoutes.contains(location)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const HomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.clinic,
              builder: (_, _) => const ClinicPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.appointment,
              builder: (_, _) => const AppointmentPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfilePage(),
            ),
          ]),
        ],
      ),

      GoRoute(
        path: AppRoutes.admin,
        builder: (_, _) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSecurity,
        builder: (_, _) => const AccountSecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});