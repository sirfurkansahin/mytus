# HANDOFF.md: Devir notu

Son guncelleme: 4 Kasim 2026 (Gemini), Master Rapor Faz 3: Nörobiyoloji, Uyku & Bilişsel Performans modülü tamamlandı (`model2/bilissel-performans`, PR #14).

## Durum
- Faz 1 (Deneme Sınavları & Hata Analizi - PR #12) `main` dalına birleştirildi.
- Faz 2 (Özel Defterler & Akıllı Havuz - PR #13) `main` dalına birleştirildi.
- Faz 3 (`model2/bilissel-performans` - PR #14) geliştirildi ve CI testlerinden başarıyla geçti:
  1. **F.T. Time Blok Sonu Odak Puanı (1-5 Puan):**
     - Her çalışma bloğu bitiminde 1-5 puanlık mikro odak değerlendirmesi (`OdakKaydi.odakPuani`).
     - "Ağır Analitik İş" seçimi (`OdakKaydi.zorBilissel`).
  2. **Zor Bilişsel İş Tavanı (Rapor Bölüm 1.1: 3-4 Saat Kuralı):**
     - Günlük net 180-240 dk (3-4 saat) ağır analitik kapasite takibi.
     - 180 dk eşiğinde "Zor Bilişsel Tavana Yaklaşıldı", 240 dk dolduğunda "Ağır Analitik Tavan Doldu (4 saat)" uyarısı.
  3. **Sirkadiyen Odak Dağılımı:**
     - Son 14 günün saatlik ortalama odak eğrisi (zirve analitik saatler ve sirkadiyen çukur analizi).
  4. **Uyku & Kafein Disiplini (`UykuKaydi`):**
     - Hedef yatış/kalkış penceresi ve gerçek saatler arası dairesel sapma hesabı (hedef: ±30 dk).
     - Yatış saatinden 8 saat önce otomatik kafein kesilme alarm saati (Rapor Bölüm 1.3).
     - Sınava son 7 gün kala "Uyku Taper Protokolü" rozeti ve uyarısı.
  5. **Prefrontal Korteks (PFC) & %70 Yük Kurtarma Modu:**
     - Son denemelerdeki C tipi (okuma/dikkat) hata oranı > %15 olduğunda otomatik PFC aşırı yük uyarısı.
     - Tek dokunuşla %70 Kurtarma Modu (yeni konular ertelenir, yük %70'e çekilir, sadece R1-R2 tekrarları yapılır).
  6. **Arayüz ve Entegrasyon:**
     - `BilisselEkrani`: Tüm bilişsel, sirkadiyen ve uyku göstergeleri.
     - `BugunEkrani`: Bilişsel takip butonu ve kurtarma modu / tavan aşıldı rozetleri.
     - `FtEkrani`: F.T. time hazırlık ekranında ağır analitik tavan ilerleme çubuğu.
     - `FtSayacEkrani`: Döngü geçişinde kompakt odak değerlendirmesi.
     - `AyarlarEkrani`: Bilişsel Yönetim bağlantısı.
  7. **Testler:**
     - `test/bilissel_test.dart` (model, sapma, kafein kesilme, tavan, PFC erken uyarı testleri).
     - `test/widget_test.dart` içine `bilisselTestleri` eklendi.

## Siradaki adim
1. PR #14 (`model2/bilissel-performans`) kullanıcının onayıyla `main` dalına birleştirilecek (`gh pr merge 14 --merge`).
2. **Faz 4 (Modül 4: Sınav Anı, Panik Protokolü & Provalar):**
   - 90 saniyelik panik & döngüsel iç çekme (Cyclic Sighing) görsel animasyonlu nefes rehberi ve uyarılmayı yeniden değerlendirme kartı.
   - Gerçek saat deneme modu (10:15 TTBT / 14:45 KTBT) ve çeyrek dilim tempo bildirimleri (dk 32, 65, 98, 130).
   - Cevap değiştirme ve beklenen değer (EV) kartı.
3. **Faz 5 (Modül 5: Master Yönetim Kokpiti):**
   - Haftalık 8+4 bilişsel gösterge paneli ve otomatik strateji motoru.

## Bilinen sorunlar / riskler
- Kod bulutta derlenmez; doğrulama GitHub Actions üzerinden yapılır.
- Tüm testler yeşildir (`APK derle` ve `Web ve iPhone Dağıt`).

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
