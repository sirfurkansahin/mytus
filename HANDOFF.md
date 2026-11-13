# HANDOFF.md: Devir notu

Son guncelleme: 13 Kasım 2026, Takvim, Kütüphane ve Organik Entegrasyon 3 Aşamalı Paketi tamamlandı (dal `claude/takvim-kutuphane-3asama`).

## Durum
Kullanıcının "sırayla hepsini uygula" talimatı ve netleştirdiği kararlar doğrultusunda 3 aşamalı geliştirme eksiksiz uygulandı:

1. **Aşama 1: Takvim Modülü Geliştirmeleri (`lib/features/takvim/`)**
   - **Telafi Planı (Catch-Up):** Nöbet veya yoğunluk sebebiyle biriken (geciken) konular ve tekrarlar için `telafi_plani.dart` ve `telafi_dialogu.dart` oluşturuldu. Tekrarlar "yapıldı" sayılmaz; erteleme kuralıyla günlük limitlere (yeni konu ve tekrar sınırı) göre sonraki günlere dengeli dağıtılır. Bugün ekranına ve Takvim sekmesine Telafi butonu bağlandı.
   - **Tek Dokunuşla Erteleme & Taşıma:** Tekrarlar ve planlı çalışmalar için `tekrarErtele`, `tekrarBirGunErtele` eklendi (`calisma.dart` ertelemeler). Ertelenen tekrarın sonraki tekrarları da gecikme kayması kuralıyla aynı gün kadar kaydırılır.
   - **Haftalık Odak Görünümü:** Takvim ekranına Ay / Hafta görünüm seçicisi (`SegmentedButton`) eklendi. Nöbette tek elle 7 günlük odak görünümü rahatça kullanılabilir.

2. **Aşama 2: Kütüphane Modülü Geliştirmeleri (`lib/features/kutuphane/`)**
   - **Fotoğraflı Not Etiketleri:** `BolumNotu` modeline etiket desteği eklendi. Kullanıcının seçtiği 4 kritik etiket (`Tablo`, `Spot`, `Hoca notu`, `Şema / Algoritma`) not ekleme/düzenleme pencerelerine yerleştirildi. Bölüm notları ekranında bu etiketlerle canlı filtreleme çipleri eklendi.
   - **Kalan Sayfa & Bitiş Tarihi Tahmini:** Hibrit model uygulandı (`Kitap.kalanSayfaSayisi`, `Kitap.tahminiKalanGun`). Kitap kartına günlük sayfa hedefi belirleme penceresi eklendi; hedef girilirse hedefe göre, girilmezse son 14 günde tamamlanan bölümlerden türetilen otomatik günlük hıza göre tahmini kalan gün ve tarih hesaplanır.

3. **Aşama 3: Kütüphane ⟷ Takvim Organik Bağı**
   - Kitap detay ekranında hem sıradaki bölüm kartından hem de her bölümün menüsünden **"Bugün Çalıştım & Tekrar Başlat"** ve **"İleri Tarihe Planla"** köprüsü kuruldu.
   - Kullanıcı kararı gereği dersteki konulardan birini seçme veya tek dokunuşla yeni konu oluşturma diyaloğu açılır; "Çalıştım" dendiğinde R0-R4 tekrar zinciri bugünden başlatılır ve bölüm tamamlanır.
   - Takvim ve Bugün ekranındaki konu/tekrar eylem menülerine, derse ait bir kitap varsa tek dokunuşla o kitabın notlarına ve fotoğraflarına gitme bağlantısı (`Kitap / Fasikül notları`) bağlandı.

4. **Testler (`test/telafi_test.dart`, `test/kutuphane_test.dart`):**
   - Tekrar erteleme, gecikme kayması, telafi planı hesaplama ve uygulama birim testleri eklendi.
   - Bölüm notu etiketleri ve kitap sayfa tahmini testleri eklendi.

## CI ve Canlı Dağıtım Doğrulaması
- **GitHub Actions İş Akışı (Run 43468985212):** Kod analizi (`flutter analyze`), tüm birim/widget/uçtan uca testler (`flutter test`) ve Web derlemesi başarıyla tamamlandı (yeşil).
- **Canlı Yayın:** Web Mobil (PWA) sürümü `https://sirfurkansahin.github.io/mytus/` adresinde güncellendi.

## Siradaki adim
- Kullanıcının talebine göre sonraki modül geliştirmelerine geçilmesi (F.T. Time sayacı, Denemeler veya Kullanıcı Hesabı / Bulut).

## Bilinen sorunlar / riskler
- Yok. Mevcut veri yapılarıyla tam geriye dönük uyumludur. Küçük ekran taşmaları Wrap düzeniyle güvenceye alınmıştır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
