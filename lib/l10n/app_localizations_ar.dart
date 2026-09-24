// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'HospoJobs';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailValidation => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordValidation =>
      'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل ورقم واحد على الأقل';

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
  String get loginWithEmail => 'الدخول بالبريد الإلكتروني';

  @override
  String get loginWithPhone => 'الدخول برقم الهاتف';

  @override
  String get phoneLabel => 'رقم الهاتف';

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
  String get rememberMe => 'تذكرني';

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
  String get loginButton => 'تسجيل الدخول';

  @override
  String get registerButton => 'إنشاء حساب';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get noAccountPrompt => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get hasAccountPrompt => 'لديك حساب بالفعل؟ سجّل الدخول';

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
  String get seasonLabel => 'الموسم';

  @override
  String get seasonSummer2025 => 'صيف 2025';

  @override
  String get seasonWinter202526 => 'شتاء 2025-26';

  @override
  String get seasonYearRound => 'طوال العام';

  @override
  String get seasonAny => 'أي / كل المواسم';

  @override
  String get addSeasonalAlert => 'Hatırlatıcı Ekle';

  @override
  String get createAlertSuccess =>
      'Sezonluk hatırlatıcı başarıyla oluşturuldu.';

  @override
  String get roleSelectionError => 'Lütfen bir rol seçin';

  @override
  String get continueButton => 'متابعة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCategories => 'الفئات';

  @override
  String get navCreateListing => 'نشر إعلان';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get navProfile => 'حسابي';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get myListings => 'إعلاناتي';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get categoryReception => 'الاستقبال';

  @override
  String get categoryHousekeeping => 'خدمة الغرف';

  @override
  String get categoryKitchenChef => 'المطبخ / الطهاة';

  @override
  String get categoryServiceWaiter => 'الخدمة / النُدُل';

  @override
  String get categorySecurity => 'الأمن';

  @override
  String get categoryAnimation => 'الأنيميشن';

  @override
  String get categoryManagement => 'الإدارة';

  @override
  String get categoryTechnicalService => 'الخدمة الفنية';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get regionLabel => 'المنطقة السياحية';

  @override
  String get regionSelectHint => 'اختر المنطقة';

  @override
  String get regionRequired => 'يجب اختيار منطقة';

  @override
  String get regionsTitle => 'المناطق';

  @override
  String get regionsLoadError => 'Bölgeler yüklenemedi.';

  @override
  String activeListingCount(int count) {
    return '$count aktif ilan';
  }

  @override
  String get nearMe => 'بالقرب مني';

  @override
  String get nearbyTitle => 'إعلانات قريبة';

  @override
  String get nearbyPermissionTitle => 'Konum izni';

  @override
  String get nearbyPermissionExplanation =>
      'Yakınınızdaki iş ilanlarını mesafeye göre göstermek için yalnızca siz bu özelliği kullandığınızda anlık konumunuza erişmemiz gerekiyor.';

  @override
  String get cancelButton => 'إلغاء';

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
  String get retryButton => 'إعادة المحاولة';

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
  String get selectDate => 'اختر التاريخ';

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
  String get experienceLevelLabel => 'الخبرة';

  @override
  String get educationLevelLabel => 'التعليم';

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
  String get urgentListingLabel => 'مطلوب بشكل عاجل';

  @override
  String get urgentListingHint =>
      'Bölgedeki kullanıcılara anlık bildirim gönderilir.';

  @override
  String get urgentBadge => 'عاجل';

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
  String get matchLabel => 'تطابق';

  @override
  String get languageSettingsTitle => 'لغة التطبيق';

  @override
  String get languageSettingsSubtitle =>
      'بعض النصوص لم تُترجم بعد؛ الأجزاء غير المترجمة تظهر باللغة التركية.';

  @override
  String get homeSearchHint => 'ابحث عن إعلانات الوظائف...';

  @override
  String get filtersTooltip => 'عوامل التصفية';

  @override
  String get seasonalCalendarTooltip => 'التقويم الموسمي';

  @override
  String get clearFiltersAction => 'مسح';

  @override
  String resultCount(int count) {
    return '$count نتيجة';
  }

  @override
  String gridColumnsTooltip(int count) {
    return '$count أعمدة';
  }

  @override
  String get tableViewTooltip => 'عرض الجدول';

  @override
  String get noListingsTitle => 'لا توجد إعلانات بعد';

  @override
  String get noListingsBody =>
      'لا توجد إعلانات نشطة. يمكنك تحميل إعلانات نموذجية إلى قاعدة البيانات أو إنشاء إعلان جديد.';

  @override
  String get seedSampleListingsAction =>
      'تحميل إعلانات نموذجية إلى قاعدة البيانات';

  @override
  String get createFirstListingAction => 'أنشئ أول إعلان';

  @override
  String get advancedFiltersTitle => 'عوامل تصفية متقدمة';

  @override
  String get cityOrRegionLabel => 'المدينة / المنطقة';

  @override
  String get allCitiesOption => 'جميع المدن';

  @override
  String get jobBranchLabel => 'مجال العمل';

  @override
  String get allBranchesOption => 'جميع المجالات';

  @override
  String get minSalaryLabel => 'الحد الأدنى للراتب';

  @override
  String get maxSalaryLabel => 'الحد الأقصى للراتب';

  @override
  String get listingDateLabel => 'تاريخ الإعلان';

  @override
  String get employmentTypeLabel => 'نوع التوظيف';

  @override
  String get allEmploymentTypesOption => 'جميع أنواع التوظيف';

  @override
  String get sortLabel => 'الترتيب';

  @override
  String get applyFiltersAction => 'تطبيق عوامل التصفية';

  @override
  String get salaryRangeError => 'تحقق من نطاق الراتب.';

  @override
  String salaryMinAndUp(String amount) {
    return '$amount ليرة فأكثر';
  }

  @override
  String salaryMaxAndDown(String amount) {
    return '$amount ليرة فأقل';
  }

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get columnListingTitle => 'عنوان الإعلان';

  @override
  String get columnCategory => 'الفئة';

  @override
  String get columnLocation => 'الموقع';

  @override
  String get columnSalary => 'الأجر';

  @override
  String get columnListingDate => 'تاريخ الإعلان';

  @override
  String get employmentTypeFullTime => 'دوام كامل';

  @override
  String get employmentTypePartTime => 'دوام جزئي';

  @override
  String get employmentTypeSeasonal => 'موسمي';

  @override
  String get dateFilterAll => 'الكل';

  @override
  String get dateFilterLast24Hours => 'آخر 24 ساعة';

  @override
  String get dateFilterLastWeek => 'الأسبوع الماضي';

  @override
  String get dateFilterLastMonth => 'الشهر الماضي';

  @override
  String get sortOrderNewest => 'الأحدث';

  @override
  String get sortOrderSalaryHighToLow => 'الراتب: من الأعلى إلى الأدنى';

  @override
  String get sortOrderSalaryLowToHigh => 'الراتب: من الأدنى إلى الأعلى';

  @override
  String get allFilterChip => 'الكل';

  @override
  String get perkHousing => 'سكن';

  @override
  String perkMeals(int count) {
    return '$count وجبات';
  }

  @override
  String get perkShuttle => 'نقل';

  @override
  String get verifiedEmployer => 'صاحب عمل موثّق';

  @override
  String seasonSummerOf(String year) {
    return 'صيف $year';
  }

  @override
  String seasonWinterOf(String years) {
    return 'شتاء $years';
  }
}
