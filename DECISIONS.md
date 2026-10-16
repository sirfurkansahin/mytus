# DECISIONS.md: Kararlar

Son guncelleme: 16 Ekim 2026. Bu kararlar kullanici tarafindan onaylandi. Degistirmeden once kullaniciya sor.

| Konu | Karar |
|---|---|
| Urun | Calisma sureci takibi + planlama. Soru bankasi degil. Tibbi icerik yok. |
| Kullanicilar | Kullanicinin arkadaslari, 2-10 kisi, hepsi Android ve 18+. Ucretsiz. |
| Uygulama adi / modul | MY TUS / "F.T. time" (odak sayaci modulu) |
| Paket adi | com.mytus.app |
| Teknoloji | Flutter + Firebase Spark. Puan hesabi istemcide. |
| Surumler | Surum 1: planlama + takvim + F.T. time, hesapsiz/yerel. Surum 2: Google girisi, bulut, davet kodlu grup, haftalik puan tablosu, istege bagli konu paylasimi, KVKK ekranlari |
| Veri (Surum 2) | Takma ad + e-posta + calisma verisi. Notlar ozel, asla paylasilmaz. |
| Puan tablosu | Haftalik sifirlanir |
| Paylasim | Istege bagli (opt-in), yalnizca konu adlari |
| Plan olusturma | Her yeni planda sinav tarihi sorulur |
| Hazir icerik | Hazir DERS ADI listesi. Temel: Anatomi, Histoloji ve Embriyoloji, Fizyoloji, Biyokimya, Mikrobiyoloji, Patoloji, Farmakoloji. Klinik: Dahiliye, Pediatri, Genel Cerrahi, Kadin Hastaliklari ve Dogum. Dersler Temel/Klinik gruplarinda durur, kullanici iki gruba da kendi dersini ekleyebilir. Liste guncel OSYM kilavuzuyla dogrulanmadi. |
| Dagitim | Firebase App Distribution |
| KVKK | Hafif uyum: aydinlatma metni, ilk giriste onay, hesap/veri silme, minimum veri |
| Gelir | Yok |
| Derleme | GitHub Actions |
| Yapay zeka ozelligi | Ileride dusunulecek |
| Tasarim | Faz 3 ekran taslaklari ONAYLANDI (16 Ekim 2026). Kopya: `docs/tasarim/`. Ana renk mor, tema telefona uyar, alt menu Bugun/Dersler/Takvim/F.T. time. |
| Takvime yerlestirme | Iki yol da olacak: konu detayinda "Takvime ekle" (gun secilir) ve takvimde gune dokunup "+ Konu yerlestir". |
| Puan kurali | Tamamlanan odak suresi kadar puan (ornek: 1 dakika = 1 puan). Sure ayarindan bagimsiz. Yalnizca TAMAMLANAN donguler puan kazandirir (yarim birakilan puan getirmez), kullanici karari 16 Ekim 2026. |
| F.T. time varsayilan sureler | 25 dk calisma, 5 dk kisa mola, 15 dk uzun mola, her 4 dongude bir uzun mola. Kullanici degistirebilir. |
| Firebase projesi | Ad: mytus, Spark plani, Google hesabi: kullanicinin kendi hesabi. Google Analytics ACIK (kullanici karari, 16 Ekim 2026). |
| Analytics sonucu | Analytics, cihaz/kullanim verisi toplar. Uygulamaya eklendiginde aydinlatma metnine yazilmali ve ilk giriste onay alinmali. KARAR (16 Ekim 2026): Analytics SDK'si Surum 2'de, Google girisi ve KVKK ekranlariyla birlikte eklenecek. Surum 1 hicbir veriyi cihazdan cikarmaz. |

## Teknik kararlar (kullanici teknik secimleri bana birakti, 16 Ekim 2026)
| Konu | Karar ve neden |
|---|---|
| F.T. time sayac mantigi | Saniye saymak yerine BITIS SAATI saklanir; kalan sure her seferinde saatten hesaplanir (`lib/features/ft_time/ft_timer.dart`). Uygulama kapansa veya telefon uyusa bile sure dogru kalir. Duvar saati (DateTime.now) kullanilir, cunku Android alarmi da duvar saatine baglidir; kullanici telefonun saatini elle degistirirse sayac sapar (kabul edildi). |
| Sure bitince uyari | `AlarmManager.setAlarmClock` (Android'in "saat alarmi" turu): pil tasarrufundan en az etkilenen alarm turu, ayrica "tam zamanli alarm" izni istemez. Bildirim + titresim (bildirim kanalindan), kilit ekraninda gorunur, ses yok (kullanici karari 2-a). |
| Calisirken bildirim | Geri sayimli (chronometer) kalici bildirim; sistem kendisi gosterir, uygulama calismasa da akar. On plan servisi (foreground service) prototipte KULLANILMADI; olcum yetersizse eklenecek. |
| Ek paket kullanmama (Parca 1) | Bildirim/alarm/kayit icin ucuncu taraf paket kullanilmadi, kucuk Kotlin kodu yazildi (`android/.../TimerNotifier.kt`, `TimerAlarmReceiver.kt`, `MainActivity.kt`). Neden: kod yerelde derlenemiyor (yalnizca Actions'ta); paketlerin surum/Gradle uyumsuzluklari (ornegin bazi bildirim paketleri ek Gradle ayari ister) kor calisirken risk. Android'in kendi siniflari sabit ve bilinen. Kalici veri depolama secimi (Parca 2) ayri karar. |
| Prototip kapsami | Tek test ekrani (1/5/25 dk, baslat/duraklat/sifirla). Amac: arka plan guvenilirligini realme GT 2'de olcmek. Ekranda "Alarm olcumu" paneli: alarm gercekten ne zaman tetiklendi, kac sn gecikti, hic tetiklenmedi mi. |
| Pil rehberi | Ilk acilista ve istenince "Pil ayarlarini ac" rehberi (kullanici karari 3-a): bildirim izni, pil kisitlamasi yok, arka planda calismaya izin / otomatik baslatma. Menu adlari markaya gore degisebilir; realme icin yollar DOGRULANMADI. |
| Bilinen sinirlar | Telefon yeniden baslarsa alarm silinir (sayac acilinca bitis saatine bakilip "bitti" gosterilir). Zorla durdurulan (Force stop) uygulamada alarm calismaz. |

## Tekrar sistemi
- Konu basina en fazla 4 kisa tekrar (10-15 dk, notlara bakmadan hatirlama + kontrol).
- Sinava kalan gune gore tekrar gunleri (ilk calismadan sonra gun sayisi):

| Sinava kalan gun | Tekrar gunleri |
|---|---|
| 7 | 1, 3, 4 |
| 14 | 1, 4, 7, 9 |
| 30 | 1, 7, 12, 16 |
| 60 | 1, 8, 17, 25 |
| 120 | 1, 8, 21, 33 |
| 180 | 1, 8, 26, 43 |
| 300 | 1, 8, 29, 53 |

- Kullanici tur sayisini secer (varsayilan 2). Gunluk tekrar yuku siniri vardir, fazlasi ertesi gune kayar. Tekrarlar takvimde otomatik "Tekrar" olarak gorunur (bildirim yok).
- Dayanak: Cepeda 2008, Kerfoot ve ark. TUS'a ozgu akademik veri yok. Oranlar ara degerleme, kanitlanmis kesin deger degil.

## Acik / dogrulanmamis noktalar
- Firebase yurt disi aktarimi icin KVKK m.9 yolu kesinlesmedi (hukukcu sorusu).
- Android gelistirici dogrulamasi 2027'de kuresel olabilir; "sinirli dagitim hesabi" (en fazla 20 cihaz) not edildi, acilis durumu dogrulanmadi.
- Firebase App Distribution tester limiti ve GitHub Actions ucretsiz kotasi dogrulanmadi.
- Ileride arkadas disina acilma karari yok; guvenlik kurallari bastan cok kullanicili yazilacak.
- APK imzalama: Kalici anahtar (alias `mytus`) uretildi; kullanici yedekledi ve GitHub Secrets'a koydu (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD). Anahtar ASLA depoya girmez. Sirlar yoksa derleme debug anahtariyla imzalanir ve o APK ile kalici anahtarli APK birbirinin uzerine kurulamaz (once silmek gerekir).
- Dagitim otomasyonu: sirlar FIREBASE_APP_ID, FIREBASE_SERVICE_ACCOUNT, FIREBASE_TESTERS. main dalina gonderimde veya elle `dagit` secilince APK Firebase App Distribution'a yuklenir. Build numarasi her derlemede `github.run_number` ile artar.
