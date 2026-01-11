import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ─────────────────────────────────────────────────────────────
  // Constants
  // ─────────────────────────────────────────────────────────────
  static const _fadeDuration = Duration(milliseconds: 1500);
  static const _initialDelay = Duration(seconds: 2);

  // ─────────────────────────────────────────────────────────────
  // Animation
  // ─────────────────────────────────────────────────────────────
  late final AnimationController _controller;
  late final Animation<double> _fade;

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────
  bool _isInitializing = true;
  bool _showRetry = false;
  String _status = 'Initializing...';
  bool _animationInitialized = false;
  bool _hasNavigated = false;

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureAnimationForAccessibility();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Animation setup
  // ─────────────────────────────────────────────────────────────
  void _initAnimation() {
    _controller = AnimationController(vsync: this, duration: _fadeDuration);

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  void _configureAnimationForAccessibility() {
    if (_animationInitialized) return;

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }

    _animationInitialized = true;
  }

  // ─────────────────────────────────────────────────────────────
  // Initialization flow
  // ─────────────────────────────────────────────────────────────
  Future<void> _initializeApp() async {
    try {
      _setStatus('Initializing...');

      await Future.delayed(_initialDelay);

      _setStatus('Loading preferences...');
      await Future.delayed(const Duration(milliseconds: 500));

      _setStatus('Fetching community data...');
      await Future.delayed(const Duration(milliseconds: 500));

      final isAuthenticated = await _checkAuthenticationState();
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));

      await _navigateNext(isAuthenticated);
    } catch (_) {
      if (!mounted) return;
      _setErrorState();
    }
  }

  Future<void> _navigateNext(bool isAuthenticated) async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/user-profile-screen');
      return;
    }

    final hasSeenOnboarding = await _checkOnboardingStatus();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      hasSeenOnboarding ? '/login-screen' : '/onboarding-flow',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // State helpers
  // ─────────────────────────────────────────────────────────────
  void _setStatus(String message) {
    if (!mounted) return;
    setState(() {
      _status = message;
      _isInitializing = true;
      _showRetry = false;
    });
  }

  void _setErrorState() {
    setState(() {
      _isInitializing = false;
      _showRetry = true;
      _status = 'Connection error. Please try again.';
    });
  }

  void _retryInitialization() {
    HapticFeedback.lightImpact();
    _hasNavigated = false;
    _initializeApp();
  }

  // ─────────────────────────────────────────────────────────────
  // Simulated services (replace in prod)
  // ─────────────────────────────────────────────────────────────
  Future<bool> _checkAuthenticationState() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return false;
  }

  Future<bool> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              FadeTransition(
                opacity: _fade,
                child: Flexible(flex: 3, child: _Logo(theme: theme)),
              ),

              const Spacer(flex: 1),

              // App title
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'HOA Connect',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Tagline
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'Your Community, Connected',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onPrimary.withOpacity(0.9),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Loading indicator or retry button
              if (_isInitializing)
                _LoadingIndicator(color: colors.onPrimary)
              else if (_showRetry)
                _RetryButton(onPressed: _retryInitialization),

              const Spacer(flex: 1),

              // Status message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withOpacity(0.8),
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets (clean separation)
// ─────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  final ThemeData theme;
  const _Logo({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final heightBasedSize = constraints.maxHeight * 0.35;
        final widthBasedSize = constraints.maxWidth * 0.6;

        const absoluteMax = 120.0;
        const absoluteMin = 120.0;

        final size = [
          heightBasedSize,
          widthBasedSize,
          absoluteMax,
        ].reduce((a, b) => a < b ? a : b).clamp(absoluteMin, absoluteMax);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.onPrimary,
                borderRadius: BorderRadius.circular(size * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'home',
                  size: size * 0.55,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final Color color;
  const _LoadingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RetryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: CustomIconWidget(
        iconName: 'refresh',
        size: 20.w,
        color: colors.primary,
      ),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.onPrimary,
        foregroundColor: colors.primary,
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.w),
        ),
      ),
    );
  }
}
