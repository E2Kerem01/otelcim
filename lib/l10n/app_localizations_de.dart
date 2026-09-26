// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'HospoJobs';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get emailHint => 'beispiel@email.com';

  @override
  String get emailValidation => 'Gültige E-Mail-Adresse eingeben';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get passwordValidation =>
      'Das Passwort muss mindestens 8 Zeichen und mindestens 1 Ziffer enthalten';

  @override
  String get referralCodeLabel => 'Referans Kodu (opsiyonel)';

  @override
  String get referralCodeHint => 'Arkadaşının kodu';

  @override
  String get inviteFriendsTitle => 'Arkadaşını Davet Et';

  @override
  String get inviteFriendsMenuLabel => 'Arkadaşını Davet Et';

  @override
  String get inviteFriendsDescription =>
      'Kodunu arkadaşınla paylaş, o kaydolup ilk ilanını yayınladığında veya ilk sohbetini başlattığında sana ücretsiz bir boost hakkı kazandırsın.';

  @override
  String get yourReferralCodeLabel => 'Referans Kodun';

  @override
  String get copyCodeAction => 'Kodu Kopyala';

  @override
  String get codeCopiedMessage => 'Kod kopyalandı';

  @override
  String get shareCodeAction => 'Paylaş';

  @override
  String shareReferralMessage(String code) {
    return 'Otelcim\'de otel/turizm işleri bul veya ilan ver! $code kodumla kayıt ol, ikimiz de kazanalım.';
  }

  @override
  String get referralCountLabel => 'Davet Ettiğin Kişi Sayısı';

  @override
  String get freeBoostCreditsLabel => 'Ücretsiz Boost Hakkın';

  @override
  String freeBoostBannerText(int count) {
    return '$count ücretsiz boost hakkınız var';
  }

  @override
  String get useFreeBoostAction => 'Ücretsiz Kullan';

  @override
  String get freeBoostRedeemedMessage => 'Ücretsiz boost uygulandı!';

  @override
  String get freeBoostRedeemFailedMessage => 'Ücretsiz boost uygulanamadı';

  @override
  String get loginWithEmail => 'Mit E-Mail anmelden';

  @override
  String get loginWithPhone => 'Mit Telefon anmelden';

  @override
  String get phoneLabel => 'Telefonnummer';

  @override
  String get phoneHint => '5XX XXX XX XX';

  @override
  String get phoneValidation =>
      'Geçerli bir telefon numarası girin (ör: 5551234567)';

  @override
  String get sendSmsCode => 'Kod Gönder';

  @override
  String get smsCodeLabel => 'SMS Doğrulama Kodu';

  @override
  String get smsCodeHint => '6 haneli kod';

  @override
  String get smsCodeValidation => 'Lütfen 6 haneli doğrulama kodunu girin';

  @override
  String get verifySmsCode => 'Doğrula ve Giriş Yap';

  @override
  String get rememberMe => 'Angemeldet bleiben';

  @override
  String tooManyAttempts(int seconds) {
    return 'Çok fazla başarısız deneme. Lütfen $seconds saniye bekleyin.';
  }

  @override
  String get brandTitle => 'Türkiye\'nin Otel & Turizm İş Platformu';

  @override
  String get brandDescription =>
      'Otel ve turizm sektöründe hayalinizdeki işi veya personeli hızlıca bulun.';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get registerTitle => 'Registrieren';

  @override
  String get noAccountPrompt => 'Kein Konto? Jetzt registrieren';

  @override
  String get hasAccountPrompt => 'Bereits ein Konto? Anmelden';

  @override
  String get onboardingWelcome => 'Otelcim\'e Hoş Geldiniz!';

  @override
  String get onboardingRolePrompt =>
      'Size en uygun deneyimi sunabilmemiz için lütfen rolünüzü seçin:';

  @override
  String get roleJobSeeker => 'İş Arıyorum';

  @override
  String get roleJobSeekerDescription =>
      'Otel ve turizm sektöründe iş arıyorum. İlanları görmek ve başvurmak istiyorum.';

  @override
  String get roleEmployer => 'Personel Arıyorum';

  @override
  String get roleEmployerDescription =>
      'Otelim veya işletmem için çalışan arıyorum. İlan vermek istiyorum.';

  @override
  String get incompletePositionsError =>
      'Lütfen tüm pozisyon bilgilerini eksiksiz doldurun.';

  @override
  String get batchCreateButton => 'Toplu İlan Ver';

  @override
  String get seasonalCalendarTitle => 'Sezonluk İşe Alım Takvimi';

  @override
  String get seasonalRemindersTitle => 'Sezonluk Hatırlatıcılarım';

  @override
  String get seasonalRemindersDesc =>
      'Sezon başlamadan önce belirlediğiniz şehir ve kategorideki ilanlardan haberdar olun.';

  @override
  String get seasonLabel => 'Saison';

  @override
  String get seasonSummer2025 => 'Sommer 2025';

  @override
  String get seasonWinter202526 => 'Winter 2025-26';

  @override
  String get seasonYearRound => 'Ganzjährig';

  @override
  String get seasonAny => 'Egal / Alle Saisons';

  @override
  String get addSeasonalAlert => 'Hatırlatıcı Ekle';

  @override
  String get createAlertSuccess =>
      'Sezonluk hatırlatıcı başarıyla oluşturuldu.';

  @override
  String get roleSelectionError => 'Lütfen bir rol seçin';

  @override
  String get continueButton => 'Weiter';

  @override
  String get navHome => 'Start';

  @override
  String get navCategories => 'Kategorien';

  @override
  String get navCreateListing => 'Inserieren';

  @override
  String get navMessages => 'Nachrichten';

  @override
  String get navProfile => 'Konto';

  @override
  String get profileTitle => 'Mein Konto';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get myListings => 'Meine Anzeigen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get desktopNavFavorites => 'Favoriten';

  @override
  String get desktopNavProfile => 'Profil';

  @override
  String get desktopNavSettings => 'Einstellungen';

  @override
  String get desktopNavLanguage => 'Sprache';

  @override
  String get categoryReception => 'Rezeption';

  @override
  String get categoryHousekeeping => 'Housekeeping';

  @override
  String get categoryKitchenChef => 'Küche / Koch';

  @override
  String get categoryServiceWaiter => 'Service / Kellner';

  @override
  String get categorySecurity => 'Sicherheit';

  @override
  String get categoryAnimation => 'Animation';

  @override
  String get categoryManagement => 'Management';

  @override
  String get categoryTechnicalService => 'Technischer Dienst';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get regionLabel => 'Tourismusregion';

  @override
  String get regionSelectHint => 'Region wählen';

  @override
  String get regionRequired => 'Bitte eine Region wählen';

  @override
  String get regionsTitle => 'Regionen';

  @override
  String get regionsLoadError => 'Bölgeler yüklenemedi.';

  @override
  String activeListingCount(int count) {
    return '$count aktif ilan';
  }

  @override
  String get nearMe => 'In meiner Nähe';

  @override
  String get nearbyTitle => 'Anzeigen in der Nähe';

  @override
  String get nearbyPermissionTitle => 'Konum izni';

  @override
  String get nearbyPermissionExplanation =>
      'Yakınınızdaki iş ilanlarını mesafeye göre göstermek için yalnızca siz bu özelliği kullandığınızda anlık konumunuza erişmemiz gerekiyor.';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get radiusLabel => 'Arama yarıçapı';

  @override
  String get nearbyEmpty => 'Seçilen yarıçapta konum bilgili ilan bulunamadı.';

  @override
  String get nearbyLocationDenied =>
      'Konum izni verilmedi. Yakınımda özelliği kapalı kaldı.';

  @override
  String get nearbyLocationDeniedForever =>
      'Konum izni kalıcı olarak kapalı. İzni cihaz ayarlarından açabilirsiniz.';

  @override
  String get nearbyServicesDisabled => 'Cihazınızın konum hizmetleri kapalı.';

  @override
  String get nearbyLocationUnavailable =>
      'Konum şu anda alınamıyor. Lütfen tekrar deneyin.';

  @override
  String get retryButton => 'Erneut versuchen';

  @override
  String distanceKm(String distance) {
    return '$distance km uzakta';
  }

  @override
  String get addListingLocation => 'Anlık konumumu ilana ekle (isteğe bağlı)';

  @override
  String get listingLocationAdded => 'Konum ilana eklenecek.';

  @override
  String get listingLocationOptionalHint =>
      'Koordinatlar yalnızca yakın ilan aramalarında kullanılır.';

  @override
  String get seasonNone => 'Sezon seçilmedi';

  @override
  String get contractStartDateLabel => 'Sözleşme başlangıcı';

  @override
  String get contractEndDateLabel => 'Sözleşme bitişi';

  @override
  String get selectDate => 'Datum wählen';

  @override
  String get contractDatesRequired =>
      'Sezonluk ilanlar için başlangıç ve bitiş tarihlerini seçin.';

  @override
  String get contractDateRangeInvalid =>
      'Sözleşme bitiş tarihi başlangıç tarihinden önce olamaz.';

  @override
  String get regionMapTitle => 'Bölge haritası';

  @override
  String get regionMapAttribution => 'OpenStreetMap katkıda bulunanları';

  @override
  String get listingSafetyTipsTitle => 'Güvenlik İpuçları';

  @override
  String get listingSafetyTipsBody =>
      'İşverenle görüşmeden ve iş yerini ziyaret etmeden ödeme yapmayın. Kimlik, kredi kartı, banka veya diğer hassas kişisel bilgilerinizi paylaşmayın. Şüpheli durumları bize bildirin.';

  @override
  String get listingSafetyReportAction => 'İlanı Şikâyet Et';

  @override
  String get availableImmediatelyLabel => 'Şu An Boşta / Hemen Başlayabilir';

  @override
  String get availableImmediatelyHint =>
      'İşverenlerin sohbet ekranında yeşil rozet ile görünürsünüz.';

  @override
  String get availableImmediatelyBadge => 'Hemen Başlayabilir';

  @override
  String get notAvailableBadge => 'Müsait Değil';

  @override
  String get experienceLevelLabel => 'Erfahrung';

  @override
  String get educationLevelLabel => 'Ausbildung';

  @override
  String get optionalNotSpecified => 'Belirtilmedi (isteğe bağlı)';

  @override
  String get experienceNone => 'Deneyim Aranmıyor';

  @override
  String get experienceUnderOneYear => '1 Yıldan Az';

  @override
  String get experienceOneToThreeYears => '1-3 Yıl';

  @override
  String get experienceThreePlusYears => '3+ Yıl';

  @override
  String get educationNone => 'Eğitim Şartı Yok';

  @override
  String get educationPrimary => 'En Az İlköğretim';

  @override
  String get educationHighSchool => 'En Az Lise';

  @override
  String get educationUniversity => 'En Az Üniversite';

  @override
  String get proposeInterview => 'Mülakat Saati Öner';

  @override
  String get interviewProposalTitle => 'Mülakat Zamanı Önerisi';

  @override
  String get interviewConfirmedTitle => 'Mülakat Onaylandı';

  @override
  String get waitingCandidateSelection =>
      'Adayın mülakat saati seçimi bekleniyor...';

  @override
  String get confirmSlotPrompt => 'Bu mülakat saatini onaylıyor musunuz?';

  @override
  String get selectSlot => 'Seç';

  @override
  String get interviewSlotsProposedSuccess =>
      'Mülakat saatleri başarıyla önerildi.';

  @override
  String get introVideoTitle => 'Tanıtım Videosu';

  @override
  String get introVideoLabel => '15-30 Saniyelik Tanıtım Videosu';

  @override
  String get introVideoHint =>
      'Kendinizi işverenlere tanıtan kısa bir video yükleyin.';

  @override
  String get uploadVideoAction => 'Video Yükle';

  @override
  String get changeVideoAction => 'Videoyu Değiştir';

  @override
  String get removeVideoAction => 'Videoyu Kaldır';

  @override
  String get watchIntroVideo => 'Tanıtım Videosunu İzle';

  @override
  String get videoDurationWarning => 'Video en fazla 30 saniye olmalıdır.';

  @override
  String get videoUploadSuccess => 'Tanıtım videosu başarıyla yüklendi!';

  @override
  String get videoRemoveSuccess => 'Tanıtım videosu kaldırıldı.';

  @override
  String get sendWhatsAppAction => 'WhatsApp ile Mesaj Gönder';

  @override
  String get certificateTypeCankurtaran => 'Cankurtaran Sertifikası';

  @override
  String get certificateTypeEhliyet => 'Sürücü Belgesi (Ehliyet)';

  @override
  String get certificateTypeDil => 'Yabancı Dil Belgesi';

  @override
  String get certificateTypeDiger => 'Diğer Sertifika';

  @override
  String get certificateStatusPending => 'Beklemede';

  @override
  String get certificateStatusApproved => 'Onaylandı';

  @override
  String get certificateStatusRejected => 'Reddedildi';

  @override
  String get adminCertificateReviewTitle => 'Belge Onay Kuyruğu';

  @override
  String get talentPoolTitle => 'Yetenek Havuzu';

  @override
  String get talentPoolMyPool => 'Yetenek Havuzum';

  @override
  String get talentPoolSubtitle => 'Gelecek sezon adayları ve notlar';

  @override
  String get addToTalentPool => 'Yetenek Havuzuna Ekle';

  @override
  String get addedToTalentPool => 'Aday yetenek havuzunuza eklendi.';

  @override
  String get removedFromTalentPool => 'Aday yetenek havuzundan çıkarıldı.';

  @override
  String get emptyTalentPool => 'Henüz Yetenek Havuzunuzda Aday Yok';

  @override
  String get emptyTalentPoolSubtitle =>
      'İş arayanlarla yaptığınız sohbetlerde detay menüsünden \"Yetenek Havuzuna Ekle\" seçeneği ile adayları buraya kaydedebilirsiniz.';

  @override
  String get backToChat => 'Sohbete Dön';

  @override
  String get removeFromPoolConfirmTitle => 'Adayı Havuzdan Çıkar';

  @override
  String get housingAddTitle => 'Lojman Bilgileri Ekle';

  @override
  String get housingTitle => 'Lojman & Sosyal İmkanlar';

  @override
  String get housingRoomType => 'Oda tipi';

  @override
  String get housingSingleRoom => 'Tek kişilik oda';

  @override
  String get housingSharedRoom => 'Çok kişilik oda';

  @override
  String get housingHasAc => 'Klima';

  @override
  String get housingHasWifi => 'Wi-Fi';

  @override
  String get housingMealsIncluded => 'Günlük dahil öğün';

  @override
  String get housingPhotos => 'Lojman fotoğrafları';

  @override
  String get staffShuttleRouteLabel => 'Personel Servisi Güzergahı';

  @override
  String get staffShuttleRouteHint => 'Örn. Kemer Merkez - Göynük - Otel';

  @override
  String get housingAddPhoto => 'Fotoğraf ekle';

  @override
  String get urgentListingLabel => 'Dringend gesucht';

  @override
  String get urgentListingHint =>
      'Bölgedeki kullanıcılara anlık bildirim gönderilir.';

  @override
  String get urgentBadge => 'DRINGEND';

  @override
  String get urgentNotificationsTitle => 'Acil İlan Bildirimleri';

  @override
  String get urgentNotificationsDescription =>
      'Seçtiğiniz turizm bölgesindeki acil personel ilanlarını anında alın.';

  @override
  String get qrPosterTitle => 'QR İlan Posteri';

  @override
  String get createQrPosterAction => 'QR Poster Oluştur';

  @override
  String get sharePosterAction => 'Posteri Paylaş';

  @override
  String get qrPosterScanInstruction =>
      'İlanı görüntülemek ve hızlı başvuru yapmak için QR kodu taratın.';

  @override
  String get qrPosterFooter =>
      'www.otelcim.app • Otel & Turizm İş İlanları Platformu';

  @override
  String get whatsappNotInstalled => 'WhatsApp cihazınızda açılamadı.';

  @override
  String get preferredRegionLabel => 'Tercih Edilen Turizm Bölgesi';

  @override
  String get optionalSelection => 'Seçim Yapılmadı (isteğe bağlı)';

  @override
  String get myExperienceLevelLabel => 'Deneyim Seviyem';

  @override
  String get myEducationLevelLabel => 'Eğitim Durumum';

  @override
  String get matchLabel => 'Übereinstimmung';

  @override
  String get languageSettingsTitle => 'App-Sprache';

  @override
  String get languageSettingsSubtitle =>
      'Einige Texte sind noch nicht übersetzt; nicht übersetzte Teile werden auf Türkisch angezeigt.';

  @override
  String get homeSearchHint => 'Stellenanzeigen suchen...';

  @override
  String get filtersTooltip => 'Filter';

  @override
  String get seasonalCalendarTooltip => 'Saisonkalender';

  @override
  String get clearFiltersAction => 'Zurücksetzen';

  @override
  String resultCount(int count) {
    return '$count Ergebnisse';
  }

  @override
  String gridColumnsTooltip(int count) {
    return '$count Spalten';
  }

  @override
  String get tableViewTooltip => 'Tabellenansicht';

  @override
  String get noListingsTitle => 'Noch keine Anzeigen';

  @override
  String get listingsLoadError =>
      'Anzeigen konnten nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get noListingsBody =>
      'Es gibt keine aktiven Anzeigen. Du kannst Beispielanzeigen in die Datenbank laden oder eine neue erstellen.';

  @override
  String get seedSampleListingsAction => 'Beispielanzeigen in Datenbank laden';

  @override
  String get createFirstListingAction => 'Erstelle die erste Anzeige';

  @override
  String get advancedFiltersTitle => 'Erweiterte Filter';

  @override
  String get cityOrRegionLabel => 'Stadt / Region';

  @override
  String get allCitiesOption => 'Alle Städte';

  @override
  String get jobBranchLabel => 'Berufsfeld';

  @override
  String get allBranchesOption => 'Alle Bereiche';

  @override
  String get minSalaryLabel => 'Mindestgehalt';

  @override
  String get maxSalaryLabel => 'Höchstgehalt';

  @override
  String get listingDateLabel => 'Anzeigendatum';

  @override
  String get employmentTypeLabel => 'Beschäftigungsart';

  @override
  String get allEmploymentTypesOption => 'Alle Beschäftigungsarten';

  @override
  String get sortLabel => 'Sortierung';

  @override
  String get applyFiltersAction => 'Filter anwenden';

  @override
  String get salaryRangeError => 'Überprüfe den Gehaltsbereich.';

  @override
  String salaryMinAndUp(String amount) {
    return 'ab $amount TL';
  }

  @override
  String salaryMaxAndDown(String amount) {
    return 'bis $amount TL';
  }

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get columnListingTitle => 'Anzeigentitel';

  @override
  String get columnCategory => 'Kategorie';

  @override
  String get columnLocation => 'Standort';

  @override
  String get columnSalary => 'Gehalt';

  @override
  String get columnListingDate => 'Anzeigendatum';

  @override
  String get employmentTypeFullTime => 'Vollzeit';

  @override
  String get employmentTypePartTime => 'Teilzeit';

  @override
  String get employmentTypeSeasonal => 'Saisonal';

  @override
  String get dateFilterAll => 'Alle';

  @override
  String get dateFilterLast24Hours => 'Letzte 24 Stunden';

  @override
  String get dateFilterLastWeek => 'Letzte Woche';

  @override
  String get dateFilterLastMonth => 'Letzter Monat';

  @override
  String get sortOrderNewest => 'Neueste';

  @override
  String get sortOrderSalaryHighToLow => 'Gehalt: hoch nach niedrig';

  @override
  String get sortOrderSalaryLowToHigh => 'Gehalt: niedrig nach hoch';

  @override
  String get allFilterChip => 'Alle';

  @override
  String get perkHousing => 'Unterkunft';

  @override
  String perkMeals(int count) {
    return '$count Mahlzeiten';
  }

  @override
  String get perkShuttle => 'Shuttle';

  @override
  String get verifiedEmployer => 'Verifizierter Arbeitgeber';

  @override
  String seasonSummerOf(String year) {
    return 'Sommer $year';
  }

  @override
  String seasonWinterOf(String years) {
    return 'Winter $years';
  }

  @override
  String get forgotPasswordLink => 'Passwort vergessen?';

  @override
  String get passwordResetTitle => 'Passwort zurücksetzen';

  @override
  String get passwordResetSend => 'Link zum Zurücksetzen senden';

  @override
  String get passwordResetSuccess =>
      'Falls ein Konto existiert, wurde ein Link zum Zurücksetzen gesendet';

  @override
  String get passwordResetInvalidEmail =>
      'Geben Sie eine gültige E-Mail-Adresse ein.';

  @override
  String get passwordResetTooManyRequests =>
      'Zu viele Anfragen. Bitte versuchen Sie es später erneut.';

  @override
  String get passwordResetNetworkError =>
      'Überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get passwordResetGenericError =>
      'Der Link konnte nicht gesendet werden. Bitte versuchen Sie es erneut.';

  @override
  String get adminPanelEntry => 'Adminbereich';
}
