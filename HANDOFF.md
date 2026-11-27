# HANDOFF.md: Devir notu

Son guncelleme: 27 Kasım 2026, Claude (denetim sonrası 2. aşama; `model2/github-temizlik` ile birleştirildi).

## Durum
- **27 Kasım 2026, GitHub temizliği (`model2/github-temizlik`, PR #21 ile `main`'de):**
  - `github-pages` ortamı yalnızca `main` dalına kısıtlandı (`claude/*` ve `model2/*` yayın izinleri kaldırıldı).
  - PR birleşince otomatik dal silme (`delete_branch_on_merge`) açıldı.
  - İçeriği zaten `main`'e alınmış 29 eski dal + gereksiz `claude/s2-giris-yedek` dalı silindi (birleşmemiş aktif dallar ve kanıt dalları korundu).
  - Kullanılmayan 5 eski Secret (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_TESTERS`, `FIREBASE_WEB_APP_ID`) silindi; yalnızca aktif 5 Firebase Web anahtarı kaldı.
  - Eski Android döneminden kalan `.github/workflows/bootstrap-android.yml` kaldırıldı ve `README.md` güncel Web Mobil (PWA) durumuna göre yenilendi.
  - Not (Claude): dal silme `git ls-remote` ile doğrulandı. Ortam kısıtı ve Secret silme bu ortamdan görülemiyor (doğrulanmadı).
- **25 Kasım 2026, denetim 1. aşama (PR #20 ile `main`'de):** `claude/yayin-yalniz-main`,
  `claude/kayit-hatasi-uyari`, `claude/bulut-esitleme-onarim`, `claude/kayit-alan-koruma`
  (A1–A3 ve "yalnız main yayınlar").
- **27 Kasım 2026, denetim 2. aşama:** kullanıcının 25 Kasım kararları ve onayladığı bulgular
  ayrı dallarda, zincir halinde yapıldı; hepsi GitHub Actions'ta geçti:

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
| `claude/belgeler-guncel` | A11: DECISIONS/README güncel; A9: kalan kanıt testleri kalıcı testlere alındı; `main` (PR #21) ile birleştirildi | #105 geçti (220 test) |

Zincir: `main` ← yukarıdaki dallar, tablo sırasıyla. Son dal `main`'i (PR #21) de içerir.

## Sıradaki adım
1. 2. aşamayı `main`'e almak: kullanıcı 27 Kasım'da onayladı; aynı saatlerde `model2` de
   `main`'e yazdığı için Claude birleştirmeden önce kullanıcıya bir kez daha soruyor.
2. Onaylananlar, ayrı dallarda: B4 (Bugün üstü: "A · Kısayol şeridi" seçildi) ve F.T. time
   gizliyken Tanıtım turu/Rehber anlatımı ile İlerleme'deki odak kutularının gizlenmesi.
   Her biri için `main`'e birleştirme ayrıca sorulur.
3. Birleştirmeden sonra: 2. aşama dalları ve kanıt dalları (`claude/kanit-testleri-main`,
   `claude/kanit-testleri-uc`) silinebilir. Bu ortamdan dal silinemiyor (403).

## Kanıt testleri (A9)
KANIT-01…17'nin karşılığı artık kalıcı testlerde. KANIT-03 (%70 Kurtarma Modu) özellik
kaldırıldığı için düştü.

## Bilinen sorunlar / notlar
- 27 Kasım'da iki model aynı saatlerde depoya yazdı (`model2`: GitHub temizliği; Claude:
  2. aşama). Kod çakışması olmadı; README ve HANDOFF elle birleştirildi.
- Bulut eşitlemesinin Firestore tarafı (sunucudan okuma, önbellek olaylarını atlama) gerçek
  Firebase'de denenmedi; testler sahte bulutla.
- `kurtarmaModuAktif` alanı eski kayıtlarla uyum için kayıtta duruyor; hiçbir şeyi etkilemiyor.
- Arka planda süre bitince bildirim gelmemesi (17 Ekim 2026 notu) planın dışında.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
