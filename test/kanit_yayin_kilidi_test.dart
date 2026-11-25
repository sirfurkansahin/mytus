// YAYIN KİLİDİ
//
// Bu dal yalnızca kanıt testleri içindir. deploy-web.yml "claude/*" dallarında
// testler geçerse siteyi yayınlar. Bu test bilerek her zaman başarısız olur;
// böylece "Testler" adımı kırmızı biter ve yayın (deploy) adımı hiç çalışmaz.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('YAYIN KİLİDİ: bu dal canlı siteye yayınlanmamalı', () {
    fail(
      'Bilerek başarısız: kanıt dalının canlı siteyi '
      '(sirfurkansahin.github.io/mytus) değiştirmesini engeller.',
    );
  });
}
