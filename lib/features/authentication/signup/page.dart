import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './widgets/form.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // FORM INPUT CONTROLLERS
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _contactController   = TextEditingController();
  final _addressController   = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();

  bool _isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullAddress = _addressController.text.trim();

    try {
      // Step 1: Check if resident exists in Firestore
      final query = await FirebaseFirestore.instance
          .collection('master_residents')
          .where('firstName', isEqualTo: firstName)
          .where('lastName', isEqualTo: lastName)
          .where('fullAddress', isEqualTo: fullAddress)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorDialog('Registration Error', 'Resident does not exist in the system.');
        return;
      }

      // Resident exists
      final residentDoc = query.docs.first;
      final DocumentReference residentRef = residentDoc.reference;

      // Step 2: Register Firebase User
      final userCredential = await authService.value.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential?.user!.uid;

      // Step 3: Update Firestore resident with userId
      await residentRef.update({
        'userId': uid,
      });

      // Step 4: Show success toast
      Fluttertoast.showToast(
        msg: 'Account created successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Step 5: Redirect user
      Navigator.pushReplacementNamed(context, AppRoutes.residentDashboard);
    }
    on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);

      if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password must be at least 6 characters.';
      } else {
        errorMessage = e.message ?? 'Registration failed.';
      }

      _showErrorDialog('Registration Error', errorMessage);
    }
    catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog('Unexpected Error', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
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
            child: const Text('OK'),
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  SizedBox(height: 4.h),

                  // Logo
                  Center(
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 15.w,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Title
                  Text(
                    'Create an Account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 1.h),
                  Text(
                    'Fill out the form to join your community',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),

                  // SIGNUP FORM (updated widget)
                  SignUpFormWidget(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    contactController: _contactController,
                    addressController: _addressController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    formKey: _formKey,
                    onForgotPassword: () {}, // disable for signup
                  ),
                  SizedBox(height: 3.h),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
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
                            'Create Account',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                  ),

                  SizedBox(height: 3.h),

                  // Go back to login link
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.signIn),
                    child: Text(
                      "Already have an account? Sign In",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
