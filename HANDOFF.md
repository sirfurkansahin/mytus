# HANDOFF.md: Devir notu

Son guncelleme: 27 Kasım 2026, Claude (denetim sonrası düzeltmeler, 2. aşama bitti).

## Durum
- 1. aşama (A1–A3 + "yalnız main yayınlar") 25 Kasım 2026'da kullanıcı onayıyla `main`'e
  alındı ve canlıda (`3dcd6de`).
- 2. aşama: kullanıcının 25 Kasım kararları ve onayladığı bulgular ayrı dallarda, zincir
  halinde yapıldı; hepsi GitHub Actions'ta geçti. `main`'e henüz ALINMADI.

| Dal | İçerik | CI |
|---|---|---|
| `claude/ekran-metin-duzeltmeleri` | B1, B2, B5, C4: kaybolan sayılar geri kondu, 320 px ekranda taşma yok, tahmini puan 45'e yükseltilmiyor, nöbet düğmesine sağlık simgesi | #89 geçti |
| `claude/veri-hesap-duzeltmeleri` | A4, A5, A6, A8: sıfırla/müfredat uyarıları doğru, hesap silmeden önce şifre doğrulaması, yarıda bozulan yedek veriyi değiştirmez, eski kayıtta müfredat tanınır, çalışılmamış konunun tekrarları sınıra sayılmaz, grup puanı haftalık | #90 geçti |
| `claude/sinav-tarihi-secimi` | Karar 1: 27 Mart veya 22 Ağustos 2027 (karşılama + Ayarlar) | #92 geçti |
| `claude/bilissel-icerik-kaldir` | Karar 2 ve 3: Bilişsel & Uyku, nefes/panik, kafein, Kokpit, %70 Kurtarma Modu kaldırıldı | #98 geçti |
| `claude/affet-dagit` | Karar 6: "Tekrarları affet & dağıt" gecikenleri günlük sınırla dağıtır, yapıldı saymaz | #100 geçti |
| `claude/ders-paylasimi-istege-bagli` | Karar 7: son ders paylaşımı Ayarlar'dan açılır, varsayılan kapalı | #101 geçti |
| `claude/puan-secenek-c` | Karar 8: puan her yerde 1 konu = 10, 1 soru = 1; odak süresi "dk"; sabit "22 Ağustos" metinleri seçilen tarihe bağlandı | #102 geçti (212 test) |
| `claude/ornek-kitap-kaldir` | Karar 9: örnek kitap kaldırıldı; cihazdan, yedekten ve buluttan da siliniyor | #104 geçti (217 test) |
| `claude/belgeler-guncel` | A11: DECISIONS/README güncel; A9: kalan kanıt testleri kalıcı testlere alındı; bu dosya | #105 geçti (220 test) |

Zincir: `main` ← yukarıdaki dallar, tablo sırasıyla (her dal bir öncekinin üstünde).
`main` zincirin atasıdır; birleştirme "ileri sarma" ile çakışmasız olur.

## Sıradaki adım
1. B4 (Bugün ekranının üstündeki 6 simge): kullanıcıya taslak gösterildi, seçimi bekleniyor.
   Seçime göre ayrı dalda (`claude/bugun-ust-simgeler`) yapılacak.
2. `main`'e birleştirme: kullanıcının AÇIK izniyle (birleştirme siteyi yayınlar). Sonra canlı
   sitede doğrulama.
3. Birleştirmeden sonra: 2. aşama dalları ve kanıt dalları silinebilir (bkz. aşağı).

## Kanıt testleri (A9)
KANIT-01…17'nin karşılığı artık kalıcı testlerde. KANIT-03 (%70 Kurtarma Modu) özellik
kaldırıldığı için düştü. Kanıt dalları (`claude/kanit-testleri-main`, `claude/kanit-testleri-uc`)
artık gerekmiyor.

## Bilinen sorunlar / notlar
- Bu ortamdan dal SİLİNEMİYOR (git push --delete: 403, ağ politikası). Kullanıcının silmeyi
  onayladığı, içeriği main'de olan dallar: claude/ders-konu-not, claude/ft-ayarlar-puan,
  claude/ft-sayac-prototip, claude/ft-time-sadelestirme, claude/ilerleme, claude/imza-ve-dagitim,
  claude/kapanis, claude/on-plan-servisi, claude/takvim-tekrar, claude/uctan-uca-test,
  model2/ft-time-temizlik, model2/ios-web-test, model2/rapor-tekrar-sistemi,
  model2/speetus-mufredat; ayrıca claude/s2-giris-yedek (tek değişiklik 6c6c32eda6f1,
  APK imza parmak izi; artık gereksiz). GitHub > Branches sayfasından silinebilir.
- GitHub ayarı: `github-pages` ortamı yalnız `main`'e izin verecek şekilde kısıtlanmalı
  (kullanıcıya adımlar verildi; buradan API ile değiştirilemiyor).
- Bulut eşitlemesinin Firestore tarafı (sunucudan okuma, önbellek olaylarını atlama) gerçek
  Firebase'de denenmedi; testler sahte bulutla.
- F.T. time gizli (`ftTimeAcik = false`), ama Tanıtım turu (2. slayt) ve Rehber (3. kategori)
  onu anlatıyor. Karar sorusu olarak kullanıcıya iletildi.
- `kurtarmaModuAktif` alanı eski kayıtlarla uyum için kayıtta duruyor; hiçbir şeyi etkilemiyor.
- `.github/workflows/bootstrap-android.yml` her `main` gönderiminde çalışıyor ama `android/`
  klasörü olduğu için hiçbir şey yapmıyor. APK kaldırıldığından silinebilir (kullanıcıya sorulmadı).
- Arka planda süre bitince bildirim gelmemesi (17 Ekim 2026 notu) planın dışında.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
