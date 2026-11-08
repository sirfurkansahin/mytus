# HANDOFF.md: Devir notu

Son guncelleme: 8 Kasım 2026, Seçenek 1: Çalışma Grubu ve Haftalık Puan Tablosu (Sürüm 2) tamamlandı (dal `claude/calisma-grubu-puan`).

## Durum
Kullanıcının "Seçenek 1 (Çalışma Grubu ve Haftalık Puan Tablosu)" ve "Seçenek C (1 Soru = 1 Puan, 1 Konu = 10 Puan)" tercihi doğrultusunda geliştirme tamamlandı:

1. **Veri Modelleri (`lib/features/grup/modeller.dart`):**
   - `Grup`: Grup adı, 6 karakterlik davet kodu, kurucu UID'si, ortak konu ve soru hedefleri.
   - `GrupUyesi`: Üye UID, takma ad, hafta başlangıcı (Pazartesi), konu sayısı, soru sayısı, toplam puan ((konu * 10) + soru), son ders ve güncelleme tarihi.
   - `GrupHedefDurumu`: Ortak hedef yüzdesi ve ilerleme oranları.
   - `davetKoduUret()`: O, 0, I, 1 gibi karışıklık yaratan karakterlerden arındırılmış 6 haneli rastgele kod üretimi.

2. **Servis Mimarisi (`lib/features/grup/grup_servisi.dart`):**
   - `GrupServisi` soyut arayüzü.
   - Bellekte ve testlerde çalışan `SahteGrupServisi`.
   - Gerçek zamanlı Firestore akışlarını (`snapshots()`) ve batch işlemlerini yöneten `FirestoreGrupServisi`.

3. **Plan ve Puan Entegrasyonu (`lib/features/dersler/plan_deposu.dart`):**
   - `haftalikTamamlananKonuSayisi(gun)`
   - `haftalikCozulenSoruSayisi(gun)`
   - `haftalikGrupPuani(gun)`: `(tamamlananKonu * 10) + cozulenSoru`
   - `aktifGrupId` ve `aktifGrupAyarla(grupId)`: Kullanıcının yerel planında ve ayarlarında aktif grup ID'si tutulur.

4. **Kullanıcı Arayüzü (`lib/features/grup/grup_ekrani.dart`):**
   - Boş Durum: 6 haneli kodla mevcut bir gruba katılma veya hedef konu/soru belirleyerek yeni grup oluşturma.
   - Aktif Grup Durumu: Grup adı, davet kodu panoya kopyalama/paylaşma, 2-10 kişilik haftalık sıralama (altın, gümüş, bronz madalyalar, puan rozetleri) ve ortak hedef modu (kümülatif ilerleme çubuğu).
   - Menüden gruptan ayrılma onayı.

5. **Gezinme Bağlantıları:**
   - `BugunEkrani`: Üst aksiyon satırına `Çalışma Grubu & Puan` simge butonu eklendi.
   - `AyarlarEkrani`: `ÇALIŞMA GRUBU` başlığı altında durum kartı eklendi.

6. **Cloud Firestore Güvenlik Kuralları (`firestore.rules`):**
   - `firestore-rules-author` uzman alt ajanı tarafından oluşturuldu.
   - `gruplar/{grupId}`, `gruplar/{grupId}/uyeler/{uid}`, `davetKodlari/{kod}` yolları korundu.
   - Kişisel notlar gizli tutuldu; `firebase-tools deploy --dry-run` başarıyla test edildi.

7. **Testler (`test/grup_test.dart`):**
   - Model, kod üretimi, SahteGrupServisi akış, PlanDeposu haftalık puan hesabı ve GrupEkrani widget testleri yazıldı.

## Siradaki adim
- GitHub Actions CI derlemesi ve testlerinin izlenmesi.
- Başarılı derleme sonrası ana dala (`main`) birleştirme veya kullanıcı incelemesi.

## Bilinen sorunlar / riskler
- Yok. Firebase Spark ücretsiz plan sınırlarına (Cloud Functions/Storage kullanılmadan istemci taraflı hesap) %100 uyumludur.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
