import 'package:app/core/renkler.dart';
import 'package:app/features/ft_time/ft_timer.dart';
import 'package:flutter/material.dart';

// Sayaç testi ekranının kart, satır, düğme ve ölçüm panelleri.

class FtKart extends StatelessWidget {
  const FtKart({super.key, required this.baslik, required this.children});

  final String baslik;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ftYuzeyHafif,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class FtSatir extends StatelessWidget {
  const FtSatir({
    super.key,
    required this.etiket,
    required this.deger,
    this.renk = ftAcikYazi,
  });

  final String etiket;
  final String deger;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              etiket,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              deger,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: renk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FtLinkDugme extends StatelessWidget {
  const FtLinkDugme({super.key, required this.yazi, required this.onPressed});

  final String yazi;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: ftAcikYazi),
      child: Text(yazi),
    );
  }
}

/// Sayaç testi ekranındaki "Arka plan durumu" kartı.
class FtTestArkaPlanKarti extends StatelessWidget {
  const FtTestArkaPlanKarti({
    super.key,
    required this.bildirimAcik,
    required this.pilKisitsiz,
    required this.onPilAyar,
    required this.onUygulamaAyar,
    required this.onRehber,
  });

  final bool? bildirimAcik;
  final bool? pilKisitsiz;
  final VoidCallback onPilAyar;
  final VoidCallback onUygulamaAyar;
  final VoidCallback onRehber;

  String _izinYazisi(bool? deger, String acik, String kapali) {
    if (deger == null) return 'Bilinmiyor';
    return deger ? acik : kapali;
  }

  Color _izinRengi(bool? deger) {
    if (deger == null) return ftAcikYazi;
    return deger ? ftIyi : ftUyari;
  }

  @override
  Widget build(BuildContext context) {
    return FtKart(
      baslik: 'Arka plan durumu',
      children: [
        FtSatir(
          etiket: 'Bildirim izni',
          deger: _izinYazisi(bildirimAcik, 'Açık', 'Kapalı'),
          renk: _izinRengi(bildirimAcik),
        ),
        FtSatir(
          etiket: 'Pil kısıtlaması',
          deger: _izinYazisi(
            pilKisitsiz,
            'Yok (iyi)',
            'Olabilir (sorun çıkarabilir)',
          ),
          renk: _izinRengi(pilKisitsiz),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            FtLinkDugme(
              yazi: 'Pil ayarlarını aç',
              onPressed: onPilAyar,
            ),
            FtLinkDugme(
              yazi: 'Uygulama ayarlarını aç',
              onPressed: onUygulamaAyar,
            ),
            FtLinkDugme(
              yazi: 'Rehberi göster',
              onPressed: onRehber,
            ),
          ],
        ),
      ],
    );
  }
}

/// Sayaç testi ekranındaki "Alarm ölçümü" kartı.
class FtTestAlarmKarti extends StatelessWidget {
  const FtTestAlarmKarti({
    super.key,
    required this.durum,
    required this.sonTetik,
    required this.sonBeklenen,
  });

  final FtTimerState durum;
  final int? sonTetik;
  final int? sonBeklenen;

  List<Widget> _satirlar() {
    final bitis = durum.endAtMs;
    if (durum.phase == FtPhase.bitti && bitis != null) {
      final tetik = sonTetik;
      return [
        FtSatir(etiket: 'Beklenen bitiş', deger: saatYaz(bitis)),
        if (tetik != null && sonBeklenen == bitis)
          FtSatir(
            etiket: 'Alarm tetiklendi',
            deger:
                '${saatYaz(tetik)} (${((tetik - bitis) / 1000).toStringAsFixed(1)} sn gecikme)',
            renk: ftIyi,
          )
        else
          const FtSatir(
            etiket: 'Alarm kaydı',
            deger: 'Yok. Alarm çalışmamış olabilir.',
            renk: ftUyari,
          ),
      ];
    }
    if (durum.phase == FtPhase.calisiyor && bitis != null) {
      return [
        FtSatir(etiket: 'Beklenen bitiş', deger: saatYaz(bitis)),
        const FtSatir(
          etiket: 'Test',
          deger:
              'Ekranı kapat veya başka uygulamaya geç; süre bitince bildirim gelmeli.',
        ),
      ];
    }
    return const [
      FtSatir(
        etiket: 'Nasıl test edilir',
        deger: 'Başlat, ekranı kapat, süre bitince bildirimi bekle.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FtKart(baslik: 'Alarm ölçümü', children: _satirlar());
  }
}

/// Sayaç testi ekranındaki "Servis ölçümü" kartı.
class FtTestServisKarti extends StatelessWidget {
  const FtTestServisKarti({
    super.key,
    required this.derlemeNo,
    required this.servisBasladi,
    required this.servisDurdu,
    required this.servisHata,
  });

  final String? derlemeNo;
  final int? servisBasladi;
  final int? servisDurdu;
  final String? servisHata;

  @override
  Widget build(BuildContext context) {
    return FtKart(
      baslik: 'Servis ölçümü',
      children: [
        FtSatir(etiket: 'Derleme no', deger: derlemeNo ?? '-'),
        FtSatir(
          etiket: 'Servis başladı',
          deger: servisBasladi == null ? 'Hayır' : saatYaz(servisBasladi!),
          renk: servisBasladi == null ? ftUyari : ftIyi,
        ),
        FtSatir(
          etiket: 'Servis durdu',
          deger: servisDurdu == null ? 'Hayır' : saatYaz(servisDurdu!),
        ),
        FtSatir(
          etiket: 'Servis hatası',
          deger: servisHata ?? 'Yok',
          renk: servisHata == null ? ftAcikYazi : ftUyari,
        ),
      ],
    );
  }
}
