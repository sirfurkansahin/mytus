# HANDOFF.md: Devir notu

Son guncelleme: 6 Kasım 2026, Kütüphane Modülü eklendi ve F.T. Time geçici olarak gizlendi (dal `model2/kutuphane-modulu`).

## Durum
Kullanıcı direktifleri doğrultusunda Sürüm 1'e Kütüphane modülü eklendi ve F.T. time modülü geçici olarak arayüzden kaldırıldı:
- **F.T. Time Modülü:**
  - `lib/core/gizli_ozellikler.dart` içinde `const bool ftTimeAcik = false;` tanımlandı.
  - Kodlar silinmedi; motor ve sayaç mantığı projede duruyor. Düzenleme sonrası tekrar açılacak.
  - Bugün ekranındaki sayaç başlatma butonu gizlendi.
  - Alt gezinme çubuğundaki (NavigationBar) 4. sekme F.T. time yerine **Kütüphane** oldu.
- **Kütüphane Modülü (`lib/features/kutuphane/`):**
  - `modeller.dart`: `Kitap` ve `KitapBolumu` modelleri, ilerleme oranı, kalan bölüm sayısı, sıradaki çalışılacak bölüm hesabı ve `topluBolumleriAyristir()` fonksiyonu.
  - `kitap_ekle_dialogu.dart`: Kitap adı, ders/branş seçimi, toplam sayfa sayısı ve 2 farklı içindekiler ekleme modu:
    1. *Toplu Yapıştırma (Hızlı):* Sayfadan kopyalanan veya telefon kamerasından (Google Lens / Canlı Metin) taranan çok satırlı metni alt alta satır satır bölümlere ve sayfa aralıklarına dönüştürür.
    2. *Tek Tek Ekleme:* Bölüm adı ve isteğe bağlı sayfa aralığı (örn. s. 1–35).
  - `kitap_detay_ekrani.dart`: Bölüm listesi, tek dokunuşla `[✓] Çalışıldı` işaretleme, çalışma tarihi, en üstte sıradaki çalışılacak bölüm odak kartı, filtreler (Tümü / Kalanlar / Bitenler), yeni bölüm ekleme ve kitap silme.
  - `kutuphane_ekrani.dart`: Genel kütüphane ilerleme kartı (toplam kitap, toplam bölüm, biten bölüm, genel yüzde), kitap kartları (ders rozeti, yüzde, ilerleme çubuğu, sıradaki bölüm etiketi) ve boş kütüphane karşılama kartı.
- **Veri Kalıcılığı:**
  - Kitaplar ve bölümler `PlanDeposu`'nun yerel JSON yapısına entegre edildi (`kitaplar` anahtarı); yedekleme, geri yükleme ve sıfırlama sistemine tam uyumlu.
- **Testler:**
  - `test/kutuphane_test.dart`: Model hesapları, toplu metin ayrıştırma, JSON serileştirme ve depo entegrasyonu testleri.
  - `test/widget_test.dart` ve `test/uctan_uca_test.dart`: F.T. time testleri doğrudan ekran üzerinden çağrılarak korundu; yeni Kütüphane widget ve uçtan uca testleri eklendi.

## Siradaki adim
- GitHub Actions CI (APK derleme ve Web testleri) doğrulanacak.
- F.T. time modülü üzerinde yapılacak düzenlemeler için kullanıcı direktifleri beklenecek.

## Bilinen sorunlar / riskler
- Bildirim sorunu (sayaç bitişinde sistem bildirimi) kullanıcının talebiyle kapsam dışı bırakılmıştır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
