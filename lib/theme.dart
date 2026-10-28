import 'package:flutter/material.dart';

// the website's purples (src/styles.scss) plus a gold for TechCoins
const purple = Color(0xFF49005E);
const violet = Color(0xFF7C4DFF);
const pink = Color(0xFFFF4FA3);
const lilac = Color(0xFFF0E8F7);
const gold = Color(0xFFFFB300);
const mint = Color(0xFF26C6A6);
const sky = Color(0xFF29B6F6);
// the website's dark mode: page background and text
const night = Color(0xFF1B1022);
const nightText = Color(0xFFE8D7F3);

const funGradient = LinearGradient(colors: [violet, pink], begin: Alignment.topLeft, end: Alignment.bottomRight);

bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

// a card on the page: white by day, a lifted purple at night
Color cardColor(BuildContext context) => isDark(context) ? const Color(0xFF2A1E36) : Colors.white;

// a quiet box inside a card
Color softColor(BuildContext context) => isDark(context) ? const Color(0xFF362945) : lilac;

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final text = dark ? nightText : purple;
  final base = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: brightness, surface: dark ? night : lilac),
    scaffoldBackgroundColor: dark ? night : lilac,
    // Ubuntu has no Armenian letters; those fall back to Yerevanyan like on the website
    fontFamily: 'Ubuntu',
    fontFamilyFallback: const ['Yerevanyan'],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF2A1E36) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    ),
  );
  // recolour the theme's own text, which already carries the fonts
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
  );
}
