import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding step enumeration
///
/// Defines the sequential steps in the onboarding flow:
/// 1. Welcome slides (3-4 feature introduction slides)
/// 2. Role selection (job seeker or employer)
/// 3. Profile setup (name, photo)
enum OnboardingStep {
  /// Feature introduction slides (swipeable)
  welcome,

  /// Role selection step
  roleSelection,

  /// Profile setup step
  profileSetup,

  /// Onboarding completed
  completed;

  /// Get the next step in the flow
  OnboardingStep? get next {
    final index = OnboardingStep.values.indexOf(this);
    if (index < OnboardingStep.values.length - 1) {
      return OnboardingStep.values[index + 1];
    }
    return null;
  }

  /// Get the previous step in the flow
  OnboardingStep? get previous {
    final index = OnboardingStep.values.indexOf(this);
    if (index > 0) {
      return OnboardingStep.values[index - 1];
    }
    return null;
  }
}

/// Onboarding state model
///
/// Tracks the current state of the onboarding flow including:
/// - Current step
/// - Current slide index (for welcome slides)
/// - Whether user skipped onboarding
/// - Selected role
class OnboardingState {
  /// Current step in the onboarding flow
  final OnboardingStep currentStep;

  /// Current slide index (used in welcome step with 3-4 slides)
  final int currentSlideIndex;

  /// Total number of welcome slides
  final int totalSlides;

  /// Whether the user skipped onboarding
  final bool skipped;

  /// Selected role during onboarding (if any)
  final String? selectedRole;

  /// Creates an OnboardingState instance
  const OnboardingState({
    this.currentStep = OnboardingStep.welcome,
    this.currentSlideIndex = 0,
    this.totalSlides = 3,
    this.skipped = false,
    this.selectedRole,
  });

  /// Creates a copy with specified fields replaced
  OnboardingState copyWith({
    OnboardingStep? currentStep,
    int? currentSlideIndex,
    int? totalSlides,
    bool? skipped,
    String? selectedRole,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      totalSlides: totalSlides ?? this.totalSlides,
      skipped: skipped ?? this.skipped,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }

  /// Returns true if on the last welcome slide
  bool get isLastSlide => currentSlideIndex >= totalSlides - 1;

  /// Returns true if on the first welcome slide
  bool get isFirstSlide => currentSlideIndex == 0;

  /// Returns true if the onboarding flow is completed
  bool get isCompleted => currentStep == OnboardingStep.completed;

  /// Returns true if currently on welcome slides
  bool get isOnWelcomeSlides => currentStep == OnboardingStep.welcome;

  /// Returns true if currently on role selection
  bool get isOnRoleSelection => currentStep == OnboardingStep.roleSelection;

  /// Returns true if currently on profile setup
  bool get isOnProfileSetup => currentStep == OnboardingStep.profileSetup;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingState &&
        other.currentStep == currentStep &&
        other.currentSlideIndex == currentSlideIndex &&
        other.totalSlides == totalSlides &&
        other.skipped == skipped &&
        other.selectedRole == selectedRole;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentStep,
      currentSlideIndex,
      totalSlides,
      skipped,
      selectedRole,
    );
  }

  @override
  String toString() {
    return 'OnboardingState(currentStep: $currentStep, '
        'currentSlideIndex: $currentSlideIndex, totalSlides: $totalSlides, '
        'skipped: $skipped, selectedRole: $selectedRole)';
  }
}

/// StateNotifier for managing onboarding flow state
///
/// Provides methods to navigate through the onboarding flow:
/// - Navigate between welcome slides
/// - Move to next/previous steps
/// - Skip onboarding
/// - Select role
/// - Complete onboarding
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  /// Move to the next welcome slide
  ///
  /// If on the last slide, moves to role selection step.
  void nextSlide() {
    if (!state.isOnWelcomeSlides) return;

    if (state.isLastSlide) {
      // Move to role selection step
      state = state.copyWith(
        currentStep: OnboardingStep.roleSelection,
        currentSlideIndex: 0,
      );
    } else {
      // Move to next slide
      state = state.copyWith(
        currentSlideIndex: state.currentSlideIndex + 1,
      );
    }
  }

  /// Move to the previous welcome slide
  void previousSlide() {
    if (!state.isOnWelcomeSlides || state.isFirstSlide) return;

    state = state.copyWith(
      currentSlideIndex: state.currentSlideIndex - 1,
    );
  }

  /// Jump to a specific slide index
  ///
  /// [index] must be within valid range (0 to totalSlides - 1)
  void goToSlide(int index) {
    if (!state.isOnWelcomeSlides) return;
    if (index < 0 || index >= state.totalSlides) return;

    state = state.copyWith(currentSlideIndex: index);
  }

  /// Move to the next onboarding step
  void nextStep() {
    final nextStep = state.currentStep.next;
    if (nextStep != null) {
      state = state.copyWith(
        currentStep: nextStep,
        currentSlideIndex: 0,
      );
    }
  }

  /// Move to the previous onboarding step
  void previousStep() {
    final previousStep = state.currentStep.previous;
    if (previousStep != null) {
      state = state.copyWith(
        currentStep: previousStep,
        currentSlideIndex: 0,
      );
    }
  }

  /// Skip the onboarding flow
  ///
  /// Marks onboarding as skipped and moves to completed state.
  /// User can re-access onboarding from settings later.
  void skipOnboarding() {
    state = state.copyWith(
      currentStep: OnboardingStep.completed,
      skipped: true,
    );
  }

  /// Set the user's selected role
  ///
  /// [role] - Either 'job_seeker' or 'employer'
  /// Automatically moves to the next step after role selection.
  void selectRole(String role) {
    if (role != 'job_seeker' && role != 'employer') {
      throw ArgumentError(
        'Geçersiz rol. "job_seeker" veya "employer" olmalı',
      );
    }

    state = state.copyWith(selectedRole: role);
    nextStep();
  }

  /// Complete the onboarding flow
  ///
  /// Sets the current step to completed.
  /// Should be called after profile setup is finished.
  void completeOnboarding() {
    state = state.copyWith(
      currentStep: OnboardingStep.completed,
      skipped: false,
    );
  }

  /// Reset the onboarding flow
  ///
  /// Returns to the initial state.
  /// Used when user wants to re-access onboarding from settings.
  void resetOnboarding() {
    state = const OnboardingState();
  }

  /// Set the total number of welcome slides
  ///
  /// [total] - Number of slides (typically 3-4)
  void setTotalSlides(int total) {
    if (total < 1) return;
    state = state.copyWith(totalSlides: total);
  }
}

/// Provider for onboarding flow state
///
/// Use this to access and manage the onboarding flow state throughout the app.
///
/// Example usage:
/// ```dart
/// // Read current state
/// final onboardingState = ref.watch(onboardingProvider);
///
/// // Navigate to next slide
/// ref.read(onboardingProvider.notifier).nextSlide();
///
/// // Select role
/// ref.read(onboardingProvider.notifier).selectRole('job_seeker');
///
/// // Skip onboarding
/// ref.read(onboardingProvider.notifier).skipOnboarding();
/// ```
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
