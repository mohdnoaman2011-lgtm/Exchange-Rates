import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Pal {
  final Color bg, card, border, ink, muted, tile, tileText, divider, navBg, navInactive, navInk;
  const Pal({
    required this.bg, required this.card, required this.border, required this.ink,
    required this.muted, required this.tile, required this.tileText, required this.divider,
    required this.navBg, required this.navInactive, required this.navInk,
  });

  static const coral = Color(0xFFFF7A59);

  static const dark = Pal(
    bg: Color(0xFF14102B), card: Color(0xFF1F1A3D), border: Color(0xFF33295E),
    ink: Color(0xFFF5F3FF), muted: Color(0xFFB4AEDB), tile: Color(0xFF2A2250),
    tileText: Color(0xFFFF7A59), divider: Color(0xFF2C2452), navBg: Color(0xFF1F1A3D),
    navInactive: Color(0xFFC9C4EE), navInk: Color(0xFF14102B),
  );

  static const light = Pal(
    bg: Color(0xFFF6F3FF), card: Colors.white, border: Color(0xFFE3DDF7),
    ink: Color(0xFF1B1438), muted: Color(0xFF5E5780), tile: Color(0xFFF1ECFF),
    tileText: Color(0xFFC23B16), divider: Color(0xFFEEE9FB), navBg: Color(0xFF1B1438),
    navInactive: Color(0xFFD8D2F2), navInk: Color(0xFF1B1438),
  );

  static Pal of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Pal.dark : Pal.light;
  final base = ThemeData(brightness: b, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: Pal.coral, brightness: b),
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
        .apply(bodyColor: p.ink, displayColor: p.ink),
  );
}
