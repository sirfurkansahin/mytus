# HANDOFF.md: Devir notu

Son guncelleme: 13 Kasım 2026, Misafir Modu & Esnek Bulut Girişi tamamlandı (dal `claude/esnek-giris-bulut`).

## Durum
Kullanıcının tercihi doğrultusunda "Misafir Modu & Esnek Giriş" akışı eksiksiz uygulandı:
- **Giriş Ekranı (`lib/features/auth/giris_ekrani.dart`):**
  - İlk açılışta zorunlu giriş barajı kaldırıldı. Giriş/Kayıt butonlarının altına "Hesap Açmadan Devam Et (Misafir Modu)" seçeneği eklendi.
  - Hekimlerin nöbette veya ilk denemede vakit kaybetmeden uygulamayı doğrudan kullanabilmesi sağlandı.
  - Ekran Ayarlar'dan açıldığında kapatma ikonu (`X`) ve işlem tamamlanınca geri dönme desteği eklendi (`misafirModundanMi`).
- **Veri Kalıcılığı ve Misafir Durumu (`lib/features/dersler/plan_deposu.dart`):**
  - `PlanDeposu` içerisine `misafirModu` durumu ve `misafirModunuAyarla(bool)` metodu eklendi; yerel bellekte (`localStorage`) kalıcı olarak saklanır.
  - `_AcilisKapisi` (`lib/main.dart`): Kullanıcı misafir modunu seçtiğinde veya oturum açtığında doğrudan karşılama veya ana ekrana yönlendirilir.
- **Ayarlar Ekranında Buluta Bağlan Kartı (`lib/features/ayarlar/ayarlar_ekrani.dart`):**
  - Misafir modundaki kullanıcıya Ayarlar sekmesinde mor temalı `_BulutaBaglanKarti` sunulur: "Şu an yerel moddasın, tek dokunuşla buluta yedekle ve diğer cihazlarınla eşitle".
  - Giriş yapıldığında mevcut yerel veriler (dersler, notlar, takvim, kütüphane) otomatik olarak yeni bulut hesabına aktarılır (İlk Giriş Göçü) ve kart `HesapKarti`na dönüşür.
- **Çıkış ve Hesap Silme (`lib/features/auth/hesap_karti.dart`):**
  - Oturum kapatıldığında veya hesap silindiğinde misafir modu sıfırlanarak kullanıcı başlangıç giriş ekranına yönlendirilir.
- **Çalışma Grubu Köprüsü (`lib/features/grup/grup_ekrani.dart`):**
  - Misafir modundaki kullanıcı bir gruba katılmak veya grup kurmak istediğinde doğrudan bulut girişine yönlendirilir.
- **Testler (`test/kimlik_servisi_test.dart`):**
  - Misafir modu seçimiyle uygulamaya geçiş ve Ayarlar'dan bulut hesabına bağlanıp verilerin eşitlenmesi widget testleri eklendi.

## Siradaki adim
- Kullanıcı talebine göre sıradaki modül geliştirmeleri (F.T. Time odak sayacı, Deneme Sınavı analizi veya Google ile Giriş).

## Bilinen sorunlar / riskler
- Yok. Geriye dönük tam uyumludur.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
