import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Bulut veri tabanı (Firestore) işlemlerini soyutlayan arayüz.
/// Gerçek uygulamada [FirestoreBulutKaynagi], testlerde [SahteBulutKaynagi] kullanılır.
abstract class BulutKaynagi {
  /// Kullanıcının profil belgesini (`kullanicilar/{uid}`) kaydeder/günceller.
  Future<void> profilKaydet({
    required String uid,
    required String eposta,
    String? takmaAd,
  });

  /// Kullanıcının tüm bölüm belgelerini (`kullanicilar/{uid}/bolumler/{bolumId}`) okur.
  Future<Map<String, String>> bolumleriOku(String uid);

  /// Yalnızca değişen bölümleri buluta yazar.
  Future<void> bolumleriYaz({
    required String uid,
    required Map<String, String> degisenBolumler,
    required String cihazId,
  });

  /// Başka cihazlardan gelen değişiklikleri gerçek zamanlı dinler.
  Stream<({Map<String, String> bolumler, String? sonCihazId})> bolumleriDinle(
    String uid,
  );

  /// Kullanıcının buluttaki tüm bölümlerini ve profil belgesini siler (KVKK uyumu).
  Future<void> kullaniciVerileriniSil(String uid);
}

/// Cloud Firestore tabanlı gerçek bulut kaynağı.
class FirestoreBulutKaynagi implements BulutKaynagi {
  FirestoreBulutKaynagi({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _kullaniciRef(String uid) =>
      _db.collection('kullanicilar').doc(uid);

  CollectionReference<Map<String, dynamic>> _bolumlerRef(String uid) =>
      _kullaniciRef(uid).collection('bolumler');

  @override
  Future<void> profilKaydet({
    required String uid,
    required String eposta,
    String? takmaAd,
  }) async {
    final simdi = DateTime.now().toIso8601String();
    final veri = <String, dynamic>{
      'eposta': eposta,
      'guncellemeZamani': simdi,
      'kvkkOnayTarihi': simdi,
      if (takmaAd != null && takmaAd.trim().isNotEmpty)
        'takmaAd': takmaAd.trim(),
    };
    await _kullaniciRef(uid).set(veri, SetOptions(merge: true));
  }

  @override
  Future<Map<String, String>> bolumleriOku(String uid) async {
    final snap = await _bolumlerRef(uid).get();
    final sonuc = <String, String>{};
    for (final doc in snap.docs) {
      final veri = doc.data()['veri'];
      if (veri is String && veri.isNotEmpty) {
        sonuc[doc.id] = veri;
      }
    }
    return sonuc;
  }

  @override
  Future<void> bolumleriYaz({
    required String uid,
    required Map<String, String> degisenBolumler,
    required String cihazId,
  }) async {
    if (degisenBolumler.isEmpty) return;
    final batch = _db.batch();
    final simdi = DateTime.now().toIso8601String();
    for (final entry in degisenBolumler.entries) {
      final docRef = _bolumlerRef(uid).doc(entry.key);
      batch.set(docRef, {
        'veri': entry.value,
        'guncellemeZamani': simdi,
        'surum': 1,
        'cihazId': cihazId,
      });
    }
    await batch.commit();
  }

  @override
  Stream<({Map<String, String> bolumler, String? sonCihazId})> bolumleriDinle(
    String uid,
  ) {
    return _bolumlerRef(uid).snapshots().map((snap) {
      final sonuc = <String, String>{};
      String? sonCihaz;
      for (final doc in snap.docs) {
        final data = doc.data();
        final veri = data['veri'];
        if (veri is String && veri.isNotEmpty) {
          sonuc[doc.id] = veri;
        }
        final cihaz = data['cihazId'];
        if (cihaz is String) {
          sonCihaz = cihaz;
        }
      }
      return (bolumler: sonuc, sonCihazId: sonCihaz);
    });
  }

  @override
  Future<void> kullaniciVerileriniSil(String uid) async {
    final snap = await _bolumlerRef(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_kullaniciRef(uid));
    await batch.commit();
  }
}

/// Birim ve widget testleri için bellekte çalışan sahte bulut kaynağı.
class SahteBulutKaynagi implements BulutKaynagi {
  final Map<String, Map<String, String>> kullaniciBolumleri = {};
  final Map<String, Map<String, String?>> profiller = {};
  final Map<String, StreamController<({Map<String, String> bolumler, String? sonCihazId})>>
      _yayinlar = {};

  bool cevrimdisi = false;
  int yazmaSayisi = 0;

  StreamController<({Map<String, String> bolumler, String? sonCihazId})>
      _kanal(String uid) {
    return _yayinlar.putIfAbsent(
      uid,
      () => StreamController<
          ({Map<String, String> bolumler, String? sonCihazId})>.broadcast(),
    );
  }

  @override
  Future<void> profilKaydet({
    required String uid,
    required String eposta,
    String? takmaAd,
  }) async {
    if (cevrimdisi) throw StateError('Çevrimdışı');
    profiller[uid] = {'eposta': eposta, 'takmaAd': takmaAd};
  }

  @override
  Future<Map<String, String>> bolumleriOku(String uid) async {
    if (cevrimdisi) throw StateError('Çevrimdışı');
    return Map<String, String>.from(kullaniciBolumleri[uid] ?? const {});
  }

  @override
  Future<void> bolumleriYaz({
    required String uid,
    required Map<String, String> degisenBolumler,
    required String cihazId,
  }) async {
    if (cevrimdisi) throw StateError('Çevrimdışı');
    final mevcut = kullaniciBolumleri.putIfAbsent(uid, () => {});
    mevcut.addAll(degisenBolumler);
    yazmaSayisi++;
    _kanal(uid).add((
      bolumler: Map<String, String>.from(mevcut),
      sonCihazId: cihazId,
    ));
  }

  /// Başka bir cihazdan buluta veri yazılmasını simüle eder.
  void uzaktanDegisiklikSimuleEt({
    required String uid,
    required Map<String, String> bolumler,
    String cihazId = 'baska_cihaz',
  }) {
    final mevcut = kullaniciBolumleri.putIfAbsent(uid, () => {});
    mevcut.addAll(bolumler);
    _kanal(uid).add((
      bolumler: Map<String, String>.from(mevcut),
      sonCihazId: cihazId,
    ));
  }

  @override
  Stream<({Map<String, String> bolumler, String? sonCihazId})> bolumleriDinle(
    String uid,
  ) {
    return _kanal(uid).stream;
  }

  @override
  Future<void> kullaniciVerileriniSil(String uid) async {
    if (cevrimdisi) throw StateError('Çevrimdışı');
    kullaniciBolumleri.remove(uid);
    profiller.remove(uid);
  }

  void kapat() {
    for (final c in _yayinlar.values) {
      c.close();
    }
    _yayinlar.clear();
  }
}
