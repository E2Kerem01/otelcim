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
  String get incompletePositionsError =>
      'Lütfen tüm pozisyon bilgilerini eksiksiz doldurun.';

  @override
  String get batchCreateButton => 'Toplu İlan Ver';

  @override
  String get seasonalCalendarTitle => 'Seasonal Hiring Calendar';

  @override
  String get seasonalRemindersTitle => 'My Seasonal Reminders';

  @override
  String get seasonalRemindersDesc =>
      'Get notified about listings in your selected region & category before the season starts.';

  @override
  String get seasonLabel => 'Season';

  @override
  String get seasonSummer2025 => 'Summer 2025';

  @override
  String get seasonWinter202526 => 'Winter 2025-26';

  @override
  String get seasonYearRound => 'Year-Round';

  @override
  String get seasonAny => 'Any / All Seasons';

  @override
  String get addSeasonalAlert => 'Add Alert';

  @override
  String get createAlertSuccess => 'Seasonal reminder created successfully.';

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

  @override
  String get regionLabel => 'Tourism region';

  @override
  String get regionSelectHint => 'Select a region';

  @override
  String get regionRequired => 'Please select a region';

  @override
  String get regionsTitle => 'Regions';

  @override
  String get regionsLoadError => 'Regions could not be loaded.';

  @override
  String activeListingCount(int count) {
    return '$count active listings';
  }

  @override
  String get nearMe => 'Near Me';

  @override
  String get nearbyTitle => 'Nearby Listings';

  @override
  String get nearbyPermissionTitle => 'Location permission';

  @override
  String get nearbyPermissionExplanation =>
      'To show nearby jobs sorted by distance, we need your current location only when you use this feature.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get radiusLabel => 'Search radius';

  @override
  String get nearbyEmpty =>
      'No listings with location data were found within this radius.';

  @override
  String get nearbyLocationDenied =>
      'Location permission was denied. Near Me remains disabled.';

  @override
  String get nearbyLocationDeniedForever =>
      'Location permission is permanently disabled. You can enable it in device settings.';

  @override
  String get nearbyServicesDisabled =>
      'Location services are disabled on your device.';

  @override
  String get nearbyLocationUnavailable =>
      'Your location is currently unavailable. Please try again.';

  @override
  String get retryButton => 'Try again';

  @override
  String distanceKm(String distance) {
    return '$distance km away';
  }

  @override
  String get addListingLocation =>
      'Add my current location to this listing (optional)';

  @override
  String get listingLocationAdded => 'Location will be added to the listing.';

  @override
  String get listingLocationOptionalHint =>
      'Coordinates are used only for nearby listing searches.';

  @override
  String get seasonNone => 'No season selected';

  @override
  String get contractStartDateLabel => 'Contract start';

  @override
  String get contractEndDateLabel => 'Contract end';

  @override
  String get selectDate => 'Select date';

  @override
  String get contractDatesRequired =>
      'Select contract start and end dates for seasonal listings.';

  @override
  String get contractDateRangeInvalid =>
      'Contract end date cannot be before the start date.';

  @override
  String get regionMapTitle => 'Region map';

  @override
  String get regionMapAttribution => 'OpenStreetMap contributors';

  @override
  String get listingSafetyTipsTitle => 'Safety tips';

  @override
  String get listingSafetyTipsBody =>
      'Never pay money before meeting the employer and visiting the workplace. Do not share identity, credit card, banking, or other sensitive personal information. Report anything suspicious.';

  @override
  String get listingSafetyReportAction => 'Report listing';

  @override
  String get availableImmediatelyLabel =>
      'Currently Available / Immediate Start';

  @override
  String get availableImmediatelyHint =>
      'Employers will see a green badge on the chat screen.';

  @override
  String get availableImmediatelyBadge => 'Available Immediately';

  @override
  String get notAvailableBadge => 'Not Available';

  @override
  String get experienceLevelLabel => 'Experience';

  @override
  String get educationLevelLabel => 'Education Level';

  @override
  String get optionalNotSpecified => 'Not specified (optional)';

  @override
  String get experienceNone => 'No Experience Required';

  @override
  String get experienceUnderOneYear => 'Less Than 1 Year';

  @override
  String get experienceOneToThreeYears => '1-3 Years';

  @override
  String get experienceThreePlusYears => '3+ Years';

  @override
  String get educationNone => 'No Education Requirement';

  @override
  String get educationPrimary => 'At Least Primary School';

  @override
  String get educationHighSchool => 'At Least High School';

  @override
  String get educationUniversity => 'At Least University';
}
