import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('ru'),
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
  /// **'Şifre en az 8 karakter ve en az 1 rakam içermelidir'**
  String get passwordValidation;

  /// No description provided for @referralCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Referans Kodu (opsiyonel)'**
  String get referralCodeLabel;

  /// No description provided for @referralCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşının kodu'**
  String get referralCodeHint;

  /// No description provided for @inviteFriendsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşını Davet Et'**
  String get inviteFriendsTitle;

  /// No description provided for @inviteFriendsMenuLabel.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşını Davet Et'**
  String get inviteFriendsMenuLabel;

  /// No description provided for @inviteFriendsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kodunu arkadaşınla paylaş, o kaydolup ilk ilanını yayınladığında veya ilk sohbetini başlattığında sana ücretsiz bir boost hakkı kazandırsın.'**
  String get inviteFriendsDescription;

  /// No description provided for @yourReferralCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Referans Kodun'**
  String get yourReferralCodeLabel;

  /// No description provided for @copyCodeAction.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Kopyala'**
  String get copyCodeAction;

  /// No description provided for @codeCopiedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kod kopyalandı'**
  String get codeCopiedMessage;

  /// No description provided for @shareCodeAction.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get shareCodeAction;

  /// No description provided for @shareReferralMessage.
  ///
  /// In tr, this message translates to:
  /// **'Otelcim\'de otel/turizm işleri bul veya ilan ver! {code} kodumla kayıt ol, ikimiz de kazanalım.'**
  String shareReferralMessage(String code);

  /// No description provided for @referralCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Davet Ettiğin Kişi Sayısı'**
  String get referralCountLabel;

  /// No description provided for @freeBoostCreditsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz Boost Hakkın'**
  String get freeBoostCreditsLabel;

  /// No description provided for @freeBoostBannerText.
  ///
  /// In tr, this message translates to:
  /// **'{count} ücretsiz boost hakkınız var'**
  String freeBoostBannerText(int count);

  /// No description provided for @useFreeBoostAction.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz Kullan'**
  String get useFreeBoostAction;

  /// No description provided for @freeBoostRedeemedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz boost uygulandı!'**
  String get freeBoostRedeemedMessage;

  /// No description provided for @freeBoostRedeemFailedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz boost uygulanamadı'**
  String get freeBoostRedeemFailedMessage;

  /// No description provided for @loginWithEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta ile Giriş'**
  String get loginWithEmail;

  /// No description provided for @loginWithPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ile Giriş'**
  String get loginWithPhone;

  /// No description provided for @phoneLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In tr, this message translates to:
  /// **'5XX XXX XX XX'**
  String get phoneHint;

  /// No description provided for @phoneValidation.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir telefon numarası girin (ör: 5551234567)'**
  String get phoneValidation;

  /// No description provided for @sendSmsCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod Gönder'**
  String get sendSmsCode;

  /// No description provided for @smsCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'SMS Doğrulama Kodu'**
  String get smsCodeLabel;

  /// No description provided for @smsCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'6 haneli kod'**
  String get smsCodeHint;

  /// No description provided for @smsCodeValidation.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen 6 haneli doğrulama kodunu girin'**
  String get smsCodeValidation;

  /// No description provided for @verifySmsCode.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula ve Giriş Yap'**
  String get verifySmsCode;

  /// No description provided for @rememberMe.
  ///
  /// In tr, this message translates to:
  /// **'Beni Hatırla'**
  String get rememberMe;

  /// No description provided for @tooManyAttempts.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla başarısız deneme. Lütfen {seconds} saniye bekleyin.'**
  String tooManyAttempts(int seconds);

  /// No description provided for @brandTitle.
  ///
  /// In tr, this message translates to:
  /// **'Türkiye\'nin Otel & Turizm İş Platformu'**
  String get brandTitle;

  /// No description provided for @brandDescription.
  ///
  /// In tr, this message translates to:
  /// **'Otel ve turizm sektöründe hayalinizdeki işi veya personeli hızlıca bulun.'**
  String get brandDescription;

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

  /// Error when positions not filled
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tüm pozisyon bilgilerini eksiksiz doldurun.'**
  String get incompletePositionsError;

  /// Batch create button text
  ///
  /// In tr, this message translates to:
  /// **'Toplu İlan Ver'**
  String get batchCreateButton;

  /// Seasonal calendar title
  ///
  /// In tr, this message translates to:
  /// **'Sezonluk İşe Alım Takvimi'**
  String get seasonalCalendarTitle;

  /// Seasonal reminders title
  ///
  /// In tr, this message translates to:
  /// **'Sezonluk Hatırlatıcılarım'**
  String get seasonalRemindersTitle;

  /// Seasonal reminders description
  ///
  /// In tr, this message translates to:
  /// **'Sezon başlamadan önce belirlediğiniz şehir ve kategorideki ilanlardan haberdar olun.'**
  String get seasonalRemindersDesc;

  /// Season label
  ///
  /// In tr, this message translates to:
  /// **'Sezon'**
  String get seasonLabel;

  /// Summer 2025 season
  ///
  /// In tr, this message translates to:
  /// **'Yaz 2025'**
  String get seasonSummer2025;

  /// Winter 2025-26 season
  ///
  /// In tr, this message translates to:
  /// **'Kış 2025-26'**
  String get seasonWinter202526;

  /// Year round season
  ///
  /// In tr, this message translates to:
  /// **'Tüm Yıl'**
  String get seasonYearRound;

  /// Any season
  ///
  /// In tr, this message translates to:
  /// **'Farketmez / Tüm Sezonlar'**
  String get seasonAny;

  /// Add seasonal alert button text
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı Ekle'**
  String get addSeasonalAlert;

  /// Success message for alert creation
  ///
  /// In tr, this message translates to:
  /// **'Sezonluk hatırlatıcı başarıyla oluşturuldu.'**
  String get createAlertSuccess;

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

  /// No description provided for @desktopNavFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get desktopNavFavorites;

  /// No description provided for @desktopNavProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get desktopNavProfile;

  /// No description provided for @desktopNavSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get desktopNavSettings;

  /// No description provided for @desktopNavLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get desktopNavLanguage;

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

  /// No description provided for @regionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Turizm bölgesi'**
  String get regionLabel;

  /// No description provided for @regionSelectHint.
  ///
  /// In tr, this message translates to:
  /// **'Bölge seçin'**
  String get regionSelectHint;

  /// No description provided for @regionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bölge seçmeniz gerekiyor'**
  String get regionRequired;

  /// No description provided for @regionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölgeler'**
  String get regionsTitle;

  /// No description provided for @regionsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Bölgeler yüklenemedi.'**
  String get regionsLoadError;

  /// No description provided for @activeListingCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} aktif ilan'**
  String activeListingCount(int count);

  /// No description provided for @nearMe.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımda'**
  String get nearMe;

  /// No description provided for @nearbyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki İlanlar'**
  String get nearbyTitle;

  /// No description provided for @nearbyPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni'**
  String get nearbyPermissionTitle;

  /// No description provided for @nearbyPermissionExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Yakınınızdaki iş ilanlarını mesafeye göre göstermek için yalnızca siz bu özelliği kullandığınızda anlık konumunuza erişmemiz gerekiyor.'**
  String get nearbyPermissionExplanation;

  /// No description provided for @cancelButton.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancelButton;

  /// No description provided for @radiusLabel.
  ///
  /// In tr, this message translates to:
  /// **'Arama yarıçapı'**
  String get radiusLabel;

  /// No description provided for @nearbyEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen yarıçapta konum bilgili ilan bulunamadı.'**
  String get nearbyEmpty;

  /// No description provided for @nearbyLocationDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Yakınımda özelliği kapalı kaldı.'**
  String get nearbyLocationDenied;

  /// No description provided for @nearbyLocationDeniedForever.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı olarak kapalı. İzni cihaz ayarlarından açabilirsiniz.'**
  String get nearbyLocationDeniedForever;

  /// No description provided for @nearbyServicesDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Cihazınızın konum hizmetleri kapalı.'**
  String get nearbyServicesDisabled;

  /// No description provided for @nearbyLocationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konum şu anda alınamıyor. Lütfen tekrar deneyin.'**
  String get nearbyLocationUnavailable;

  /// No description provided for @retryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retryButton;

  /// No description provided for @distanceKm.
  ///
  /// In tr, this message translates to:
  /// **'{distance} km uzakta'**
  String distanceKm(String distance);

  /// No description provided for @addListingLocation.
  ///
  /// In tr, this message translates to:
  /// **'Anlık konumumu ilana ekle (isteğe bağlı)'**
  String get addListingLocation;

  /// No description provided for @listingLocationAdded.
  ///
  /// In tr, this message translates to:
  /// **'Konum ilana eklenecek.'**
  String get listingLocationAdded;

  /// No description provided for @listingLocationOptionalHint.
  ///
  /// In tr, this message translates to:
  /// **'Koordinatlar yalnızca yakın ilan aramalarında kullanılır.'**
  String get listingLocationOptionalHint;

  /// No description provided for @seasonNone.
  ///
  /// In tr, this message translates to:
  /// **'Sezon seçilmedi'**
  String get seasonNone;

  /// No description provided for @contractStartDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme başlangıcı'**
  String get contractStartDateLabel;

  /// No description provided for @contractEndDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme bitişi'**
  String get contractEndDateLabel;

  /// No description provided for @selectDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seçin'**
  String get selectDate;

  /// No description provided for @contractDatesRequired.
  ///
  /// In tr, this message translates to:
  /// **'Sezonluk ilanlar için başlangıç ve bitiş tarihlerini seçin.'**
  String get contractDatesRequired;

  /// No description provided for @contractDateRangeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşme bitiş tarihi başlangıç tarihinden önce olamaz.'**
  String get contractDateRangeInvalid;

  /// No description provided for @regionMapTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölge haritası'**
  String get regionMapTitle;

  /// No description provided for @regionMapAttribution.
  ///
  /// In tr, this message translates to:
  /// **'OpenStreetMap katkıda bulunanları'**
  String get regionMapAttribution;

  /// No description provided for @listingSafetyTipsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik İpuçları'**
  String get listingSafetyTipsTitle;

  /// No description provided for @listingSafetyTipsBody.
  ///
  /// In tr, this message translates to:
  /// **'İşverenle görüşmeden ve iş yerini ziyaret etmeden ödeme yapmayın. Kimlik, kredi kartı, banka veya diğer hassas kişisel bilgilerinizi paylaşmayın. Şüpheli durumları bize bildirin.'**
  String get listingSafetyTipsBody;

  /// No description provided for @listingSafetyReportAction.
  ///
  /// In tr, this message translates to:
  /// **'İlanı Şikâyet Et'**
  String get listingSafetyReportAction;

  /// No description provided for @availableImmediatelyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şu An Boşta / Hemen Başlayabilir'**
  String get availableImmediatelyLabel;

  /// No description provided for @availableImmediatelyHint.
  ///
  /// In tr, this message translates to:
  /// **'İşverenlerin sohbet ekranında yeşil rozet ile görünürsünüz.'**
  String get availableImmediatelyHint;

  /// No description provided for @availableImmediatelyBadge.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Başlayabilir'**
  String get availableImmediatelyBadge;

  /// No description provided for @notAvailableBadge.
  ///
  /// In tr, this message translates to:
  /// **'Müsait Değil'**
  String get notAvailableBadge;

  /// No description provided for @experienceLevelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Deneyim'**
  String get experienceLevelLabel;

  /// No description provided for @educationLevelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim Durumu'**
  String get educationLevelLabel;

  /// No description provided for @optionalNotSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmedi (isteğe bağlı)'**
  String get optionalNotSpecified;

  /// No description provided for @experienceNone.
  ///
  /// In tr, this message translates to:
  /// **'Deneyim Aranmıyor'**
  String get experienceNone;

  /// No description provided for @experienceUnderOneYear.
  ///
  /// In tr, this message translates to:
  /// **'1 Yıldan Az'**
  String get experienceUnderOneYear;

  /// No description provided for @experienceOneToThreeYears.
  ///
  /// In tr, this message translates to:
  /// **'1-3 Yıl'**
  String get experienceOneToThreeYears;

  /// No description provided for @experienceThreePlusYears.
  ///
  /// In tr, this message translates to:
  /// **'3+ Yıl'**
  String get experienceThreePlusYears;

  /// No description provided for @educationNone.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim Şartı Yok'**
  String get educationNone;

  /// No description provided for @educationPrimary.
  ///
  /// In tr, this message translates to:
  /// **'En Az İlköğretim'**
  String get educationPrimary;

  /// No description provided for @educationHighSchool.
  ///
  /// In tr, this message translates to:
  /// **'En Az Lise'**
  String get educationHighSchool;

  /// No description provided for @educationUniversity.
  ///
  /// In tr, this message translates to:
  /// **'En Az Üniversite'**
  String get educationUniversity;

  /// No description provided for @proposeInterview.
  ///
  /// In tr, this message translates to:
  /// **'Mülakat Saati Öner'**
  String get proposeInterview;

  /// No description provided for @interviewProposalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mülakat Zamanı Önerisi'**
  String get interviewProposalTitle;

  /// No description provided for @interviewConfirmedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mülakat Onaylandı'**
  String get interviewConfirmedTitle;

  /// No description provided for @waitingCandidateSelection.
  ///
  /// In tr, this message translates to:
  /// **'Adayın mülakat saati seçimi bekleniyor...'**
  String get waitingCandidateSelection;

  /// No description provided for @confirmSlotPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Bu mülakat saatini onaylıyor musunuz?'**
  String get confirmSlotPrompt;

  /// No description provided for @selectSlot.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get selectSlot;

  /// No description provided for @interviewSlotsProposedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Mülakat saatleri başarıyla önerildi.'**
  String get interviewSlotsProposedSuccess;

  /// No description provided for @introVideoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tanıtım Videosu'**
  String get introVideoTitle;

  /// No description provided for @introVideoLabel.
  ///
  /// In tr, this message translates to:
  /// **'15-30 Saniyelik Tanıtım Videosu'**
  String get introVideoLabel;

  /// No description provided for @introVideoHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendinizi işverenlere tanıtan kısa bir video yükleyin.'**
  String get introVideoHint;

  /// No description provided for @uploadVideoAction.
  ///
  /// In tr, this message translates to:
  /// **'Video Yükle'**
  String get uploadVideoAction;

  /// No description provided for @changeVideoAction.
  ///
  /// In tr, this message translates to:
  /// **'Videoyu Değiştir'**
  String get changeVideoAction;

  /// No description provided for @removeVideoAction.
  ///
  /// In tr, this message translates to:
  /// **'Videoyu Kaldır'**
  String get removeVideoAction;

  /// No description provided for @watchIntroVideo.
  ///
  /// In tr, this message translates to:
  /// **'Tanıtım Videosunu İzle'**
  String get watchIntroVideo;

  /// No description provided for @videoDurationWarning.
  ///
  /// In tr, this message translates to:
  /// **'Video en fazla 30 saniye olmalıdır.'**
  String get videoDurationWarning;

  /// No description provided for @videoUploadSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Tanıtım videosu başarıyla yüklendi!'**
  String get videoUploadSuccess;

  /// No description provided for @videoRemoveSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Tanıtım videosu kaldırıldı.'**
  String get videoRemoveSuccess;

  /// No description provided for @sendWhatsAppAction.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp ile Mesaj Gönder'**
  String get sendWhatsAppAction;

  /// No description provided for @certificateTypeCankurtaran.
  ///
  /// In tr, this message translates to:
  /// **'Cankurtaran Sertifikası'**
  String get certificateTypeCankurtaran;

  /// No description provided for @certificateTypeEhliyet.
  ///
  /// In tr, this message translates to:
  /// **'Sürücü Belgesi (Ehliyet)'**
  String get certificateTypeEhliyet;

  /// No description provided for @certificateTypeDil.
  ///
  /// In tr, this message translates to:
  /// **'Yabancı Dil Belgesi'**
  String get certificateTypeDil;

  /// No description provided for @certificateTypeDiger.
  ///
  /// In tr, this message translates to:
  /// **'Diğer Sertifika'**
  String get certificateTypeDiger;

  /// No description provided for @certificateStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get certificateStatusPending;

  /// No description provided for @certificateStatusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get certificateStatusApproved;

  /// No description provided for @certificateStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get certificateStatusRejected;

  /// No description provided for @adminCertificateReviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Belge Onay Kuyruğu'**
  String get adminCertificateReviewTitle;

  /// No description provided for @talentPoolTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yetenek Havuzu'**
  String get talentPoolTitle;

  /// No description provided for @talentPoolMyPool.
  ///
  /// In tr, this message translates to:
  /// **'Yetenek Havuzum'**
  String get talentPoolMyPool;

  /// No description provided for @talentPoolSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelecek sezon adayları ve notlar'**
  String get talentPoolSubtitle;

  /// No description provided for @addToTalentPool.
  ///
  /// In tr, this message translates to:
  /// **'Yetenek Havuzuna Ekle'**
  String get addToTalentPool;

  /// No description provided for @addedToTalentPool.
  ///
  /// In tr, this message translates to:
  /// **'Aday yetenek havuzunuza eklendi.'**
  String get addedToTalentPool;

  /// No description provided for @removedFromTalentPool.
  ///
  /// In tr, this message translates to:
  /// **'Aday yetenek havuzundan çıkarıldı.'**
  String get removedFromTalentPool;

  /// No description provided for @emptyTalentPool.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Yetenek Havuzunuzda Aday Yok'**
  String get emptyTalentPool;

  /// No description provided for @emptyTalentPoolSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İş arayanlarla yaptığınız sohbetlerde detay menüsünden \"Yetenek Havuzuna Ekle\" seçeneği ile adayları buraya kaydedebilirsiniz.'**
  String get emptyTalentPoolSubtitle;

  /// No description provided for @backToChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbete Dön'**
  String get backToChat;

  /// No description provided for @removeFromPoolConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Adayı Havuzdan Çıkar'**
  String get removeFromPoolConfirmTitle;

  /// No description provided for @housingAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Lojman Bilgileri Ekle'**
  String get housingAddTitle;

  /// No description provided for @housingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Lojman & Sosyal İmkanlar'**
  String get housingTitle;

  /// No description provided for @housingRoomType.
  ///
  /// In tr, this message translates to:
  /// **'Oda tipi'**
  String get housingRoomType;

  /// No description provided for @housingSingleRoom.
  ///
  /// In tr, this message translates to:
  /// **'Tek kişilik oda'**
  String get housingSingleRoom;

  /// No description provided for @housingSharedRoom.
  ///
  /// In tr, this message translates to:
  /// **'Çok kişilik oda'**
  String get housingSharedRoom;

  /// No description provided for @housingHasAc.
  ///
  /// In tr, this message translates to:
  /// **'Klima'**
  String get housingHasAc;

  /// No description provided for @housingHasWifi.
  ///
  /// In tr, this message translates to:
  /// **'Wi-Fi'**
  String get housingHasWifi;

  /// No description provided for @housingMealsIncluded.
  ///
  /// In tr, this message translates to:
  /// **'Günlük dahil öğün'**
  String get housingMealsIncluded;

  /// No description provided for @housingPhotos.
  ///
  /// In tr, this message translates to:
  /// **'Lojman fotoğrafları'**
  String get housingPhotos;

  /// No description provided for @staffShuttleRouteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Personel Servisi Güzergahı'**
  String get staffShuttleRouteLabel;

  /// No description provided for @staffShuttleRouteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Kemer Merkez - Göynük - Otel'**
  String get staffShuttleRouteHint;

  /// No description provided for @housingAddPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ekle'**
  String get housingAddPhoto;

  /// No description provided for @urgentListingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Acil İhtiyaç'**
  String get urgentListingLabel;

  /// No description provided for @urgentListingHint.
  ///
  /// In tr, this message translates to:
  /// **'Bölgedeki kullanıcılara anlık bildirim gönderilir.'**
  String get urgentListingHint;

  /// No description provided for @urgentBadge.
  ///
  /// In tr, this message translates to:
  /// **'ACİL'**
  String get urgentBadge;

  /// No description provided for @urgentNotificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Acil İlan Bildirimleri'**
  String get urgentNotificationsTitle;

  /// No description provided for @urgentNotificationsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğiniz turizm bölgesindeki acil personel ilanlarını anında alın.'**
  String get urgentNotificationsDescription;

  /// No description provided for @qrPosterTitle.
  ///
  /// In tr, this message translates to:
  /// **'QR İlan Posteri'**
  String get qrPosterTitle;

  /// No description provided for @createQrPosterAction.
  ///
  /// In tr, this message translates to:
  /// **'QR Poster Oluştur'**
  String get createQrPosterAction;

  /// No description provided for @sharePosterAction.
  ///
  /// In tr, this message translates to:
  /// **'Posteri Paylaş'**
  String get sharePosterAction;

  /// No description provided for @qrPosterScanInstruction.
  ///
  /// In tr, this message translates to:
  /// **'İlanı görüntülemek ve hızlı başvuru yapmak için QR kodu taratın.'**
  String get qrPosterScanInstruction;

  /// No description provided for @qrPosterFooter.
  ///
  /// In tr, this message translates to:
  /// **'www.otelcim.app • Otel & Turizm İş İlanları Platformu'**
  String get qrPosterFooter;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp cihazınızda açılamadı.'**
  String get whatsappNotInstalled;

  /// No description provided for @preferredRegionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tercih Edilen Turizm Bölgesi'**
  String get preferredRegionLabel;

  /// No description provided for @optionalSelection.
  ///
  /// In tr, this message translates to:
  /// **'Seçim Yapılmadı (isteğe bağlı)'**
  String get optionalSelection;

  /// No description provided for @myExperienceLevelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Deneyim Seviyem'**
  String get myExperienceLevelLabel;

  /// No description provided for @myEducationLevelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim Durumum'**
  String get myEducationLevelLabel;

  /// No description provided for @matchLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uyum'**
  String get matchLabel;

  /// App language picker screen title
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Dili'**
  String get languageSettingsTitle;

  /// Explains partial translation coverage on the language picker
  ///
  /// In tr, this message translates to:
  /// **'Bazı metinler henüz çevrilmedi; çevrilmeyen yerler Türkçe gösterilir.'**
  String get languageSettingsSubtitle;

  /// Home feed search field hint
  ///
  /// In tr, this message translates to:
  /// **'İş ilanı ara...'**
  String get homeSearchHint;

  /// Tooltip on the advanced-filters button
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filtersTooltip;

  /// Tooltip on the seasonal calendar action
  ///
  /// In tr, this message translates to:
  /// **'Sezon Takvimi'**
  String get seasonalCalendarTooltip;

  /// Button that clears all active filters
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clearFiltersAction;

  /// Count of listings currently shown in the feed
  ///
  /// In tr, this message translates to:
  /// **'{count} sonuç'**
  String resultCount(int count);

  /// Tooltip on a grid column-count toggle
  ///
  /// In tr, this message translates to:
  /// **'{count} Sütun'**
  String gridColumnsTooltip(int count);

  /// Tooltip on the table view toggle
  ///
  /// In tr, this message translates to:
  /// **'Tablo Görünümü'**
  String get tableViewTooltip;

  /// Empty-state heading on the home feed
  ///
  /// In tr, this message translates to:
  /// **'Henüz İlan Bulunmuyor'**
  String get noListingsTitle;

  /// No description provided for @listingsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İlanlar yüklenemedi. Lütfen tekrar deneyin.'**
  String get listingsLoadError;

  /// Empty-state explanation on the home feed
  ///
  /// In tr, this message translates to:
  /// **'Sistemde aktif ilan bulunmamaktadır. Örnek ilanları veritabanına ekleyebilir veya yeni bir ilan oluşturabilirsiniz.'**
  String get noListingsBody;

  /// Empty-state button that seeds sample listings
  ///
  /// In tr, this message translates to:
  /// **'Örnek İlanları Veritabanına Yükle'**
  String get seedSampleListingsAction;

  /// Empty-state button to create the first listing
  ///
  /// In tr, this message translates to:
  /// **'İlk İlanı Sen Oluştur'**
  String get createFirstListingAction;

  /// Title of the advanced filters bottom sheet
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş filtreler'**
  String get advancedFiltersTitle;

  /// Filter field label for city or area
  ///
  /// In tr, this message translates to:
  /// **'Şehir / bölge'**
  String get cityOrRegionLabel;

  /// Dropdown option that selects every city
  ///
  /// In tr, this message translates to:
  /// **'Tüm şehirler'**
  String get allCitiesOption;

  /// Filter field label for the job field / branch
  ///
  /// In tr, this message translates to:
  /// **'İş branşı'**
  String get jobBranchLabel;

  /// Dropdown option that selects every job field
  ///
  /// In tr, this message translates to:
  /// **'Tüm branşlar'**
  String get allBranchesOption;

  /// Filter field label for the minimum salary
  ///
  /// In tr, this message translates to:
  /// **'En düşük maaş'**
  String get minSalaryLabel;

  /// Filter field label for the maximum salary
  ///
  /// In tr, this message translates to:
  /// **'En yüksek maaş'**
  String get maxSalaryLabel;

  /// Filter field label for the listing date range
  ///
  /// In tr, this message translates to:
  /// **'İlan tarihi'**
  String get listingDateLabel;

  /// Filter field label for the employment type
  ///
  /// In tr, this message translates to:
  /// **'Çalışma tipi'**
  String get employmentTypeLabel;

  /// Dropdown option that selects every employment type
  ///
  /// In tr, this message translates to:
  /// **'Tüm çalışma tipleri'**
  String get allEmploymentTypesOption;

  /// Filter field label for the sort order
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get sortLabel;

  /// Button that applies the selected filters
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri uygula'**
  String get applyFiltersAction;

  /// Snackbar shown when min salary exceeds max salary
  ///
  /// In tr, this message translates to:
  /// **'Maaş aralığını kontrol edin.'**
  String get salaryRangeError;

  /// Active filter chip: minimum salary and above
  ///
  /// In tr, this message translates to:
  /// **'{amount} TL ve üzeri'**
  String salaryMinAndUp(String amount);

  /// Active filter chip: maximum salary and below
  ///
  /// In tr, this message translates to:
  /// **'{amount} TL ve altı'**
  String salaryMaxAndDown(String amount);

  /// Tooltip on the favorite toggle when not favorited
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get addToFavorites;

  /// Tooltip on the favorite toggle when favorited
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get removeFromFavorites;

  /// Table view column header: listing title
  ///
  /// In tr, this message translates to:
  /// **'İlan Başlığı'**
  String get columnListingTitle;

  /// Table view column header: category
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get columnCategory;

  /// Table view column header: location
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get columnLocation;

  /// Table view column header: salary
  ///
  /// In tr, this message translates to:
  /// **'Ücret'**
  String get columnSalary;

  /// Table view column header: listing date
  ///
  /// In tr, this message translates to:
  /// **'İlan Tarihi'**
  String get columnListingDate;

  /// Employment type: full-time
  ///
  /// In tr, this message translates to:
  /// **'Tam zamanlı'**
  String get employmentTypeFullTime;

  /// Employment type: part-time
  ///
  /// In tr, this message translates to:
  /// **'Yarı zamanlı'**
  String get employmentTypePartTime;

  /// Employment type: seasonal
  ///
  /// In tr, this message translates to:
  /// **'Mevsimlik'**
  String get employmentTypeSeasonal;

  /// Listing date filter: all dates
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get dateFilterAll;

  /// Listing date filter: last 24 hours
  ///
  /// In tr, this message translates to:
  /// **'Son 24 saat'**
  String get dateFilterLast24Hours;

  /// Listing date filter: last week
  ///
  /// In tr, this message translates to:
  /// **'Son hafta'**
  String get dateFilterLastWeek;

  /// Listing date filter: last month
  ///
  /// In tr, this message translates to:
  /// **'Son ay'**
  String get dateFilterLastMonth;

  /// Sort order: newest first
  ///
  /// In tr, this message translates to:
  /// **'En yeni'**
  String get sortOrderNewest;

  /// Sort order: salary high to low
  ///
  /// In tr, this message translates to:
  /// **'Maaş yüksekten düşüğe'**
  String get sortOrderSalaryHighToLow;

  /// Sort order: salary low to high
  ///
  /// In tr, this message translates to:
  /// **'Maaş düşükten yükseğe'**
  String get sortOrderSalaryLowToHigh;

  /// Category filter chip that clears the category filter
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get allFilterChip;

  /// Feed card chip: the job includes staff housing
  ///
  /// In tr, this message translates to:
  /// **'Lojman'**
  String get perkHousing;

  /// Feed card chip: meals per day included
  ///
  /// In tr, this message translates to:
  /// **'{count} öğün'**
  String perkMeals(int count);

  /// Feed card chip: staff shuttle provided
  ///
  /// In tr, this message translates to:
  /// **'Servis'**
  String get perkShuttle;

  /// Tooltip/semantic label for the verified-employer badge
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış işveren'**
  String get verifiedEmployer;

  /// Season label for any summer season code yaz_YYYY
  ///
  /// In tr, this message translates to:
  /// **'Yaz {year}'**
  String seasonSummerOf(String year);

  /// Season label for any winter season code kis_YYYY_YY
  ///
  /// In tr, this message translates to:
  /// **'Kış {years}'**
  String seasonWinterOf(String years);

  /// No description provided for @forgotPasswordLink.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum?'**
  String get forgotPasswordLink;

  /// No description provided for @passwordResetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetSend.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırlama bağlantısı gönder'**
  String get passwordResetSend;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta ile bir hesap varsa, sıfırlama bağlantısı gönderildi.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin.'**
  String get passwordResetInvalidEmail;

  /// No description provided for @passwordResetTooManyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.'**
  String get passwordResetTooManyRequests;

  /// No description provided for @passwordResetNetworkError.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantınızı kontrol edip tekrar deneyin.'**
  String get passwordResetNetworkError;

  /// No description provided for @passwordResetGenericError.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı gönderilemedi. Lütfen tekrar deneyin.'**
  String get passwordResetGenericError;

  /// No description provided for @adminPanelEntry.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim Paneli'**
  String get adminPanelEntry;
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
      <String>['ar', 'de', 'en', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
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
