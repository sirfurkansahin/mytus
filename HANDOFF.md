# HANDOFF.md: Devir notu

Son guncelleme: 6 Kasım 2026, APK derlemesi kaldırıldı, Web Mobil Uygulama (PWA) mimarisine geçildi (dal `model2/web-mobil-gecis`).

## Durum
Kullanıcı kararı doğrultusunda projenin platform ve dağıtım stratejisi güncellendi:
- **APK Derlemesi Kaldırıldı:**
  - `.github/workflows/build-apk.yml` iş akışı silindi. Android APK derleme ve Firebase App Distribution adımları emekliye ayrıldı.
  - Proje artık gereksiz Android derleme bekleme sürelerinden arındırıldı.
- **Web Mobil Uygulama (PWA) Ana Mimarisi:**
  - Tüm cihazlarda (iPhone iOS / Safari ve Android / Chrome) tam ekran, tarayıcı çubuğu olmadan yerel mobil uygulama gibi çalışır.
  - Dağıtım ve canlı adres: `https://sirfurkansahin.github.io/mytus/`
  - `.github/workflows/deploy-web.yml`: Kod analizi, tüm birim/widget/uçtan uca testler ve Flutter Web derlemesini tek seferde çalıştırıp doğrudan yayına alır.
- **Kütüphane Modülü & Örnek Kitap:**
  - Zengin TUSDATA Patoloji Konu Kitabı (6 bölüm, 260 sayfa, tamamlananlar ve klinik spot notuyla) aktif.
  - Kütüphane kartlarında metin taşması engellendi (`Wrap`).
- **Belgeler:**
  - `AGENTS.md` ve `DECISIONS.md` Web Mobil odaklı olarak güncellendi.

## Siradaki adim
- F.T. time modülü üzerinde yapılacak düzenlemeler veya kullanıcının sıradaki istekleri.

## Bilinen sorunlar / riskler
- Bildirim sorunu (sayaç bitişinde sistem bildirimi) kullanıcının talebiyle kapsam dışı bırakılmıştır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
