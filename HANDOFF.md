# HANDOFF.md: Devir notu

Son guncelleme: 3 Kasim 2026 (Gemini), TUS Birincilik ve Maksimum Bilissel Performans Raporu dogrultusunda R0–R4 tekrar sistemi, 3 tur varsayilani, Kucuk Stajlar dersi ve 50/10 derin blok ayari uygulandi (`model2/rapor-tekrar-sistemi`)

## Durum
- Faz 2 (kurulum) ve Faz 3 (UX/UI tasarim) TAMAMLANDI.
- PR #9 (`model2/moduller-gelistirme` — Surum 1'in 7 modulu) GitHub Actions'ta tum analiz, test ve APK adimlarindan yesil gecerek `main` dalina BIRLESTI (3 Kasim 2026).
- Dal `model2/rapor-tekrar-sistemi`: Kullanicinin paylastigi **"TUS Turkiye 1.ligi ve Maksimum Bilissel Performans — Master Arastirma Raporu"** dogrultusunda kullanici onayiyla su guncellemeler yapildi:
  1. **R0–R4 Aralikli Tekrar Takvimi (`tekrar_motoru.dart` & `bugun_ekrani.dart`):**
     - Standart tekrar gunleri rapordaki **R1 = G+1**, **R2 = G+7**, **R3 = G+30**, **R4 = Faz sonu (+60 / +75 / +90 gun)** ve sinava 60 gunden az kaldiginda Cepeda (2008) sikistirma oranlarina (`7: [1, 3, 6]`, `14: [1, 4, 7, 12]`, `30: [1, 7, 15, 25]`, `60: [1, 7, 21, 45]`) guncellendi.
     - Bugun en az 1 konu `"Calistim"` yapildiginda Bugun ekraninda **"R0 · Aksam uyku oncesi beyaz sayfa tekrari"** hatirlatma karti gosterilir.
  2. **R1–R4 Asama Etiketleri (`takvim_ogeleri.dart`, `konu_ekrani.dart`):**
     - Tekrar satirlarinda ve konu detay ekranindaki tekrar kutularinda hangi tekrar asamasinda olundugu (`R1`, `R2`, `R3`, `R4`) acikca gosterilir.
  3. **Varsayilan Tur Sayisi = 3 (`plan_deposu.dart`):**
     - Rapordaki *"3 faz, 3 tur, R0–R4"* mimarisine uygun olarak varsayilan `turSayisi` `2`'den `3`'e cikarildi.
  4. **50/10 Derin Calisma Blogu ve Kucuk Stajlar (`ayar_ogeleri.dart`, `hazir_dersler.dart`):**
     - Hazir klinik derslere **Kucuk Stajlar** eklendi (toplam 7 Temel + 5 Klinik = 12 ders).
     - F.T. time sure ayarlarina tek dokunusla **"Klasik (25/5/15 dk)"** ve **"Derin blok (50/10/20 dk)"** hazir secim cipleri eklendi.
  5. **Birim Testleri (`test/tekrar_motoru_test.dart`, `test/calisma_deposu_test.dart`, `test/plan_deposu_test.dart`):**
     - Yeni R1–R4 tablosu, 3 tur varsayilani ve 5 klinik ders sayisi ile uyumlu sekilde guncellendi.

## Siradaki adim
1. Kullanici istediginde `model2/rapor-tekrar-sistemi` dalini GitHub'a gonderip Actions'ta (analiz + test + APK) dogrulamak ve `main` dalina birlestirmek.
2. **Modul 8 (Surum 2):** Google girisi, KVKK aydinlatma/onay ekranlari, bulut esitleme, davet kodlu arkadas grubu, haftalik puan tablosu ve istege bagli konu paylasimi.
3. ACIK SORUN (kullanici karariyla NOTA ALINDI, simdilik cozulmeyecek): arka planda/ekran kilitliyken sure bitince bildirim GELMIYOR (realme GT 2, pil ayari varsayilanda). Sayac dogru calisiyor (uygulamaya donunce sure bitmis gorunur ve puan yazilir). Detay "Bilinen sorunlar" altinda.

## Bilinen sorunlar / riskler
- **ARKA PLAN BILDIRIMI GELMIYOR (17 Ekim 2026, kullanici testi):** F.T. time suresi bitince, telefon kilitliyken ve MY TUS icin pil ayari VARSAYILANDAYKEN bildirim gelmiyor. Pil ayari "kisitlama yok" yapildiginda ilk prototip testleri (A/B/C) gecmisti (~0,1 sn). Ek on plan servisi eklendi, bildirim yine gelmedi. Uygulamada sayac dogru (sure bitmis gorunuyor, puan yaziliyor, bildirim izni acik).
- APK imzalama: kalici anahtar GitHub Secrets'ta (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD); anahtarin tek yedegi kullanicida.
- Kod yerelde derlenemez; sonuclar yalnizca Actions'tan gelir.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
