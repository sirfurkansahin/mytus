# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude)

## Durum
- Faz 2 (kurulum) devam ediyor.
- Depoda: bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `android/` klasoru (bootstrap akisiyla uretildi), `pubspec.lock`, GitHub Actions akislari, bu belgeler.
- Dogrulandi: paket adi `com.mytus.app` (namespace, applicationId, MainActivity). Ilk "APK derle" akisi (analiz + test + release APK) basarili, APK yaklasik 20 MB.
- Uygulama etiketi "MY TUS" olarak ayarlandi (`AndroidManifest.xml`).

## Siradaki adim
1. Kullanici son basarili "APK derle" calismasindan `mytus-apk` dosyasini indirir (GitHub > Actions > calisma > Artifacts), zip'ten cikan `app-release.apk` dosyasini telefonuna kurar. Bu adim GitHub'a girisli tarayici ister.
2. Firebase projesini kullaniciyla birlikte olustur (Spark plani, Android uygulamasi: com.mytus.app). `google-services.json` Faz 2 sonunda degil, Surum 2'de Firebase eklenirken depoya girer.
3. Firebase App Distribution'a ilk APK'yi yukle, kullanici kendi e-postasini test kullanicisi olarak ekler.

## Bilinen sorunlar / riskler
- Flutter surumu sabitlenmedi (`channel: stable`) ve ilk derlemede hangi surumun kullanildigi kaydedilmedi. Sabitleme: `build-apk.yml` icinde `flutter-version` ekle.
- APK imzalama: release APK varsayilan (debug) anahtarla imzali. Her derlemede imza degisebilir; kurulu uygulama guncellenemez. Surum 1 dagitimindan ONCE kalici anahtar GitHub Secrets'a konmali (`DECISIONS.md` sonundaki nota bak).
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.
- `analysis_options.yaml` dosyasina diskte `analyzer.exclude` (build/**, android/**) eklenmis; degisikligi kimin yaptigi bilinmiyor, zararsiz gorundugu icin korundu.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
