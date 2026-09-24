import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/onboarding/presentation/onboarding_screen.dart';
import 'package:otelcim/features/onboarding/presentation/role_selection_screen.dart';
import 'package:otelcim/shared/providers/onboarding_provider.dart';

void main() {
  group('OnboardingNotifier & State Unit Tests', () {
    late OnboardingNotifier notifier;

    setUp(() {
      notifier = OnboardingNotifier();
    });

    test('initial state is at welcome step, slide 0 of 3', () {
      expect(notifier.state.currentStep, OnboardingStep.welcome);
      expect(notifier.state.currentSlideIndex, 0);
      expect(notifier.state.totalSlides, 3);
      expect(notifier.state.skipped, isFalse);
      expect(notifier.state.isFirstSlide, isTrue);
      expect(notifier.state.isLastSlide, isFalse);
      expect(notifier.state.isOnWelcomeSlides, isTrue);
    });

    test('nextSlide advances through welcome slides and then moves to roleSelection', () {
      notifier.nextSlide();
      expect(notifier.state.currentSlideIndex, 1);
      expect(notifier.state.isFirstSlide, isFalse);

      notifier.nextSlide();
      expect(notifier.state.currentSlideIndex, 2);
      expect(notifier.state.isLastSlide, isTrue);

      // On last slide, nextSlide moves to roleSelection step
      notifier.nextSlide();
      expect(notifier.state.currentStep, OnboardingStep.roleSelection);
      expect(notifier.state.currentSlideIndex, 0);
      expect(notifier.state.isOnRoleSelection, isTrue);
    });

    test('previousSlide decrements slide index and respects lower bound', () {
      // On first slide, previousSlide is a no-op
      notifier.previousSlide();
      expect(notifier.state.currentSlideIndex, 0);

      notifier.nextSlide();
      expect(notifier.state.currentSlideIndex, 1);

      notifier.previousSlide();
      expect(notifier.state.currentSlideIndex, 0);
    });

    test('goToSlide sets index within range and ignores out-of-range indices', () {
      notifier.goToSlide(2);
      expect(notifier.state.currentSlideIndex, 2);

      // Out of bounds: negative
      notifier.goToSlide(-1);
      expect(notifier.state.currentSlideIndex, 2);

      // Out of bounds: >= totalSlides
      notifier.goToSlide(5);
      expect(notifier.state.currentSlideIndex, 2);
    });

    test('nextStep and previousStep navigate sequentially through all steps', () {
      expect(notifier.state.currentStep, OnboardingStep.welcome);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.roleSelection);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.profileSetup);

      notifier.nextStep();
      expect(notifier.state.currentStep, OnboardingStep.completed);
      expect(notifier.state.isCompleted, isTrue);

      notifier.previousStep();
      expect(notifier.state.currentStep, OnboardingStep.profileSetup);
    });

    test('skipOnboarding marks skipped true and completed', () {
      notifier.skipOnboarding();
      expect(notifier.state.skipped, isTrue);
      expect(notifier.state.currentStep, OnboardingStep.completed);
    });

    test('selectRole accepts job_seeker and employer and advances step', () {
      notifier.nextStep(); // Advance from welcome to roleSelection step
      notifier.selectRole('job_seeker');
      expect(notifier.state.selectedRole, 'job_seeker');
      expect(notifier.state.currentStep, OnboardingStep.profileSetup);

      notifier.resetOnboarding();
      notifier.nextStep(); // Advance from welcome to roleSelection step
      notifier.selectRole('employer');
      expect(notifier.state.selectedRole, 'employer');
      expect(notifier.state.currentStep, OnboardingStep.profileSetup);
    });

    test('selectRole throws ArgumentError for unknown role', () {
      expect(
        () => notifier.selectRole('super_admin'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'selectRole accepts jobseeker value used by RegisterScreen and UserProfile',
      () {
        // RegisterScreen sets userType to 'jobseeker' (without underscore),
        // but OnboardingNotifier.selectRole throws if passed 'jobseeker' instead of 'job_seeker'.
        expect(
          () => notifier.selectRole('jobseeker'),
          returnsNormally,
        );
      },
      skip: 'BUG-t6-08: OnboardingNotifier.selectRole rejects the jobseeker role string used by RegisterScreen and UserProfile',
    );

    test('completeOnboarding and resetOnboarding lifecycle', () {
      notifier.completeOnboarding();
      expect(notifier.state.isCompleted, isTrue);
      expect(notifier.state.skipped, isFalse);

      notifier.resetOnboarding();
      expect(notifier.state.currentStep, OnboardingStep.welcome);
      expect(notifier.state.currentSlideIndex, 0);
    });

    test('setTotalSlides updates slide count and ignores invalid values', () {
      notifier.setTotalSlides(4);
      expect(notifier.state.totalSlides, 4);

      notifier.setTotalSlides(0);
      expect(notifier.state.totalSlides, 4);
    });

    test('OnboardingState value equality and hashCode', () {
      const state1 = OnboardingState(
        currentStep: OnboardingStep.welcome,
        currentSlideIndex: 1,
        totalSlides: 3,
        skipped: false,
        selectedRole: 'job_seeker',
      );
      const state2 = OnboardingState(
        currentStep: OnboardingStep.welcome,
        currentSlideIndex: 1,
        totalSlides: 3,
        skipped: false,
        selectedRole: 'job_seeker',
      );
      const state3 = OnboardingState(
        currentStep: OnboardingStep.roleSelection,
      );

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
      expect(state1, isNot(equals(state3)));
    });
  });

  group('Onboarding Screens Widget Tests', () {
    testWidgets('OnboardingScreen renders slides, page indicator, and skip button', (tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Geç'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sonraki'), findsOneWidget);
    });

    testWidgets('RoleSelectionScreen shows role options and validates selection', (tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RoleSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Otelcim'e Hoş Geldiniz!"), findsOneWidget);
      expect(find.text('İş Arıyorum'), findsOneWidget);
      expect(find.text('Personel Arıyorum'), findsOneWidget);

      // Tapping continue without selecting a role displays error
      await tester.tap(find.widgetWithText(FilledButton, 'Devam Et'));
      await tester.pumpAndSettle();

      expect(find.text('Lütfen bir rol seçin'), findsOneWidget);

      // Select role
      await tester.tap(find.text('İş Arıyorum'));
      await tester.pumpAndSettle();

      // Error message should disappear
      expect(find.text('Lütfen bir rol seçin'), findsNothing);
    });
  });
}
