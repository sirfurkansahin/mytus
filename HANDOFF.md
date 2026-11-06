# HANDOFF.md: Devir notu

Son guncelleme: 6 Kasım 2026, Kütüphane Bölüm Notları ve Fotoğraf Ekleme özelliği eklendi (dal `model2/kutuphane-modulu`).

## Durum
Kullanıcı direktifleri doğrultusunda Kütüphane modülüne bölüm notları alanı ve fotoğraf desteği eklendi:
- **Bölüm Notları (`lib/features/kutuphane/bolum_notlari_ekrani.dart`):**
  - Her bölümün içine birden fazla not kartı eklenebilir.
  - İsteğe bağlı fotoğraf (kamera/galeri) + bilgi girişi/metin alanı. Sadece fotoğraf veya sadece metin de eklenebilir.
  - Kartlarda fotoğraf önizlemesi, metin, eklenme tarihi, düzenleme ve silme butonları.
  - `TamEkranResimEkrani`: Fotoğrafa dokunulduğunda tam ekran açılır ve iki parmakla serbest yakınlaştırma/uzaklaştırma (pinch-to-zoom) yapılabilir (`InteractiveViewer`).
- **Resim Seçici Soyutlaması (`lib/features/kutuphane/resim_secici.dart`):**
  - `ResimSecici` arayüzü, `CihazResimSecici` (`image_picker` ile kamera/galeri) ve `SahteResimSecici` (testler için sıfır bağımlılık).
- **Veri Modelleri & Depo:**
  - `BolumNotu`: id, metin, resimBase64, olusturmaTarihi.
  - `KitapBolumu`: notlar listesi, `notSayisi`, `notVar`.
  - `PlanDeposu`: `kitapBolumNotuEkle`, `kitapBolumNotuGuncelle`, `kitapBolumNotuSil`.
- **Arayüz Entegrasyonu:**
  - Bölüm kartlarında not rozeti (`📝 1 not`) ve doğrudan notları açan buton/dokunma alanı.
  - "SIRADAKİ ÇALIŞILACAK BÖLÜM" odak kartında hızlı not butonu.
  - Kütüphane genel kartında toplam not sayısı gösterimi.
- **Testler:**
  - `test/kutuphane_test.dart`: Model serileştirme ve depo not CRUD testleri.
  - `test/widget_test.dart` ve `test/uctan_uca_test.dart`: Bölüm notları açma, fotoğraf ekleme simülasyonu, metin girme, kaydetme ve rozet görünüm testleri.

## Siradaki adim
- GitHub Actions CI (APK derleme ve Web testleri) doğrulanacak.
- F.T. time modülü üzerinde yapılacak düzenlemeler için kullanıcı direktifleri beklenecek.

## Bilinen sorunlar / riskler
- Bildirim sorunu (sayaç bitişinde sistem bildirimi) kullanıcının talebiyle kapsam dışı bırakılmıştır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
