import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/admin/dashboard/page.dart';
import '../features/splash_screen/splash_screen.dart';
import '../features/onboarding/onboarding.dart';
import '../features/resident/pages/resident_page.dart';
import '../features/authentication/login/login.dart';


class AppRoutes {
  // static const String initialRoute = '/';
  static const String splash = '/splash-screen';
  static const String userProfile = '/user-profile-screen';
  static const String login = '/login-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String residentDashboard = '/resident/dashboard';
  static const String adminDashboard = '/admin/dashboard';

  static Map<String, WidgetBuilder> routes = {
    // initialRoute: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    adminDashboard: (context) => const AdminDashboard(),
    residentDashboard: (context) => const ResidentPage(),
    // userProfile: (context) => const UserProfileScreen(),
    login: (context) => const LoginScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
  };
}
