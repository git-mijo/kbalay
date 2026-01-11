import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/admin/announcement/page.dart';
import 'package:flutter_hoa/features/admin/dashboard/page.dart';
import 'package:flutter_hoa/features/admin/payment/page.dart';
import 'package:flutter_hoa/features/admin/report/page.dart';
import 'package:flutter_hoa/features/resident/profile/profile_settings.dart';
import '../features/splash_screen/splash_screen.dart';
import '../features/onboarding/onboarding.dart';
import '../features/resident/home/page.dart';
import '../features/authentication/signin/page.dart';
import '../features/authentication/signup/page.dart';


class AppRoutes {
  // static const String initialRoute = '/';
  static const String splash = '/splash-screen';
  static const String userProfile = '/user-profile-screen';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String onboardingFlow = '/onboarding-flow';
  static const String residentDashboard = '/resident/dashboard';
  static const String residentProfile = '/resident/profile';
  static const String residentProfileSettings = '/resident/profile/settings';
  static const String adminDashboard = '/admin';
  static const String adminPayment = '/admin/payment';
  static const String adminReports = '/admin/reports';
  static const String adminAnnouncement = '/admin/announcement';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    adminDashboard: (context) => const AdminDashboard(),
    adminPayment: (context) => const PaymentManagement(),
    adminReports: (context) => const ReportDueUsersPage(),
    adminAnnouncement: (context) => const AdminAnnouncementsScreen(),
    residentDashboard: (context) => const ResidentPage(),
    residentProfileSettings: (context) => const ResidentProfileSettingsPage(),
    // userProfile: (context) => const UserProfileScreen(),
    signIn: (context) => const SignInScreen(),
    signUp: (context) => const SignUpScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
  };
}
