import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hoa/routes/app_routes.dart';
import 'package:sizer/sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'widgets/page.dart';

/// Onboarding Flow Screen
///
/// Multi-step guided experience introducing HOA community features:
/// - Community access and secure communications
/// - Service requests and notifications
/// - Firebase authentication benefits
/// - Swipe navigation with haptic feedback
/// - Skip functionality for experienced users
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding content data
  final List<Map<String, String>> _onboardingPages = [
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_164209056-1764850962493.png',
      'semanticLabel':
          'Modern residential community with well-maintained homes, green lawns, and tree-lined streets under blue sky',
      'title': 'Welcome to Your Community',
      'description':
          'Access all your HOA community features in one secure mobile app. Stay connected with neighbors and manage your home effortlessly.',
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1611746869696-d09bce200020',
      'semanticLabel':
          'Smartphone displaying messaging app with notification icons and chat bubbles on wooden desk',
      'title': 'Secure Communications',
      'description':
          'Receive instant notifications about community updates, events, and important announcements. Stay informed in real-time.',
    },
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1d0e75cac-1764741058510.png',
      'semanticLabel':
          'Professional maintenance worker in uniform using tablet to manage service requests in residential area',
      'title': 'Easy Service Requests',
      'description':
          'Submit maintenance requests, track their progress, and communicate directly with property management—all from your phone.',
    },
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1398298d5-1766476603039.png',
      'semanticLabel':
          'Digital security shield icon with lock symbol on blue gradient background representing data protection',
      'title': 'Secures & Private',
      'description':
          'Your data is protected with Firebase authentication. Enjoy peace of mind with enterprise-grade security for your community.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    HapticFeedback.selectionClick();
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _onboardingPages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    Navigator.pushReplacementNamed(context, AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button area
            SizedBox(
              height: 8.h,
              child: _currentPage < _onboardingPages.length - 1
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4.w, top: 2.h),
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _skipToEnd();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.h,
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // PageView with onboarding screens
            Expanded(
              flex: 7,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  final page = _onboardingPages[index];
                  return OnboardingPageWidget(
                    imageUrl: page['imageUrl']!,
                    semanticLabel: page['semanticLabel']!,
                    title: page['title']!,
                    description: page['description']!,
                  );
                },
              ),
            ),

            // Page indicators
            SizedBox(
              height: 8.h,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _onboardingPages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: theme.colorScheme.primary,
                    dotColor: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    dotHeight: 1.h,
                    dotWidth: 2.w,
                    expansionFactor: 4,
                    spacing: 2.w,
                  ),
                ),
              ),
            ),

            // Action button
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 4.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _currentPage == _onboardingPages.length - 1
                        ? _completeOnboarding()
                        : _nextPage();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2.0,
                  ),
                  child: Text(
                    _currentPage == _onboardingPages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
