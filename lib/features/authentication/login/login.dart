import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hoa/app/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './widgets/biometric.dart';
import './widgets/form.dart';
// import './widgets/sign_up_prompt_widget.dart';

/// Login Screen provides secure authentication with mobile-optimized
/// input methods and biometric options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate Firebase authentication delay
    await Future.delayed(const Duration(seconds: 2));
    try{
      await authService.value.signIn(email: _emailController.text, password: _passwordController.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        } else {
          errorMessage = e.message ?? 'Incorrect user credential.';
        }
        _showErrorDialog(
          'Invalid Credentials',
          errorMessage,
        );
      }
    } catch (e){
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Firebase Error',
          e.toString(),
        );
      }
    }
    // Check credentials
    // if (_emailController.text.trim() == _mockEmail && _passwordController.text == _mockPassword) {
    //   // Success - trigger haptic feedback
    //   HapticFeedback.mediumImpact();

    //   if (mounted) {
    //     setState(() => _isLoading = false);

    //     // Show success message
    //     Fluttertoast.showToast(
    //       msg: 'Login successful!',
    //       toastLength: Toast.LENGTH_SHORT,
    //       gravity: ToastGravity.BOTTOM,
    //       backgroundColor: Theme.of(context).colorScheme.tertiary,
    //       textColor: Theme.of(context).colorScheme.onTertiary,
    //     );

    //     // Navigate to dashboard
    //     Navigator.pushReplacementNamed(context, AppRoutes.residentDashboard);
    //   }
    // } else {
    //   // Failed authentication
    //   if (mounted) {
    //     setState(() => _isLoading = false);

    //     // Show error message
    //     _showErrorDialog(
    //       'Invalid Credentials',
    //       'The email or password you entered is incorrect. Please try again.\n\nTest credentials:\nEmail: user@hoaconnect.com\nPassword: password123',
    //     );
    //   }
    // }
  }

  Future<void> _handleBiometricAuth() async {
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    // Simulate biometric authentication
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);

      // Success
      HapticFeedback.mediumImpact();

      Fluttertoast.showToast(
        msg: 'Biometric authentication successful!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        textColor: Theme.of(context).colorScheme.onTertiary,
      );

      Navigator.pushReplacementNamed(context, '/user-profile-screen');
    }
  }

  void _handleForgotPassword() {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'email',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: 'Password reset link sent to your email',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _handleSignUp() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/onboarding-flow');
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: Theme.of(context).colorScheme.error,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 4.h),

                    // Community Logo
                    Center(
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'home',
                            color: theme.colorScheme.primary,
                            size: 15.w,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Welcome text
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Sign in to access your community',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),

                    // Login form
                    LoginFormWidget(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      formKey: _formKey,
                      onForgotPassword: _handleForgotPassword,
                    ),
                    SizedBox(height: 3.h),

                    // Sign in button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 7.h),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 5.w,
                              height: 5.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                    ),
                    SizedBox(height: 3.h),

                    // Biometric authentication
                    BiometricAuthWidget(onBiometricAuth: _handleBiometricAuth),
                    SizedBox(height: 4.h),

                    // Sign up prompt
                    // SignUpPromptWidget(onSignUp: _handleSignUp),
                    // SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
