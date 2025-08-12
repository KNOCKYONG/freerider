import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/main/main_screen.dart';

// 라우트 경로 상수
class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String main = '/main';
  static const String home = '/home';
  static const String activity = '/activity';
  static const String mission = '/mission';
  static const String card = '/card';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String cardRegistration = '/card-registration';
  static const String pointHistory = '/point-history';
  static const String challenge = '/challenge';
  static const String leaderboard = '/leaderboard';
  static const String notification = '/notification';
}

// GoRouter Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Main App with Bottom Navigation
      GoRoute(
        path: AppRoutes.main,
        name: 'main',
        builder: (context, state) => const MainScreen(),
        routes: [
          // Nested routes for main features
          GoRoute(
            path: 'card-registration',
            name: 'card-registration',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Card Registration')),
            ),
          ),
          GoRoute(
            path: 'point-history',
            name: 'point-history',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Point History')),
            ),
          ),
          GoRoute(
            path: 'challenge',
            name: 'challenge',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Challenge')),
            ),
          ),
          GoRoute(
            path: 'leaderboard',
            name: 'leaderboard',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Leaderboard')),
            ),
          ),
          GoRoute(
            path: 'notification',
            name: 'notification',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Notification')),
            ),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settings')),
            ),
          ),
        ],
      ),
    ],
    
    // Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '알 수 없는 오류',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.main),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
    
    // Redirect Logic
    redirect: (context, state) {
      // TODO: Add authentication check logic
      // final isAuthenticated = ref.read(authProvider).isAuthenticated;
      // final isOnboardingComplete = ref.read(onboardingProvider).isComplete;
      
      // if (!isAuthenticated && !publicRoutes.contains(state.location)) {
      //   return AppRoutes.login;
      // }
      
      return null;
    },
  );
});

// Navigation Helper Extension
extension NavigationExtension on BuildContext {
  void navigateTo(String route) => go(route);
  void navigateToNamed(String name, {Map<String, String>? params}) => 
      goNamed(name, pathParameters: params ?? {});
  void navigateBack() => pop();
}