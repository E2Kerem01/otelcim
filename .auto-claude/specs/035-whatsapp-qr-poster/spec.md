# WhatsApp Hızlı İletişim & QR Poster Generator

Roadmap `feature-27` (phase-5). Ideation raporu Feature 5.6, MoSCoW
"Must Have" — düşük karmaşıklık, yüksek etki.

## Açıklama

İlan detayından 1 tıkla WhatsApp sohbeti başlatma + işverenin ilanı için
basılabilir QR kodlu poster oluşturması.

## Yapılacaklar

**WhatsApp:**
- `listing_detail_screen.dart`'a "WhatsApp ile Mesaj Gönder" butonu ekle
  (mevcut iletişim/mesaj bölümünün yanına — 023'ün güvenlik kutusuyla
  aynı bölgede olabilir, dikkatli ekle). `url_launcher` zaten pubspec'te
  var: `https://wa.me/<telefon>?text=<url-encoded şablon mesaj>`.
  İşverenin telefon numarası `contactInfo` alanından telefon formatı
  regex'iyle çıkarılabiliyorsa buton görünsün, çıkarılamıyorsa buton
  gizlensin (crash yerine zarif gizleme).
- Mesaj şablonu ilan başlığı + otel adını otomatik doldursun (mevcut
  `feature-13` quick-apply template deseninden ilham al,
  `lib/features/chat/domain/message_template.dart`'a bak).

**QR Poster:**
- `qr_flutter` paketini `pubspec.yaml`'a ekle (yaygın, hafif bir paket).
- Yeni ekran: `lib/features/listings/presentation/listing_qr_poster_screen.dart`
  — ilanın public linkini (paylaşım linkiyle aynı format, `feature-7`'ye
  bak) QR koda çevirip, ilan başlığı + otel adıyla birlikte
  yazdırılabilir/paylaşılabilir bir poster görünümü oluştur (`share_plus`
  ile ekran görüntüsü paylaşımı yeterli, native print entegrasyonu
  gerekmiyor).
- Bu ekrana, sadece ilan sahibi işveren için `listing_detail_screen.dart`'ta
  bir "QR Poster Oluştur" butonu/menü öğesi ekle.
- Router'a `/listing/:id/qr-poster` route'u ekle.

## Acceptance Criteria

- [ ] WhatsApp butonu geçerli telefon olan ilanlarda çalışıyor
- [ ] QR poster ekranı ilan linkini doğru QR koda çeviriyor, paylaşılabiliyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`listing_detail_screen.dart`'a **030** da dokunuyor (lojman kartı) — ikisi
de additive, dikkatli birleştirin. `router.dart`'a sadece kendi route'unu
ekle.
