import 'package:app/features/defterler/modeller.dart';

/// ÖSYM'nin mantıkla türetilemeyen ve ezber sorulan hazır TUS skorları (Rapor Bölüm 2.2).
const List<SkorKarti> hazirSkorlar = [
  SkorKarti(
    id: 'skor_hinchey',
    ad: 'Modifiye Hinchey Sınıflaması',
    brans: 'Genel Cerrahi',
    parametreler: [
      'Evre 0: Hafif klinik divertikülit (BT normal)',
      'Evre Ia: Kolona sınırlı flegmon veya perikolik inflamasyon',
      'Evre Ib: Perikolik sınırlı apse (<4-5 cm)',
      'Evre II: Pelvik, retroperitoneal veya uzak apse',
      'Evre III: Pürülan jeneralize peritonit',
      'Evre IV: Fekal jeneralize peritonit (en mortal)',
    ],
    klinikKarar:
        'Evre Ia-Ib: Medikal / antibiyotik. Evre II (>4 cm): Perkütan drenaj. Evre III-IV: Acil cerrahi (Hartmann veya rezeksiyon + primer anastomoz).',
    osymTuzagi:
        'Perkütan drenaj endikasyonunu sorar (Evre 2 / pelvik apse). Fekal peritonitin Evre IV olduğunu çeldiriciye koyar.',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_hodgkin_ips',
    ad: 'Hodgkin Uluslararası Prognostik Skor (IPS)',
    brans: 'Dahiliye / Hematoloji',
    parametreler: [
      '1. Yaş ≥ 45',
      '2. Erkek cinsiyet',
      '3. Evre IV hastalık',
      '4. Albumin < 4 g/dL',
      '5. Hemoglobin < 10.5 g/dL',
      '6. Lökosit ≥ 15.000 /mm³',
      '7. Lenfosit < 600 /mm³ veya < %8',
    ],
    klinikKarar:
        'Her kriter 1 puan. 0-2 puan: Düşük risk. 3-4 puan: Orta risk. ≥5 puan: Yüksek risk (daha agresif kemoterapi).',
    osymTuzagi:
        'Trombosit sayısı ve Sedimantasyon (ESR) bu skorda YOKTUR! Çeldiriciye daima sedim veya trombosit koyarlar.',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_child_pugh',
    ad: 'Child-Pugh Siroz Evrelemesi',
    brans: 'Dahiliye / Gastroenteroloji',
    parametreler: [
      '1. Total Bilirubin (<2 / 2-3 / >3 mg/dL)',
      '2. Serum Albumin (>3.5 / 2.8-3.5 / <2.8 g/dL)',
      '3. INR / Protrombin Zamanı (<1.7 / 1.7-2.3 / >2.3)',
      '4. Asit (Yok / Hafif-Orta / Belirgin-Refrakter)',
      '5. Hepatik Ensefalopati (Yok / Evre 1-2 / Evre 3-4)',
    ],
    klinikKarar:
        'Sınıf A: 5-6 puan (1 yıllık sağkalım %100). Sınıf B: 7-9 puan (Cerrahi için dikkat). Sınıf C: 10-15 puan (Karaciğer nakil adayı).',
    osymTuzagi:
        'Kreatinin, AST/ALT ve Trombosit Child-Pugh parametresi DEĞİLDİR! (Kreatinin MELD skoru içindedir).',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_wells_pe',
    ad: 'Wells Pulmoner Emboli Skoru',
    brans: 'Dahiliye / Göğüs Hastalıkları',
    parametreler: [
      '+3.0: DVT klinik bulgu ve semptomları',
      '+3.0: Pulmoner emboliden daha olası alternatif tanı yok',
      '+1.5: Taşikardi (Nabız > 100/dk)',
      '+1.5: İmmobilizasyon (≥3 gün yatak) veya son 4 haftada cerrahi',
      '+1.5: Daha önceden geçirilmiş DVT veya PE öyküsü',
      '+1.0: Hemoptizi',
      '+1.0: Malignite (aktif tedavi veya son 6 ay)',
    ],
    klinikKarar:
        'Puan > 4: Pulmoner Emboli Olası ➔ Doğrudan BT Pulmoner Anjiyo yap. Puan ≤ 4: PE Düşük Olasılık ➔ Önce D-Dimer bak.',
    osymTuzagi:
        'Plesitral göğüs ağrısı ve EKG bulguları skorda YOKTUR. En yüksek puan (+3.0) alternatif tanı olmaması ve DVT kliniğidir.',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_curb65',
    ad: 'CURB-65 Toplum Kökenli Pnömoni Skoru',
    brans: 'Dahiliye / Göğüs Hastalıkları',
    parametreler: [
      'C: Konfüzyon (Mental durum değişikliği)',
      'U: Üre > 42 mg/dL (BUN > 19 mg/dL)',
      'R: Solunum sayısı (Respiratuar rate) ≥ 30/dk',
      'B: Kan basıncı (Sistolik < 90 veya Diyastolik ≤ 60 mmHg)',
      '65: Yaş ≥ 65',
    ],
    klinikKarar:
        '0-1 Puan: Ayaktan tedavi. 2 Puan: Serviste yatış. ≥3 Puan: Yoğun bakım değerlendirmesi.',
    osymTuzagi:
        'Ateş yüksekliği, lökositoz ve hipoksi (SpO2) CURB-65 skoru içinde YER ALMAZ!',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_ranson',
    ad: 'Akut Pankreatit Ranson Kriterleri',
    brans: 'Genel Cerrahi',
    parametreler: [
      'Başvuru anında (GA LAW):',
      '· G: Glukoz > 200 mg/dL',
      '· A: Yaş (Age) > 55',
      '· L: Lökosit > 16.000 /mm³',
      '· A: AST > 250 U/L',
      '· W: LDH > 350 U/L',
      '48. saatte (C HOBBS): Kalsiyum < 8, Hct düşüşü > %10, PaO2 < 60, BUN artışı > 5, Baz açığı > 4, Sıvı sekestrasyonu > 6L',
    ],
    klinikKarar:
        '<3 kriter: Hafif pankreatit (mortalite <%3). ≥3 kriter: Ciddi akut pankreatit (yoğun bakım takibi gerekir).',
    osymTuzagi:
        'Amilaz ve Lipaz seviyesi Ranson kriterleri içinde ve pankreatit prognozunda ASLA YER ALMAZ!',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_duke_ie',
    ad: 'Modifiye Duke İnfektif Endokardit Kriterleri',
    brans: 'Dahiliye / Kardiyoloji',
    parametreler: [
      'Majör Kriterler:',
      '· 1. Tipik mikroorganizma ile pozitif kan kültürü (2 ayrı)',
      '· 2. Pozitif Ekokardiyografi (Vejetasyon, apse, yeni protez kapak ayrılması)',
      '· 3. Coxiella burnetii için tek pozitif kültür veya Faz 1 IgG > 1:800',
      'Minör Kriterler: Predispozisyon (kalp patolojisi / IV ilaç), Ateş ≥ 38°C, Vasküler fenomenler (emboli, Janeway), İmmünolojik fenomenler (Osler nodülü, Roth lekesi, GN), Şüpheli mikrobiyoloji.',
    ],
    klinikKarar:
        'Kesin Tanı: 2 Majör VEYA 1 Majör + 3 Minör VEYA 5 Minör kriter.',
    osymTuzagi:
        'Janeway lezyonları Vasküler/ağrısızdır; Osler nodülleri İmmünolojik/ağrılıdır. Ayrımını sıklıkla sorarlar.',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_qsofa',
    ad: 'qSOFA (Hızlı Sepsis Değerlendirmesi)',
    brans: 'Genel Cerrahi / Dahiliye',
    parametreler: [
      '1. Solunum sayısı ≥ 22 /dk',
      '2. Değişmiş mental durum (GKS < 15)',
      '3. Sistolik kan basıncı ≤ 100 mmHg',
    ],
    klinikKarar:
        '≥ 2 kriter varlığında sepsis şüphesi yüksektir; organ disfonksiyonu ve yoğun bakım riski değerlendirilir.',
    osymTuzagi:
        'Lökosit ve ateş qSOFA içinde YOKTUR (Bunlar eski SIRS kriterleridir).',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_jones_arf',
    ad: 'Modifiye Jones Akut Romatizmal Ateş (ARA) Kriterleri',
    brans: 'Pediatri / Kardiyoloji',
    parametreler: [
      'Ön Şart: Geçirilmiş AGBHS enfeksiyon kanıtı (ASO yüksekliği veya boğaz kültürü)',
      'Majör Kriterler (JONES):',
      '· J: Gezici poliartrit (eklemler)',
      '· O: Kardit (Kalp / en sık tutulan mitral kapak)',
      '· N: Subkutan nodüller',
      '· E: Eritema marjinatum',
      '· S: Sydenham koresi (tek başına bile tanı koydurabilir)',
      'Minör Kriterler: Ateş, Artralji, Sedim/CRP artışı, EKG\'de uzamış PR aralığı.',
    ],
    klinikKarar:
        'Ön şart + 2 Majör VEYA Ön şart + 1 Majör + 2 Minör kriter ile ARA tanısı konur.',
    osymTuzagi:
        'Poliartrit majör iken artralji minördür. Kardit varsa EKG\'de PR uzaması ek minör kriter sayılamaz.',
    ozelMi: false,
  ),
  SkorKarti(
    id: 'skor_alvarado',
    ad: 'Alvarado Akut Apandisit Skoru (MANTRELS)',
    brans: 'Genel Cerrahi',
    parametreler: [
      'M: Göç eden (migrating) ağrı (+1)',
      'A: İştahsızlık (anoreksi) (+1)',
      'N: Bulantı/kusma (+1)',
      'T: Sağ alt kadranda hassasiyet (+2 - İKİ PUAN)',
      'R: Rebound hassasiyeti (+1)',
      'E: Ateş (Elevation of temp ≥37.3°C) (+1)',
      'L: Lökositoz > 10.000 (+2 - İKİ PUAN)',
      'S: Sola kayma / nötrofili (+1)',
    ],
    klinikKarar:
        'Toplam 10 puan. ≤4: Apandisit dışlanır. 5-6: Gözlem / USG. 7-8: Muhtemel apandisit (cerrahi değerlendirme). 9-10: Kesin apandisit (cerrahi).',
    osymTuzagi:
        'Sağ alt kadran hassasiyeti ve Lökositoz 2\'şer puandır, diğer tüm kriterler 1 puandır.',
    ozelMi: false,
  ),
];
