import 'dart:async';

import 'package:app/core/tarih.dart';
import 'package:app/features/grup/modeller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Grup veri yönetim servisi soyut arayüzü.
abstract class GrupServisi {
  /// Yeni bir çalışma grubu kurar, davet kodu üretir ve kurucuyu ilk üye yapar.
  Future<Grup> grupOlustur({
    required String grupAdi,
    required String olusturanUid,
    required String takmaAd,
    int hedefKonu = 40,
    int hedefSoru = 1000,
  });

  /// 6 haneli davet kodundan grubu bulur.
  Future<Grup?> kodIleGrupBul(String davetKodu);

  /// Kullanıcıyı gruba ekler.
  Future<void> grubaKatil({
    required String grupId,
    required String uid,
    required String takmaAd,
    int konuSayisi = 0,
    int soruSayisi = 0,
    String? sonDers,
  });

  /// Kullanıcıyı gruptan çıkarır.
  Future<void> gruptanAyril({
    required String grupId,
    required String uid,
  });

  /// Kullanıcının haftalık puan ve çalışma durumunu günceller.
  Future<void> puanGuncelle({
    required String grupId,
    required String uid,
    required String takmaAd,
    required int konuSayisi,
    required int soruSayisi,
    String? sonDers,
    DateTime? tarih,
  });

  /// Grubu tek seferlik okur.
  Future<Grup?> grupGetir(String grupId);

  /// Gruptaki üyeleri puana göre çoktan aza sıralı okur.
  Future<List<GrupUyesi>> uyeleriGetir(String grupId);

  /// Grubu canlı dinler.
  Stream<Grup?> grupDinle(String grupId);

  /// Grup üyelerini ve puan tablosunu canlı dinler (puana göre sıralı).
  Stream<List<GrupUyesi>> uyeleriDinle(String grupId);
}

/// Testler ve çevrimdışı kullanım için bellek içi Sahte Grup Servisi.
class SahteGrupServisi implements GrupServisi {
  final Map<String, Grup> _gruplar = {};
  final Map<String, String> _kodlar = {}; // davetKodu -> grupId
  final Map<String, Map<String, GrupUyesi>> _uyeler = {}; // grupId -> {uid: GrupUyesi}

  final Map<String, StreamController<Grup?>> _grupYayincilari = {};
  final Map<String, StreamController<List<GrupUyesi>>> _uyeYayincilari = {};

  StreamController<Grup?> _grupYayinci(String grupId) =>
      _grupYayincilari.putIfAbsent(grupId, () => StreamController<Grup?>.broadcast());

  StreamController<List<GrupUyesi>> _uyeYayinci(String grupId) =>
      _uyeYayincilari.putIfAbsent(grupId, () => StreamController<List<GrupUyesi>>.broadcast());

  void _yay(String grupId) {
    if (_grupYayincilari.containsKey(grupId)) {
      _grupYayincilari[grupId]!.add(_gruplar[grupId]);
    }
    if (_uyeYayincilari.containsKey(grupId)) {
      final liste = _siraliUyeler(grupId);
      _uyeYayincilari[grupId]!.add(liste);
    }
  }

  List<GrupUyesi> _siraliUyeler(String grupId) {
    final harita = _uyeler[grupId] ?? {};
    final liste = harita.values.toList()
      ..sort((a, b) => b.puan.compareTo(a.puan));
    return liste;
  }

  @override
  Future<Grup> grupOlustur({
    required String grupAdi,
    required String olusturanUid,
    required String takmaAd,
    int hedefKonu = 40,
    int hedefSoru = 1000,
  }) async {
    final grupId = 'grup_${DateTime.now().microsecondsSinceEpoch}';
    final kod = davetKoduUret();
    final grup = Grup(
      id: grupId,
      ad: grupAdi.trim(),
      davetKodu: kod,
      olusturanUid: olusturanUid,
      olusturmaTarihi: DateTime.now(),
      hedefKonu: hedefKonu,
      hedefSoru: hedefSoru,
    );

    _gruplar[grupId] = grup;
    _kodlar[kod] = grupId;

    final simdi = DateTime.now();
    final usta = GrupUyesi(
      uid: olusturanUid,
      takmaAd: takmaAd.trim(),
      haftaBaslangici: tarihAnahtari(haftaBasi(simdi)),
      guncellemeTarihi: simdi,
    );
    _uyeler[grupId] = {olusturanUid: usta};

    _yay(grupId);
    return grup;
  }

  @override
  Future<Grup?> kodIleGrupBul(String davetKodu) async {
    final temizKod = davetKodu.trim().toUpperCase();
    final grupId = _kodlar[temizKod];
    if (grupId == null) return null;
    return _gruplar[grupId];
  }

  @override
  Future<void> grubaKatil({
    required String grupId,
    required String uid,
    required String takmaAd,
    int konuSayisi = 0,
    int soruSayisi = 0,
    String? sonDers,
  }) async {
    final grup = _gruplar[grupId];
    if (grup == null) throw StateError('Grup bulunamadı.');

    final simdi = DateTime.now();
    final uye = GrupUyesi(
      uid: uid,
      takmaAd: takmaAd.trim(),
      haftaBaslangici: tarihAnahtari(haftaBasi(simdi)),
      konuSayisi: konuSayisi,
      soruSayisi: soruSayisi,
      sonDers: sonDers,
      guncellemeTarihi: simdi,
    );

    final harita = _uyeler.putIfAbsent(grupId, () => {});
    harita[uid] = uye;
    _yay(grupId);
  }

  @override
  Future<void> gruptanAyril({
    required String grupId,
    required String uid,
  }) async {
    final harita = _uyeler[grupId];
    if (harita != null) {
      harita.remove(uid);
      _yay(grupId);
    }
  }

  @override
  Future<void> puanGuncelle({
    required String grupId,
    required String uid,
    required String takmaAd,
    required int konuSayisi,
    required int soruSayisi,
    String? sonDers,
    DateTime? tarih,
  }) async {
    final harita = _uyeler[grupId];
    if (harita == null) return;
    final simdi = tarih ?? DateTime.now();
    final uye = GrupUyesi(
      uid: uid,
      takmaAd: takmaAd.trim(),
      haftaBaslangici: tarihAnahtari(haftaBasi(simdi)),
      konuSayisi: konuSayisi,
      soruSayisi: soruSayisi,
      sonDers: sonDers,
      guncellemeTarihi: simdi,
    );
    harita[uid] = uye;
    _yay(grupId);
  }

  @override
  Future<Grup?> grupGetir(String grupId) async => _gruplar[grupId];

  @override
  Future<List<GrupUyesi>> uyeleriGetir(String grupId) async => _siraliUyeler(grupId);

  @override
  Stream<Grup?> grupDinle(String grupId) {
    final c = _grupYayinci(grupId);
    Timer.run(() => c.add(_gruplar[grupId]));
    return c.stream;
  }

  @override
  Stream<List<GrupUyesi>> uyeleriDinle(String grupId) {
    final c = _uyeYayinci(grupId);
    Timer.run(() => c.add(_siraliUyeler(grupId)));
    return c.stream;
  }
}

/// Cloud Firestore tabanlı gerçek grup servisi.
class FirestoreGrupServisi implements GrupServisi {
  FirestoreGrupServisi({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _gruplarRef =>
      _db.collection('gruplar');

  CollectionReference<Map<String, dynamic>> get _kodlarRef =>
      _db.collection('davetKodlari');

  DocumentReference<Map<String, dynamic>> _grupDoc(String grupId) =>
      _gruplarRef.doc(grupId);

  CollectionReference<Map<String, dynamic>> _uyelerRef(String grupId) =>
      _grupDoc(grupId).collection('uyeler');

  @override
  Future<Grup> grupOlustur({
    required String grupAdi,
    required String olusturanUid,
    required String takmaAd,
    int hedefKonu = 40,
    int hedefSoru = 1000,
  }) async {
    final grupDoc = _gruplarRef.doc();
    final grupId = grupDoc.id;
    final kod = davetKoduUret();
    final simdi = DateTime.now();

    final grup = Grup(
      id: grupId,
      ad: grupAdi.trim(),
      davetKodu: kod,
      olusturanUid: olusturanUid,
      olusturmaTarihi: simdi,
      hedefKonu: hedefKonu,
      hedefSoru: hedefSoru,
    );

    final batch = _db.batch();

    // 1. Grubu kaydet
    batch.set(grupDoc, grup.toJson());

    // 2. Davet kodunu eşle
    final kodDoc = _kodlarRef.doc(kod);
    batch.set(kodDoc, {
      'grupId': grupId,
      'grupAdi': grup.ad,
      'olusturanUid': olusturanUid,
      'olusturmaTarihi': simdi.toIso8601String(),
    });

    // 3. Kurucuyu üye yap
    final kurucuUye = GrupUyesi(
      uid: olusturanUid,
      takmaAd: takmaAd.trim(),
      haftaBaslangici: tarihAnahtari(haftaBasi(simdi)),
      guncellemeTarihi: simdi,
    );
    batch.set(_uyelerRef(grupId).doc(olusturanUid), kurucuUye.toJson());

    await batch.commit();
    return grup;
  }

  @override
  Future<Grup?> kodIleGrupBul(String davetKodu) async {
    final temizKod = davetKodu.trim().toUpperCase();
    final doc = await _kodlarRef.doc(temizKod).get();
    if (!doc.exists) return null;
    final data = doc.data();
    final grupId = data?['grupId'] as String?;
    if (grupId == null) return null;
    return grupGetir(grupId);
  }

  @override
  Future<void> grubaKatil({
    required String grupId,
    required String uid,
    required String takmaAd,
    int konuSayisi = 0,
    int soruSayisi = 0,
    String? sonDers,
  }) async {
    final simdi = DateTime.now();
    final uye = GrupUyesi(
      uid: uid,
      takmaAd: takmaAd.trim(),
      haftaBaslangici: tarihAnahtari(haftaBasi(simdi)),
      konuSayisi: konuSayisi,
      soruSayisi: soruSayisi,
      sonDers: sonDers,
      guncellemeTarihi: simdi,
    );
    await _uyelerRef(grupId).doc(uid).set(uye.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> gruptanAyril({
    required String grupId,
    required String uid,
  }) async {
    await _uyelerRef(grupId).doc(uid).delete();
  }

  @override
  Future<void> puanGuncelle({
    required String grupId,
    required String uid,
    required String takmaAd,
    required int konuSayisi,
    required int soruSayisi,
    String? sonDers,
    DateTime? tarih,
  }) async {
    final simdi = tarih ?? DateTime.now();
    final uye = GrupUyesi(
      uid: uid,
      takmaAd: takmaAd.trim(),
      haftaBaslangici: tarihAnahtari(haftaBasi(simdi)),
      konuSayisi: konuSayisi,
      soruSayisi: soruSayisi,
      sonDers: sonDers,
      guncellemeTarihi: simdi,
    );
    await _uyelerRef(grupId).doc(uid).set(uye.toJson(), SetOptions(merge: true));
  }

  @override
  Future<Grup?> grupGetir(String grupId) async {
    final doc = await _grupDoc(grupId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Grup.fromJson(doc.data()!, docId: doc.id);
  }

  @override
  Future<List<GrupUyesi>> uyeleriGetir(String grupId) async {
    final snap = await _uyelerRef(grupId).get();
    final liste = snap.docs
        .map((d) => GrupUyesi.fromJson(d.data(), docId: d.id))
        .toList()
      ..sort((a, b) => b.puan.compareTo(a.puan));
    return liste;
  }

  @override
  Stream<Grup?> grupDinle(String grupId) {
    return _grupDoc(grupId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Grup.fromJson(doc.data()!, docId: doc.id);
    });
  }

  @override
  Stream<List<GrupUyesi>> uyeleriDinle(String grupId) {
    return _uyelerRef(grupId).snapshots().map((snap) {
      final liste = snap.docs
          .map((d) => GrupUyesi.fromJson(d.data(), docId: d.id))
          .toList()
        ..sort((a, b) => b.puan.compareTo(a.puan));
      return liste;
    });
  }
}
