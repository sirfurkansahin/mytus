import 'dart:async';

import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_kontrol.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:app/features/ft_time/ft_timer.dart';
import 'package:app/features/ft_time/pil_rehberi.dart';
import 'package:flutter/material.dart';

/// Çalışan F.T. time oturumunun sayaç ekranı (koyu mor, onaylı tasarım).
class FtSayacEkrani extends StatefulWidget {
  const FtSayacEkrani({super.key, required this.kontrol});

  final FtKontrol kontrol;

  @override
  State<FtSayacEkrani> createState() => _FtSayacEkraniState();
}

class _FtSayacEkraniState extends State<FtSayacEkrani>
    with WidgetsBindingObserver {
  Timer? _ticker;

  int _simdi() => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Ekran açıldığında süre dolmuşsa işle; ilk oturumda pil rehberini göster.
      widget.kontrol.tazele();
      pilRehberiniBirKezGoster(context, widget.kontrol.native);
    });
    _tickerAyarla();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed) widget.kontrol.tazele();
  }

  void _tickerAyarla() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final o = widget.kontrol.depo.oturum;
      if (o == null || !mounted) return;
      if (o.sayac.phase == FtPhase.calisiyor) {
        if (o.guncelle(_simdi()).bolumBitti) {
          widget.kontrol.tazele();
        } else {
          setState(() {});
        }
      }
    });
  }

  Future<void> _bitir() async {
    final depo = widget.kontrol.depo;
    final o = depo.oturum;
    if (o == null) return;
    final yarim = !o.tamamlandi &&
        o.faz == FtFaz.calisma &&
        o.sayac.phase != FtPhase.bosta &&
        !o.bolumBitti;
    if (yarim) {
      final onay = await onayDialogu(
        context,
        baslik: 'Oturum bitirilsin mi?',
        metin: 'Yarım kalan döngü puan getirmez. Tamamlanan '
            '${o.tamamlananDongu} döngü (${o.kazanilanDakika} puan) kalır.',
        eylem: 'Bitir',
      );
      if (!onay || !mounted) return;
    }
    // Soruyu oturum ekranı hâlâ açıkken sor; sonra oturumu kapat.
    final ozet = widget.kontrol.ozet();
    if (ozet == null) return;
    await _calistimSor(ozet);
    if (!mounted) return;
    await widget.kontrol.bitir();
  }

  /// Konu seçilmişse ve en az bir döngü bittiyse "Çalıştım" onayı sorar.
  Future<void> _calistimSor(FtOzet ozet) async {
    final depo = widget.kontrol.depo;
    final konuId = ozet.konuId;
    if (konuId == null || ozet.tamamlananDongu < 1) return;
    final konu = depo.konuBul(konuId);
    if (konu == null) return;
    final evet = await onayDialogu(
      context,
      baslik: 'Konuyu çalıştım olarak işaretleyeyim mi?',
      metin: '"${konu.ad}" için ${ozet.tamamlananDongu} döngü '
          '(${ozet.puan} puan) tamamladın. İşaretlersen tekrarların bugünden başlar.',
      eylem: 'Evet, işaretle',
    );
    if (evet) depo.konuCalistimIsaretle(konuId, gunBasi(DateTime.now()));
  }

  String _fazAdi(FtFaz faz) {
    switch (faz) {
      case FtFaz.calisma:
        return 'Çalışma';
      case FtFaz.kisaMola:
        return 'Kısa mola';
      case FtFaz.uzunMola:
        return 'Uzun mola';
    }
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final o = depo.oturum;
    if (o == null) return const SizedBox.shrink();
    final kontrol = widget.kontrol;
    final konu = o.konuId == null ? null : depo.konuBul(o.konuId!);
    final ders = konu == null ? null : depo.dersBul(konu.dersId);
    final kalan = o.sayac.kalanMs(_simdi());
    final calisma = o.faz == FtFaz.calisma;
    final bugun = DateTime.now();

    final String durum;
    if (o.tamamlandi) {
      durum = 'Oturum tamamlandı';
    } else if (o.bolumBitti) {
      durum = calisma ? 'Döngü tamamlandı' : 'Mola bitti';
    } else if (o.sayac.phase == FtPhase.duraklatildi) {
      durum = 'Duraklatıldı';
    } else {
      durum = _fazAdi(o.faz);
    }

    final String? bilgi;
    if (o.tamamlandi) {
      bilgi = 'Tüm döngüler bitti · +${o.kazanilanDakika} puan kazandın';
    } else if (o.bolumBitti && calisma) {
      bilgi = '+${o.donguPuani} puan kazandın';
    } else {
      bilgi = null;
    }

    final Widget anaDugme;
    if (o.tamamlandi) {
      anaDugme = _Dugme(yazi: 'Bitir', onPressed: _bitir);
    } else if (o.bolumBitti) {
      final sonraki = calisma
          ? (o.siradakiMolaTuru == FtFaz.uzunMola ? 'Uzun molayı başlat' : 'Molayı başlat')
          : 'Döngü ${o.dongu + 1} başlat';
      anaDugme = _Dugme(yazi: sonraki, onPressed: kontrol.ilerle);
    } else if (o.sayac.phase == FtPhase.calisiyor) {
      anaDugme = _Dugme(yazi: 'Duraklat', onPressed: kontrol.duraklat);
    } else {
      anaDugme = _Dugme(
        yazi: o.sayac.phase == FtPhase.duraklatildi ? 'Devam et' : 'Başlat',
        onPressed: kontrol.devam,
      );
    }

    return Scaffold(
      backgroundColor: ftZemin,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'F.T. TIME',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: ftAcikYazi,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                konu?.ad ?? 'Konusuz çalışma',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (ders != null)
                Text(
                  ders.ad,
                  style: const TextStyle(fontSize: 15, color: ftAcikYazi),
                ),
              const SizedBox(height: 32),
              Text(
                sureYaz(kalan),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                durum,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ftAcikYazi,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Döngü ${o.dongu} / ${o.toplamDongu}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: ftAcikYazi),
              ),
              if (bilgi != null) ...[
                const SizedBox(height: 12),
                Text(
                  bilgi,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ftIyi,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: anaDugme),
                  if (!o.tamamlandi) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _bitir,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x66FFFFFF)),
                        minimumSize: const Size(96, 52),
                      ),
                      child: const Text('Bitir'),
                    ),
                  ],
                ],
              ),
              if (!calisma && !o.bolumBitti)
                TextButton(
                  onPressed: kontrol.molayiAtla,
                  style: TextButton.styleFrom(foregroundColor: ftAcikYazi),
                  child: const Text('Molayı atla'),
                ),
              const SizedBox(height: 24),
              Text(
                'Her döngü sonunda puan kazanırsın · '
                'Bugün ${depo.puanGun(bugun)} puan',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: ftAcikYazi),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dugme extends StatelessWidget {
  const _Dugme({required this.yazi, required this.onPressed});

  final String yazi;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ftVurgu,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
      ),
      child: Text(yazi),
    );
  }
}
