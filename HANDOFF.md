# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), Master Rapor Faz 1: Deneme Sınavları & Bilişsel Hata Analizi modülü `main` dalına birleştirildi (PR #12).

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- Master Rapor Faz 1 (PR #12) başarıyla `main` dalına birleştirildi:
  1. **200 Soru ve Puanlama Mimarisi:**
     - 100 Temel (TTBT) + 100 Klinik (KTBT) soru yapısı.
     - Net hesabı ($D - Y/4$).
     - Ağırlıklı Puanlar ($K = 0.4 \times TTBT + 0.6 \times KTBT$; $T = 0.6 \times TTBT + 0.4 \times KTBT$).
     - ÖSYM 85 EBAP (En Büyük Ağırlıklı Puan) tavan ölçeklemesi.
  2. **A–F Hata Sınıfları ve Güven Matrisi:**
     - A: Bilgi, B: Yanlış inanç, C: Okuma/kurgu, D: Mantık/halka, E: Süre, F: Form.
     - "Emin + Yanlış" için ⚠️ **HİPERDÜZELTME ALARMI** (aynı gün kapatma uyarısı).
     - Kalibrasyon Farkı hesabı ($Ortalama Güven - Doğruluk$; $\le \%5$ hedefi, $>+\%8$ aşırı güven uyarısı).
     - Sınav Öncesi Test Kaygısı (0–10 skalası).
  3. **Arayüz ve Ekranlar (`lib/features/denemeler/`):**
     - `DenemelerEkrani`: Deneme listesi, özet kokpit ve net geçmişi.
     - `DenemeEkleEkrani`: Canlı net ve EBAP puan hesaplayıcı form.
     - `DenemeDetayEkrani`: A-F hata dağılım çubukları, kayıp net analizi ve soru bazlı çeldirici/kriter incelemesi.
     - `soruAnalizDialogu`: Hatalı soru ekleme dialogu.
  4. **Gezinme:**
     - `BugunEkrani` üst barına "Denemeler & Analiz" butonu eklendi.
     - `IlerlemeEkrani` içine "Deneme Sınavları & Net Analizi" kartı eklendi.
  5. **CI / Dağıtım:**
     - Kod analizi, birim testleri (`test/deneme_test.dart`) ve widget testleri (`test/widget_test.dart`) GitHub Actions'ta yeşil.
     - APK Firebase App Distribution'a yüklendi, Web sürümü GitHub Pages üzerinde canlı.

## Siradaki adim
1. **Master Rapor Faz 2 (Özel Defterler):**
   - **Hata Defteri & Çeldirici Bankası:** Denemelerden veya soru çözümlerinden gelen hataların toplanıp aralıklı tekrar zincirine (R1/R2) dahil edilmesi, karışan çeldirici ve ayıran tek kriterin gösterimi.
   - **Sınıflama & Skor Defteri (Tuzak Sınıfı 8):** Hodgkin IPS, Hinchey, Child-Pugh, Wells vb. skorlar için hızlı kart kütüphanesi.
   - **Mekanizma Zincirleri (Illness Script Rehberi):** 6 temel branş için 5 halkalı kavram zinciri şablonları.
   - **3 Dakikalık Vaka Kartı:** İntörn/klinisyen vaka dönüştürücü.
2. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.

## Bilinen sorunlar / riskler
- Web ortaminda telefon kilitliyken sistem alarm servisi (`AlarmManager`) bulunmaz; sayaç tarayici acikken kusursuz calisir.
- Kod yerelde derlenemez; derleme ve test sonuçları GitHub Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
