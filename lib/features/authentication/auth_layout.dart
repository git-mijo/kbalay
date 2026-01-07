
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/app/auth_service.dart';
import 'package:flutter_hoa/features/admin/dashboard/page.dart';
import 'package:flutter_hoa/features/authentication/login/login.dart';
import 'package:flutter_hoa/features/resident/pages/resident_page.dart';
import 'package:flutter_hoa/features/splash_screen/splash_screen.dart';

class AuthLayout extends StatelessWidget{
  const AuthLayout({
    super.key,
    this.pageIfNotAuthenticated,
  });

  final Widget? pageIfNotAuthenticated;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            } else if (snapshot.hasData && snapshot.data != null) {
              final uid = snapshot.data!.uid;
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('master_residents')
                    .where('userId', isEqualTo: uid)
                    .get(),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const SplashScreen();
                  } else if (roleSnapshot.hasData &&
                      roleSnapshot.data!.docs.isNotEmpty) {
                    final doc = roleSnapshot.data!.docs.first;
                    final data = doc.data() as Map<String, dynamic>;
                    final role = data['role'] ?? 'user';

                    if (role == 'admin') {
                      return const AdminDashboard();
                    } else {
                      return const ResidentPage();
                    }
                  } else {
                    // No matching user found
                    return const LoginScreen();
                  }
                },
              );
            } else {
              // Not logged in
              return pageIfNotAuthenticated ?? const LoginScreen();
            }
          },
        );
      },
    );
  }

}