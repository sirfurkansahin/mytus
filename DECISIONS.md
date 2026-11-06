# DECISIONS.md: Kararlar

Son guncelleme: 3 Kasim 2026. Bu kararlar kullanici tarafindan onaylandi. Degistirmeden once kullaniciya sor.

| Konu | Karar |
|---|---|
| Urun | Calisma sureci takibi + planlama. Soru bankasi degil. Tibbi icerik yok; ISTISNA (6 Kasim 2026): kucuk, salt-okunur "Referans" (hazir skorlar, mekanizma sablonlari) serbest. |
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

## Deneme Sınavı & Bilişsel Hata Analizi (Modül 1, 3 Kasım 2026)
| Konu | Karar ve Neden |
|---|---|
| Soru ve Süre Formatı | 200 soru (100 Temel TTBT + 100 Klinik KTBT; oturum başına 135 dk). Net hesabı: Doğru - Yanlış/4. |
| Ağırlıklı Puanlar | Klinik Ağırlıklı K = 0.4 TTBT + 0.6 KTBT; Temel Ağırlıklı T = 0.6 TTBT + 0.4 KTBT. |
| ÖSYM 85 EBAP Puanlama | Sınav Puanı = 55 + 30 * [7(AP - X) - S] / [7(EBAP - X) - S] formülü ile 85 tavanına göre ölçeklenir. |
| A–F Hata Sınıfları | A: Bilgi kusuru, B: Yanlış biliyordum (Emin + Yanlış), C: Okuma/kurgu, D: Mantık/halka, E: Süre/yorgunluk, F: Form/dikkat. |
| Hiperdüzeltme Alarmı | "Emin + Yanlış" hücresindeki hatalar yanlış inanç olduğundan AYNI GÜN düzeltilmelidir uyarısı verilir. |
| Kalibrasyon Farkı | Ortalama Güven - Doğruluk (hedef mutlak değer <= %5). +%8 üzeri aşırı güven alarmı üretir. |

## Özel Defterler & Akıllı Havuz (Modül 2, 3 Kasım 2026)
| Konu | Karar ve Neden |
|---|---|
| Hata Defteri & Çeldirici Bankası | Denemelerden ve soru çözümlerinden gelen hatalar toplanır. Her yanlış için 3 zorunlu alan: karışan çeldirici, ayıran tek kriter ve adayın kendi kuralı. "Pekiştirildi" takibi vardır. |
| Sınıflama & Skor Defteri (Tuzak Sınıfı 8) | Mantıkla türetilemeyen ezber skorlar için 10+ hazır TUS skoru (Hinchey, Hodgkin IPS, Child-Pugh, Wells, CURB-65, Ranson vb.) kütüphanesi ve kullanıcının özel skor ekleme imkanı. |
| Mekanizma Zincirleri (Illness Script) | 6 branş için 5 halkalı şablonlar (Dahiliye, Farmakoloji, Biyokimya, Mikrobiyoloji, Fizyoloji, Anatomi). Ayıran özellik ve "Neden?" açıklaması zorunlu. |
| 3 Dakikalık Vaka Kartı | Klinisyen/intörn adayların nöbet ve servisteki hastaları 3 dakikada TUS formatına dönüştürme aracı. |

## Sınav Anı, Panik Protokolü & Provalar (Modül 4, 4 Kasım 2026)
| Konu | Karar ve Neden |
|---|---|
| 90 sn Panik / Nefes Protokolü | Huberman Lab 84 sn (7 döngü x 12 sn) Döngüsel İç Çekme (Cyclic Sighing) animasyonlu rehberi + Jamieson bilişsel yeniden değerlendirme kartı. |
| Gerçek Saat Sınav Provası (135 Dk) | 100 soru, 135 dk geri sayım, çeyrek dilim tempo kontrolü (25., 50., 75., 100. sorular), doğrudan Deneme Kaydetme ekranına aktarım. |
| Ara Dinlenme Protokolü (135 Dk) | TTBT ve KTBT oturumları arasında cevap tartışmasını engelleyen sıfırlama rehberi. |
| Beklenen Değer (EV) & Cevap Değiştirme | 2 şık elendiğinde işaretlemenin beklenen net kazancı (+0.167 net) ve cevap değiştirme kuralları. |

## Master Yönetim Kokpiti & "Eğer–O Zaman" Algoritmaları (Modül 5, 4 Kasım 2026)
| Konu | Karar ve Neden |
|---|---|
| Master Yönetim Kokpiti | Haftalık 8 Bilişsel + 4 Sınav Göstergesini ve 0-100 Kompozit Bilişsel Sağlık Skorunu tek ekranda birleştirir. |
| 8 Bilişsel Gösterge | 1. Kalibrasyon Farkı, 2. Aşırı Güven Alarmı, 3. Uyku Süresi & Sirkadiyen Sapma, 4. Prefrontal Korteks & C Tipi Hata Oranı, 5. Test Kaygı Puanı, 6. R1 Tekrar Geçiş Oranı, 7. R3 Tekrar Geçiş Oranı, 8. Odak Puanı & Ağır Analitik Tavan. |
| 4 Sınav Göstergesi | Temel Net (TTBT), Klinik Net (KTBT), Klinik Ağırlıklı K Puanı (0.4 TTBT + 0.6 KTBT), Tahmini ÖSYM 85 EBAP Puanı. |
| Otomatik "Eğer–O Zaman" Motoru | C hatası > %15 ➔ %70 Kurtarma Modu; Kalibrasyon > +%8 ➔ Çeldiriciye tersini düşün; Son çeyrek hatası > 1.5x ➔ Tempo & mikro nefes molası; Kaygı ≥ 7 ➔ 90 sn panik provaları; R1 < %75 ➔ Yeni konuyu %20 kıs; Uyku sapması > 30 dk ➔ Sirkadiyen sabitleme; EV ➔ 2 şık elendiğinde boş bırakma yasağı. |

## Kullanım Rehberi & Görsel Tanıtım Turu (4 Kasım 2026 - Kullanıcı Kararı: Seçenek 1 Hibrit Model)
| Konu | Karar ve Neden |
|---|---|
| Görsel Tanıtım Turu (TanitimTuruEkrani) | 5 tematik slayt (1. Planlama & R0-R4 Tekrarlar, 2. F.T. time & 3-4 Saat Tavanı, 3. Denemeler & Özel Defterler, 4. Sınav Anı & 90 sn Nefes, 5. Master Kokpit). Karşılama ekranında, Bugün ekranında, Rehberde ve Ayarlarda tek dokunuşla izlenebilir. |
| Kullanım Rehberi & SSS (RehberEkrani) | 6 ana kategoride pratik soru-cevap rehberi: İlk gün adımları, R0-R4 tekrar formülleri, gecikme kayması, kafein kesilme alarmı, %70 kurtarma modu, A-F hata kodlaması, 90 sn panik protokolü, Beklenen Değer (EV) kuralı ve Master Kokpit göstergeleri. |


## Sadelestirme ve Rakip Analizi Kararlari (6 Kasim 2026 - Kullanici Karari)
Kaynak: pazar analizi ve ozellik budama raporu (4 Kasim 2026). Plan ayrintilari `docs/sadelestirme-plani.md` icinde.

| Konu | Karar |
|---|---|
| Budama yontemi | Ozellikler SILINMEZ, arayuzden GIZLENIR. Mevcut JSON verisi ve kullanici notlari korunur. |
| Hazir tibbi referans | Hazir skor listesi ve mekanizma sablonlari salt-okunur kucuk "Referans" olarak kalir. Yukaridaki "Tibbi icerik yok" karari buna gore guncellendi. |
| Grup motivasyonu (Surum 2) | Iki secenek de olacak: haftalik siralama VE ortak haftalik hedef. Kullanici hangisini gorecegini secebilir. |
| Gunluk limit | Iki sinir birlikte: gunde en fazla 4 YENI konu + en fazla 10 TEKRAR. (Eski "10 tekrar/gun" karari yeni konu siniriyla tamamlandi.) |
| Bildirim sorunu | Planlamanin DISINDA. Kullanici ozel bir zamanda kendisi ilgilenecek. Yeni gorevlerde bu soruna bagimlilik kurulmaz. Sorun HANDOFF > Bilinen sorunlar'da kalir. |
| Hata kodu esleme (S5) | Kullanici karari devretti (6 Kasim 2026), model karar verdi: A ve D -> Bilgi, B -> Yanlis biliyordum, C, E, F -> Dikkat-Sure. Neden: D (mantik/halka hatasi) neden-sonuc zincirinde eksik bilgiden kaynaklanir; dikkat veya sure sorunu degildir. Eski kayitlar silinmez, yalnizca gosterimde eslenir. |

## Kütüphane Modülü ve F.T. Time Geçici Kaldırma (6 Kasım 2026)
| Konu | Karar |
|---|---|
| F.T. Time Modülü | Geçici olarak projeden kaldırıldı/gizlendi (`ftTimeAcik = false`). Kodlar silinmedi; düzenleme yapıldıktan sonra yeniden açılacak. |
| Alt Menü Dönüşümü | 4. sekme olan F.T. time yerine **Kütüphane** sekmesi yerleştirildi (Bugün · Dersler · Takvim · Kütüphane). |
| Kütüphane Modülü | Sürüm 1 için kitap ekleme, içindekiler/bölüm yerleştirme, çalışma işaretleme ve ilerleme takibi. |
| İçindekiler Girişi | 1) Toplu Yapıştırma: alt alta yapıştırılan veya telefon kamerasından (Google Lens / Canlı Metin) kopyalanan içindekiler metnini otomatik bölümlere ayırma. 2) Tek tek bölüm ekleme. İsteğe bağlı sayfa aralığı desteği. |
| İlerleme Takibi | Kitap bazında (% ve bölüm sayısı) ve genel kütüphane bazında tamamlama oranı; sıradaki çalışılacak bölümün öne çıkarılması. |
| Veri Saklama | Kitap ve bölüm verileri yerel `PlanDeposu` JSON yapısına entegre edildi. |

## Kütüphane Bölüm Notları ve Fotoğraf Ekleme (6 Kasım 2026 - Kullanıcı Kararı)
| Konu | Karar |
|---|---|
| Bölüm Notları | Her kitabın her bölümüne birden fazla fotoğraflı veya metinli not kartı eklenebilir. İstendiğinde sadece fotoğraf, sadece metin veya her ikisi birlikte kullanılabilir. |
| Fotoğraf Kaynağı | Hem cihaz kamerası (anında çekim) hem de galeri (ekran görüntüleri) desteklenir (`image_picker`). |
| Fotoğraf Görüntüleme & Zoom | Eklenen fotoğrafa dokunulduğunda tam ekran açılır ve iki parmakla yakınlaştırma (pinch-to-zoom) yapılabilir (`InteractiveViewer`). |
| Veri & Optimizasyon | Fotoğraflar okunabilirlik korunarak optimize edilir ve yerel JSON içinde Base64 olarak saklanır; böylece harici dosya kaybı riski olmadan yedeklenebilir. |
| Test Soyutlaması | `ResimSecici` soyut arayüzü sayesinde testler `SahteResimSecici` ile çalışır; platform/kamera bağımlılığı testleri etkilemez. |
| Örnek Kitap Desteği | İlk kurulumda veya kütüphane boşken/menüden tek dokunuşla yüklenebilen zengin TUSDATA Patoloji Konu Kitabı (6 bölüm, 260 sayfa, 2 tamamlanmış bölüm ve örnek klinik not). |
