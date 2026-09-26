// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'HospoJobs';

  @override
  String get emailLabel => 'Электронная почта';

  @override
  String get emailHint => 'primer@pochta.com';

  @override
  String get emailValidation => 'Введите корректный адрес эл. почты';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get passwordValidation =>
      'Пароль должен содержать не менее 8 символов и хотя бы одну цифру';

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
  String get loginWithEmail => 'Вход по эл. почте';

  @override
  String get loginWithPhone => 'Вход по телефону';

  @override
  String get phoneLabel => 'Номер телефона';

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
  String get rememberMe => 'Запомнить меня';

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
  String get loginButton => 'Войти';

  @override
  String get registerButton => 'Регистрация';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get noAccountPrompt => 'Нет аккаунта? Зарегистрируйтесь';

  @override
  String get hasAccountPrompt => 'Уже есть аккаунт? Войдите';

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
  String get seasonLabel => 'Сезон';

  @override
  String get seasonSummer2025 => 'Лето 2025';

  @override
  String get seasonWinter202526 => 'Зима 2025-26';

  @override
  String get seasonYearRound => 'Круглый год';

  @override
  String get seasonAny => 'Любой / все сезоны';

  @override
  String get addSeasonalAlert => 'Hatırlatıcı Ekle';

  @override
  String get createAlertSuccess =>
      'Sezonluk hatırlatıcı başarıyla oluşturuldu.';

  @override
  String get roleSelectionError => 'Lütfen bir rol seçin';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get navHome => 'Главная';

  @override
  String get navCategories => 'Категории';

  @override
  String get navCreateListing => 'Разместить';

  @override
  String get navMessages => 'Сообщения';

  @override
  String get navProfile => 'Профиль';

  @override
  String get profileTitle => 'Мой аккаунт';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get myListings => 'Мои объявления';

  @override
  String get signOut => 'Выйти';

  @override
  String get desktopNavFavorites => 'Избранное';

  @override
  String get desktopNavProfile => 'Профиль';

  @override
  String get desktopNavSettings => 'Настройки';

  @override
  String get desktopNavLanguage => 'Язык';

  @override
  String get categoryReception => 'Стойка регистрации';

  @override
  String get categoryHousekeeping => 'Уборка номеров';

  @override
  String get categoryKitchenChef => 'Кухня / Повар';

  @override
  String get categoryServiceWaiter => 'Обслуживание / Официант';

  @override
  String get categorySecurity => 'Охрана';

  @override
  String get categoryAnimation => 'Анимация';

  @override
  String get categoryManagement => 'Управление';

  @override
  String get categoryTechnicalService => 'Техническая служба';

  @override
  String get categoryOther => 'Другое';

  @override
  String get regionLabel => 'Туристический регион';

  @override
  String get regionSelectHint => 'Выберите регион';

  @override
  String get regionRequired => 'Необходимо выбрать регион';

  @override
  String get regionsTitle => 'Регионы';

  @override
  String get regionsLoadError => 'Bölgeler yüklenemedi.';

  @override
  String activeListingCount(int count) {
    return '$count aktif ilan';
  }

  @override
  String get nearMe => 'Рядом со мной';

  @override
  String get nearbyTitle => 'Объявления рядом';

  @override
  String get nearbyPermissionTitle => 'Konum izni';

  @override
  String get nearbyPermissionExplanation =>
      'Yakınınızdaki iş ilanlarını mesafeye göre göstermek için yalnızca siz bu özelliği kullandığınızda anlık konumunuza erişmemiz gerekiyor.';

  @override
  String get cancelButton => 'Отмена';

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
  String get retryButton => 'Повторить';

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
  String get selectDate => 'Выберите дату';

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
  String get experienceLevelLabel => 'Опыт';

  @override
  String get educationLevelLabel => 'Образование';

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
  String get urgentListingLabel => 'Срочно требуется';

  @override
  String get urgentListingHint =>
      'Bölgedeki kullanıcılara anlık bildirim gönderilir.';

  @override
  String get urgentBadge => 'СРОЧНО';

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
  String get matchLabel => 'Совпадение';

  @override
  String get languageSettingsTitle => 'Язык приложения';

  @override
  String get languageSettingsSubtitle =>
      'Некоторые тексты ещё не переведены; непереведённые части показаны на турецком.';

  @override
  String get homeSearchHint => 'Поиск вакансий...';

  @override
  String get filtersTooltip => 'Фильтры';

  @override
  String get seasonalCalendarTooltip => 'Сезонный календарь';

  @override
  String get clearFiltersAction => 'Сбросить';

  @override
  String resultCount(int count) {
    return 'Результатов: $count';
  }

  @override
  String gridColumnsTooltip(int count) {
    return '$count столбца';
  }

  @override
  String get tableViewTooltip => 'Табличный вид';

  @override
  String get noListingsTitle => 'Пока нет объявлений';

  @override
  String get listingsLoadError =>
      'Не удалось загрузить объявления. Повторите попытку.';

  @override
  String get noListingsBody =>
      'Активных объявлений нет. Вы можете загрузить примеры объявлений в базу данных или создать новое.';

  @override
  String get seedSampleListingsAction => 'Загрузить примеры объявлений в базу';

  @override
  String get createFirstListingAction => 'Создайте первое объявление';

  @override
  String get advancedFiltersTitle => 'Расширенные фильтры';

  @override
  String get cityOrRegionLabel => 'Город / регион';

  @override
  String get allCitiesOption => 'Все города';

  @override
  String get jobBranchLabel => 'Сфера работы';

  @override
  String get allBranchesOption => 'Все сферы';

  @override
  String get minSalaryLabel => 'Минимальная зарплата';

  @override
  String get maxSalaryLabel => 'Максимальная зарплата';

  @override
  String get listingDateLabel => 'Дата объявления';

  @override
  String get employmentTypeLabel => 'Тип занятости';

  @override
  String get allEmploymentTypesOption => 'Все типы занятости';

  @override
  String get sortLabel => 'Сортировка';

  @override
  String get applyFiltersAction => 'Применить фильтры';

  @override
  String get salaryRangeError => 'Проверьте диапазон зарплаты.';

  @override
  String salaryMinAndUp(String amount) {
    return 'от $amount TL';
  }

  @override
  String salaryMaxAndDown(String amount) {
    return 'до $amount TL';
  }

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get removeFromFavorites => 'Убрать из избранного';

  @override
  String get columnListingTitle => 'Заголовок';

  @override
  String get columnCategory => 'Категория';

  @override
  String get columnLocation => 'Местоположение';

  @override
  String get columnSalary => 'Зарплата';

  @override
  String get columnListingDate => 'Дата';

  @override
  String get employmentTypeFullTime => 'Полная занятость';

  @override
  String get employmentTypePartTime => 'Частичная занятость';

  @override
  String get employmentTypeSeasonal => 'Сезонная';

  @override
  String get dateFilterAll => 'Все';

  @override
  String get dateFilterLast24Hours => 'За последние 24 часа';

  @override
  String get dateFilterLastWeek => 'За последнюю неделю';

  @override
  String get dateFilterLastMonth => 'За последний месяц';

  @override
  String get sortOrderNewest => 'Сначала новые';

  @override
  String get sortOrderSalaryHighToLow => 'Зарплата: по убыванию';

  @override
  String get sortOrderSalaryLowToHigh => 'Зарплата: по возрастанию';

  @override
  String get allFilterChip => 'Все';

  @override
  String get perkHousing => 'Жильё';

  @override
  String perkMeals(int count) {
    return 'Питание: $count';
  }

  @override
  String get perkShuttle => 'Трансфер';

  @override
  String get verifiedEmployer => 'Проверенный работодатель';

  @override
  String seasonSummerOf(String year) {
    return 'Лето $year';
  }

  @override
  String seasonWinterOf(String years) {
    return 'Зима $years';
  }

  @override
  String get forgotPasswordLink => 'Забыли пароль?';

  @override
  String get passwordResetTitle => 'Сброс пароля';

  @override
  String get passwordResetSend => 'Отправить ссылку для сброса';

  @override
  String get passwordResetSuccess =>
      'Если существует аккаунт с этим адресом, ссылка для сброса отправлена';

  @override
  String get passwordResetInvalidEmail =>
      'Введите действительный адрес электронной почты.';

  @override
  String get passwordResetTooManyRequests =>
      'Слишком много запросов. Повторите попытку позже.';

  @override
  String get passwordResetNetworkError =>
      'Проверьте подключение к интернету и повторите попытку.';

  @override
  String get passwordResetGenericError =>
      'Не удалось отправить ссылку. Повторите попытку.';

  @override
  String get adminPanelEntry => 'Панель администратора';

  @override
  String get listingPreviewOpenFullPage => 'Открыть на всю страницу';

  @override
  String get listingPreviewClose => 'Закрыть предпросмотр';

  @override
  String get listingPreviewShowMore => 'Показать больше';

  @override
  String get listingPreviewShowLess => 'Показать меньше';

  @override
  String get listingPreviewNotFound => 'Объявление не найдено или удалено';

  @override
  String get listingPreviewEditListing => 'Редактировать объявление';

  @override
  String get listingPreviewLoginToContact => 'Войдите, чтобы связаться';

  @override
  String get listingPreviewSendMessage => 'Отправить сообщение';

  @override
  String get listingPreviewError => 'Произошла ошибка при загрузке объявления';

  @override
  String get listingPreviewRetry => 'Повторить';
}
