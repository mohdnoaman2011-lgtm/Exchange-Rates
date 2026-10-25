import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان الهوية مأخوذة من الشعار:
/// كحلي #002463 · أخضر #02AC77 · ذهبي #FEC923 · برتقالي #FE8003 · فضي #99B2DB
class Pal {
  final Color bg, card, border, ink, muted, tile, tileText, divider, navBg, navInactive, navInk;
  const Pal({
    required this.bg, required this.card, required this.border, required this.ink,
    required this.muted, required this.tile, required this.tileText, required this.divider,
    required this.navBg, required this.navInactive, required this.navInk,
  });

  static const navy = Color(0xFF002463);
  static const accent = Color(0xFF02AC77); // أخضر الشعار (اللون الأساسي)
  static const gold = Color(0xFFFEC923); // ذهبي العملة (لون ثانوي)
  static const coral = accent; // الاسم القديم، يشير الآن إلى أخضر الشعار

  static const dark = Pal(
    bg: Color(0xFF07142F), card: Color(0xFF0E2252), border: Color(0xFF1C3A78),
    ink: Color(0xFFF3F7FF), muted: Color(0xFF9FB4DC), tile: Color(0xFF12306B),
    tileText: Color(0xFF2FD39B), divider: Color(0xFF173263), navBg: Color(0xFF0E2252),
    navInactive: Color(0xFFBCCBEA), navInk: navy,
  );

  static const light = Pal(
    bg: Color(0xFFF1F5FC), card: Colors.white, border: Color(0xFFD5E0F3),
    ink: navy, muted: Color(0xFF4D6089), tile: Color(0xFFE7F0FF),
    tileText: Color(0xFF007A55), divider: Color(0xFFE3EAF7), navBg: navy,
    navInactive: Color(0xFFC5D3EF), navInk: navy,
  );

  static Pal of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Pal.dark : Pal.light;
  final base = ThemeData(brightness: b, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: Pal.accent, brightness: b),
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
        .apply(bodyColor: p.ink, displayColor: p.ink),
  );
}