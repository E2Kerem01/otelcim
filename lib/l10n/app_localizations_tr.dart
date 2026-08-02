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
}
