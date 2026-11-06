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
- Uygulama adi: MY TUS. Dart paket adi: `app` (ornek: `import 'package:app/main.dart';`).
- Teknoloji: Flutter (Dart) + Web Mobil (PWA) + Firebase Spark (ucretsiz plan). Cloud Functions ve Cloud Storage Spark planinda YOK, kullanma. Puan hesabi istemcide yapilir.
- Surum 1: hesapsiz, yerel veriyle (tarayici yerel bellegi / localStorage) telefonlarda tam ekran Web Mobil (PWA) olarak calisir. Surum 2: Google girisi, bulut, grup, puan tablosu, paylasim.
- Hedef & Dagitim: Web Mobil uygulama (tum mobil cihazlar, iPhone ve Android; canli adres: `https://sirfurkansahin.github.io/mytus/`). APK derlemesi 6 Kasim 2026 kullanici karariyla planlardan kaldirilmistir.

## Derleme ortami (ONEMLI)
- Bulut gelistirme ortaminda Flutter/pub.dev araclarina erisim engellidir. Kod orada DERLENEMEZ ve calistirilamaz.
- Derleme, test ve canli yayin GitHub Actions'ta yapilir: `.github/workflows/deploy-web.yml` (kod analizi + birim/widget/uctan uca testler + Web Mobil PWA dagitimi).
- Hatalari Actions gunluklerinden (log) oku. Ara adimlarda yerelde kal, yalnizca is bittiginde veya kullanici istediginde gonder/derle.

## Kod kurallari
- Kucuk, tek sorumluluklu dosyalar. Her ozellik kendi klasorunde: `lib/features/<ozellik>/`.
- Kisa Turkce yorumlar. Karmasik mantik (ozellikle tekrar motoru) birim testiyle birlikte.
- Gizli bilgi (anahtar, sifre) ASLA depoya girmez. Depo ACIKTIR (public).
- Notlar kullanicinin ozel verisidir, hicbir zaman paylasilmaz.
- Commit mesajlari Turkce, kisa ve aciklayici.

## Alan bilgisi
- Tekrar kurali ve diger kararlar `DECISIONS.md` icinde. Degistirmeden once kullaniciya sor.
