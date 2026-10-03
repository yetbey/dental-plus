import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/clinic/presentation/home_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String home = '/';
  static const String admin = '/admin';

  /// Sadece oturum açmamış kullanıcıların görebileceği ekranlar.
  static const authRoutes = {login, register, forgotPassword};
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
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
        return AppRoutes.authRoutes.contains(location)
            ? null
            : AppRoutes.login;
      }

      // 3) E-posta doğrulanmamışsa doğrulama ekranına gönder.
      // Google ve Apple hesaplarının e-postası zaten doğrulanmış gelir.
      if (!firebaseUser.emailVerified) return goTo(AppRoutes.verifyEmail);

      // 4) Profil (rol) henüz yüklenmediyse bekle.
      final appUser = userState.value;
      if (appUser == null) return goTo(AppRoutes.splash);

      // 5) Rol bazlı yönlendirme.
      final inAdminArea = location.startsWith(AppRoutes.admin);
      if (appUser.isAdmin) {
        return inAdminArea ? null : AppRoutes.admin;
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
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, _) => const AdminDashboardScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});