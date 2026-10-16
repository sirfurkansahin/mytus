# AGENTS.md: Bu depoda calisan yapay zeka modelleri icin kurallar

Bu dosyayi her oturumun basinda oku. Sonra `HANDOFF.md` (durum, siradaki adim) ve `DECISIONS.md` (kararlar) dosyalarini oku.

## Kullanici
- Kullanici teknik degil. Tum aciklamalar TURKCE, sade dille olmali. Teknik terimleri kisaca acikla.
- Kullaniciya danismadan karar verme: secenekleri artilari/eksileriyle sun, oneriyi belirt, cevabi bekle.
- Eksik bilgi varsa varsayim yapma, sor. Kucuk adimlarla ilerle, her adimdan sonra onay al.
- Kaynak gerektiren iddialarda kaynak goster, emin olunmayan/eski bilgiyi belirt.

## Tek yazar kurali
- Ayni anda yalnizca BIR model kodu degistirir. Baska bir model calisiyorsa dokunma.
- Her is ayri bir dalda (branch) yapilir: `claude/<kisa-konu>` veya `model2/<kisa-konu>`. `main` dalina dogrudan yazma (ilk kurulum haric).
- Isi birakirken `HANDOFF.md` dosyasini guncelle: ne yapildi, siradaki adim, bilinen sorunlar.

## Proje
- Uygulama adi: MY TUS. Android paket adi: `com.mytus.app`. Dart paket adi: `app` (ornek: `import 'package:app/main.dart';`).
- Teknoloji: Flutter (Dart) + Firebase Spark (ucretsiz plan). Cloud Functions ve Cloud Storage Spark planinda YOK, kullanma. Puan hesabi istemcide yapilir.
- Surum 1: hesapsiz, yalnizca telefonda calisir (yerel veri). Surum 2: Google girisi, bulut, grup, puan tablosu, paylasim.
- Hedef: Android, arkadas grubu (2-10 kisi). Dagitim: Firebase App Distribution.

## Derleme ortami (ONEMLI)
- Bulut gelistirme ortaminda Flutter/pub.dev/Android araclarina erisim engellidir. Kod orada DERLENEMEZ ve calistirilamaz.
- Derleme ve test GitHub Actions'ta yapilir: `.github/workflows/build-apk.yml` (analiz + test + APK).
- Hatalari Actions gunluklerinden (log) oku. Her degisiklikte once kucuk tut, derleme sonucunu bekle.
- Ilk kurulumda `android/` klasoru `bootstrap-android.yml` akisiyla uretilir.

## Kod kurallari
- Kucuk, tek sorumluluklu dosyalar. Her ozellik kendi klasorunde: `lib/features/<ozellik>/`.
- Kisa Turkce yorumlar. Karmasik mantik (ozellikle tekrar motoru) birim testiyle birlikte.
- Gizli bilgi (anahtar, sifre, keystore) ASLA depoya girmez. Depo ACIKTIR (public).
- Notlar kullanicinin ozel verisidir, hicbir zaman paylasilmaz.
- Commit mesajlari Turkce, kisa ve aciklayici.

## Alan bilgisi
- Tekrar kurali ve diger kararlar `DECISIONS.md` icinde. Degistirmeden once kullaniciya sor.
