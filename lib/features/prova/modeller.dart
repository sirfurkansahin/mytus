import 'package:flutter/material.dart';

/// Sınav anı, prova temposu ve beklenen değer modelleri.
/// (Master Araştırma Raporu Bölüm 5.1, 5.2 ve 5.3)

/// Deneme sınavı anında soru çözüm temposu durumu.
enum TempoDurumu {
  onde('Öndesiniz ⚡', Colors.green),
  zamaninda('Zamanında ✅', Colors.blue),
  geride('Geridesiniz ⚠️', Colors.orange);

  const TempoDurumu(this.etiket, this.renk);

  final String etiket;
  final Color renk;
}

/// Çeyrek dilim tempo kontrol noktası (Rapor Bölüm 5.1).
class CeyrekDilimHedefi {
  const CeyrekDilimHedefi({
    required this.soruNo,
    required this.hedefDakika,
    required this.etiket,
  });

  final int soruNo;
  final int hedefDakika;
  final String etiket;
}

/// 135 dakikalık 100 soruluk TUS oturumu için çeyrek dilim referansları.
const List<CeyrekDilimHedefi> resmiCeyrekDilimler = [
  CeyrekDilimHedefi(soruNo: 25, hedefDakika: 32, etiket: '1. Çeyrek (25. Soru)'),
  CeyrekDilimHedefi(soruNo: 50, hedefDakika: 65, etiket: 'Yarı Yol (50. Soru)'),
  CeyrekDilimHedefi(soruNo: 75, hedefDakika: 98, etiket: '3. Çeyrek (75. Soru)'),
  CeyrekDilimHedefi(soruNo: 100, hedefDakika: 130, etiket: 'Bitiş & Kontrol (100. Soru)'),
];

/// Belirli bir soru numarası için hedeflenen süreyi (dakika) döndürür.
/// 100 soru 130 dakikada biter, son 5 dakika kontrol ve form payıdır.
double hedefGecenDakika(int soruNo) {
  return (soruNo * 1.30);
}

/// Tempo analizi sonucu.
class TempoBilgisi {
  const TempoBilgisi({
    required this.durum,
    required this.farkDakika,
    required this.aciklama,
  });

  final TempoDurumu durum;
  final int farkDakika;
  final String aciklama;
}

/// Anlık soru numarası ve geçen süreye göre tempo durumunu hesaplar.
TempoBilgisi tempoAnalizi({required int soruNo, required int gecenSaniye}) {
  if (soruNo <= 0) {
    return const TempoBilgisi(
      durum: TempoDurumu.zamaninda,
      farkDakika: 0,
      aciklama: 'Prova başladı',
    );
  }
  final gecenDk = gecenSaniye / 60.0;
  final hedefDk = hedefGecenDakika(soruNo);
  final farkDk = (hedefDk - gecenDk).round();

  if (farkDk >= 2) {
    return TempoBilgisi(
      durum: TempoDurumu.onde,
      farkDakika: farkDk,
      aciklama: '$farkDk dk öndesiniz · Temponuz rahat',
    );
  } else if (farkDk <= -2) {
    return TempoBilgisi(
      durum: TempoDurumu.geride,
      farkDakika: farkDk.abs(),
      aciklama: '${farkDk.abs()} dk geridesiniz · Hızlanmanız önerilir',
    );
  } else {
    return const TempoBilgisi(
      durum: TempoDurumu.zamaninda,
      farkDakika: 0,
      aciklama: 'Tam hedef tempodasınız (±1 dk)',
    );
  }
}

/// ÖSYM 5 seçenekli soru için elenen şık sayısına göre Beklenen Değer (EV) hesabı.
/// Yanlış: -0.25 net, Doğru: +1.0 net.
/// (Rapor Bölüm 5.3)
double beklenenDegerHesapla(int elenenSikSayisi) {
  final k = (5 - elenenSikSayisi).clamp(1, 5);
  final ev = (1.25 - (0.25 * k)) / k;
  return double.parse(ev.toStringAsFixed(3));
}
