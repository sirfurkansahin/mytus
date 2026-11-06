/// Arayüzden GİZLENEN özellikler (Sadeleştirme Planı, 6 Kasım 2026).
/// Veri silinmez: kayıtlar JSON dosyasında durur, yalnızca ekranlarda görünmez.
/// Bir özelliği geri açmak için ilgili değeri `true` yapmak yeterlidir.
library;

/// F.T. time modülü (geçici olarak kapatıldı; düzenleme sonrası tekrar açılacak).
const bool ftTimeAcik = false;

/// K1: Günlük uyku kaydı girişi ve son kayıtlar listesi.
/// (Hedef yatış saati ve kafein kesilme saati kartı açık kalır.)
const bool gunlukUykuGirisiAcik = false;

/// K1: 14 günlük sirkadiyen odak (biyolojik verim saatleri) grafiği.
const bool sirkadiyenGrafikAcik = false;

/// K2: Master Kokpit ve 0-100 Bilişsel Sağlık Skoru ekranı (giriş noktaları).
const bool kokpitAcik = false;

/// K3: 3 Dakikalık Vaka Kartı sekmesi.
const bool vakaKartiAcik = false;

/// K4: Mekanizma Zincirleri sekmesi.
const bool mekanizmaZinciriAcik = false;

/// K5: F.T. time blok sonunda zorunlu 1-5 odak puanı ve Ağır Analitik kutusu.
const bool odakPuaniSorulsun = false;

/// K6: Kırmızı (sert) Bilişsel Tavan uyarısı. Kapalıyken tek satırlık soluk not çıkar.
const bool sertTavanUyarisiAcik = false;

/// K7: Deneme girişinde soru bazlı güven matrisi.
const bool soruBazliGuvenAcik = false;
