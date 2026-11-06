# HANDOFF.md: Devir notu

Son guncelleme: 6 Kasım 2026, Sadeleştirme ve Pratik Özellikler uygulandı (dal `model2/gizleme-k1-k8`).

## Durum
Kullanıcı direktifleri doğrultusunda pazar analizi ve sadeleştirme planı aşamaları uygulandı:
- **Gizlenenler (K1-K8):**
  - Veri kaybı veya JSON şema değişikliği yapılmadan `lib/core/gizli_ozellikler.dart` üzerinden arayüzden gizlendi.
  - Günlük uyku/kaygı giriş formu ve sirkadiyen grafik gizlendi (hedef yatış saati ve kafein kesilme saati kartı sade biçimde korundu).
  - Master Kokpit ve 0-100 Bilişsel Sağlık Skoru Bugün ekranından gizlendi.
  - Vaka Kartı ve Mekanizma Zincirleri ana menüden kaldırıldı; hazır şablonlar "Defter" içindeki salt-okunur "Referans" sekmesinde korundu.
  - Blok sonu zorunlu odak puanı ve ağır analitik kutucuğu isteğe bağlı ayara bağlandı (varsayılan kapalı).
  - Sert tavan kırmızı uyarısı gizlendi.
  - Soru bazlı güven matrisi sadeleştirildi (oturum sonu genel güven dağılımı korundu).
  - Tanıtım turundaki "kanıtlı tavan" ifadesi "referans tavan" olarak yumuşatıldı.
- **Sadeleştirmeler (S2, S3, S5, S6, S8, S9, S14):**
  - Bugün ekranı: "SIRADAKİ GÖREV" kartı eklendi, karmaşa temizlendi.
  - Tekrar satırları: 3 hızlı işlem butonu eklendi (`✅ Hatırladım`, `😐 Zorlandım`, `➡️ Yarına ertele`).
  - Hata kodları 3 ana gruba uyarlandı (Bilgi / Yanlış biliyordum / Dikkat-Süre).
  - İlerleme ekranına Master Kokpit yerine sade "Haftalık Özet" kartı konuldu.
  - Zor Gün Modu: Tek dokunuşla "Bugün nöbetteyim / Yoğun gün" modu açılıp kapanabilir hale getirildi (tekrar yükünü %70'e çeker).
  - Günlük Limit: 4 yeni konu + 10 tekrar sınırı getirildi (ayarlardan değiştirilebilir; gün dolduğunda uyarır).
- **Yeni Eklenenler (E2, E3, E5, E7):**
  - E2: Bugün ekranından tek dokunuşla 25 dk odak sayacı başlatma (sıradaki konuya/tekrara doğrudan bağlanır).
  - E3: İlerleme ekranından WhatsApp'a tek tıkla yapıştırılabilir formatlı haftalık çalışma özeti kopyalama.
  - E5: Geciken tekrarları affetme ve bugünden itibaren takvime yeniden dağıtma butonu.
  - E7: Bugün ekranında hızlı soru sayacı `[-] [X Soru] [+] [+20]` (kalıcı ve pratik).
- **Testler:**
  - `test/plan_deposu_test.dart` ve `test/widget_test.dart` güncellendi, yeni özelliklerin testleri eklendi.

## Siradaki adim
- `git add` ve `git commit` yapılarak GitHub'a pushlanacak.
- GitHub Actions CI (APK derleme ve Web testleri) doğrulanacak.
- Kullanıcı onayına göre Sürüm 2 (Firebase arkadas grubu, canlı çalışma şeridi, haftalık grup sıralaması/ortak hedef) aşamasına geçilecek.

## Bilinen sorunlar / riskler
- Bildirim sorunu (sayaç bitişinde sistem bildirimi) kullanıcının talebiyle kapsam dışı bırakılmıştır.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
