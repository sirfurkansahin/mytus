// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web (tarayıcı) ortamında veriyi localStorage içine yazar ve oradan okur.
String? webDepoOku() {
  try {
    return html.window.localStorage['mytus_data.json'];
  } catch (_) {
    return null;
  }
}

void webDepoYaz(String icerik) {
  try {
    html.window.localStorage['mytus_data.json'] = icerik;
  } catch (_) {}
}
