/// Tarih yardımcıları. Ek paket kullanmadan Türkçe ay adlarıyla çalışır.
const List<String> _ayAdlari = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

/// Örnek: "16 Ekim 2026".
String tarihYaz(DateTime t) => '${t.day} ${_ayAdlari[t.month - 1]} ${t.year}';

/// Kayıt için gün anahtarı: "2026-10-16".
String tarihAnahtari(DateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final a = t.month.toString().padLeft(2, '0');
  final g = t.day.toString().padLeft(2, '0');
  return '$y-$a-$g';
}

/// "2026-10-16" metnini gün olarak okur. Geçersizse null döner.
DateTime? tarihCoz(String? metin) {
  if (metin == null) return null;
  final parcalar = metin.split('-');
  if (parcalar.length != 3) return null;
  final y = int.tryParse(parcalar[0]);
  final a = int.tryParse(parcalar[1]);
  final g = int.tryParse(parcalar[2]);
  if (y == null || a == null || g == null) return null;
  final t = DateTime(y, a, g);
  // 31 Şubat gibi tarihler ertesi aya kayar; bunları geçersiz say.
  if (t.year != y || t.month != a || t.day != g) return null;
  return t;
}

/// İki gün arasındaki tam gün sayısı (saatler yok sayılır). sonra - once.
int gunFarki(DateTime sonra, DateTime once) {
  final s = DateTime.utc(sonra.year, sonra.month, sonra.day);
  final o = DateTime.utc(once.year, once.month, once.day);
  return s.difference(o).inDays;
}
