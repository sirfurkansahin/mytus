# HANDOFF.md: Devir notu

Son guncelleme: 16 Ekim 2026 (Claude)

## Durum
- Faz 2 (kurulum) devam ediyor.
- Depoda: bos Flutter uygulamasi (`lib/main.dart`, `test/widget_test.dart`), `pubspec.yaml`, GitHub Actions akislari, bu belgeler.
- `android/` klasoru HENUZ YOK. Sebep: bulut ortaminda Flutter calistirilamiyor. `bootstrap-android.yml` akisi bunu uretip depoya yazar.

## Siradaki adim
1. `bootstrap-android.yml` main'e ilk gonderimde otomatik calisir, `android/` klasorunu uretip depoya yazar ve "APK derle" akisini baslatir. Calismazsa: GitHub > Actions > "Android klasorunu olustur" > Run workflow.
2. Akis bitince `git pull` yap, `android/app/src/main/AndroidManifest.xml` icindeki `android:label` degerini "MY TUS" yap.
3. "APK derle" akisi yesil olunca APK'yi Artifacts'tan indir, telefona kur.
4. Firebase projesini kullaniciyla birlikte olustur (Spark plani, Android uygulamasi: com.mytus.app).
5. Firebase App Distribution'a ilk APK'yi yukle.

## Bilinen sorunlar / riskler
- Kod yerelde derlenemedi. Ilk derlemede hata cikabilir (ozellikle bootstrap adimi ve paket adi com.mytus.app dogrulamasi).
- Flutter surumu sabitlenmedi (`channel: stable`). Ilk basarili derlemeden sonra surumu `build-apk.yml` icinde sabitle ve burada not et.
- Imzalama anahtari sorunu icin `DECISIONS.md` sonundaki nota bak.

## Calisma kurali
- Tek yazar: baska model calisiyorsa dokunma. Isi birakirken bu dosyayi guncelle.
