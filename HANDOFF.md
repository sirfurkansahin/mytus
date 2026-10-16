# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude), Parca 4a kodlandi

## Durum
- Faz 2 (kurulum) TAMAMLANDI (16 Ekim 2026): GitHub deposu + Actions derlemesi calisiyor, Firebase projesi (mytus, Spark, com.mytus.app) kuruldu, bos uygulama Firebase App Distribution ile kullanicinin realme GT 2 telefonuna kuruldu ve acildi.
- Faz 3 (UX/UI tasarim) TAMAMLANDI ve onaylandi; taslaklar `docs/tasarim/` altinda.
- Siradaki faz: Faz 4a (Surum 1 gelistirme). Basla: imza anahtari + otomatik dagitim, sonra ozellikler (sira kullanici onayiyla).
- Depoda (main dalinda): bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `android/` klasoru (bootstrap akisiyla uretildi), `pubspec.lock`, GitHub Actions akislari, bu belgeler.
- Dogrulandi: paket adi `com.mytus.app` (namespace, applicationId, MainActivity). Ilk "APK derle" akisi (analiz + test + release APK) basarili, APK yaklasik 20 MB.
- Uygulama etiketi "MY TUS" olarak ayarlandi (`AndroidManifest.xml`).

## Siradaki adim
1. Parca 1-3 main'e BIRLESTIRILDI (Parca 3: PR #2, kullanici izniyle). Pil ayari YAPILMADAN alarm testi (6. adim) hala yapilmadi.
2. Parca 4a (Ayarlar + gercek F.T. time + odak puani) KODLANDI, dal `claude/ft-ayarlar-puan`, Actions yesil, `dagit=true` ile Firebase'e yuklendi. Kurallar DECISIONS.md "Ayarlar, F.T. time ve puan" bolumunde (benim yorumlarim isaretli). BEKLENEN: kullanici telefonda dener; main'e birlestirme icin kullanicinin acik izni gerekir (PR + REST ile birlestirme).
3. Sonraki: Parca 4b = Ilerleme ekrani (Bugun'un sag ustunden; hafta konu/dongu/odak suresi, gunluk odak grafigi, en cok calisilan dersler; veri hazir: `PlanDeposu.odaklar`, `puanGun`, `puanHafta`). Sonra Surum 1 kapanis (README/kullanim notlari, hata duzeltmeleri), sonra Surum 2.
4. Analytics paketi ve google-services.json konusu Surum 2'de ele alinacak.

## Bilinen sorunlar / riskler
- Flutter surumu sabitlenmedi (`channel: stable`). Son derlemede kullanilan surum: Flutter 3.47.7 (Actions "Flutter surumu" bildiriminden). Sabitleme: `build-apk.yml` icinde `flutter-version: 3.47.7` ekle (kullanici onayiyla / Parca 2 oncesi).
- Prototipte on plan servisi (foreground service) yok; alarm `setAlarmClock` ile kuruluyor. Telefon yeniden baslarsa alarm silinir.
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida. Sirlar yoksa derleme debug anahtariyla imzalanir (kurulu uygulamanin uzerine kurulmaz). Imza sertifikasi akis icinde dogrulama bildirimi olarak yazdirilamadi; gunluk (log) indirilemedigi icin kalici anahtarla imzalandigi dolayli olarak (sirlar var, 'Imza anahtarini hazirla' adimi calisti) kabul ediliyor.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.
- `analysis_options.yaml` dosyasina diskte `analyzer.exclude` (build/**, android/**) eklenmis; degisikligi kimin yaptigi bilinmiyor, zararsiz gorundugu icin korundu.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
