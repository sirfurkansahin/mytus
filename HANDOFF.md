# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), Master Rapor Faz 2: Özel Defterler & Akıllı Havuz modülü geliştirildi (`model2/ozel-defterler`).

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- Master Rapor Faz 1 (Deneme Sınavları & Hata Analizi - PR #12) `main` dalına birleştirildi.
- Master Rapor Faz 2 (`model2/ozel-defterler`) geliştirildi:
  1. **Hata Defteri & Çeldirici Bankası (`HataKaydi`):**
     - Denemelerden veya soru çözümünden gelen hatalar tek havuzda toplanır.
     - 3 zorunlu alan: Karışan çeldirici, İki şıkkı **ayıran tek kriter** ve Bir daha yapmamak için **kendi kuralım**.
     - B sınıfı (Emin + Yanlış) için ⚠️ Hiperdüzeltme uyarısı ve "Pekiştirildi" takibi.
  2. **Sınıflama & Skor Defteri (`SkorKarti`):**
     - Rapor Tuzak Sınıfı 8 için 10+ kritik hazır TUS skoru (Modifiye Hinchey, Hodgkin IPS, Child-Pugh, Wells PE/DVT, CURB-65, Ranson, qSOFA, Jones ARA, Duke İE, Alvarado).
     - Kullanıcının kendi özel skorunu ekleme imkanı, arama çubuğu ve ÖSYM çeldirici uyarıları.
  3. **Mekanizma Zincirleri (`MekanizmaZinciri`):**
     - 6 branş şablonu (Dahiliye, Farmakoloji, Biyokimya, Mikrobiyoloji, Fizyoloji, Anatomi) ile 5 halkalı hastalık betiği (Illness script).
     - Komşusundan ayıran tek özellik ve "Neden?" mekanizma açıklaması.
  4. **3 Dakikalık Vaka Kartı (`VakaKarti`):**
     - İntörn ve klinisyen adayların günlük hasta karşılaşmasını TUS soru mantığına ve ayırıcı tanıya dönüştürme aracı.
  5. **Depo & Gezinme Entegrasyonu:**
     - `PlanDeposu` içinde kalıcı depolama, ekleme, güncelleme, pekiştirme ve silme metotları.
     - `DenemeDetayEkrani` üzerinde eklenen hatalı soruların otomatik olarak Hata Defteri'ne akması.
     - `DerslerEkrani` ve `BugunEkrani` üzerinden tek dokunuşla Özel Defterler'e erişim.
  6. **Testler:**
     - `test/defterler_test.dart` ile modeller, hazır skorlar, illness scripts ve depo CRUD testleri.
     - `test/widget_test.dart` içine `defterlerTestleri` eklendi.

## Siradaki adim
1. GitHub'a gönderim (push) ve GitHub Actions CI (analiz, test, APK ve Web) doğrulaması.
2. PR açılarak kullanıcının onayıyla `main` dalına birleştirilmesi.
3. **Faz 3 (Modül 3):** Nörobiyoloji & Bilişsel Takip (F.T. time blok sonu 1-5 Odak Puanı, günlük 3-4 saat zor bilişsel iş tavanı, Uyku/Kafein disiplini ve PFC Erken Uyarı / %70 Yük kuralı).

## Bilinen sorunlar / riskler
- Web ortaminda telefon kilitliyken sistem alarm servisi (`AlarmManager`) bulunmaz; sayaç tarayici acikken kusursuz calisir.
- Kod yerelde derlenemez; derleme ve test sonuçları GitHub Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
