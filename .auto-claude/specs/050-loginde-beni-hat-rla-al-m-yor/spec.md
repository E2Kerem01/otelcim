# Quick Spec: Fix "Beni Hatırla" (Remember Me) Not Working

## Task
Login ekranındaki "Beni Hatırla" checkbox'ı beklenen davranışı sağlamıyor — bir platformda (muhtemelen mobil) veya belirli koşullarda çalışmıyor.

## Investigation Notes (başlangıç noktası, kesin kök neden değil — önce doğrula)
- `lib/shared/services/auth_service.dart` içinde `signIn()` (~satır 63) ve `signInWithSmsCode()` (~satır 119) bir `rememberMe` parametresi alıyor, ama `_auth.setPersistence(...)` çağrısı **sadece `if (kIsWeb)` bloğunun içinde**. Yani mobilde (Android/iOS/Windows/macOS) checkbox hiçbir şey yapmıyor — native Firebase Auth SDK oturumu platform varsayılanına göre (genelde kalıcı) tutuyor, kullanıcı checkbox'ı işaretlemese bile.
- Web tarafında mantık doğru görünüyor (`Persistence.LOCAL` vs `Persistence.SESSION`, sign-in çağrısından önce `await` ediliyor).
- `lib/features/auth/presentation/login_screen.dart` içinde checkbox state (`_rememberMe`, satır ~30) ve iki sign-in çağrısına geçirilmesi (satır ~108, ~158) doğru wire edilmiş görünüyor.
- **İlk adım:** Bug raporunu hangi platformda (web mi mobil mi) tekrar ürettiğini doğrula — kök neden ona göre değişir.

## Suggested Fix Direction
- **Mobil:** Native SDK'da "session-only" (tarayıcı sekmesi kapanınca biten) bir persistence modu yok. Pratik çözüm: `rememberMe=false` seçildiğinde bunu local/secure storage'a bir flag olarak yaz, app başlangıcında (`main.dart` / auth bootstrap) bu flag `false` ise otomatik `signOut()` tetikle.
- **Web:** Sorun web'de tekrar üretilebiliyorsa, `setPersistence` çağrısının sign-in credential çağrısından önce gerçekten tamamlandığını (race condition olmadığını) doğrula.

## Files to Reference
- `lib/shared/services/auth_service.dart` — `signIn`, `signInWithSmsCode`
- `lib/features/auth/presentation/login_screen.dart` — checkbox + submit handler'lar

## Verification
- [ ] Web: "Beni hatırla" işaretliyken login → tarayıcıyı kapat/aç → oturum devam ediyor
- [ ] Web: "Beni hatırla" işaretsizken login → tarayıcıyı kapat/aç → oturum sonlanmış, login ekranına düşüyor
- [ ] Mobil: "Beni hatırla" işaretsizken login → app'i tamamen kapat/aç → oturum sonlanmış
- [ ] Mobil: "Beni hatırla" işaretliyken login → app'i tamamen kapat/aç → oturum devam ediyor
