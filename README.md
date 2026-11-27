# MY TUS

Kişisel TUS çalışma süreci takibi ve planlama uygulaması (**Web Mobil / PWA**, Flutter). Soru bankası değildir; tıbbi içerik üretmez (yalnız küçük, salt-okunur "Referans" bölümü var).

**Canlı Adres:** https://sirfurkansahin.github.io/mytus/

## Temel Özellikler
- **Plan:** Sınav dönemi seçimi (27 Mart veya 22 Ağustos 2027), günlük yeni konu ve tekrar sınırı.
- **Bugün & Takvim:** Konu yerleştirme, R0–R4 aralıklı tekrar motoru, gecikme kayması, telafi planı ve "Tekrarları affet & dağıt".
- **Dersler:** Klasik Branşlar veya SpeeTUS Sarmal Sistem müfredat seçimi, kişisel konu notları (notlar özeldir, paylaşılmaz).
- **Denemeler:** Net, kabaca tahmini TUS puanı (45 barajı altı açıkça yazılır) ve hata analizi.
- **Kütüphane:** Kitap ve bölüm ilerleme takibi, fotoğraflı/etiketli bölüm notları, takvim köprüsü.
- **Misafir Modu & Bulut Eşitleme:** Hesap açmadan yerel kullanım veya e-posta/şifre ile bulut yedekleme (Firebase Spark).
- **Çalışma Grubu:** Davet koduyla 2–10 kişilik çalışma grubu, haftalık puan tablosu ve ortak hedef takibi. Puan: 1 biten konu = 10, 1 çözülen soru = 1. Son çalışılan ders adı yalnız Ayarlar'dan açılırsa görünür.

## Geliştirme ve Yayın
- Kod analizi, testler ve Flutter Web derlemesi GitHub Actions (`.github/workflows/deploy-web.yml`) üzerinden her dalda otomatik çalışır.
- Canlı yayın yalnızca `main` dalından GitHub Pages üzerine yapılır; `main`'e birleştirme kullanıcının açık izniyle.

## Proje Belgeleri
- Güncel durum ve sıradaki adım: `HANDOFF.md`
- Onaylı ürün ve teknik kararlar: `DECISIONS.md`
- Çalışma kuralları: `AGENTS.md`
