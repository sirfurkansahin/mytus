import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/konu_ekrani.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter/material.dart';

/// Bir konuyu yerleştirebileceğin en geç gün: sınavdan bir gün önce (sınav yoksa 1 yıl sonrası).
DateTime yerlestirmeSonGunu(PlanDeposu depo, DateTime bugun) {
  final sinav = depo.sinavTarihi;
  final son = sinav == null
      ? gunEkle(bugun, 365)
      : gunEkle(gunBasi(sinav), -1);
  return son.isBefore(bugun) ? bugun : son;
}

/// Gün seçtirir (bugünden sınavdan önceki güne kadar). İptalde null.
Future<DateTime?> yerlestirmeGunuSec(
  BuildContext context,
  PlanDeposu depo, {
  DateTime? baslangic,
}) {
  final bugun = gunBasi(DateTime.now());
  final son = yerlestirmeSonGunu(depo, bugun);
  var ilk = baslangic ?? bugun;
  if (ilk.isBefore(bugun)) ilk = bugun;
  if (ilk.isAfter(son)) ilk = son;
  return showDatePicker(
    context: context,
    initialDate: ilk,
    firstDate: bugun,
    lastDate: son,
    helpText: 'Hangi gün çalışacaksın?',
  );
}

void _mesaj(BuildContext context, String metin) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(metin)));
}

Widget _eylemSatiri(
  BuildContext sheetContext,
  IconData ikon,
  String yazi,
  String deger,
) {
  return ListTile(
    leading: Icon(ikon),
    title: Text(yazi),
    onTap: () => Navigator.of(sheetContext).pop(deger),
  );
}

/// Takvimdeki bir çalışma için işlem menüsü.
Future<void> calismaEylemleri(
  BuildContext context,
  Calisma calisma,
  DateTime bugun,
) async {
  final depo = DepoKapsami.oku(context);
  final konu = depo.konuBul(calisma.konuId);
  if (konu == null) return;
  final secim = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                konu.ad,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          if (!calisma.tamam)
            _eylemSatiri(
              sheetContext,
              Icons.check_circle_outline,
              'Çalıştım (tekrarlar bugünden başlar)',
              'calistim',
            ),
          if (calisma.tamam)
            _eylemSatiri(
              sheetContext,
              Icons.undo,
              'Çalıştım işaretini geri al',
              'geriAl',
            ),
          if (!calisma.tamam && !ayniGun(calisma.tarih, bugun))
            _eylemSatiri(
              sheetContext,
              Icons.today_outlined,
              'Bugüne al',
              'bugune',
            ),
          if (!calisma.tamam)
            _eylemSatiri(
              sheetContext,
              Icons.event_outlined,
              'Gününü değiştir',
              'gun',
            ),
          _eylemSatiri(sheetContext, Icons.menu_book_outlined, 'Konuya git', 'konu'),
          _eylemSatiri(
            sheetContext,
            Icons.delete_outline,
            'Takvimden kaldır',
            'sil',
          ),
        ],
      ),
    ),
  );
  if (secim == null || !context.mounted) return;
  switch (secim) {
    case 'calistim':
      depo.calistim(calisma.id, bugun);
      _mesaj(context, 'Güzel! Tekrarların bugünden itibaren planlandı.');
    case 'geriAl':
      depo.calismaGeriAl(calisma.id);
    case 'bugune':
      depo.calismaGunuDegistir(calisma.id, bugun);
      _mesaj(context, 'Bugüne alındı. Tekrarlar yeni güne göre hesaplandı.');
    case 'gun':
      final yeni = await yerlestirmeGunuSec(
        context,
        depo,
        baslangic: calisma.tarih,
      );
      if (yeni != null) depo.calismaGunuDegistir(calisma.id, yeni);
    case 'konu':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KonuEkrani(konuId: calisma.konuId),
        ),
      );
    case 'sil':
      final onay = await onayDialogu(
        context,
        baslik: 'Takvimden kaldırılsın mı?',
        metin: '"${konu.ad}" bu günden kaldırılacak. Tekrarları da kalkar. '
            'Konu ve notların silinmez.',
        eylem: 'Kaldır',
      );
      if (onay) depo.calismaSil(calisma.id);
  }
}

/// Takvimdeki bir tekrar için işlem menüsü.
Future<void> tekrarEylemleri(
  BuildContext context,
  TekrarOgesi tekrar,
  DateTime bugun,
) async {
  final depo = DepoKapsami.oku(context);
  final konu = depo.konuBul(tekrar.konuId);
  if (konu == null) return;
  final secim = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${konu.ad} · Tekrar ${tekrar.no}/${tekrar.toplam}',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          if (tekrar.eylemYapilabilir)
            _eylemSatiri(
              sheetContext,
              Icons.check_circle_outline,
              'Tekrar yaptım',
              'yaptim',
            ),
          if (tekrar.yapildi)
            _eylemSatiri(
              sheetContext,
              Icons.undo,
              'Yaptım işaretini geri al',
              'geriAl',
            ),
          if (!tekrar.calismaTamam)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Önce konuyu "Çalıştım" olarak işaretlemelisin.'),
            ),
          if (tekrar.calismaTamam && !tekrar.siradaki && !tekrar.yapildi)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Önceki tekrarı yaptıktan sonra sıra buna gelir.'),
            ),
          _eylemSatiri(sheetContext, Icons.menu_book_outlined, 'Konuya git', 'konu'),
        ],
      ),
    ),
  );
  if (secim == null || !context.mounted) return;
  switch (secim) {
    case 'yaptim':
      depo.tekrarYapildi(tekrar.calismaId, tekrar.no, bugun);
    case 'geriAl':
      depo.tekrarGeriAl(tekrar.calismaId, tekrar.no);
    case 'konu':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KonuEkrani(konuId: tekrar.konuId),
        ),
      );
  }
}
