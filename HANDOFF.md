# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude), Parca 3 kodlandi

## Durum
- Faz 2 (kurulum) TAMAMLANDI (16 Ekim 2026): GitHub deposu + Actions derlemesi calisiyor, Firebase projesi (mytus, Spark, com.mytus.app) kuruldu, bos uygulama Firebase App Distribution ile kullanicinin realme GT 2 telefonuna kuruldu ve acildi.
- Faz 3 (UX/UI tasarim) TAMAMLANDI ve onaylandi; taslaklar `docs/tasarim/` altinda.
- Siradaki faz: Faz 4a (Surum 1 gelistirme). Basla: imza anahtari + otomatik dagitim, sonra ozellikler (sira kullanici onayiyla).
- Depoda (main dalinda): bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `android/` klasoru (bootstrap akisiyla uretildi), `pubspec.lock`, GitHub Actions akislari, bu belgeler.
- Dogrulandi: paket adi `com.mytus.app` (namespace, applicationId, MainActivity). Ilk "APK derle" akisi (analiz + test + release APK) basarili, APK yaklasik 20 MB.
- Uygulama etiketi "MY TUS" olarak ayarlandi (`AndroidManifest.xml`).

## Siradaki adim
1. Parca 1 (sayac prototipi) ve Parca 2 (dersler, konular, notlar, karsilama, alt menu, yerel kayit) main'e BIRLESTIRILDI (PR #1, kullanici izniyle). 6. adim (pil ayari YAPILMADAN alarm testi) HENUZ YAPILMADI.
2. Parca 3 (takvim + tekrar motoru + Bugun ekrani + Konu'da tekrar plani) KODLANDI, dal `claude/takvim-tekrar`. Kurallar DECISIONS.md "Takvim ve tekrar motoru" bolumunde (benim yorumlarim isaretli). BEKLENEN: kullanici telefonda dener; main'e birlestirme yine kullanicinin acik iznini gerektirir (PR + REST ile birlestirme; `gh pr merge` GraphQL engelli).
3. Sonraki: Parca 4 (Bugun/Ilerleme/Ayarlar: tur sayisi ve gunluk sinir ayari; gercek F.T. time ekrani 25/5/15, 4 dongude uzun mola; puan = tamamlanan odak dakikasi). Her biri ayri dal.
4. Analytics paketi ve google-services.json konusu Surum 2'de ele alinacak.

## Bilinen sorunlar / riskler
- Flutter surumu sabitlenmedi (`channel: stable`). Son derlemede kullanilan surum: Flutter 3.47.7 (Actions "Flutter surumu" bildiriminden). Sabitleme: `build-apk.yml` icinde `flutter-version: 3.47.7` ekle (kullanici onayiyla / Parca 2 oncesi).
- Prototipte on plan servisi (foreground service) yok; alarm `setAlarmClock` ile kuruluyor. Telefon yeniden baslarsa alarm silinir.
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida. Sirlar yoksa derleme debug anahtariyla imzalanir (kurulu uygulamanin uzerine kurulmaz). Imza sertifikasi akis icinde dogrulama bildirimi olarak yazdirilamadi; gunluk (log) indirilemedigi icin kalici anahtarla imzalandigi dolayli olarak (sirlar var, 'Imza anahtarini hazirla' adimi calisti) kabul ediliyor.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.
- `analysis_options.yaml` dosyasina diskte `analyzer.exclude` (build/**, android/**) eklenmis; degisikligi kimin yaptigi bilinmiyor, zararsiz gorundugu icin korundu.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
