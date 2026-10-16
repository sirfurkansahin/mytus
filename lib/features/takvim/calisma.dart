import 'package:app/core/tarih.dart';

/// Bir tekrarın yapıldığını gösteren kayıt.
class TekrarKaydi {
  const TekrarKaydi({required this.no, required this.tarih});

  /// 1'den başlar (Tekrar 1, Tekrar 2...).
  final int no;

  /// Tekrarın gerçekten yapıldığı gün.
  final DateTime tarih;

  Map<String, Object?> toJson() => {'no': no, 'tarih': tarihAnahtari(tarih)};

  static TekrarKaydi? fromJson(Object? veri) {
    if (veri is! Map<String, dynamic>) return null;
    final no = veri['no'];
    final tarih = veri['tarih'];
    if (no is! int || no < 1 || tarih is! String) return null;
    final gun = tarihCoz(tarih);
    return gun == null ? null : TekrarKaydi(no: no, tarih: gun);
  }
}

/// Bir konunun takvime yerleştirilmiş tek bir çalışması (bir "tur").
/// Aynı konu birden çok kez yerleştirilebilir (ikinci tur gibi); her biri kendi
/// tekrar dizisini üretir.
class Calisma {
  const Calisma({
    required this.id,
    required this.konuId,
    required this.tarih,
    this.tamam = false,
    this.tekrarlar = const [],
  });

  final int id;
  final int konuId;

  /// Planlanan gün; "Çalıştım" denince çalışılan gün olur. Tekrarlar bu günden hesaplanır.
  final DateTime tarih;

  /// Kullanıcı "Çalıştım" işaretledi mi?
  final bool tamam;

  /// Yapılmış tekrarlar.
  final List<TekrarKaydi> tekrarlar;

  Calisma kopya({DateTime? tarih, bool? tamam, List<TekrarKaydi>? tekrarlar}) =>
      Calisma(
        id: id,
        konuId: konuId,
        tarih: tarih ?? this.tarih,
        tamam: tamam ?? this.tamam,
        tekrarlar: tekrarlar ?? this.tekrarlar,
      );

  TekrarKaydi? tekrarKaydi(int no) {
    for (final k in tekrarlar) {
      if (k.no == no) return k;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'konuId': konuId,
        'tarih': tarihAnahtari(tarih),
        'tamam': tamam,
        'tekrarlar': [for (final k in tekrarlar) k.toJson()],
      };

  static Calisma? fromJson(Object? veri) {
    if (veri is! Map<String, dynamic>) return null;
    final id = veri['id'];
    final konuId = veri['konuId'];
    final tarih = veri['tarih'];
    if (id is! int || konuId is! int || tarih is! String) return null;
    final gun = tarihCoz(tarih);
    if (gun == null) return null;
    final kayitlar = <TekrarKaydi>[];
    final liste = veri['tekrarlar'];
    if (liste is List) {
      for (final e in liste) {
        final k = TekrarKaydi.fromJson(e);
        if (k != null) kayitlar.add(k);
      }
    }
    return Calisma(
      id: id,
      konuId: konuId,
      tarih: gun,
      tamam: veri['tamam'] == true,
      tekrarlar: kayitlar,
    );
  }
}
