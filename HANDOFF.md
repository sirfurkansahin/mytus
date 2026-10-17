# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude), Parca 4b birlesti; arka plan bildirimi sorunu nota alindi

## Durum
- Faz 2 (kurulum) TAMAMLANDI (16 Ekim 2026): GitHub deposu + Actions derlemesi calisiyor, Firebase projesi (mytus, Spark, com.mytus.app) kuruldu, bos uygulama Firebase App Distribution ile kullanicinin realme GT 2 telefonuna kuruldu ve acildi.
- Faz 3 (UX/UI tasarim) TAMAMLANDI ve onaylandi; taslaklar `docs/tasarim/` altinda.
- Siradaki faz: Faz 4a (Surum 1 gelistirme). Basla: imza anahtari + otomatik dagitim, sonra ozellikler (sira kullanici onayiyla).
- Depoda (main dalinda): bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `android/` klasoru (bootstrap akisiyla uretildi), `pubspec.lock`, GitHub Actions akislari, bu belgeler.
- Dogrulandi: paket adi `com.mytus.app` (namespace, applicationId, MainActivity). Ilk "APK derle" akisi (analiz + test + release APK) basarili, APK yaklasik 20 MB.
- Uygulama etiketi "MY TUS" olarak ayarlandi (`AndroidManifest.xml`).

## Siradaki adim
1. Parca 1-4b main'e BIRLESTIRILDI (4b: PR #4, kullanici izniyle).
2. Dal `claude/on-plan-servisi` (main'e HENUZ BIRLESTIRILMEDI, kullanici izni gerekir) icerir: Flutter surumunu 3.47.7'ye sabitleme, on plan servisi (`TimerService`), sayac ekraninda pil uyarisi, olcum paneli (Ayarlar > Sayac testi > "Servis olcumu") ve Ayarlar altinda "derleme no". Actions yesil, Firebase derleme no 37.
3. ACIK SORUN (kullanici karariyla NOTA ALINDI, simdilik cozulmeyecek): arka planda/ekran kilitliyken sure bitince bildirim GELMIYOR (realme GT 2, pil ayari varsayilanda). Sayac dogru calisiyor (uygulamaya donunce sure bitmis gorunur ve puan yazilir). Detay "Bilinen sorunlar" altinda.
4. Sonraki: kullanici "kaldigimiz yerden" dedi: Surum 1 kapanis (arkadaslara dagitim hazirligi). Kullaniciyla sira konusulacak.
5. Surum 2: Google girisi, bulut, grup, puan tablosu, paylasim. Analytics paketi ve google-services.json konusu orada ele alinacak.

## Bilinen sorunlar / riskler
- **ARKA PLAN BILDIRIMI GELMIYOR (17 Ekim 2026, kullanici testi):** F.T. time suresi bitince, telefon kilitliyken ve MY TUS icin pil ayari VARSAYILANDAYKEN bildirim gelmiyor. Pil ayari "kisitlama yok" yapildiginda ilk prototip testleri (A/B/C) gecmisti (~0,1 sn). Ek on plan servisi eklendi, bildirim yine gelmedi. Uygulamada sayac dogru (sure bitmis gorunuyor, puan yaziliyor, bildirim izni acik). Olasiliklar: (1) realme/ColorOS "otomatik baslatma" veya arka plan kisitlamasi alarm yayinini engelliyor, (2) alarm silindi/tetiklenmedi, (3) bildirim kanali/Rahatsiz etme. AYIRT ETMEK ICIN: Ayarlar > Sayac testi: 1 dk baslat, kilitle, 2 dk bekle; "Alarm olcumu" ve "Servis olcumu" kartlarini oku (bu olcum HENUZ YAPILMADI, kullanici sorunu simdilik not etmeyi secti). Gecici cozum: kullaniciya "pil kisitlamasi yok" ayarini yaptirmak (Ayarlar > Arka plan > Pil ayarlarini ac) ve uygulamayi acik tutmak.
- Flutter surumu sabitlenmedi (`channel: stable`). Son derlemede kullanilan surum: Flutter 3.47.7 (Actions "Flutter surumu" bildiriminden). Sabitleme: `build-apk.yml` icinde `flutter-version: 3.47.7` ekle (kullanici onayiyla / Parca 2 oncesi).
- Prototipte on plan servisi (foreground service) yok; alarm `setAlarmClock` ile kuruluyor. Telefon yeniden baslarsa alarm silinir.
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida. Sirlar yoksa derleme debug anahtariyla imzalanir (kurulu uygulamanin uzerine kurulmaz). Imza sertifikasi akis icinde dogrulama bildirimi olarak yazdirilamadi; gunluk (log) indirilemedigi icin kalici anahtarla imzalandigi dolayli olarak (sirlar var, 'Imza anahtarini hazirla' adimi calisti) kabul ediliyor.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.
- `analysis_options.yaml` dosyasina diskte `analyzer.exclude` (build/**, android/**) eklenmis; degisikligi kimin yaptigi bilinmiyor, zararsiz gorundugu icin korundu.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
