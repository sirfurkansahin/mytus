# DECISIONS.md: Kararlar

Son guncelleme: 3 Kasim 2026. Bu kararlar kullanici tarafindan onaylandi. Degistirmeden once kullaniciya sor.

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
| Plan olusturma | Resmi TUS sinav tarihi `22 Agustos 2027` olarak sabitlendi (2 Kasim 2026 kullanici karari). |
| Hazir icerik ve Mufredat | Çift Müfredat desteği (3 Kasım 2026 kullanıcı kararı): Başlangıç karşılama ekranında iki seçenek sunulur: 1) **Klasik Branşlar** (11 branş: Anatomi, Fizyoloji, Biyokimya, Patoloji, Farmakoloji, Mikrobiyoloji - Temel; Dahiliye, Pediatri, Genel Cerrahi, Kadın Doğum, Küçük Stajlar - Klinik; Dersler ekranında Temel/Klinik sekme ayrımı aktif). 2) **SpeeTUS Sarmal Sistem** (19 Sistem Paketi ve hazır video alt konuları; tek liste, sekmesiz). Kullanıcı ayrıca Ayarlar ekranından dilediği zaman müfredat tarzını değiştirebilir veya sıfırlayabilir. |
| Dagitim | Android icin Firebase App Distribution (APK); iPhone ve tarayici testi icin GitHub Pages (Web / PWA: `https://sirfurkansahin.github.io/mytus/`) (3 Kasim 2026 kullanici karari - Secenek 1). |
| KVKK | Hafif uyum: aydinlatma metni, ilk giriste onay, hesap/veri silme, minimum veri |
| Gelir | Yok |
| Derleme | GitHub Actions |
| Yapay zeka ozelligi | Ileride dusunulecek |
| Tasarim | Faz 3 ekran taslaklari ONAYLANDI (16 Ekim 2026). Kopya: `docs/tasarim/`. Ana renk mor, tema telefona uyar, alt menu Bugun/Dersler/Takvim/F.T. time. |
| Takvime yerlestirme | Iki yol da olacak: konu detayinda "Takvime ekle" (gun secilir) ve takvimde gune dokunup "+ Konu yerlestir". |
| Puan kurali | Tamamlanan odak suresi kadar puan (ornek: 1 dakika = 1 puan). Sure ayarindan bagimsiz. Yalnizca TAMAMLANAN donguler puan kazandirir (yarim birakilan puan getirmez), kullanici karari 16 Ekim 2026. |
| F.T. time varsayilan sureler | 25 dk calisma, 5 dk kisa mola, 15 dk uzun mola, her 4 dongude bir uzun mola. Ayrica rapora uygun tek dokunusla **"Derin blok (50/10/20 dk)"** ve **"Klasik (25/5/15 dk)"** hazir secim cipleri eklendi (3 Kasim 2026). Kullanici degistirebilir. |
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
| Veri saklama (Parca 2 & Web) | Android'de telefonun uygulama klasorunde (`mytus_data.json`), Web ortaminda ise tarayicinin `localStorage` alaninda saklanir (`lib/core/veri_kaydi.dart`). Yazma once gecici dosyaya, sonra yer degistirme (yazarken kapanirsa eski veri bozulmaz). Ek paket yok (Android'de Kotlin kanali `com.mytus.app/storage`, Web'de yerel browser storage). Dosya bozuksa/okunamazsa uygulama ustune yazmaz, "Tekrar dene" ekrani gosterir. |
| Not yazma kaydi | Yazarken her tusta degil, 500 ms sessizlikten sonra veya sayfa kapanirken/uygulama arka plana giderken kaydedilir. |
| Flutter surumu | `build-apk.yml` ve `deploy-web.yml` icinde 3.47.7'ye SABITLENDI (17 Ekim 2026). Neden: kod yerelde derlenemiyor, "stable" kaydiginda otomatik surum atlarsa gecen gun yesil olan derleme bozulabilir. Surum yukseltme bilincli yapilir ve once Actions'ta denenir. |
| On plan servisi (17 Ekim 2026) | KULLANICI TESTI 6: pil ayari YAPILMADAN sure bitince bildirim GELMEDI (uygulamada sayac dogru bitmis gorunuyordu, bildirim izni aciktı). Karar (kullanici 3-a): sayac calisirken `TimerService` (on plan servisi, tur: specialUse) calisir ve "calisan sayac" bildirimini tutar; boylece sistem uygulama surecini oldurup alarmi silemez. Sure takibi yine `setAlarmClock` ile; sure bitince alici servisi durdurur ve "Sure bitti" bildirimini gosterir. Servis baslatilamazsa duz bildirime donulur. Sayac ekraninda pil kisitlamasi varsa kapatilabilir uyari + "Pil ayarlarini ac" dugmesi. SONUC (17 Ekim 2026): servisle de bildirim GELMEDI; neden olculmedi, sorun kullanici karariyla NOTA ALINDI (HANDOFF.md > Bilinen sorunlar). Servis dalda duruyor, ama calistigi kanitlanmadi. |
| Ek Flutter paketi | Yalnizca `flutter_localizations` (Flutter'in kendi paketi): tarih secici ve sistem yazilari Turkce. |
| Karsilama (Parca 2) | Sinav tarihi `22 Agustos 2027` sabit. Hazir dersler tek liste olarak baslangicta secili; istenmeyenin cipi kaldirilir; "+ Kendi dersimi ekle" ile ders eklenir. Temel/Klinik ayrimi yoktur. |
| Konu ekleme (Parca 2) | Hazir dersler kendi iclerindeki zengin alt konularla birlikte otomatik gelir; ayrica ders detayinda hizli ekleme kutusuyla kullanici kendi konusunu da ekleyebilir. |
| Not bicimi (Parca 2) | Duz yazi, konu basina tek not alani (kullanici karari 4-a). |
| Ders/konu kurallari | Ad bosluklari temizlenir, bos olamaz, en fazla 80 karakter. Ayni adli ders tekrar eklenemez (buyuk/kucuk harf ayirt edilmez, tum liste tekildir). Ayni derste ayni adli konu eklenemez. Ders silinince konulari ve notlari da silinir (onay sorulur). Ders ve konu adi degistirilebilir. |
| Ders detayi ekrani | Onayli tasarimda yoktu; Dersler -> konu listesi icin ayni gorsel dille EKLENDI. |
| "Calisildi" sayisi | Bir konuda en az bir yerlestirme "Calistim" ile isaretlenince konu "calisildi" sayilir (Parca 3'te baglandi). |

## Takvim ve tekrar motoru (Parca 3, 16 Ekim 2026 & Rapor guncellemesi 3 Kasim 2026)
Kullanici onayli kurallar ve TUS Birincilik ve Maksimum Bilissel Performans Raporu guncellemeleri:

| Konu | Karar |
|---|---|
| Her yerlestirme kendi serisi | Bir konu birden fazla gune yerlestirilebilir; her yerlestirme ("Calisma") kendi tekrar serisine sahiptir ("Tur 1/3, Tur 2/3, Tur 3/3"). Tur numarasi = ayni konunun yerlestirmeleri arasinda tarih sirasi. (ONAYLI) |
| "Calistim" | Yerlestirmenin gunu bugune cekilir ve tekrar zinciri BUGUNDEN baslar. Geri alinabilir (yapilan tekrar kayitlari da silinir). (ONAYLI) |
| R0 (Aksam tekrari) | Bugun en az 1 konu "Calistim" olarak isaretlendiginde Bugun ekraninda **"R0 · Aksam uyku oncesi beyaz sayfa tekrari"** hatirlatma karti gosterilir (uyku sirasinda hipokampal-neokortikal pekistirme oncesi 15-20 dk). (ONAYLI - 3 Kasim 2026) |
| Tekrar gunleri (R1–R4) | Asagidaki R1–R4 tablosu; sinava kalan gun, ilk calismanin gununden hesaplanir. Tablodaki satirlar arasi degerlerde en yakin ALT satir kullanilir; 7 gunden azda 7 gunluk satir. (ONAYLI - 3 Kasim 2026) |
| Gecikme kaymasi | Bir tekrar gec yapilirsa sonrakiler ayni gun sayisi kadar kayar (ornek: 1. tekrar 2 gun gec yapilirsa sonrakiler de 2 gun gecikir). Tekrarlar saklanmaz, taban tarih + birikmis gecikmeden TURETILIR. (ONAYLI) |
| Sinav siniri | Hicbir tekrar sinavdan sonraya kalmaz; en gec sinavdan 1 gun once. (ONAYLI) |
| Gunluk sinir | Varsayilan 10 tekrar/gun; fazlasi ertesi gune kayar. Yapilan ve geciken tekrarlar sinira sayilmaz. |
| Siralama | Tekrar yalnizca konu "Calistim" yapildiktan sonra ve yalnizca SIRADAKI tekrar yapilabilir; sonrakiler gorunur ama kapali. |
| Gecikenler | Bugun ekraninda "Geciken": gunu gecmis ama yapilmamis yerlestirmeler + gunu gecmis, sirasi gelmis tekrarlar. |
| Yerlestirme sinirlari | Gecmis gune ve sinav gunu/sonrasina yerlestirilemez. Sinav tarihi yoksa 1 yila kadar. |
| Tur sayisi | Varsayilan **3** (Rapor Bolum 6: "3 faz, 3 tur, R0–R4"; 3 Kasim 2026 kullanici onayi). Ayarlardan 1-5 arasi degistirilebilir. |
| Kod yeri | `lib/features/takvim/` (motor saf fonksiyon: `tekrar_motoru.dart`, birim testli). Tum veri hala tek JSON dosyasinda (`calismalar` anahtari). |

## Ayarlar, F.T. time ve puan (Parca 4a, 16 Ekim 2026)
| Konu | Karar |
|---|---|
| F.T. time blok presetleri | Rapordaki 50/10/20 dk "Derin blok" ve 25/5/15 dk "Klasik Pomodoro" ayarlardan veya sayactan tek dokunusla secilebilir (3 Kasim 2026). |
