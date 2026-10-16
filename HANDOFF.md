# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude), Parca 2 kodlandi

## Durum
- Faz 2 (kurulum) TAMAMLANDI (16 Ekim 2026): GitHub deposu + Actions derlemesi calisiyor, Firebase projesi (mytus, Spark, com.mytus.app) kuruldu, bos uygulama Firebase App Distribution ile kullanicinin realme GT 2 telefonuna kuruldu ve acildi.
- Faz 3 (UX/UI tasarim) TAMAMLANDI ve onaylandi; taslaklar `docs/tasarim/` altinda.
- Siradaki faz: Faz 4a (Surum 1 gelistirme). Basla: imza anahtari + otomatik dagitim, sonra ozellikler (sira kullanici onayiyla).
- Depoda (main dalinda): bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `android/` klasoru (bootstrap akisiyla uretildi), `pubspec.lock`, GitHub Actions akislari, bu belgeler.
- Dogrulandi: paket adi `com.mytus.app` (namespace, applicationId, MainActivity). Ilk "APK derle" akisi (analiz + test + release APK) basarili, APK yaklasik 20 MB.
- Uygulama etiketi "MY TUS" olarak ayarlandi (`AndroidManifest.xml`).

## Siradaki adim
1. Parca 1 (sayac prototipi) kullanici tarafindan realme GT 2'de test edildi: A (ekran kilitli), B (arka plan), C (uygulama kapali) GECTI, alarm gecikmesi ~0,1 sn. 6. adim (pil ayari YAPILMADAN test) HENUZ YAPILMADI.
2. Dal `claude/ft-sayac-prototip` main'e HENUZ birlestirilmedi: otomatik guvenlik denetimi "inceleme olmadan birlestirme" diyerek engelledi. Kullanici GitHub'da Pull requests sekmesinden birlestirebilir (veya acikca izin verirse REST ile birlestirilir). `claude/ders-konu-not` dali bu dalin USTUNDE kurulu; ikisi birlikte birlesecek.
3. Parca 2 (dersler, konular, notlar, karsilama, alt menu, yerel dosya kaydi) KODLANDI, dalda `claude/ders-konu-not`. Actions yesil, `dagit=true` ile Firebase'e yuklendi (run 38937564381). BEKLENEN: kullanici telefonda dener (karsilama, ders/konu/not ekleme, uygulamayi kapatip acinca verinin durmasi, Bugun'de sinav tarihi degistirme).
4. Sonraki: Parca 3 (takvim + tekrar motoru, birim testli; takvime yerlestirme iki yolla), Parca 4 (Bugun/Ilerleme/Ayarlar + puan). Her biri ayri dal.
5. Analytics paketi ve google-services.json konusu Surum 2'de ele alinacak.

## Bilinen sorunlar / riskler
- Flutter surumu sabitlenmedi (`channel: stable`). Son derlemede kullanilan surum: Flutter 3.47.7 (Actions "Flutter surumu" bildiriminden). Sabitleme: `build-apk.yml` icinde `flutter-version: 3.47.7` ekle (kullanici onayiyla / Parca 2 oncesi).
- Prototipte on plan servisi (foreground service) yok; alarm `setAlarmClock` ile kuruluyor. Telefon yeniden baslarsa alarm silinir.
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida. Sirlar yoksa derleme debug anahtariyla imzalanir (kurulu uygulamanin uzerine kurulmaz). Imza sertifikasi akis icinde dogrulama bildirimi olarak yazdirilamadi; gunluk (log) indirilemedigi icin kalici anahtarla imzalandigi dolayli olarak (sirlar var, 'Imza anahtarini hazirla' adimi calisti) kabul ediliyor.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.
- `analysis_options.yaml` dosyasina diskte `analyzer.exclude` (build/**, android/**) eklenmis; degisikligi kimin yaptigi bilinmiyor, zararsiz gorundugu icin korundu.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
