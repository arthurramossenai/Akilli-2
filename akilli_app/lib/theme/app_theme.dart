import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData akilliTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF), // --bg
  textTheme: GoogleFonts.ralewayTextTheme().apply(
    bodyColor: const Color(0xFF0E1215), // --text
    displayColor: const Color(0xFF0E1215),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F3A36), // --brand-900
    primary: const Color(0xFF144E45), // --accent-600
    surface: const Color(0xFFE5E6E7), // --surface
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF144E45),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.raleway(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF144E45),
      side: const BorderSide(color: Color(0xFF144E45)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
);
