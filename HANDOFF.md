# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), Çift Müfredat desteği tamamlandı ve `main` dalına birleştirildi (PR #11).

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- `model2/cift-mufredat` (PR #11) başarıyla `main` dalına birleştirildi:
  1. **Çift Müfredat Mimarisi:**
     - `MufredatTuru` enum (`klasik`, `speetus`) eklendi.
     - Hazır müfredatlar:
       * **Klasik Branşlar:** 11 branş (Temel: Anatomi, Fizyoloji, Biyokimya, Patoloji, Farmakoloji, Mikrobiyoloji; Klinik: Dahiliye, Pediatri, Genel Cerrahi, Kadın Doğum, Küçük Stajlar).
       * **SpeeTUS Sarmal Sistem:** 19 Sistem Paketi ve hazır tüm video/alt konu başlıkları.
  2. **Karşılama Ekranı (`karsilama_ekrani.dart`):**
     - Kullanıcıya iki müfredat tarzı SegmentedButton ile sunuluyor.
     - Klasik seçildiğinde Temel ve Klinik başlıkları altında cipler; SpeeTUS seçildiğinde tek parça 19 paket cipi gösteriliyor.
  3. **Dersler Ekranı & Konu Ekranı:**
     - `DerslerEkrani`: Klasik modda "Temel" / "Klinik" sekme filtresi ve renk ayrımı aktif; SpeeTUS modunda ise tek parça liste gösteriliyor.
     - `DersEkleDialogu`: Yalnızca Klasik modda Temel/Klinik grup seçimi soruluyor, SpeeTUS modunda sade isim soruluyor.
     - `KonuEkrani`: Klinik rozeti ve mor vurgusu yalnızca klasik müfredatta gösteriliyor.
  4. **Ayarlar Ekranı (`ayarlar_ekrani.dart`):**
     - "Müfredat tarzı" ayar satırı eklendi. Kullanıcı istediği zaman Klasik ile SpeeTUS arasında geçiş yapabiliyor veya müfredatı sıfırlayabiliyor.
  5. **CI / Dağıtım Durumu:**
     - `main` dalı üzerinde GitHub Actions çalıştı; analiz ve testler geçti.
     - İmzalı Release APK derlendi ve **Firebase App Distribution** üzerinden test grubuna dağıtıldı.
     - Canlı Web PWA sürümü **GitHub Pages** (`https://sirfurkansahin.github.io/mytus/`) üzerinde güncellendi.

## Siradaki adim
1. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.

## Bilinen sorunlar / riskler
- Web ortaminda telefon kilitliyken sistem alarm servisi (`AlarmManager`) bulunmaz; sayaç tarayici acikken kusursuz calisir.
- Kod yerelde derlenemez; derleme ve test sonuçları GitHub Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
