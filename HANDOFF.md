# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), SpeeTUS Sarmal Egitim mufredatina gore 19 Sistem Paketi (8 Temel, 11 Klinik) ve hazir alt konulari entegre edildi (`model2/speetus-mufredat`)

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- `model2/rapor-tekrar-sistemi` (R0–R4 aralikli tekrar, 3 tur, 50/10 derin blok) GitHub Actions'ta dogrulandi (yesil yandi).
- Dal `model2/speetus-mufredat`: Kullanicinin verdigi **SpeeTUS Sarmal Egitim** takip listesi dogrultusunda secenek 1 uygulandi:
  1. **19 Sistem Paketi (`hazir_dersler.dart`, `modeller.dart`):**
     - Temel Sistemler (8 Paket): *Tibbin Temelleri, Periferik Sinir Sistemi ve Kas, Merkezi Sinir Sistemi, Duyu Organlari - Dermatoloji, Duyu Organlari - KBB, Duyu Organlari - Goz, Immunoloji ve Alerji, Mikrobiyoloji ve Enfeksiyonlar*.
     - Klinik Sistemler (11 Paket): *Hematoloji ve Onkoloji, Gastrointestinal ve Hepatobiliyer Sistem, Endokrinoloji, Meme Hastaliklari, Uriner Sistem, Genital Sistem, Obstetri ve Yenidogan, Kardiyovaskuler Sistem, Solunum Sistemi, Kas Iskelet Sistemi, Siniflandirilmayan Konular*.
  2. **Hazir Alt Konular (`hazir_dersler.dart`, `plan_deposu.dart`):**
     - Her paketin altindaki ders ve konu basliklari (orn. *Fizyoloji · Hucre Histolojisi ve Fizyolojisi*, *Patoloji · Hucre Hasari*, *Dahiliye · Kardiyoloji* vb.) hazir konu olarak tanimlandi.
     - Karsilama ekraninda dersler secildiginde alt konulari da otomatik olarak depoya aktarilir.
  3. **Testler ve Dokumanlar:**
     - `test/plan_deposu_test.dart`, `test/widget_test.dart`, `test/uctan_uca_test.dart`, `DECISIONS.md`, `mytus_canli_onizleme.html` yeni 19 sistem paketi ve alt konulariyla uyumlu hale getirildi.

## Siradaki adim
1. Kullanici istediginde `model2/speetus-mufredat` dalini GitHub'a gonderip Actions'ta (analiz + test + APK) dogrulamak.
2. `main` dalina birlestirme yapilmasi.
3. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.

## Bilinen sorunlar / riskler
- **ARKA PLAN BILDIRIMI GELMIYOR (17 Ekim 2026, kullanici testi):** F.T. time suresi bitince, telefon kilitliyken ve MY TUS icin pil ayari VARSAYILANDAYKEN bildirim gelmiyor. Pil ayari "kisitlama yok" yapildiginda ilk prototip testleri (A/B/C) gecmisti (~0,1 sn). Ek on plan servisi eklendi, bildirim yine gelmedi. Uygulamada sayac dogru (sure bitmis gorunuyor, puan yaziliyor, bildirim izni acik).
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
