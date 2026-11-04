# HANDOFF.md: Devir notu

Son guncelleme: 4 Kasim 2026 (Gemini), Kullanım Rehberi & Görsel Tanıtım Turu tamamlandı (`model2/kullanim-rehberi`, PR hazırlanıyor).

## Durum
Tüm modüller aktif, birim ve uçtan uca testleri geçmiş ve CI doğrulaması tamamlanmıştır:
- **Faz 1 (Modül 1: Deneme Sınavları & Bilişsel Hata Analizi - PR #12):**
  - 200 soru (100 TTBT + 100 KTBT, 135'er dk), ÖSYM net formülü (Doğru - Yanlış/4).
  - Klinik Ağırlıklı K Puanı (0.4 TTBT + 0.6 KTBT) ve ÖSYM 85 EBAP tavan tahmin puanı.
  - A–F Hata Sınıfları (A: Bilgi, B: Yanlış İnanç, C: Okuma/Kurgu, D: Mantık, E: Süre, F: Form).
  - Güven Matrisi (Emin / Kararsız / Tahmin), Kalibrasyon Farkı ve B Sınıfı Hiperdüzeltme Alarmları.
- **Faz 2 (Modül 2: Özel Defterler & Akıllı Havuz - PR #13):**
  - Hata Defteri & Çeldirici Bankası (karışan çeldirici, ayıran tek kriter, adayın kendi kuralı).
  - Sınıflama & Skor Defteri (10+ hazır TUS skoru: Hinchey, Wells, CURB-65 vb. ve özel skorlar).
  - Mekanizma Zincirleri (Illness Script - 6 branş 5 halkalı şablonlar).
  - 3 Dakikalık Vaka Kartı (klinik vizit vakalarını TUS soru kalıbına dönüştürme).
- **Faz 3 (Modül 3: Nörobiyoloji, Uyku & Bilişsel Performans - PR #14):**
  - F.T. Time blok sonu 1-5 odak puanı ve "Ağır Analitik İş" takibi.
  - Zor Bilişsel İş Tavanı (günlük 180 dk uyarı, 240 dk / 4 saat kanıtlı tavan aşımı).
  - Sirkadiyen Odak Dağılımı ve 14 günlük biyolojik verim eğrisi.
  - Uyku & Kafein Disiplini (hedef yatıştan 8 saat önce kafein kesilme alarmı, sirkadiyen sapma hesabı).
  - Prefrontal Korteks %70 Yük Kurtarma Modu (C hatası > %15 ise yük %70'e iner, sadece R1-R2 tekrarları yapılır).
- **Faz 4 (Modül 4: Sınav Anı, Panik Protokolü & Provalar - PR #15):**
  - 84 saniyelik Huberman Lab Döngüsel İç Çekme (Cyclic Sighing) görsel nefes rehberi ve Jamieson uyarılmayı yeniden değerlendirme kartı.
  - Gerçek Saat Sınav Provası (135 dk geri sayım, 25, 50, 75, 100. soru tempo kontrolleri).
  - İki oturum arası 135 dk Ara Dinlenme Protokolü.
  - Beklenen Değer (EV) Kartı (+0.167 net matematiksel kazanç ve cevap değiştirme kuralları).
- **Faz 5 (Modül 5: Master Yönetim Kokpiti & Karar Motoru - PR #16):**
  - Haftalık 8 Bilişsel Gösterge (Kalibrasyon, Aşırı Güven, Uyku, PFC C Hatası, Kaygı, R1, R3, Odak/Tavan).
  - 4 Sınav Göstergesi (Temel Net, Klinik Net, K Puanı, EBAP Puanı).
  - 0-100 Kompozit Bilişsel Sağlık Skoru.
  - Otomatik "Eğer–O Zaman" (If-Then) Strateji ve Eylem Motoru.
- **Kullanım Rehberi & Görsel Tanıtım Turu (`model2/kullanim-rehberi`):**
  - `TanitimTuruEkrani`: 5 tematik görsel slayt (Planlama & Tekrar, Odak & 3-4 Saat Tavanı, Hata Defteri & Çeldirici, Sınav Anı & 90 sn Nefes, Master Kokpit).
  - `RehberEkrani`: 6 ana kategoride detaylı Sıkça Sorulan Sorular (SSS) ve modül kullanım kılavuzu.
  - Karşılama, Bugün ve Ayarlar ekranlarında doğrudan erişim kısayolları.
  - `test/rehber_test.dart` ve `test/widget_test.dart` (rehberTestleri) ile doğrulandı.

## Siradaki adim
1. Değişiklikler GitHub'a gönderilecek (`origin model2/kullanim-rehberi`) ve PR açılacak.
2. GitHub Actions (APK derle ve Web dağıt) yeşil olunca kullanıcıya raporlanıp onayı istenecek.
3. Kullanıcı onayıyla PR birleştirilecek.

## Bilinen sorunlar / riskler
- Bulut ortamında yerel derleme kısıtlıdır; tüm analiz, test ve derlemeler GitHub Actions üzerinde yeşil olarak doğrulanmaktadır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
