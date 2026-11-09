# HANDOFF.md: Devir notu

Son guncelleme: 9 Kasım 2026, Takvime Çoklu Ders Ekleme ve Kütüphane Hazır Klasör Kartının Kaldırılması geliştirildi (dal `claude/takvim-kutuphane-gelistirme`).

## Durum
Kullanıcının "takvime ders ekleme fonksiyonunu geliştir. tek seferde birden çok ders eklensin. kütüphane modülünde klasör indirme butonunu ekrandan kaldır. çok yer kaplıyor" talebi doğrultusunda geliştirmeler yapıldı:

1. **Kütüphane Ekranı Temizliği (`lib/features/kutuphane/kutuphane_ekrani.dart`):**
   - Ekranda dikeyde çok yer kaplayan `Hazır Klasörler — İstediğini Seç, Hesabına İndir` kartı gövdeden kaldırıldı.
   - Hazır klasörlere erişim AppBar bulut indirme ikonu ve açılır menü üzerinden eksiksiz korundu.
   - `test/widget_test.dart` içindeki kütüphane testi güncellendi.

2. **Takvime Çoklu Ders ve Konu Ekleme:**
   - **Plan Deposu (`lib/features/dersler/plan_deposu.dart`):** `calismalariEkle(Iterable<int> konuIdleri, DateTime gun)` ve `dersinKonulariniGetirVeyaOlustur(int dersId)` fonksiyonları eklendi.
   - **Günlük Sınır Onayı (`lib/features/takvim/gun_siniri.dart`):** `yeniKonuSiniriOnayi` fonksiyonuna `eklenecekSayi` parametresi eklendi; çoklu eklemede tek bir bilgilendirme penceresiyle toplam sayı soruluyor.
   - **Konu ve Ders Seçim Ekranı (`lib/features/takvim/konu_sec_ekrani.dart`):**
     - İki sekmeli modern arayüz: 1) "Konular" (tekil/çoklu konu seçimi ve arama), 2) "Dersler (Toplu Ekle)" (Temel ve Klinik bilimler bazında tek dokunuşla tüm dersi veya birden çok dersi seçme).
     - Hızlı seçim çipleri: "Tüm Temel Bilimler", "Tüm Klinik Bilimler", "Seçimi Temizle".
     - Altta ergonomik başparmak alanı (Thumb Zone) seçim çubuğu: `${seciliDersSayisi} ders · ${seciliKonuSayisi} konu seçildi` ve `Takvime Ekle` butonu.
     - Tek konuya dokunulduğunda doğrudan yerleştirme (önceki hızlı akış) bozulmadan korundu.
   - **Takvim Ekranı (`lib/features/takvim/takvim_ekrani.dart`):** Gün görünümüne `+ Çoklu Ders Ekle` butonu eklendi, `_konuYerlestir` fonksiyonu çoklu seçimleri ve ders adları özetli SnackBar bildirimini destekleyecek şekilde güncellendi.

3. **Testler (`test/calisma_deposu_test.dart`, `test/widget_test.dart`):**
   - `calismalariEkle` ve `dersinKonulariniGetirVeyaOlustur` birim testleri eklendi.
   - Takvimden `+ Çoklu Ders Ekle` butonuyla birden çok dersin tek seferde takvime yerleştirilmesi widget testi eklendi.

## Siradaki adim
- GitHub Actions CI derlemesi ve testlerinin çalıştırılması.
- Modül 2: **Dersler & Konular** geliştirmesine devam edilmesi.

## Bilinen sorunlar / riskler
- Yok. Mevcut tekil konu yerleştirme, Pomodoro F.T. time konu seçimi ve widget testleri geriye dönük tam uyumludur.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
