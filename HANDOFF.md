# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), Master Rapor Faz 1: Deneme Sınavları & Bilişsel Hata Analizi modülü geliştirildi (`model2/deneme-analizi`).

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- `model2/deneme-analizi` dalında geliştirilenler (Master Rapor Faz 1):
  1. **Deneme & Puan Modelleri (`lib/features/denemeler/modeller.dart`):**
     - 200 soru (100 Temel TTBT + 100 Klinik KTBT).
     - Net hesabı ($Doğru - Yanlış/4$).
     - Ağırlıklı Puanlar ($K = 0.4 \times TTBT + 0.6 \times KTBT$; $T = 0.6 \times TTBT + 0.4 \times KTBT$).
     - ÖSYM 85 EBAP tavan formülü ölçeklemesi.
     - A–F Hata Sınıfları (A: Bilgi, B: Yanlış inanç, C: Okuma/kurgu, D: Mantık/halka, E: Süre, F: Form).
     - Güven Matrisi (Emin / Kararsız / Tahmin), Kalibrasyon Farkı ve "Emin + Yanlış" Hiperdüzeltme Alarmı.
     - Sınav Öncesi Test Kaygısı (0-10 skalası).
  2. **Kalıcı Depo Entegrasyonu (`plan_deposu.dart`):**
     - `denemeler` listesi, ekleme/güncelleme/silme metotları ve JSON serileştirmesi.
  3. **Arayüz Ekranları (`lib/features/denemeler/`):**
     - `DenemelerEkrani`: Deneme listesi, özet kokpit kartı ve net geçmişi.
     - `DenemeEkleEkrani`: 100+100 soru bazlı doğru/yanlış/boş girişi, canlı net/EBAP puanı hesabı ve kaygı slider'ı.
     - `DenemeDetayEkrani`: Netler, A–F hata sınıfları çubukları, kalibrasyon uyarısı ve hatalı soru analiz listesi.
     - `soruAnalizDialogu`: Tek bir sorunun çeldirici, ayıran tek kriter ve kural kaydı.
  4. **Gezinme Entegrasyonu:**
     - `BugunEkrani` üst barına "Denemeler & Analiz" butonu eklendi.
     - `IlerlemeEkrani` içine "Deneme Sınavları & Net Analizi" kartı eklendi.
  5. **Birim & Widget Testleri:**
     - `test/deneme_test.dart` oluşturuldu (Netler, ağırlıklı puanlar, EBAP formülü, A-F sınıfları, hiperdüzeltme, kalibrasyon ve depo testleri).
     - `test/widget_test.dart` içine `denemeTestleri` eklendi.

## Siradaki adim
1. GitHub'a gönderim (push) ve GitHub Actions CI (analiz, test, APK ve Web) doğrulaması.
2. PR açılarak kullanıcının onayıyla `main` dalına birleştirilmesi.
3. **Faz 2:** Hata Defteri, Çeldirici Bankası ve Sınıflama-Skor Defteri entegrasyonu.

## Bilinen sorunlar / riskler
- Web ortaminda telefon kilitliyken sistem alarm servisi (`AlarmManager`) bulunmaz; sayaç tarayici acikken kusursuz calisir.
- Kod yerelde derlenemez; derleme ve test sonuçları GitHub Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
