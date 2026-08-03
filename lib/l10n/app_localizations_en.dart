// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Otelcim';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailValidation => 'Enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordValidation => 'Password must be at least 6 characters';

  @override
  String get loginButton => 'Sign In';

  @override
  String get registerButton => 'Register';

  @override
  String get registerTitle => 'Register';

  @override
  String get noAccountPrompt => 'Don\'t have an account? Register';

  @override
  String get hasAccountPrompt => 'Already have an account? Sign in';

  @override
  String get onboardingWelcome => 'Welcome to Otelcim!';

  @override
  String get onboardingRolePrompt =>
      'Please select your role to provide you with the best experience:';

  @override
  String get roleJobSeeker => 'Looking for a Job';

  @override
  String get roleJobSeekerDescription =>
      'I\'m looking for a job in the hotel and tourism industry. I want to view and apply to job listings.';

  @override
  String get roleEmployer => 'Looking for Staff';

  @override
  String get roleEmployerDescription =>
      'I\'m looking for employees for my hotel or business. I want to post job listings.';

  @override
  String get roleSelectionError => 'Please select a role';

  @override
  String get continueButton => 'Continue';

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navCreateListing => 'Post Listing';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'My Account';

  @override
  String get profileTitle => 'My Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myListings => 'My Listings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get categoryReception => 'Reception';

  @override
  String get categoryHousekeeping => 'Housekeeping';

  @override
  String get categoryKitchenChef => 'Kitchen / Chef';

  @override
  String get categoryServiceWaiter => 'Service / Waiter';

  @override
  String get categorySecurity => 'Security';

  @override
  String get categoryAnimation => 'Animation';

  @override
  String get categoryManagement => 'Management';

  @override
  String get categoryTechnicalService => 'Technical Service';

  @override
  String get categoryOther => 'Other';
}
