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
| Puan kurali | Tamamlanan odak suresi kadar puan (ornek: 1 dakika = 1 puan). Sure ayarindan bagimsiz. Yarim birakilan donguler icin kural henuz karara baglanmadi. |
| F.T. time varsayilan sureler | 25 dk calisma, 5 dk kisa mola, 15 dk uzun mola, her 4 dongude bir uzun mola. Kullanici degistirebilir. |
| Firebase projesi | Ad: mytus, Spark plani, Google hesabi: kullanicinin kendi hesabi. Google Analytics ACIK (kullanici karari, 16 Ekim 2026). |
| Analytics sonucu | Analytics, cihaz/kullanim verisi toplar. Uygulamaya eklendiginde aydinlatma metnine yazilmali ve ilk giriste onay alinmali. KARAR (16 Ekim 2026): Analytics SDK'si Surum 2'de, Google girisi ve KVKK ekranlariyla birlikte eklenecek. Surum 1 hicbir veriyi cihazdan cikarmaz. |

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
