# Güvenlik İpuçları Kutusu (İlan Detayı)

Sahibinden.com analizinden çıkan düşük efor / yüksek etki bir bulgu. İlan
detay ekranına, dolandırıcılığa karşı sabit bir uyarı kutusu ekle.

## Açıklama

Sahibinden'in her ilan detay sayfasında, iletişim bilgilerinin hemen
yanında şöyle bir kutu var: "İşveren ile yüz yüze görüşmeyi tercih edin.
Kişisel ve finansal bilgilerinizi paylaşmayın. Herhangi bir ödeme talep
eden ilanlardan kaçının." Otelcim'de böyle bir sabit uyarı yok.
`listing_detail_screen.dart`'a benzer, Otelcim'in bağlamına uyarlanmış
bir "Güvenlik İpuçları" kutusu eklenecek.

## Rationale

Roadmap'in en başından beri platform güvenliği/güven inşası (feature-6
Report Listing & User, feature-10 Employer Verification) ana
farklılaştırıcılardan biri. Sahibinden, Kariyer.net gibi rakiplerde
sahte ilan/yüksek ücret talep eden dolandırıcılık pain point'i defalarca
işaretlenmiş (pain-1-3, pain-2-6, pain-3-3, pain-3-4). Kalıcı bir
güvenlik uyarısı, ek bir backend/model değişikliği gerektirmeden bu
riski azaltan çok ucuz bir güven sinyali.

## Yapılacaklar

- `lib/features/listings/presentation/listing_detail_screen.dart` içine,
  iletişim bilgisi / "Mesaj Gönder" bölümünün hemen yakınına sabit bir
  bilgi kutusu (ikon + kısa metin) ekle. Kart/Container + shield ikonu
  (`Icons.shield_outlined` veya benzeri) kullan, mevcut tasarım diline
  (Material 3, kart stilleri) uy.
- Metin önerisi (birebir kullanmak zorunda değilsin, ama şu noktaları
  kapsasın): işvereni/iş yerini bizzat ziyaret etmeden ilk maaşı peşin
  istemesi, kimlik/kredi kartı bilgisi istemesi gibi durumlara karşı
  uyarı; şüpheli bir şey görürse "Şikayet Et" (mevcut report akışı,
  feature-6) ile bildirmesini söyle.
- Kutu, listing detail sayfasının HER YERİNDE (hem iş arayan hem işveren
  görüntülediğinde) görünsün — role'e göre gizleme gerekmiyor.
- İsteğe bağlı: kutuya küçük bir "X" ile kapatma/gizleme eklenebilir ama
  zorunlu değil, kalıcı kalması tercih edilir (sahibinden'de kapatılamıyor).

## User Stories

- Bir iş arayan olarak, bir ilanla iletişime geçmeden önce dolandırıcılık
  belirtilerine karşı hatırlatma görmek istiyorum.

## Acceptance Criteria

- [ ] `listing_detail_screen.dart`'ta iletişim/mesaj bölümünün yakınında
      sabit bir "Güvenlik İpuçları" kutusu var
- [ ] Kutu metni ödeme talebi, kişisel/finansal bilgi paylaşımı ve
      şikayet etme konularını kapsıyor
- [ ] Tasarım mevcut Material 3 tema ve kart stiliyle tutarlı
- [ ] Metin `app_tr.arb`/`app_en.arb`'a eklendi (hardcoded string yok)
- [ ] `flutter test` geçiyor

## Bağımlılıklar

Yok. Sadece `listing_detail_screen.dart`'a dokunuyor, diğer spec'lerle
(024, 025) çakışma riski yok.
