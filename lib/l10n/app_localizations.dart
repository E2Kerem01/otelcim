import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Application name
  ///
  /// In tr, this message translates to:
  /// **'Otelcim'**
  String get appName;

  /// Email input field label
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get emailLabel;

  /// Email input field hint
  ///
  /// In tr, this message translates to:
  /// **'ornek@eposta.com'**
  String get emailHint;

  /// Email validation error message
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta girin'**
  String get emailValidation;

  /// Password input field label
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get passwordLabel;

  /// Password validation error message
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordValidation;

  /// Login button text
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginButton;

  /// Register button text
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get registerButton;

  /// Register screen title
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get registerTitle;

  /// Prompt to register when no account exists
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt ol'**
  String get noAccountPrompt;

  /// Prompt to login when account exists
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get hasAccountPrompt;

  /// Welcome message on role selection screen
  ///
  /// In tr, this message translates to:
  /// **'Otelcim\'e Hoş Geldiniz!'**
  String get onboardingWelcome;

  /// Prompt to select user role
  ///
  /// In tr, this message translates to:
  /// **'Size en uygun deneyimi sunabilmemiz için lütfen rolünüzü seçin:'**
  String get onboardingRolePrompt;

  /// Job seeker role title
  ///
  /// In tr, this message translates to:
  /// **'İş Arıyorum'**
  String get roleJobSeeker;

  /// Job seeker role description
  ///
  /// In tr, this message translates to:
  /// **'Otel ve turizm sektöründe iş arıyorum. İlanları görmek ve başvurmak istiyorum.'**
  String get roleJobSeekerDescription;

  /// Employer role title
  ///
  /// In tr, this message translates to:
  /// **'Personel Arıyorum'**
  String get roleEmployer;

  /// Employer role description
  ///
  /// In tr, this message translates to:
  /// **'Otelim veya işletmem için çalışan arıyorum. İlan vermek istiyorum.'**
  String get roleEmployerDescription;

  /// Error message when no role is selected
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir rol seçin'**
  String get roleSelectionError;

  /// Continue button text
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueButton;

  /// Bottom navigation bar home tab label
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navHome;

  /// Bottom navigation bar categories tab label
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get navCategories;

  /// Bottom navigation bar create listing tab label
  ///
  /// In tr, this message translates to:
  /// **'İlan Ver'**
  String get navCreateListing;

  /// Bottom navigation bar messages tab label
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get navMessages;

  /// Bottom navigation bar profile tab label
  ///
  /// In tr, this message translates to:
  /// **'Hesabım'**
  String get navProfile;

  /// Profile screen title
  ///
  /// In tr, this message translates to:
  /// **'Hesabım'**
  String get profileTitle;

  /// Edit profile button text
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get editProfile;

  /// My listings button text
  ///
  /// In tr, this message translates to:
  /// **'İlanlarım'**
  String get myListings;

  /// Sign out button text
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get signOut;

  /// Reception category label
  ///
  /// In tr, this message translates to:
  /// **'Resepsiyon'**
  String get categoryReception;

  /// Housekeeping category label
  ///
  /// In tr, this message translates to:
  /// **'Kat Hizmetleri'**
  String get categoryHousekeeping;

  /// Kitchen/Chef category label
  ///
  /// In tr, this message translates to:
  /// **'Mutfak / Aşçı'**
  String get categoryKitchenChef;

  /// Service/Waiter category label
  ///
  /// In tr, this message translates to:
  /// **'Servis / Garson'**
  String get categoryServiceWaiter;

  /// Security category label
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get categorySecurity;

  /// Animation category label
  ///
  /// In tr, this message translates to:
  /// **'Animasyon'**
  String get categoryAnimation;

  /// Management category label
  ///
  /// In tr, this message translates to:
  /// **'Yönetim'**
  String get categoryManagement;

  /// Technical Service category label
  ///
  /// In tr, this message translates to:
  /// **'Teknik Servis'**
  String get categoryTechnicalService;

  /// Other category label
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get categoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
