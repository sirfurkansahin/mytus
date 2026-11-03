# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), SpeeTUS Sarmal Egitim 19 Sistem Paketi ve hazir alt konulari entegre edildi, Temel/Klinik ayrimi kaldirildi, GitHub Actions CI basariyla gecti (`model2/speetus-mufredat` - Run ID: 41678080697)

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- `model2/rapor-tekrar-sistemi` (R0–R4 aralikli tekrar, 3 tur, 50/10 derin blok) GitHub Actions'ta dogrulandi (yesil yandi).
- Dal `model2/speetus-mufredat`:
  1. **SpeeTUS Sarmal Egitim 19 Sistem Paketi (`hazir_dersler.dart`, `modeller.dart`):**
     - 19 Paket tek sirali liste olarak tanimlandi (*1. Tibbin Temelleri* ... *19. Siniflandirilmayan Konular*).
     - Her paketin altindaki tum videolar/ders basliklari hazir alt konu olarak yuklendi (ornek: *Fizyoloji · Hucre Histolojisi ve Fizyolojisi*, *Patoloji · Hucre Hasari*, *Dahiliye · Kardiyoloji* vb.).
  2. **Temel / Klinik Ayriminin Kaldirilmasi:**
     - Kullanicinin *"temel klinik ayrimini kaldir"* talimati uyarinca Dersler ekranindaki ve Karsilama ekranindaki Temel/Klinik gecis butonlari, sekmeleri ve filtreleri tamamen kaldirildi.
     - Karsilama ekraninda 19 paket tek bir blokta gosterilir, "+ Kendi dersimi ekle" ile dogrudan yeni ders eklenir.
     - Dersler ekraninda tum dersler tek bir kaydirilabilir listede gosterilir, ust baslikta toplam konu ve calisilan konu sayisi yer alir.
     - Konu detay ve ders detay ekranlarinda temel/klinik etiketleri kaldirildi.
     - Ders tekillik kurali tum liste genelinde gecerli kılındı.
  3. **Testler, CI ve Dokumanlar:**
     - Tum birim, widget ve uctan uca testler tek liste SpeeTUS yapisina uyarlandi.
     - GitHub Actions uzerinde `build-apk.yml` akisi (Run `41678080697`) calisti; **kod analizi, tum testler, release APK derleme ve imza dogrulamasi basariyla gecti (yesil).**
     - `mytus-apk` artefakti GitHub Actions uzerinde uretildi.
     - `mytus_canli_onizleme.html` etkilesimli onizleme dosyasi tekil 19 SpeeTUS listesi ve kaldirilan Temel/Klinik dugmeleriyle guncellendi.
     - `DECISIONS.md` ve `HANDOFF.md` guncellendi.

## Siradaki adim
1. Kullanici onayi ile `model2/speetus-mufredat` dalinin `main` dalina birlestirilmesi (merge/PR).
2. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.

## Bilinen sorunlar / riskler
- **ARKA PLAN BILDIRIMI GELMIYOR (17 Ekim 2026, kullanici testi):** F.T. time suresi bitince, telefon kilitliyken ve MY TUS icin pil ayari VARSAYILANDAYKEN bildirim gelmiyor. Pil ayari "kisitlama yok" yapildiginda ilk prototip testleri (A/B/C) gecmisti (~0,1 sn). Ek on plan servisi eklendi, bildirim yine gelmedi. Uygulamada sayac dogru (sure bitmis gorunuyor, puan yaziliyor, bildirim izni acik).
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
