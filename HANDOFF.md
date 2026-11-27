# HANDOFF.md: Devir notu

Son guncelleme: 27 Kasım 2026, GitHub temizliği (`model2/github-temizlik`).

## Durum
- **27 Kasım 2026 (GitHub temizliği — `model2/github-temizlik`):**
  - GitHub `github-pages` ortamı yalnızca `main` dalına kısıtlandı (`claude/*` ve `model2/*` yayın izinleri kaldırıldı).
  - PR birleşince otomatik dal silme (`delete_branch_on_merge`) açıldı.
  - İçeriği zaten `main`'e alınmış 29 eski dal + gereksiz `claude/s2-giris-yedek` dalı silindi (birleşmemiş aktif dallar ve kanıt dalları korundu).
  - Eski Android döneminden kalan `.github/workflows/bootstrap-android.yml` kaldırıldı ve `README.md` güncel Web Mobil (PWA) durumuna göre yenilendi.
- **25 Kasım 2026 (Denetim 1. aşama — PR #20 ile `main`'de yayında):**
  1. aşama düzeltmeleri (`claude/yayin-yalniz-main`, `claude/kayit-hatasi-uyari`, `claude/bulut-esitleme-onarim`, `claude/kayit-alan-koruma`) `main` dalına birleştirilip canlıya alındı.

| Dal | İçerik | CI |
|---|---|---|
| `claude/yayin-yalniz-main` | `deploy-web.yml`: testler her dalda, canlı yayın YALNIZ `main`'den | #81 geçti, yayın atlandı |
| `claude/kayit-hatasi-uyari` | A1: cihaza yazılamazsa (depo dolu) uyarı şeridi + "Tekrar dene"; fotoğraflar tek kopya, silinen notun fotoğrafı kalmaz | #82 geçti (195 test) |
| `claude/bulut-esitleme-onarim` | A2: gönderilemeyen bölümler kalıcı; bulut okunamazsa hiçbir şey gönderilmez; cihaz/hesap farklıysa kullanıcıya sorulur + yedeği geri getirme; bölüm içeriğine göre eşitleme; aktif grup korunur | #83 geçti (203 test) |
| `claude/kayit-alan-koruma` | A3: kayıt sürümü 2, tanınmayan alanlar korunur; eksik "kitaplar" alanında örnek kitap eklenmez | #84 geçti (206 test) |

## Kullanıcı kararları (25 Kasım 2026)
DECISIONS.md'ye "Denetim Sonrası Kararlar" başlığıyla yazıldı.

## Sıradaki adım
1. `model2/github-temizlik` dalı kullanıcı onayıyla `main`'e birleştirilebilir.
2. 2. aşama dalları (`claude/ekran-metin-duzeltmeleri`, `claude/veri-hesap-duzeltmeleri`, `claude/sinav-tarihi-secimi`, `claude/bilissel-icerik-kaldir`, `claude/affet-dagit`, `claude/ders-paylasimi-istege-bagli`, `claude/puan-secenek-c`) tamamlanıp testleri geçtikten sonra `main`'e alınacak.
3. Kullanılmayan 5 eski Secret (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_TESTERS`, `FIREBASE_WEB_APP_ID`) kullanıcı onayına göre temizlenecek.

## Bilinen sorunlar / notlar
- Kanıt dalları (`claude/kanit-testleri-main`, `claude/kanit-testleri-uc`) düzeltmeler bitince silinecek.
- Bulut eşitlemesinin Firestore tarafı (sunucudan okuma, önbellek olaylarını atlama) gerçek
  Firebase'de denenmedi; testler sahte bulutla.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
