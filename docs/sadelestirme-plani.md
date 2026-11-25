# Sadelestirme Plani (6 Kasim 2026)

Kullanici kararlari `DECISIONS.md` icinde. Hicbir veri silinmez, yalnizca arayuzden gizlenir (`lib/core/gizli_ozellikler.dart`).

## 🔴 Gizlenecekler (Tamamlandı)
- [x] K1. Gunluk uyku/kafein/kaygi giris ekrani ve 14 gunluk sirkadiyen grafigi (gizlendi; bayraklar: `lib/core/gizli_ozellikler.dart`). Hedef yatis saati + kafein kesilme saati karti acik kaldi.
- [x] K2. Master Kokpit ve 0-100 Bilissel Saglik Skoru (Bugun ekrani ana akisindan gizlendi, bayraga baglandi).
- [x] K3. 3 Dakikalik Vaka Karti (ana menuden gizlendi).
- [x] K4. Mekanizma Zincirleri (ana menuden gizlendi; Referans sekmesine tasindi).
- [x] K5. Blok sonu zorunlu 1-5 odak puani ve "Agir analitik" kutusu (ayar olarak kaldi, varsayilan kapali `odakPuaniSorulsun = false`).
- [x] K6. Kirmizi "Bilissel Tavan Asildi" sert uyarisi (`sertTavanUyarisiAcik = false`).
- [x] K7. Soru bazli guven matrisi girisi (oturum toplami kaldi, soru bazli bayraga baglandi `soruBazliGuvenAcik = false`).
- [x] K8. Arayuzdeki "kanitli" ifadeleri ("referans tavan" olarak yumusatildi).

## 🟡 Sadelestirilecekler
- [ ] S1. Alt menu 4 sekme: Bugun / Plan / Grup / Gelisim (Surum 2 Firebase grubuyla birlikte).
- [x] S2. Bugun ekrani: kalan gun, "Siradaki Gorev", tek Basla dugmesi, 1 satir ozet, gereksiz kartlar kaldirildi.
- [x] S3. Tekrar arayuzu: "Bugun N tekrar" + 3 dugme (✅ Hatirladim / 😐 Zorlandim / ➡️ Yarin).
- [ ] S4. Deneme girisi 3 kademe (ders bazli hizli / oturum sonu guven sayilari).
- [x] S5. A-F hata kodlari 3 kategoriye indirgendi (Bilgi / Yanlis biliyordum / Dikkat-Sure; eski kayitlar icin esleme tablosu yapildi).
- [x] S6. Master Kokpit yerine Ilerleme ekraninda "Haftalik Ozet" (Odak, Konu %, Son Deneme).
- [x] S7. Tavan uyarisi: tek satir, soluk, kapatilabilir.
- [x] S8. 4 defter tek "Defter" (Hata & Celdirici + Salt-okunur Referans).
- [x] S9. Zor gun modu: tek tıkla aktifleşen "Bugün nöbetteyim / Yoğun gün" modu (tekrar yukunu %70'e indirir).
- [ ] S10. Eger-O Zaman motoru 3 kurala indirme.
- [ ] S11. Panik/Prova/EV/Ara Dinlenme "Sinav Modu" altinda toplanmasi.
- [ ] S12. Tanitim turu 5 -> 3 slayt; Rehber tek sayfa + arama.
- [ ] S13. Panik protokolu adi/suresi tutarli (84 sn ↔ "90 sn").
- [x] S14. Gunluk limit: 4 yeni konu + 10 tekrar (iki sinir birlikte, ayarlardan degistirilebilir).

## 🟢 Eklenecekler
- [ ] E1. Canli grup seridi (Surum 2): calisiyor/molada/cevrimdisi; yalnizca baslatma/bitirme aninda yazma (Spark kotasi).
- [x] E2. Tek dokunusla Basla: sayac siradaki konuya/tekrar otomatik baglanir (Bugun ekraninda 25 dk odak).
- [x] E3. WhatsApp'a paylasilabilir haftalik ozet karti (Surum 1'de bile; ozel veri/not asla girmez).
- [ ] E4. Haftalik siralama VE ortak haftalik hedef (Surum 2).
- [x] E5. Zor gun + birikmis tekrar borcu affi ("Tekrarlari affet & bugunden itibaren yeniden dagit").
- [ ] E6. Android ana ekran widget'i.
- [x] E7. Gunluk soru sayaci (+/- butonlari ve +20 hizli ekleme; bellek ve JSON kalici).
- [ ] E8. Seri + donma hakki.

## Kapsam disi
- Bildirim sorunu (sure bitince bildirim gelmemesi): kullanici ozel bir zamanda ilgilenecek. Bu plana dahil degil.
