/// Arayüzden GİZLENEN özellikler (Sadeleştirme Planı, 6 Kasım 2026).
/// Veri silinmez: kayıtlar JSON dosyasında durur, yalnızca ekranlarda görünmez.
/// Bir özelliği geri açmak için ilgili değeri `true` yapmak yeterlidir.
/// Not: Bilişsel, uyku, kafein ve nefes bölümleri ile Master Kokpit gizli değil,
/// tamamen KALDIRILDI (25 Kasım 2026 kullanıcı kararı).
library;

/// F.T. time modülü (geçici olarak kapatıldı; düzenleme sonrası tekrar açılacak).
const bool ftTimeAcik = false;

/// K3: 3 Dakikalık Vaka Kartı sekmesi.
const bool vakaKartiAcik = false;

/// K4: Mekanizma Zincirleri sekmesi.
const bool mekanizmaZinciriAcik = false;

/// K5: F.T. time blok sonunda zorunlu 1-5 odak puanı ve Ağır Analitik kutusu.
const bool odakPuaniSorulsun = false;

/// K7: Deneme girişinde soru bazlı güven matrisi.
const bool soruBazliGuvenAcik = false;
