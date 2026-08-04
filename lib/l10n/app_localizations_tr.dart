// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Otelcim';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get emailHint => 'ornek@eposta.com';

  @override
  String get emailValidation => 'Geçerli bir e-posta girin';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get passwordValidation => 'Şifre en az 6 karakter olmalı';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get registerButton => 'Kayıt Ol';

  @override
  String get registerTitle => 'Kayıt Ol';

  @override
  String get noAccountPrompt => 'Hesabın yok mu? Kayıt ol';

  @override
  String get hasAccountPrompt => 'Zaten hesabın var mı? Giriş yap';

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
  String get seasonLabel => 'Sezon';

  @override
  String get seasonSummer2025 => 'Yaz 2025';

  @override
  String get seasonWinter202526 => 'Kış 2025-26';

  @override
  String get seasonYearRound => 'Tüm Yıl';

  @override
  String get seasonAny => 'Farketmez / Tüm Sezonlar';

  @override
  String get addSeasonalAlert => 'Hatırlatıcı Ekle';

  @override
  String get createAlertSuccess =>
      'Sezonluk hatırlatıcı başarıyla oluşturuldu.';

  @override
  String get roleSelectionError => 'Lütfen bir rol seçin';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navCategories => 'Kategoriler';

  @override
  String get navCreateListing => 'İlan Ver';

  @override
  String get navMessages => 'Mesajlar';

  @override
  String get navProfile => 'Hesabım';

  @override
  String get profileTitle => 'Hesabım';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get myListings => 'İlanlarım';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get categoryReception => 'Resepsiyon';

  @override
  String get categoryHousekeeping => 'Kat Hizmetleri';

  @override
  String get categoryKitchenChef => 'Mutfak / Aşçı';

  @override
  String get categoryServiceWaiter => 'Servis / Garson';

  @override
  String get categorySecurity => 'Güvenlik';

  @override
  String get categoryAnimation => 'Animasyon';

  @override
  String get categoryManagement => 'Yönetim';

  @override
  String get categoryTechnicalService => 'Teknik Servis';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get regionLabel => 'Turizm bölgesi';

  @override
  String get regionSelectHint => 'Bölge seçin';

  @override
  String get regionRequired => 'Bölge seçmeniz gerekiyor';

  @override
  String get regionsTitle => 'Bölgeler';

  @override
  String get regionsLoadError => 'Bölgeler yüklenemedi.';

  @override
  String activeListingCount(int count) {
    return '$count aktif ilan';
  }

  @override
  String get nearMe => 'Yakınımda';

  @override
  String get nearbyTitle => 'Yakındaki İlanlar';

  @override
  String get nearbyPermissionTitle => 'Konum izni';

  @override
  String get nearbyPermissionExplanation =>
      'Yakınınızdaki iş ilanlarını mesafeye göre göstermek için yalnızca siz bu özelliği kullandığınızda anlık konumunuza erişmemiz gerekiyor.';

  @override
  String get cancelButton => 'Vazgeç';

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
  String get retryButton => 'Tekrar dene';

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
  String get selectDate => 'Tarih seçin';

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
  String get experienceLevelLabel => 'Deneyim';

  @override
  String get educationLevelLabel => 'Eğitim Durumu';

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
}
