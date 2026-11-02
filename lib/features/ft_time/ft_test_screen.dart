import 'dart:async';

import 'package:app/core/renkler.dart';
import 'package:app/features/ft_time/ft_native.dart';
import 'package:app/features/ft_time/ft_test_bilesenleri.dart';
import 'package:app/features/ft_time/ft_timer.dart';
import 'package:app/features/ft_time/pil_rehberi.dart';
import 'package:flutter/material.dart';

/// F.T. time sayaç PROTOTİPİ. Amaç: sayacın ekran kapalıyken ve uygulama
/// arka plandayken de süre bitince uyardığını telefonda ölçmek.
/// Gerçek F.T. time ekranı (döngüler, mola, puan) sonraki parçada gelecek.
class FtTestScreen extends StatefulWidget {
  const FtTestScreen({super.key, this.native = const FtNative()});

  final FtNative native;

  @override
  State<FtTestScreen> createState() => _FtTestScreenState();
}

class _FtTestScreenState extends State<FtTestScreen>
    with WidgetsBindingObserver {
  static const String _durumAnahtari = 'timer_state';
  static const int _dakikaMs = 60 * 1000;
  static const List<int> _sureSecenekleri = [1, 5, 25];

  FtTimerState _state = const FtTimerState.bosta(25 * _dakikaMs);
  Timer? _ticker;
  bool? _bildirimAcik;
  bool? _pilKisitsiz;
  int? _sonTetik;
  int? _sonBeklenen;
  int? _servisBasladi;
  int? _servisDurdu;
  String? _servisHata;
  String? _derlemeNo;

  int _simdi() => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _baslangic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed) {
      _yenile();
    }
  }

  Future<void> _baslangic() async {
    final kullanilabilir = await widget.native.kullanilabilir();
    final kayit = await widget.native.kayitOku(_durumAnahtari);
    if (!mounted) return;
    final yuklenen = FtTimerState.fromJsonString(kayit);
    if (yuklenen != null) {
      _state = yuklenen;
    }
    await _yenile();
    if (!mounted || !kullanilabilir) return;
    await pilRehberiniBirKezGoster(context, widget.native);
  }

  /// Durumu saatten yeniden hesaplar ve ekrandaki bilgileri tazeler.
  Future<void> _yenile() async {
    final onceki = _state;
    final guncel = onceki.guncelle(_simdi());
    final yeniBitti =
        guncel.phase == FtPhase.bitti && onceki.phase == FtPhase.calisiyor;
    if (yeniBitti) {
      await _kaydet(guncel);
      await widget.native.calisanBildirimiKaldir();
    }
    final bildirim = await widget.native.bildirimAcik();
    final pil = await widget.native.pilKisitsiz();
    final tetik = await widget.native.kayitOku('last_fired_at');
    final beklenen = await widget.native.kayitOku('last_expected_end');
    final svcBasladi = await widget.native.kayitOku('svc_started_at');
    final svcDurdu = await widget.native.kayitOku('svc_destroyed_at');
    final svcHata = await widget.native.kayitOku('svc_error');
    final derleme = await widget.native.derlemeNo();
    if (!mounted) return;
    setState(() {
      _state = guncel;
      _bildirimAcik = bildirim;
      _pilKisitsiz = pil;
      _sonTetik = int.tryParse(tetik ?? '');
      _sonBeklenen = int.tryParse(beklenen ?? '');
      _servisBasladi = int.tryParse(svcBasladi ?? '');
      _servisDurdu = int.tryParse(svcDurdu ?? '');
      _servisHata = (svcHata == null || svcHata.isEmpty) ? null : svcHata;
      _derlemeNo = derleme;
    });
    _tickerAyarla();
    if (yeniBitti) {
      // Alarm kaydı saniyenin altında gecikebilir; bir kez daha okuyoruz.
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) _yenile();
      });
    }
  }

  void _tickerAyarla() {
    if (_state.phase == FtPhase.calisiyor) {
      _ticker ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
        _tick();
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    final guncel = _state.guncelle(_simdi());
    if (guncel.phase != FtPhase.calisiyor) {
      _yenile();
    } else {
      setState(() {});
    }
  }

  Future<void> _kaydet(FtTimerState durum) =>
      widget.native.kayitYaz(_durumAnahtari, durum.toJsonString());

  Future<void> _baslat() async {
    final yeni = _state.baslat(_simdi());
    final bitis = yeni.endAtMs;
    if (yeni.phase != FtPhase.calisiyor || bitis == null) return;
    // Önce ekranı güncelle (anında tepki), sonra alarmı kur ve kaydet.
    setState(() {
      _state = yeni;
      _sonTetik = null;
      _sonBeklenen = null;
    });
    _tickerAyarla();
    if (_bildirimAcik == false) {
      await widget.native.bildirimIzniIste();
    }
    // Eski alarm kaydını temizle: ölçüm yalnızca bu çalıştırmaya ait olsun.
    await widget.native.kayitYaz('last_fired_at', '');
    await widget.native.kayitYaz('last_expected_end', '');
    await widget.native.kayitYaz('svc_started_at', '');
    await widget.native.kayitYaz('svc_destroyed_at', '');
    await widget.native.kayitYaz('svc_error', '');
    await _kaydet(yeni);
    await widget.native.alarmKur(bitis);
  }

  Future<void> _duraklat() async {
    final yeni = _state.duraklat(_simdi());
    setState(() => _state = yeni);
    _tickerAyarla();
    await widget.native.alarmIptal();
    await _kaydet(yeni);
  }

  Future<void> _sifirla() async {
    final yeni = _state.sifirla();
    setState(() => _state = yeni);
    _tickerAyarla();
    await widget.native.alarmIptal();
    await widget.native.bitenBildirimiKaldir();
    await _kaydet(yeni);
  }

  Future<void> _sureSec(int dakika) async {
    if (_state.phase != FtPhase.bosta) return;
    final yeni = FtTimerState.bosta(dakika * _dakikaMs);
    setState(() => _state = yeni);
    await _kaydet(yeni);
  }

  Future<void> _anaDugme() {
    switch (_state.phase) {
      case FtPhase.bosta:
      case FtPhase.duraklatildi:
        return _baslat();
      case FtPhase.calisiyor:
        return _duraklat();
      case FtPhase.bitti:
        return _sifirla();
    }
  }

  String get _anaDugmeYazisi {
    switch (_state.phase) {
      case FtPhase.bosta:
        return 'Başlat';
      case FtPhase.calisiyor:
        return 'Duraklat';
      case FtPhase.duraklatildi:
        return 'Devam et';
      case FtPhase.bitti:
        return 'Yeni sayaç';
    }
  }

  String get _durumYazisi {
    switch (_state.phase) {
      case FtPhase.bosta:
        return 'Hazır';
      case FtPhase.calisiyor:
        return 'Çalışıyor';
      case FtPhase.duraklatildi:
        return 'Duraklatıldı';
      case FtPhase.bitti:
        return 'Süre bitti';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kalan = _state.kalanMs(_simdi());
    final secimAcik = _state.phase == FtPhase.bosta;
    return Scaffold(
      backgroundColor: ftZemin,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'F.T. time',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sayaç testi (prototip)',
                style: TextStyle(fontSize: 15, color: ftAcikYazi),
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
                _durumYazisi,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: ftAcikYazi),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final dakika in _sureSecenekleri)
                    ChoiceChip(
                      label: Text('$dakika dk'),
                      selected: _state.durationMs == dakika * _dakikaMs,
                      onSelected: secimAcik ? (_) => _sureSec(dakika) : null,
                      showCheckmark: false,
                      backgroundColor: ftYuzeyOrta,
                      disabledColor: ftYuzeyHafif,
                      selectedColor: ftVurgu,
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _anaDugme,
                      style: FilledButton.styleFrom(
                        backgroundColor: ftVurgu,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(_anaDugmeYazisi),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _sifirla,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: ftCizgi),
                      minimumSize: const Size(96, 52),
                    ),
                    child: const Text('Sıfırla'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FtTestArkaPlanKarti(
                bildirimAcik: _bildirimAcik,
                pilKisitsiz: _pilKisitsiz,
                onPilAyar: widget.native.pilAyarlariniAc,
                onUygulamaAyar: widget.native.uygulamaAyarlariniAc,
                onRehber: () => pilRehberiGoster(context, widget.native),
              ),
              const SizedBox(height: 16),
              FtTestAlarmKarti(
                durum: _state,
                sonTetik: _sonTetik,
                sonBeklenen: _sonBeklenen,
              ),
              const SizedBox(height: 16),
              FtTestServisKarti(
                derlemeNo: _derlemeNo,
                servisBasladi: _servisBasladi,
                servisDurdu: _servisDurdu,
                servisHata: _servisHata,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
