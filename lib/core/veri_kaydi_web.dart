// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web (tarayıcı) ortamında veriyi localStorage içine yazar ve oradan okur.
String? webDepoOku([String anahtar = 'mytus_data.json']) {
  try {
    return html.window.localStorage[anahtar];
  } catch (_) {
    return null;
  }
}

void webDepoYaz(String icerik, [String anahtar = 'mytus_data.json']) {
  try {
    html.window.localStorage[anahtar] = icerik;
  } catch (_) {}
}

void webDepoSil([String anahtar = 'mytus_data.json']) {
  try {
    html.window.localStorage.remove(anahtar);
  } catch (_) {}
}
