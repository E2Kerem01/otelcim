# Yapay Zeka Destekli Aday-İlan Uyum Skorlaması

İlan gereksinimleri (dil, deneyim, ehliyet, lokasyon) ile aday profilini karşılaştırıp her iki tarafa % uyum skoru gösterme.

## Rationale
İşverenlerin onlarca uygunsuz mesajı incelemesini engeller, iş arayanların kabul şansı yüksek ilanlara yönelmesini sağlar.

## User Stories
- As a job seeker, I want to see how well I match a listing before messaging so I focus on realistic opportunities

## Acceptance Criteria
- [ ] İlan kartında/detayında adayın profiline göre yaklaşık uyum skoru gösteriliyor
- [ ] Skor hesaplaması deneyim/eğitim (feature-24 experience/education alanları), lokasyon, dil bilgisine dayanıyor
- [ ] Skorlama client-side basit bir ağırlıklandırma ile başlıyor (harici AI servisi zorunlu değil)
