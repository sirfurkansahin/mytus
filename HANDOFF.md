# HANDOFF.md: Devir notu

Son guncelleme: 4 Kasim 2026 (Gemini), Master Rapor Faz 5: Master Yönetim Kokpiti & "Eğer–O Zaman" Karar Motoru tamamlandı (`model2/master-kokpit`, PR hazırlanıyor).

## Durum
- Faz 1 (Deneme Sınavları & Hata Analizi - PR #12) `main` dalına birleştirildi.
- Faz 2 (Özel Defterler & Akıllı Havuz - PR #13) `main` dalına birleştirildi.
- Faz 3 (Nörobiyoloji, Uyku & Bilişsel Performans - PR #14) `main` dalına birleştirildi.
- Faz 4 (Sınav Anı, Panik Protokolü & Provalar - PR #15) `main` dalına birleştirildi.
- Faz 5 (`model2/master-kokpit`) geliştirildi:
  1. **Haftalık 8 Bilişsel Gösterge (Rapor Bölüm 6.3):**
     - Kalibrasyon Farkı (hedef: <= %5).
     - Aşırı Güven Alarmı (kalibrasyon > +%8).
     - Uyku Süresi & Sirkadiyen Yatış Sapması (7–9 sa, <= 30 dk).
     - Prefrontal Korteks & C Tipi Okuma Hatası Oranı (< %10–15).
     - Test Kaygı Puanı (0–10, hedef: <= 6).
     - R1 (G+1) Tekrar Geçiş Oranı (hedef: >= %75).
     - R3 (G+30) Tekrar Geçiş Oranı (hedef: >= %70).
     - Ortalama Odak Puanı (1–5) & Ağır Analitik Bilişsel Tavan (3–4 saat / 240 dk).
     - A–F Kayıp Net Dağılımı (en çok kayba yol açan hata sınıfı teşhisi).
  2. **4 Sınav & Net Göstergesi:**
     - Temel Bilimler Neti (TTBT) (0–100).
     - Klinik Bilimler Neti (KTBT) (0–100).
     - Klinik Ağırlıklı K Puanı (0.4 TTBT + 0.6 KTBT).
     - Tahmini ÖSYM 85 EBAP Puanı ($55 + 30 \times \dots$).
  3. **0–100 Kompozit Bilişsel Sağlık Skoru:**
     - 6 bilişsel eksenin ağırlıklı bileşimi ve durum etiketi ("Optimal Zirve - Türkiye 1.liği Hattı", "Dengeli", "Dengeleme Gerekli", "PFC Yorgunluğu").
  4. **Otomatik "Eğer–O Zaman" Karar & Strateji Motoru (Rapor Bölüm 6.4):**
     - Eğer C hatası > %15 ise ➔ %70 Kurtarma Modu eylem önerisi.
     - Eğer kalibrasyon > +%8 ise ➔ "Emin" öncesi 10 sn tersini düşün ve Çeldirici Bankası eylemi.
     - Eğer son çeyrek hatası > 1.5x ise ➔ Yorgunluk eşiği ve 135 dk sınav provası / mikro nefes önerisi.
     - Eğer kaygı >= 7 ise ➔ 90 sn Panik Protokolü & Döngüsel İç Çekme günlük prova önerisi.
     - Eğer R1 < %75 ise ➔ Yeni konuları %20 kıs ve Sıcak Liste önerisi.
     - Eğer yatış sapması > 30 dk ise ➔ Biyolojik sirkadiyen sabitleme önerisi.
     - Eğer 2 şık elenip tereddüt edildiyse ➔ Beklenen Değer (+0.167 net) kuralı.
     - Tüm göstergeler hedefteyse ➔ Optimal Zirve teyidi.
  5. **Arayüz ve Entegrasyon:**
     - `KokpitEkrani`: Master Yönetim Kokpiti ana ekranı, kural kartları, gösterge kartları ve hızlı araçlar.
     - `BugunEkrani`: AppBar'da Master Kokpit butonu ve gün özetinde hızlı kokpit navigasyon kartı.
     - `IlerlemeEkrani`: Haftalık inceleme yapan adaya yönelik üst Master Kokpit kartı.
     - `AyarlarEkrani`: Bilişsel menüde Master Kokpit bağlantısı.
  6. **Testler:**
     - `test/kokpit_test.dart` (tüm gösterge hesapları ve 8 Eğer-O Zaman kural birim testleri).
     - `test/widget_test.dart` (`kokpitTestleri` eklendi).

## Siradaki adim
1. Değişiklikler GitHub'a gönderilecek (`origin model2/master-kokpit`) ve PR #16 açılacak.
2. GitHub Actions (APK derle ve Web dağıt) yeşil olunca kullanıcıya raporlanıp onayı istenecek.
3. Kullanıcı onayıyla PR #16 birleştirilecek ve 5 fazlık Master Araştırma Raporu entegrasyonu tamamlanacak.

## Bilinen sorunlar / riskler
- Bulutta yerel derleme kısıtlıdır; testler GitHub Actions üzerinden doğrulanır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
