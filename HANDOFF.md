# HANDOFF.md: Devir notu

Son guncelleme: 8 Kasım 2026, Kullanıcı Girişi (Firebase Auth) ve Bulut Eşitlemesi (Cloud Firestore) entegre edildi (dal `claude/hesap-bulut`).

## Durum
Kullanıcı kararı doğrultusunda MY TUS Web Mobil (PWA) uygulamasına kullanıcı hesabı ve bulut eşitleme altyapısı eklendi:
- **Firebase Altyapısı ve Güvenlik (`mytus-3527d`):**
  - `MY TUS Web` uygulaması oluşturuldu, E-posta/Şifre girişi etkinleştirildi ve `sirfurkansahin.github.io` yetkili alan adlarına eklendi.
  - Cloud Firestore (`eur3` - Avrupa) veritabanı ve yalnızca kullanıcının kendi verisini (`kullanicilar/{uid}`) okuyup yazabildiği `firestore.rules` kuralları canlıya alındı.
  - Firebase yapılandırma anahtarları GitHub Actions gizli değişkenlerine (`Secrets`) kaydedildi ve `.github/workflows/deploy-web.yml` içinde `--dart-define` ile bağlandı.
- **Kimlik Doğrulama (`lib/features/auth/`):**
  - `KimlikServisi`, `FirebaseKimlikServisi` ve testler için `SahteKimlikServisi` eklendi.
  - İlk açılışta oturum yoksa `GirisEkrani` (Giriş Yap, Kayıt Ol + Takma Ad + KVKK onay kutusu, Şifremi Unuttum) açılır; girişten sonra oturum açık kalır.
  - Ayarlar ekranına `HesapKarti` eklendi (oturum durumu, Çıkış Yap, KVKK Aydınlatma, Hesabımı ve Verilerimi Sil).
- **Çevrimdışı Öncelikli Bulut Eşitleme (`lib/features/senkronizasyon/`):**
  - `BolumAyirici`: Veriyi 1 MB sınırına takılmaması için 6 mantıksal bölüme (`ayarlar`, `plan`, `odak`, `denemeler`, `defterler`, `kutuphane`) ayırır; kütüphane fotoğraflarını buluta göndermeyip cihazda hesaba özel (`mytus_photos_{uid}`) saklar.
  - `BulutSenkronServisi`: Her değişikliği önce yerel hafızaya yazar, yalnızca değişen bölümleri Firestore'a eşitler, ilk girişte mevcut yerel verileri yeni bulut hesabına aktarır (göç) ve başka cihazlardan gelen güncellemeleri anında uygular.
- **Testler:**
  - `test/kimlik_servisi_test.dart` ve `test/senkronizasyon_test.dart` eklendi; mevcut testlerin (`MyTusApp(deposu: ...)`) geriye dönük uyumluluğu korundu.

## Siradaki adim
- Çoklu cihazda canlı kullanım geri bildirimleri veya ileride fotoğraflar için bulut depolama çözümü.

## Bilinen sorunlar / riskler
- Kütüphane fotoğrafları kullanıcı kararıyla ilk aşamada yalnızca eklendiği cihazda hesaba özel olarak saklanır; başka cihazdan girildiğinde not metinleri görünür.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
