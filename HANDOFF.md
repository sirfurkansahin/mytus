# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), Çift Müfredat desteği tamamlandı (`model2/cift-mufredat`).

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- `model2/cift-mufredat` dalında geliştirilenler:
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
  5. **Testler:**
     - `test/plan_deposu_test.dart` ve `test/widget_test.dart` güncellendi, çift müfredat geçişleri ve arayüz etkileşimleri test edildi.
  6. **Canlı Önizleme:**
     - `mytus_canli_onizleme.html` prototipi güncellendi; karşılama ve dersler ekranında çift müfredat deneyimi simüle edildi.

## Siradaki adim
1. `model2/cift-mufredat` dalındaki değişikliklerin GitHub'a gönderilmesi (push).
2. GitHub Actions üzerinde analiz, test ve derlemenin (APK + Web) doğrulanması.
3. PR açılarak kullanıcının onayıyla `main` dalına birleştirilmesi.
4. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.

## Bilinen sorunlar / riskler
- Web ortaminda telefon kilitliyken sistem alarm servisi (`AlarmManager`) bulunmaz; sayaç tarayici acikken kusursuz calisir.
- Kod yerelde derlenemez; derleme ve test sonuçları GitHub Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
