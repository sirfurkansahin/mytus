# DECISIONS.md: Kararlar

Son guncelleme: 16 Ekim 2026. Bu kararlar kullanici tarafindan onaylandi. Degistirmeden once kullaniciya sor.

| Konu | Karar |
|---|---|
| Urun | Calisma sureci takibi + planlama. Soru bankasi degil. Tibbi icerik yok. |
| Kullanicilar | Kullanicinin arkadaslari, 2-10 kisi, hepsi Android ve 18+. Ucretsiz. |
| Uygulama adi / modul | MY TUS / "F.T. time" (odak sayaci modulu) |
| Paket adi | com.mytus.app |
| Teknoloji | Flutter + Firebase Spark. Puan hesabi istemcide. |
| Surumler | Surum 1: planlama + takvim + F.T. time, hesapsiz/yerel. Surum 2: Google girisi, bulut, davet kodlu grup, haftalik puan tablosu, istege bagli konu paylasimi, KVKK ekranlari |
| Veri (Surum 2) | Takma ad + e-posta + calisma verisi. Notlar ozel, asla paylasilmaz. |
| Puan tablosu | Haftalik sifirlanir |
| Paylasim | Istege bagli (opt-in), yalnizca konu adlari |
| Plan olusturma | Her yeni planda sinav tarihi sorulur |
| Hazir icerik | Hazir DERS ADI listesi. Temel: Anatomi, Histoloji ve Embriyoloji, Fizyoloji, Biyokimya, Mikrobiyoloji, Patoloji, Farmakoloji. Klinik: Dahiliye, Pediatri, Genel Cerrahi, Kadin Hastaliklari ve Dogum. Dersler Temel/Klinik gruplarinda durur, kullanici iki gruba da kendi dersini ekleyebilir. Liste guncel OSYM kilavuzuyla dogrulanmadi. |
| Dagitim | Firebase App Distribution |
| KVKK | Hafif uyum: aydinlatma metni, ilk giriste onay, hesap/veri silme, minimum veri |
| Gelir | Yok |
| Derleme | GitHub Actions |
| Yapay zeka ozelligi | Ileride dusunulecek |
| Tasarim | Faz 3 ekran taslaklari ONAYLANDI (16 Ekim 2026). Kopya: `docs/tasarim/`. Ana renk mor, tema telefona uyar, alt menu Bugun/Dersler/Takvim/F.T. time. |
| Takvime yerlestirme | Iki yol da olacak: konu detayinda "Takvime ekle" (gun secilir) ve takvimde gune dokunup "+ Konu yerlestir". |
| Puan kurali | Tamamlanan odak suresi kadar puan (ornek: 1 dakika = 1 puan). Sure ayarindan bagimsiz. Yalnizca TAMAMLANAN donguler puan kazandirir (yarim birakilan puan getirmez), kullanici karari 16 Ekim 2026. |
| F.T. time varsayilan sureler | 25 dk calisma, 5 dk kisa mola, 15 dk uzun mola, her 4 dongude bir uzun mola. Kullanici degistirebilir. |
| Firebase projesi | Ad: mytus, Spark plani, Google hesabi: kullanicinin kendi hesabi. Google Analytics ACIK (kullanici karari, 16 Ekim 2026). |
| Analytics sonucu | Analytics, cihaz/kullanim verisi toplar. Uygulamaya eklendiginde aydinlatma metnine yazilmali ve ilk giriste onay alinmali. KARAR (16 Ekim 2026): Analytics SDK'si Surum 2'de, Google girisi ve KVKK ekranlariyla birlikte eklenecek. Surum 1 hicbir veriyi cihazdan cikarmaz. |

## Teknik kararlar (kullanici teknik secimleri bana birakti, 16 Ekim 2026)
| Konu | Karar ve neden |
|---|---|
| F.T. time sayac mantigi | Saniye saymak yerine BITIS SAATI saklanir; kalan sure her seferinde saatten hesaplanir (`lib/features/ft_time/ft_timer.dart`). Uygulama kapansa veya telefon uyusa bile sure dogru kalir. Duvar saati (DateTime.now) kullanilir, cunku Android alarmi da duvar saatine baglidir; kullanici telefonun saatini elle degistirirse sayac sapar (kabul edildi). |
| Sure bitince uyari | `AlarmManager.setAlarmClock` (Android'in "saat alarmi" turu): pil tasarrufundan en az etkilenen alarm turu, ayrica "tam zamanli alarm" izni istemez. Bildirim + titresim (bildirim kanalindan), kilit ekraninda gorunur, ses yok (kullanici karari 2-a). |
| Calisirken bildirim | Geri sayimli (chronometer) kalici bildirim; sistem kendisi gosterir, uygulama calismasa da akar. On plan servisi (foreground service) prototipte KULLANILMADI; olcum yetersizse eklenecek. |
| Ek paket kullanmama (Parca 1) | Bildirim/alarm/kayit icin ucuncu taraf paket kullanilmadi, kucuk Kotlin kodu yazildi (`android/.../TimerNotifier.kt`, `TimerAlarmReceiver.kt`, `MainActivity.kt`). Neden: kod yerelde derlenemiyor (yalnizca Actions'ta); paketlerin surum/Gradle uyumsuzluklari (ornegin bazi bildirim paketleri ek Gradle ayari ister) kor calisirken risk. Android'in kendi siniflari sabit ve bilinen. Kalici veri depolama secimi (Parca 2) ayri karar. |
| Prototip kapsami | Tek test ekrani (1/5/25 dk, baslat/duraklat/sifirla). Amac: arka plan guvenilirligini realme GT 2'de olcmek. Ekranda "Alarm olcumu" paneli: alarm gercekten ne zaman tetiklendi, kac sn gecikti, hic tetiklenmedi mi. |
| Pil rehberi | Ilk acilista ve istenince "Pil ayarlarini ac" rehberi (kullanici karari 3-a): bildirim izni, pil kisitlamasi yok, arka planda calismaya izin / otomatik baslatma. Menu adlari markaya gore degisebilir; realme icin yollar DOGRULANMADI. |
| Bilinen sinirlar | Telefon yeniden baslarsa alarm silinir (sayac acilinca bitis saatine bakilip "bitti" gosterilir). Zorla durdurulan (Force stop) uygulamada alarm calismaz. |
| Veri saklama (Parca 2) | Tum plan (sinav tarihi, dersler, konular, notlar) tek JSON dosyasinda, telefonun uygulama klasorunde (`mytus_data.json`). Yazma once gecici dosyaya, sonra yer degistirme (yazarken kapanirsa eski veri bozulmaz). Ek paket yok (kendi Kotlin kanali `com.mytus.app/storage`). Dosya bozuksa/okunamazsa uygulama ustune yazmaz, "Tekrar dene" ekrani gosterir. Sinir: her degisiklikte dosya bastan yazilir; veri birkac MB'yi gecerse SQLite'a gecilir. Surum 2'de bulut esitlemesi bu yapinin ustune kurulur. |
| Not yazma kaydi | Yazarken her tusta degil, 500 ms sessizlikten sonra veya sayfa kapanirken/uygulama arka plana giderken kaydedilir. |
| Flutter surumu | `build-apk.yml` icinde 3.47.7'ye SABITLENDI (17 Ekim 2026). Neden: kod yerelde derlenemiyor, "stable" kaydiginda otomatik surum atlarsa gecen gun yesil olan derleme bozulabilir. Surum yukseltme bilincli yapilir ve once Actions'ta denenir. |
| On plan servisi (17 Ekim 2026) | KULLANICI TESTI 6: pil ayari YAPILMADAN sure bitince bildirim GELMEDI (uygulamada sayac dogru bitmis gorunuyordu, bildirim izni aciktı). Karar (kullanici 3-a): sayac calisirken `TimerService` (on plan servisi, tur: specialUse) calisir ve "calisan sayac" bildirimini tutar; boylece sistem uygulama surecini oldurup alarmi silemez. Sure takibi yine `setAlarmClock` ile; sure bitince alici servisi durdurur ve "Sure bitti" bildirimini gosterir. Servis baslatilamazsa duz bildirime donulur. Sayac ekraninda pil kisitlamasi varsa kapatilabilir uyari + "Pil ayarlarini ac" dugmesi. DOGRULANMADI: yeni surumun kullanici telefonunda pil ayari yapilmadan calistigi (test 6 tekrar edilecek). |
| Ek Flutter paketi | Yalnizca `flutter_localizations` (Flutter'in kendi paketi): tarih secici ve sistem yazilari Turkce. |
| Karsilama (Parca 2) | Sinav tarihi ZORUNLU (secilmeden "Basla" kapali; kullanici karari: her planda tarih sorulur). Hazir dersler baslangicta secili; istemedigi kaldirilir; "+ Kendi dersimi ekle" ile Temel/Klinik'e ders eklenir. |
| Konu ekleme (Parca 2) | Tek tek, ders detayinda hizli ekleme kutusu (kullanici karari 3-a). Toplu yapistirma yok. |
| Not bicimi (Parca 2) | Duz yazi, konu basina tek not alani (kullanici karari 4-a). |
| Ders/konu kurallari | Ad bosluklari temizlenir, bos olamaz, en fazla 80 karakter. Ayni grupta ayni adli ders, ayni derste ayni adli konu eklenemez (buyuk/kucuk harf ayirt edilmez). Ders silinince konulari ve notlari da silinir (onay sorulur). Ders ve konu adi degistirilebilir. |
| Ders detayi ekrani | Onayli tasarimda yoktu; Dersler -> konu listesi icin ayni gorsel dille EKLENDI. |
| "Calisildi" sayisi | Bir konuda en az bir yerlestirme "Calistim" ile isaretlenince konu "calisildi" sayilir (Parca 3'te baglandi). |
| Bugun ekrani (gecici) | Parca 2'de yalnizca "sinava N gun kaldi" ve sinav tarihini degistirme. Gunun plani Parca 3-4'te. |

## Takvim ve tekrar motoru (Parca 3, 16 Ekim 2026)
Kullanici onayli (1-a 2-a 3-a 4-b) kurallar ve BENIM YORUMLARIM ayri belirtilmistir.

| Konu | Karar |
|---|---|
| Her yerlestirme kendi serisi | Bir konu birden fazla gune yerlestirilebilir; her yerlestirme ("Calisma") kendi tekrar serisine sahiptir ("Tur 1/2, Tur 2/2"). Tur numarasi = ayni konunun yerlestirmeleri arasinda tarih sirasi. (ONAYLI) |
| "Calistim" | Yerlestirmenin gunu bugune cekilir ve tekrar zinciri BUGUNDEN baslar. Geri alinabilir (yapilan tekrar kayitlari da silinir). (ONAYLI) |
| Tekrar gunleri | Yukaridaki tablo; sinava kalan gun, ilk calismanin gununden hesaplanir. Tablodaki satirlar arasi degerlerde en yakin ALT satir kullanilir; 7 gunden azda 7 gunluk satir. (BENIM YORUMUM) |
| Gecikme kaymasi | Bir tekrar gec yapilirsa sonrakiler ayni gun sayisi kadar kayar (ornek: 1. tekrar 2 gun gec yapilirsa sonrakiler de 2 gun gecikir). Tekrarlar saklanmaz, taban tarih + birikmis gecikmeden TURETILIR. (ONAYLI) |
| Sinav siniri | Hicbir tekrar sinavdan sonraya kalmaz; en gec sinavdan 1 gun once. (ONAYLI) |
| Gunluk sinir | Varsayilan 10 tekrar/gun; fazlasi ertesi gune kayar. Yapilan ve geciken tekrarlar sinira sayilmaz. Ayarlardan degistirme Parca 4'te. (sayi BENIM YORUMUM) |
| Siralama | Tekrar yalnizca konu "Calistim" yapildiktan sonra ve yalnizca SIRADAKI tekrar yapilabilir; sonrakiler gorunur ama kapali. (BENIM YORUMUM) |
| Gecikenler | Bugun ekraninda "Geciken": gunu gecmis ama yapilmamis yerlestirmeler + gunu gecmis, sirasi gelmis tekrarlar. |
| Yerlestirme sinirlari | Gecmis gune ve sinav gunu/sonrasina yerlestirilemez. Sinav tarihi yoksa 1 yila kadar. |
| Tur sayisi | Varsayilan 2 (Ayarlardan degistirme Parca 4). |
| Kod yeri | `lib/features/takvim/` (motor saf fonksiyon: `tekrar_motoru.dart`, birim testli). Tum veri hala tek JSON dosyasinda (`calismalar` anahtari). |

## Ayarlar, F.T. time ve puan (Parca 4a, 16 Ekim 2026)
Kullanici cevaplari: bolme 1-a, konu secimi 2-a (istege bagli), 3-c (odak bitince "Calistim mi?" diye sor), puan gorunumu 4-a (F.T. time + Ilerleme). BENIM YORUMLARIM ayri belirtilmistir.

| Konu | Karar |
|---|---|
| Kapsam | 4a: Ayarlar + gercek F.T. time (hazirlik, sayac, mola, puan). 4b: Ilerleme ekrani (sonra). |
| Oturum akisi | Calisma 1, mola, calisma 2, ... calisma N. Son calismadan sonra mola yok. Uzun mola her `uzunMolaAraligi` (4) donguden sonra. Varsayilan 25/5/15 dk, 4 dongu. Toplam sure tasarim ornegiyle uyumlu (4 dongu = 1 sa 55 dk). |
| Bolum gecisi | Bolum bitince sonraki bolume kullanici dugmeyle gecer ("Molayi baslat", "Dongu N baslat"); OTOMATIK baslamaz. Neden: arka planda alarm bildirimi zaten uyarir; kullanici hazir degilken sayac kosmaz. (BENIM YORUMUM) |
| Molayi atla | Molada "Molayi atla" ile sonraki calismaya hemen gecilir. (BENIM YORUMUM) |
| Puan | Calisma bolumu BITINCE o dongunun suresi kadar puan (1 dk = 1 puan). Yarim birakilan dongu ve mola puan getirmez. Ayni dongu iki kez puanlanmaz ("oturumNo:donguNo" anahtari). Uygulama kapaliyken biten bolum, uygulama acilinca bitis saatiyle puanlanir. |
| Sure kilidi | Oturum baslarken sureler ayarlardan alinip oturuma yazilir; sonradan ayar degisse de oturum etkilenmez. (BENIM YORUMUM) |
| Konu | Istege bagli ("Konusuz calis" olabilir). Konu silinirse puanlar kalir, kayit konusuz olur. |
| Calistim sorusu | Oturum biterken konu secilmisse ve en az 1 dongu bittiyse "Konuyu calistim olarak isaretleyeyim mi?" diye sorulur. Evet: konunun bekleyen en erken yerlestirmesi bugune alinip "Calistim" yapilir; bekleyen yoksa bugune yeni yerlestirme acilir. Hayir: hicbir sey degismez. (soru: kullanici karari; "en erken bekleyen yerlestirme" secimi BENIM YORUMUM) |
| Ayarlar | Bugun ekraninin sag ustundeki disli simgesinden acilir. Sinav tarihi, tur sayisi (1-5), gunluk tekrar siniri (3-30), F.T. sureleri, arka plan/pil durumu, sayac testi (gelismis). Sinirlar BENIM YORUMUM. "Dersleri duzenle" satiri eklenmedi (Dersler sekmesi var). |
| Veri | Oturum, odak kayitlari ve F.T. ayarlari ayni JSON dosyasinda (`oturum`, `odaklar`, `ftAyar`); puan ve oturum birlikte atomik yazilir. |
| Pil rehberi | Ilk oturum acildiginda bir kez gosterilir; Ayarlar'dan tekrar acilir. |
| Prototip | Sayac prototipi (`ft_test_screen.dart`) Ayarlar > Sayac testi altinda kaldi (alarm olcumu icin; 6. test hala yapilmadi). Calisan oturum varken acilmaz. |
| Bildirim metni | "Sure bitti / Uygulamayi acip devam edebilirsin" (calisma ve mola icin ortak). |

## Ilerleme ekrani (Parca 4b, 17 Ekim 2026)
Kullanici cevaplari: 1-a (hafta oklari), 2-a ("Calistim" denen konular), 3-a (odak suresine gore ders sirasi), 4-a (ders ilerlemesi bolumu YOK, tasarimdaki gibi sade).

| Konu | Karar |
|---|---|
| Erisim | Bugun ekraninin sag ustunde grafik simgesi (disli simgesinin yaninda). |
| Hafta | Pazartesi-Pazar. Oklarla gecmis haftalara bakilir; gelecege gidilmez (bu haftada sonraki ok kapali). |
| Calisilan konu | O hafta "Calistim" isaretlenen FARKLI konu sayisi (ayni konu iki tur isaretlenirse 1). |
| Biten dongu / odak suresi | O haftaki odak kayitlari. 1 dk = 1 puan; hafta puani da gosterilir. |
| Gunluk grafik | 7 cubuk (dakika), cubuk yuksekligi haftanin en yuksek gunune gore olceklenir; bugun vurgulu. Ek paket yok. |
| En cok calisilan dersler | Konuya bagli odaklardan derse gore toplam sure, coktan aza, en cok 5 ders. Konusuz odak toplama girer ama ders listesine girmez. Konusu silinmis odak da yalnizca toplama girer. |
| Sure yazimi | 60 dk altinda "45 dk", ustunde "5,8 sa" (virgullu). |
| Ek bolum | "Ders ilerlemesi (x/y konu)" EKLENMEDI (kullanici karari). Istenirse Surum 1 sonrasi eklenir. |

## Tekrar sistemi
- Konu basina en fazla 4 kisa tekrar (10-15 dk, notlara bakmadan hatirlama + kontrol).
- Sinava kalan gune gore tekrar gunleri (ilk calismadan sonra gun sayisi):

| Sinava kalan gun | Tekrar gunleri |
|---|---|
| 7 | 1, 3, 4 |
| 14 | 1, 4, 7, 9 |
| 30 | 1, 7, 12, 16 |
| 60 | 1, 8, 17, 25 |
| 120 | 1, 8, 21, 33 |
| 180 | 1, 8, 26, 43 |
| 300 | 1, 8, 29, 53 |

- Kullanici tur sayisini secer (varsayilan 2). Gunluk tekrar yuku siniri vardir, fazlasi ertesi gune kayar. Tekrarlar takvimde otomatik "Tekrar" olarak gorunur (bildirim yok).
- Dayanak: Cepeda 2008, Kerfoot ve ark. TUS'a ozgu akademik veri yok. Oranlar ara degerleme, kanitlanmis kesin deger degil.

## Acik / dogrulanmamis noktalar
- Firebase yurt disi aktarimi icin KVKK m.9 yolu kesinlesmedi (hukukcu sorusu).
- Android gelistirici dogrulamasi 2027'de kuresel olabilir; "sinirli dagitim hesabi" (en fazla 20 cihaz) not edildi, acilis durumu dogrulanmadi.
- Firebase App Distribution tester limiti ve GitHub Actions ucretsiz kotasi dogrulanmadi.
- Ileride arkadas disina acilma karari yok; guvenlik kurallari bastan cok kullanicili yazilacak.
- APK imzalama: Kalici anahtar (alias `mytus`) uretildi; kullanici yedekledi ve GitHub Secrets'a koydu (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD). Anahtar ASLA depoya girmez. Sirlar yoksa derleme debug anahtariyla imzalanir ve o APK ile kalici anahtarli APK birbirinin uzerine kurulamaz (once silmek gerekir).
- Dagitim otomasyonu: sirlar FIREBASE_APP_ID, FIREBASE_SERVICE_ACCOUNT, FIREBASE_TESTERS. main dalina gonderimde veya elle `dagit` secilince APK Firebase App Distribution'a yuklenir. Build numarasi her derlemede `github.run_number` ile artar.
