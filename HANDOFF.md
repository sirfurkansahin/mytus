# HANDOFF.md: Devir notu

Son guncelleme: 25 Kasım 2026, Claude (denetim raporu sonrası düzeltmeler, 1. aşama).

## Durum
25 Kasım 2026'da tüm dallar denetlendi (rapor sohbette verildi). Kullanıcının kararlarıyla
1. aşama düzeltmeleri ayrı dallarda, zincir halinde yapıldı; hepsi GitHub Actions'ta geçti:

| Dal | İçerik | CI |
|---|---|---|
| `claude/yayin-yalniz-main` | `deploy-web.yml`: testler her dalda, canlı yayın YALNIZ `main`'den | #81 geçti, yayın atlandı |
| `claude/kayit-hatasi-uyari` | A1: cihaza yazılamazsa (depo dolu) uyarı şeridi + "Tekrar dene"; fotoğraflar tek kopya, silinen notun fotoğrafı kalmaz | #82 geçti (195 test) |
| `claude/bulut-esitleme-onarim` | A2: gönderilemeyen bölümler kalıcı; bulut okunamazsa hiçbir şey gönderilmez; cihaz/hesap farklıysa kullanıcıya sorulur + yedeği geri getirme; bölüm içeriğine göre eşitleme; aktif grup korunur | #83 geçti (203 test) |
| `claude/kayit-alan-koruma` | A3: kayıt sürümü 2, tanınmayan alanlar korunur; eksik "kitaplar" alanında örnek kitap eklenmez | #84 geçti (206 test) |

Zincir: `main` ← `claude/esnek-giris-bulut` (önceki 11 dallık iş zinciri) ← yukarıdaki 4 dal.
`main` bu zincirin atasıdır; birleştirme "ileri sarma" ile çakışmasız olur.
Canlı site şu an hâlâ 13 Kasım'daki `claude/esnek-giris-bulut` sürümünü gösteriyor.

## Kullanıcı kararları (25 Kasım 2026)
DECISIONS.md'ye "Denetim Sonrası Kararlar" başlığıyla yazıldı.

## Sıradaki adım
1. `main`'e birleştirme: kullanıcının AÇIK izniyle (birleştirme siteyi yayınlar).
2. 2. aşama (onaylandı, her biri ayrı dalda): sınav tarihi seçimi (27 Mart / 22 Ağustos 2027),
   bilişsel/uyku/kafein/nefes bölümlerinin tamamen kaldırılması (Kurtarma Modu dahil),
   "Tekrarları affet & dağıt" gecikenleri dağıtsın, son ders paylaşımı isteğe bağlı (varsayılan kapalı),
   puan her yerde Seçenek C, TUSDATA örnek kitabının kaldırılıp mevcut kütüphanelerden de silinmesi,
   A4 (sıfırla/müfredat/hesap silme/yedek), A5, A6, A8, C4 (45 puan), B1, B2, B5, A9, A11,
   B4 (önce taslak göster).

## Bilinen sorunlar / notlar
- Bu ortamdan dal SİLİNEMİYOR (git push --delete: 403, ağ politikası). Kullanıcının silmeyi
  onayladığı, içeriği main'de olan dallar: claude/ders-konu-not, claude/ft-ayarlar-puan,
  claude/ft-sayac-prototip, claude/ft-time-sadelestirme, claude/ilerleme, claude/imza-ve-dagitim,
  claude/kapanis, claude/on-plan-servisi, claude/takvim-tekrar, claude/uctan-uca-test,
  model2/ft-time-temizlik, model2/ios-web-test, model2/rapor-tekrar-sistemi,
  model2/speetus-mufredat; ayrıca claude/s2-giris-yedek (tek değişiklik 6c6c32eda6f1,
  APK imza parmak izi; artık gereksiz). GitHub > Branches sayfasından silinebilir.
- Kanıt dalları (`claude/kanit-testleri-main`, `claude/kanit-testleri-uc`) düzeltmeler bitince silinecek.
- GitHub ayarı: `github-pages` ortamı yalnız `main`'e izin verecek şekilde kısıtlanmalı
  (kullanıcıya adımlar verildi; buradan API ile değiştirilemiyor).
- Bulut eşitlemesinin Firestore tarafı (sunucudan okuma, önbellek olaylarını atlama) gerçek
  Firebase'de denenmedi; testler sahte bulutla.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
