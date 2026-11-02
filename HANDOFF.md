# HANDOFF.md: Devir notu

Son guncelleme: 2 Kasim 2026 (Gemini), Surum 1 modulleri (1-7) bastan sona gelistirildi (`model2/moduller-gelistirme`), Actions dogrulamasi ve birlestirme asamasinda

## Durum
- Faz 2 (kurulum) TAMAMLANDI (16 Ekim 2026): GitHub deposu + Actions derlemesi calisiyor, Firebase projesi (mytus, Spark, com.mytus.app) kuruldu, bos uygulama Firebase App Distribution ile kullanicinin realme GT 2 telefonuna kuruldu ve acildi.
- Faz 3 (UX/UI tasarim) TAMAMLANDI ve onaylandi; taslaklar `docs/tasarim/` altinda.
- PR #7 (`claude/ft-time-sadelestirme`) ve PR #8 (`model2/ft-time-temizlik`) `main` dalina BIRLESTI (2 Kasim 2026).
- Dal `model2/moduller-gelistirme`: Surum 1'in tum 7 modulu kullanici onayiyla gelistirildi:
  1. **Karsilama:** Resmi TUS sinav tarihi `22 Agustos 2027` (`resmiSinavTarihi`) sabitlendi, kalan gun sayisi, secili ders sayisi (`Dersler (X secili)`), `Tumunu kaldir / Tumunu sec` ve en az 1 ders kontrolu eklendi.
  2. **Bugun:** Puan gosterimi kaldirildi, sinav tarihi sabitlendi, gunluk gorev ilerleme cubugu (`X / Y gorev`), `+ Bugune konu yerlestir`, gecikenler icin `Tumunu bugune al` ve alt kisimda `Yarinin plani` ozeti eklendi.
  3. **Dersler / Konu / Not:** Dersler ekraninda grup bazli `Bu grupta X konu · Y calisildi` alt basligi, Ders Detay ekraninda `Tumu / Bekleyen / Calisilan` filtre cipleri ve durum simgeleri, Konu ekraninda tek dokunusla `Bugun calistim` dugmesi eklendi.
  4. **Takvim ve Tekrar:** Konu secme ekraninda anlik arama cubugu, takvimde aylik ozet (`Bu ay: X konu · Y tekrar`), tamamlanan/bekleyen gunler icin halka/dolu nokta ayrimi, `22 Agustos 2027` TUS sinav gunu vurgusu, bolum basliklarinda `X/Y` sayaclari ve calisma menusune `Yarina ertele` eklendi.
  5. **F.T. time:** Hazirlik ekraninda bugunun bekleyen konularindan hizli secim cipleri, `Bugun X dongu tamamlandi` ozeti, `2 / 4 / 6 dongu` hizli secim cipleri ve sayac ekraninda (`FtSayacEkrani`) gorsel dongu noktalari (`FtDonguNoktalari`) eklendi.
  6. **Ilerleme:** Genel TUS mufredat ilerleme karti (`X / Y konu (%Z) · N tekrar tamamlandi`), kesintisiz calisma serisi (`X gun seri`), haftalik biten tekrar ve aktif gun sayisi ile gecmis haftalarda `Bu haftaya don` dugmesi eklendi.
  7. **Ayarlar:** Sinav tarihi `22 Agustos 2027` ve kalan gun gosterimi, calisan Tema secici (`Telefonun ayari / Acik / Koyu`), F.T. time surelerini varsayilana (`25/5/15`) dondurme dugmesi ve Veri/Yedek yonetimi (`Yedegi panoya kopyala`, `Yedekten geri yukle`, `Tum verileri sifirla`) eklendi.

## Siradaki adim
1. `model2/moduller-gelistirme` dalinin GitHub Actions'ta (analiz + test + APK) dogrulanip `main` dalina birlestirilmesi.
2. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.
3. ACIK SORUN (kullanici karariyla NOTA ALINDI, simdilik cozulmeyecek): arka planda/ekran kilitliyken sure bitince bildirim GELMIYOR (realme GT 2, pil ayari varsayilanda). Sayac dogru calisiyor (uygulamaya donunce sure bitmis gorunur ve puan yazilir). Detay "Bilinen sorunlar" altinda.

## Bilinen sorunlar / riskler
- **ARKA PLAN BILDIRIMI GELMIYOR (17 Ekim 2026, kullanici testi):** F.T. time suresi bitince, telefon kilitliyken ve MY TUS icin pil ayari VARSAYILANDAYKEN bildirim gelmiyor. Pil ayari "kisitlama yok" yapildiginda ilk prototip testleri (A/B/C) gecmisti (~0,1 sn). Ek on plan servisi eklendi, bildirim yine gelmedi. Uygulamada sayac dogru (sure bitmis gorunuyor, puan yaziliyor, bildirim izni acik).
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
