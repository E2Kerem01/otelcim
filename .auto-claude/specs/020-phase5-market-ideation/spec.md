# Phase 5 Fikir Üretimi — Pazar & Rekabet Araştırması

Bu, kod yazma görevi **değil**, araştırma/fikir üretme görevidir. Çıktı bir
PR değil, bir rapor dosyasıdır. `.auto-claude/specs/000-GENERAL-RULES.md`
içindeki repo/branch kuralları bu spec için geçerli değildir; sadece kapsam
disiplini ve dosya yeri kuralı geçerli.

## Açıklama

Otelcim'in mevcut 21 feature'lık roadmap'i (Phase 1-4) tamamlandı ya da
tamamlanma aşamasında (`.auto-claude/roadmap/roadmap.json`'a bak). Bu görev,
roadmap'in ötesinde, Türkiye otelcilik/turizm işe alım pazarı için yeni bir
"Phase 5" için aday feature'lar üretmek.

## Yapılacaklar

- `.auto-claude/roadmap/roadmap.json` ve `roadmap_discovery.json` dosyalarını
  oku — mevcut vizyonu, hedef kitleyi, rakip analizini (`competitive_context`)
  ve daha önce ele alınan pain point'leri anla. Aynı pain point'leri tekrar
  önerme.
- Güncel (2026) pazar/rakip taramasını tazele: Sahibinden, Kariyer.net,
  Yenibiris, SecretCV dışında yeni/değişen rakipler var mı, otelcilik
  sektörüne özel yeni platformlar çıktı mı araştır.
- En az 8-12 aday feature fikri üret. Her biri için:
  - Başlık, kısa açıklama
  - Rationale (neden önemli, hangi pain point'i/fırsatı ele alıyor)
  - Tahmini complexity (low/medium/high) ve impact (low/medium/high)
  - Bağımlılıkları (hangi mevcut feature'lara dayanıyor)
- Fikirleri örnekler: AI destekli CV/profil eşleştirme, uygulama içi mülakat
  planlama, işveren abonelik katmanları, video-tanıtım profilleri, WhatsApp
  Business entegrasyonu, referans/tavsiye programı — ama bunlarla sınırlı
  kalma, kendi araştırmanla genişlet.
- Çıktıyı mevcut roadmap.json'daki `features` şemasına benzer yapıda,
  okunabilir bir markdown rapor olarak yaz: `.auto-claude/ideation/phase5-market-research.md`.
- Rapor sonunda, en yüksek öncelikli 5 feature için MoSCoW (must/should/
  could/won't) önerisi sun.

## Kapsam Dışı

- Kod değişikliği yapma, PR açma. Sadece rapor.

## Acceptance Criteria

- [ ] `.auto-claude/ideation/phase5-market-research.md` dosyası oluşturuldu
- [ ] En az 8 aday feature, her biri rationale + complexity/impact ile
- [ ] Güncel pazar taraması mevcut rakip analizinden farklı/ek bilgi içeriyor
- [ ] En yüksek öncelikli 5 feature için MoSCoW önceliklendirmesi var
- [ ] Rapor, mevcut roadmap'teki feature'larla çakışmıyor (tekrar üretmiyor)
