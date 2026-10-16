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

const List<String> _gunAdlari = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Takvim başlığı için kısa gün adları (hafta Pazartesi ile başlar).
const List<String> haftaGunleriKisa = [
  'Pzt',
  'Sal',
  'Çar',
  'Per',
  'Cum',
  'Cmt',
  'Paz',
];

/// 1-12 arası ay numarasının adı.
String ayAdi(int ay) => _ayAdlari[ay - 1];

/// Örnek: "16 Ekim 2026".
String tarihYaz(DateTime t) => '${t.day} ${_ayAdlari[t.month - 1]} ${t.year}';

/// Örnek: "16 Ekim".
String tarihKisa(DateTime t) => '${t.day} ${_ayAdlari[t.month - 1]}';

/// Örnek: "Cuma, 16 Ekim".
String gunAdiIleTarih(DateTime t) =>
    '${_gunAdlari[t.weekday - 1]}, ${tarihKisa(t)}';

/// Saat bilgisini atar, yalnızca günü bırakır.
DateTime gunBasi(DateTime t) => DateTime(t.year, t.month, t.day);

/// [gun] kadar sonraki (negatifse önceki) gün.
DateTime gunEkle(DateTime t, int gun) => DateTime(t.year, t.month, t.day + gun);

bool ayniGun(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Gün için sayısal anahtar (karşılaştırma ve eşleme için): 20261016.
int gunAnahtari(DateTime t) => t.year * 10000 + t.month * 100 + t.day;

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
