import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/takvim_eylemleri.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter/material.dart';

Widget _kart(BuildContext context, {required Widget child}) {
  final tema = Theme.of(context);
  return Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: tema.colorScheme.outlineVariant),
    ),
    child: child,
  );
}

/// Takvimde / Bugün'de görünen bir konu çalışması satırı.
class CalismaSatiri extends StatelessWidget {
  const CalismaSatiri({
    super.key,
    required this.calisma,
    required this.bugun,
    this.planliGunuGoster = false,
  });

  final Calisma calisma;
  final DateTime bugun;

  /// Gecikenlerde "12 Ekim planlıydı" gibi gösterir.
  final bool planliGunuGoster;

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final konu = depo.konuBul(calisma.konuId);
    if (konu == null) return const SizedBox.shrink();
    final ders = depo.dersBul(konu.dersId);
    final tur = depo.turNo(calisma);
    final isaretlenebilir = calisma.tamam || !calisma.tarih.isAfter(bugun);
    final altYazi = [
      if (ders != null) ders.ad,
      'Tur $tur/${depo.turSayisi}',
      if (planliGunuGoster) '${tarihKisa(calisma.tarih)} planlıydı',
    ].join(' · ');
    return _kart(
      context,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: IconButton(
          tooltip: calisma.tamam ? 'Çalıştım işaretini geri al' : 'Çalıştım',
          icon: Icon(
            calisma.tamam ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isaretlenebilir
                ? tema.colorScheme.primary
                : tema.colorScheme.outline,
          ),
          onPressed: !isaretlenebilir
              ? null
              : () {
                  if (calisma.tamam) {
                    depo.calismaGeriAl(calisma.id);
                  } else {
                    depo.calistim(calisma.id, bugun);
                  }
                },
        ),
        title: Text(
          konu.ad,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: calisma.tamam ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(altYazi),
        onTap: () => calismaEylemleri(context, calisma, bugun),
      ),
    );
  }
}

/// Takvimde / Bugün'de görünen bir tekrar satırı (kehribar vurgulu).
class TekrarSatiri extends StatelessWidget {
  const TekrarSatiri({
    super.key,
    required this.tekrar,
    required this.bugun,
    this.tarihiGoster = false,
  });

  final TekrarOgesi tekrar;
  final DateTime bugun;

  /// Gecikenlerde "17 Ekim" gibi tarihi de yazar.
  final bool tarihiGoster;

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final konu = depo.konuBul(tekrar.konuId);
    if (konu == null) return const SizedBox.shrink();
    final ders = depo.dersBul(konu.dersId);
    final vurgu = tekrarRengi(context);
    final etiket = 'Tekrar ${tekrar.no}/${tekrar.toplam}';
    final altYazi = [
      if (ders != null) ders.ad,
      if (tarihiGoster) tarihKisa(tekrar.tarih) else 'notlara bakmadan hatırla',
    ].join(' · ');
    return _kart(
      context,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: IconButton(
          tooltip: tekrar.yapildi ? 'Yaptım işaretini geri al' : 'Tekrar yaptım',
          icon: Icon(
            tekrar.yapildi ? Icons.check_circle : Icons.radio_button_unchecked,
            color: tekrar.yapildi || tekrar.eylemYapilabilir
                ? vurgu
                : tema.colorScheme.outline,
          ),
          onPressed: tekrar.yapildi
              ? () => depo.tekrarGeriAl(tekrar.calismaId, tekrar.no)
              : tekrar.eylemYapilabilir
                  ? () => depo.tekrarYapildi(tekrar.calismaId, tekrar.no, bugun)
                  : null,
        ),
        title: Text(
          konu.ad,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: tekrar.yapildi ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(altYazi),
        trailing: Text(
          etiket,
          style: TextStyle(
            color: vurgu,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        onTap: () => tekrarEylemleri(context, tekrar, bugun),
      ),
    );
  }
}

/// Bölüm başlığı: "Tekrarlar" + sağda küçük bilgi.
class BolumBasligi extends StatelessWidget {
  const BolumBasligi({super.key, required this.baslik, this.bilgi});

  final String baslik;
  final String? bilgi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              baslik,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (bilgi != null)
            Text(
              bilgi!,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
