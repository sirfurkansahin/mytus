# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude)

## Durum
- Faz 2 (kurulum) TAMAMLANDI (16 Ekim 2026): GitHub deposu + Actions derlemesi calisiyor, Firebase projesi (mytus, Spark, com.mytus.app) kuruldu, bos uygulama Firebase App Distribution ile kullanicinin realme GT 2 telefonuna kuruldu ve acildi.
- Faz 3 (UX/UI tasarim) TAMAMLANDI ve onaylandi; taslaklar `docs/tasarim/` altinda.
- Siradaki faz: Faz 4a (Surum 1 gelistirme). Basla: imza anahtari + otomatik dagitim, sonra ozellikler (sira kullanici onayiyla).
- Depoda: bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `android/` klasoru (bootstrap akisiyla uretildi), `pubspec.lock`, GitHub Actions akislari, bu belgeler.
- Dogrulandi: paket adi `com.mytus.app` (namespace, applicationId, MainActivity). Ilk "APK derle" akisi (analiz + test + release APK) basarili, APK yaklasik 20 MB.
- Uygulama etiketi "MY TUS" olarak ayarlandi (`AndroidManifest.xml`).

## Siradaki adim
1. Faz 4a: parca sirasini kullanicidan onayla, her parcayi ayri dalda gelistir, Actions'ta dogrula, APK'yi kullaniciya ilet.
2. Parca 0 (imza + otomatik dagitim) uygulandi; kullanici GitHub sirlarini ekledikten sonra dagitimi dogrula.
3. Analytics paketi ve google-services.json konusu Surum 2'de ele alinacak (karar: Analytics Surum 2'de eklenir).

## Bilinen sorunlar / riskler
- Flutter surumu sabitlenmedi (`channel: stable`) ve ilk derlemede hangi surumun kullanildigi kaydedilmedi. Sabitleme: `build-apk.yml` icinde `flutter-version` ekle.
- APK imzalama: release APK varsayilan (debug) anahtarla imzali. Her derlemede imza degisebilir; kurulu uygulama guncellenemez. Surum 1 dagitimindan ONCE kalici anahtar GitHub Secrets'a konmali (`DECISIONS.md` sonundaki nota bak).
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.
- `analysis_options.yaml` dosyasina diskte `analyzer.exclude` (build/**, android/**) eklenmis; degisikligi kimin yaptigi bilinmiyor, zararsiz gorundugu icin korundu.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
