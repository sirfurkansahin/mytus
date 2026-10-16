/// Dersler iki gruba ayrılır (onaylı karar): Temel ve Klinik.
enum DersGrubu { temel, klinik }

extension DersGrubuAdi on DersGrubu {
  String get ad => this == DersGrubu.temel ? 'Temel' : 'Klinik';
}

/// Hazır ders listesindeki bir satır (henüz kayıtlı ders değil).
class HazirDers {
  const HazirDers(this.ad, this.grup);

  final String ad;
  final DersGrubu grup;
}

class Ders {
  const Ders({required this.id, required this.ad, required this.grup});

  final int id;
  final String ad;
  final DersGrubu grup;

  Ders kopya({String? ad}) => Ders(id: id, ad: ad ?? this.ad, grup: grup);

  Map<String, Object?> toJson() => {'id': id, 'ad': ad, 'grup': grup.name};

  static Ders? fromJson(Object? veri) {
    if (veri is! Map<String, dynamic>) return null;
    final id = veri['id'];
    final ad = veri['ad'];
    final grupAdi = veri['grup'];
    if (id is! int || ad is! String || ad.isEmpty) return null;
    for (final g in DersGrubu.values) {
      if (g.name == grupAdi) return Ders(id: id, ad: ad, grup: g);
    }
    return null;
  }
}

class Konu {
  const Konu({
    required this.id,
    required this.dersId,
    required this.ad,
    this.not = '',
  });

  final int id;
  final int dersId;
  final String ad;

  /// Kullanıcının özel notu. Hiçbir zaman paylaşılmaz.
  final String not;

  Konu kopya({String? ad, String? not}) => Konu(
        id: id,
        dersId: dersId,
        ad: ad ?? this.ad,
        not: not ?? this.not,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'dersId': dersId,
        'ad': ad,
        'not': not,
      };

  static Konu? fromJson(Object? veri) {
    if (veri is! Map<String, dynamic>) return null;
    final id = veri['id'];
    final dersId = veri['dersId'];
    final ad = veri['ad'];
    final not = veri['not'];
    if (id is! int || dersId is! int || ad is! String || ad.isEmpty) {
      return null;
    }
    return Konu(id: id, dersId: dersId, ad: ad, not: not is String ? not : '');
  }
}
