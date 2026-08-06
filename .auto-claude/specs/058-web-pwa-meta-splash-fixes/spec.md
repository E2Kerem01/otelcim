# Web: PWA, Erişilebilirlik, Eksik Splash Görselleri, FCM Service Worker

## Öncelik: Yüksek (kullanıcı deneyimi + erişilebilirlik + gerçek özellik kırılması)

## Bulgular (hepsi `web/index.html` + yeni dosyalar, doğrulandı)

### 1. Service worker her sayfa yüklemesinde iptal ediliyor
- `web/index.html:130-137`:
  ```html
  <script>
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for (let registration of registrations) { registration.unregister(); }
      });
    }
  </script>
  ```
- Etki: PWA önbellekleme ve çevrimdışı çalışma tamamen devre dışı.
- **Fix**: Bu script bloğunu tamamen kaldır. Flutter web'in standart service worker mekanizması (`flutter_bootstrap.js` üzerinden) zaten kendi service worker'ını yönetiyor, elle unregister etmeye gerek yok.

### 2. Kullanıcı yakınlaştırması (zoom) engellenmiş — erişilebilirlik
- `web/index.html:114`: `<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport">`
- **Fix**: `maximum-scale=1.0, user-scalable=no` kısımlarını kaldır, sadece `width=device-width, initial-scale=1.0` bırak.

### 3. Splash ekranı görselleri mevcut değil — 404 + bozuk açılış ekranı
- `web/index.html:117-121` şu dosyaları referans veriyor: `splash/img/light-1x.png`, `light-2x.png`, `light-3x.png`, `light-4x.png`, `dark-1x.png`, `dark-2x.png`, `dark-3x.png`, `dark-4x.png` — ama `web/splash/img/` klasörü PROJEDE YOK (doğrulandı, `ls web/splash/img/` → "No such file or directory").
- **Fix seçenekleri** (birini uygula):
  - (Tercih edilen, hızlı) `web/icons/` altındaki mevcut app icon'unu (`Icon-512.png` gibi) kullanarak basit, tek renkli/logo içeren 8 PNG üret (light/dark varyantları aynı olabilir, sadece arka plan rengi farklı olsun — beyaz/koyu gri) ve `web/splash/img/` altına koy.
  - Ya da `web/index.html`'deki `<picture id="splash">` bloğunu, projede zaten var olan bir görsele (örn. `icons/Icon-192.png`) işaret edecek şekilde basitleştir.
- Hangi yolu seçersen seç, sonuçta tarayıcıda bu 8 istek için 404 KALMAMALI.

### 4. Web push bildirimleri için service worker dosyası eksik
- `lib/main.dart:26`: `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);` çağrılıyor ama web'de arka plan/sekme kapalıyken bildirim alabilmek için `web/firebase-messaging-sw.js` dosyası GEREKLİ ve projede YOK.
- **Fix**: `web/firebase-messaging-sw.js` oluştur. Standart FlutterFire deseni:
  ```js
  importScripts("https://www.gstatic.com/firebasejs/10.x.x/firebase-app-compat.js");
  importScripts("https://www.gstatic.com/firebasejs/10.x.x/firebase-messaging-compat.js");

  firebase.initializeApp({
    // lib/firebase_options.dart (varsa) içindeki web config değerleriyle doldur
  });

  const messaging = firebase.messaging();
  ```
  Firebase config değerlerini `lib/firebase_options.dart` dosyasından (proje içinde muhtemelen mevcut) veya `firebase.json`/mevcut web init kodundan al — YENİ/UYDURMA bir API key kullanma, projedeki gerçek değerleri kullan.

### 5. Canonical / Open Graph URL'leri yanlış domaine işaret ediyor (düşük öncelik, dikkatli ele al)
- `web/index.html:23,29,30,33-36`: `https://www.otelcim.app/` kullanılıyor, ama proje `otelcim.vercel.app` üzerinde yayında (mevcut Vercel deployment).
- **BU MADDEYİ DEĞİŞTİRMEDEN ÖNCE**: `www.otelcim.app` domain'inin gerçekten aktif/planlanan bir custom domain olup olmadığını proje sahibine SORMADAN varsayma. Eğer `vercel.json`'da veya başka bir yapılandırma dosyasında custom domain referansı görürsen (aktif olduğuna işaret), dokunma. Böyle bir kanıt yoksa, bu maddeyi atla ve bulgunu commit mesajında/PR açıklamasında not düş — riskli bir tahmin yapıp yanlış domain'e sabitleme.

## Dosya Çakışma Uyarısı
Sadece `web/` klasörü + yeni `web/firebase-messaging-sw.js`. Başka spec bu dosyalara dokunmuyor.

## Acceptance Criteria
- [ ] Service worker unregister script'i kaldırıldı
- [ ] Viewport'ta zoom kısıtlaması kaldırıldı
- [ ] Splash ekranı görselleri var, 404 yok, açılışta boş/bozuk ekran görünmüyor
- [ ] `web/firebase-messaging-sw.js` oluşturuldu, doğru Firebase config ile
- [ ] Madde 5 (canonical/OG domain) için ya kanıta dayalı bir düzeltme yapıldı ya da PR açıklamasında net bir not bırakıldı
- [ ] `flutter build web` hatasız tamamlanıyor (mümkünse dene)
