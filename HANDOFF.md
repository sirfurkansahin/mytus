# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), iPhone ve Web canli test ortami (Flutter Web + GitHub Pages PWA) hazirlandi (`model2/ios-web-test`).

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- `model2/speetus-mufredat` (19 Sistem Paketi, tek liste, Temel/Klinik ayriminin kaldirilmasi) basariyla `main` dalina birlestirildi.
- Dal `model2/ios-web-test`:
  1. **Web & iPhone PWA Uyumu:**
     - `lib/core/veri_kaydi.dart`: Web ortaminda tarayici `localStorage` hafizasina okuma/yazma yapacak sekilde conditional import (`dart.library.html`) ile genisletildi (`veri_kaydi_stub.dart`, `veri_kaydi_web.dart`).
     - `lib/features/ft_time/ft_native.dart`: Web ortaminda Android kanallari bulunmadiginda sessizce `null` donecek sekilde catch-all eklendi.
     - `web/index.html`: iPhone Safari tam ekran PWA modunu destekleyecek etiketler (`apple-mobile-web-app-capable`, `black-translucent`, viewport-fit cover) ve mor yukleme ekraniyla olusturuldu.
     - `web/manifest.json`: Web uygulama basligi, renkleri ve ikonlariyla hazirlandi.
     - `test/veri_kaydi_test.dart`: Veri kaydi unit testleri eklendi.
  2. **GitHub Actions Canli Dagitim (.github/workflows/deploy-web.yml):**
     - Flutter Web derlemesi (`--base-href "/mytus/"`) sonrasi GitHub Pages'e otomatik dagitim akisi olusturuldu.
     - GitHub Pages, `workflow` tipiyle etkinlestirildi (`https://sirfurkansahin.github.io/mytus/`).
     - Deployment branch politikasina `model2/*` eklendi.

## Siradaki adim
1. `model2/ios-web-test` dalindaki degisikliklerin GitHub'a gonderilip Actions akisinin dogrulanmasi.
2. iPhone Safari uzerinden `https://sirfurkansahin.github.io/mytus/` adresinin test edilmesi ve "Ana Ekrana Ekle" ile tam ekran deneyiminin kontrol edilmesi.
3. Onay sonrasi `main` dalina birlestirilmesi.
4. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.

## Bilinen sorunlar / riskler
- Web ortaminda telefon kilitliyken sistem alarm servisi (`AlarmManager`) bulunmaz; sayaç tarayici acikken kusursuz calisir.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
