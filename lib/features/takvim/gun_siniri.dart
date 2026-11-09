import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Güne yeni konu yerleştirmeden önce günlük yeni konu sınırını (varsayılan 4) kontrol eder.
/// Sınır aşılmıyorsa sormadan true döner; aşılıyorsa kullanıcıya "Yine de ekle?" diye sorar.
Future<bool> yeniKonuSiniriOnayi(
  BuildContext context,
  PlanDeposu depo,
  DateTime gun, {
  int eklenecekSayi = 1,
}) async {
  final mevcut = depo.gundekiKonuSayisi(gun);
  if (mevcut + eklenecekSayi <= depo.gunlukYeniKonuSiniri) return true;
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Bu gün dolu görünüyor'),
      content: Text(
        eklenecekSayi > 1
            ? 'Bu günde zaten $mevcut konu planlı '
                '(önerilen günlük sınır ${depo.gunlukYeniKonuSiniri}). '
                '$eklenecekSayi yeni konu daha eklensin mi?'
            : 'Bu güne zaten $mevcut konu yerleştirdin '
                '(önerilen en çok ${depo.gunlukYeniKonuSiniri}). Yine de eklensin mi?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yine de ekle'),
        ),
      ],
    ),
  );
  return sonuc ?? false;
}
