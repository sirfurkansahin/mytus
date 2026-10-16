import 'package:flutter/material.dart';

/// Ana renk: mor (onaylı tasarım).
const Color morAna = Color(0xFF5B3EC8);

/// Klinik dersler yeşil tonlu gösterilir (onaylı tasarım). Açık/koyu temaya uyar.
Color klinikZemin(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B3D35)
        : const Color(0xFFDDF1EC);

Color klinikYazi(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9FE0D2)
        : const Color(0xFF0B5A4C);

/// Açık temada tasarımın ışıklı zemin rengi; koyu temada sistem rengi kullanılır.
const Color acikZemin = Color(0xFFFBFAFE);
