import 'package:app/features/dersler/modeller.dart';

/// Karşılama ekranındaki hazır ders listesi (kullanıcı onaylı + Rapor Bölüm 2.4).
const List<HazirDers> hazirDersler = [
  HazirDers('Anatomi', DersGrubu.temel),
  HazirDers('Histoloji ve Embriyoloji', DersGrubu.temel),
  HazirDers('Fizyoloji', DersGrubu.temel),
  HazirDers('Biyokimya', DersGrubu.temel),
  HazirDers('Mikrobiyoloji', DersGrubu.temel),
  HazirDers('Patoloji', DersGrubu.temel),
  HazirDers('Farmakoloji', DersGrubu.temel),
  HazirDers('Dahiliye', DersGrubu.klinik),
  HazirDers('Pediatri', DersGrubu.klinik),
  HazirDers('Genel Cerrahi', DersGrubu.klinik),
  HazirDers('Küçük Stajlar', DersGrubu.klinik),
  HazirDers('Kadın Hastalıkları ve Doğum', DersGrubu.klinik),
];
