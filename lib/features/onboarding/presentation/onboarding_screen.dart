import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/onboarding_slide_data.dart';
import 'widgets/onboarding_slide.dart';

/// Onboarding screen shown to first-time users
///
/// Displays a series of slides introducing key app features:
/// - PageView for swipeable slides
/// - Page indicators (dots) showing current position
/// - Skip button to bypass onboarding
/// - Next/Get Started button for navigation
///
/// After completion, marks onboarding as completed and navigates to main screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Controller for the PageView
  final PageController _pageController = PageController();

  /// Current page index
  int _currentPage = 0;

  /// Total number of slides
  static const int _totalSlides = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle page changes
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  /// Navigate to the next slide or complete onboarding
  void _nextPage() {
    if (_currentPage < _totalSlides - 1) {
      unawaited(_pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ));
    } else {
      _completeOnboarding();
    }
  }

  /// Skip onboarding entirely and go straight to the app
  void _skipOnboarding() {
    if (mounted) context.go('/');
  }

  /// Finished the slides, move on to role selection
  void _completeOnboarding() {
    if (mounted) context.go('/onboarding/role');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Geç',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView with slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: OnboardingSlideData.slides.length,
                itemBuilder: (context, index) {
                  return OnboardingSlide(
                    slideData: OnboardingSlideData.slides[index],
                  );
                },
              ),
            ),

            // Page indicators (dots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalSlides,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    _currentPage == _totalSlides - 1
                        ? 'Başlayalım'
                        : 'Sonraki',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
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

  /// Build a single page indicator dot
  Widget _buildPageIndicator(int index) {
    final theme = Theme.of(context);
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: isActive ? 24.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
