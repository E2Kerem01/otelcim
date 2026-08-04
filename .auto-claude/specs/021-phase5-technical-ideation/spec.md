# Phase 5 Fikir Üretimi — Teknik Altyapı & Ölçeklenme Değerlendirmesi

Bu da 020 gibi kod yazma değil, araştırma/denetim görevidir. Çıktı bir rapor
dosyasıdır, PR değil.

## Açıklama

Otelcim büyüdükçe (kullanıcı sayısı, ilan sayısı, sezonluk trafik artışı)
mevcut teknik altyapının nerelerde zorlanacağını tespit et ve bir "Phase 5
teknik roadmap" önerisi hazırla.

## Yapılacaklar

- **Firestore maliyet/ölçek denetimi**: mevcut sorgu paternlerini
  (`lib/features/**/services/*.dart`) tara, N+1 okuma riski olan yerleri,
  pagination'ı olmayan sorguları, gereksiz `snapshots()` dinlemelerini
  listele. `firestore.indexes.json`'daki index'lerin sorgularla uyumlu olup
  olmadığını kontrol et.
- **Güvenlik kuralları**: repo kökünde `firestore.rules` dosyası yok — bu
  başlı başına bir bulgu, raporda ayrıca vurgula (güvenlik kurallarının
  version-control'e alınmamış olması ciddi bir risk). Firebase konsolundaki
  mevcut kuralları (erişimin varsa) veya kod içindeki erişim varsayımlarını
  inceleyerek olması gereken kuralları taslakla.
- **Moderasyon otomasyonu**: `lib/features/admin/` altındaki mevcut admin
  panelini incele (rapor, doğrulama, banner reklam yönetimi var). Otomatik
  içerik moderasyonu (örn. spam/scam ilan tespiti) için ne eksik, ne
  önerilir.
- **Analitik/BI**: `firebase_analytics` entegre ama büyüme metrikleri için
  (aktif ilan, kullanıcı, mesajlaşma oranı — roadmap'teki `success_metrics`)
  bir dashboard/BI çözümü var mı, yoksa neye ihtiyaç var.
- **CI/CD**: `.github/workflows/` altında `deploy_web.yml` (GitHub Pages),
  `ios_build.yml`, `pr_checks.yml` var — **Android release pipeline'ı yok**.
  Bunu ve eksik gördüğün diğer CI/CD boşluklarını raporla.
- Çıktıyı `.auto-claude/ideation/phase5-technical-audit.md` dosyasına yaz:
  her bulgu için risk seviyesi (low/medium/high) ve önerilen aksiyon.
- Sonuçları, teknik roadmap için 5-8 aday "teknik feature/iyileştirme"
  maddesi olarak özetle (roadmap.json'daki feature şemasına benzer:
  başlık, rationale, complexity, impact).

## Kapsam Dışı

- Kod değişikliği yapma, PR açma, güvenlik kuralı dosyasını fiilen oluşturup
  deploy etme (sadece taslak/öneri raporda kalsın — güvenlik kuralı gibi
  hassas bir değişiklik ayrı, insan onaylı bir iş olmalı).

## Acceptance Criteria

- [ ] `.auto-claude/ideation/phase5-technical-audit.md` dosyası oluşturuldu
- [ ] Firestore sorgu/index denetimi somut dosya referanslarıyla yapıldı
- [ ] Firestore güvenlik kurallarının eksikliği ayrı ve net şekilde
      raporlandı
- [ ] Android CI/CD boşluğu ve varsa diğer CI/CD eksikleri raporlandı
- [ ] Her bulgu risk seviyesi + önerilen aksiyon ile listelendi
- [ ] 5-8 aday teknik roadmap maddesi, rationale/complexity/impact ile sunuldu
