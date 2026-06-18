import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

final ThemeData akilliTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bone,
  textTheme: GoogleFonts.ralewayTextTheme().apply(
    bodyColor: AppColors.darkText,
    displayColor: AppColors.darkText,
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.kombuGreen,
    primary: AppColors.kombuGreen,
    secondary: AppColors.mossGreen,
    surface: AppColors.bone,
    onPrimary: AppColors.bone,
    onSurface: AppColors.darkText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bone,
    elevation: 0,
    iconTheme: const IconThemeData(color: AppColors.kombuGreen),
    titleTextStyle: GoogleFonts.raleway(
      color: AppColors.kombuGreen,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.tan,
      foregroundColor: AppColors.kombuGreen,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.raleway(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.kombuGreen,
      side: const BorderSide(color: AppColors.kombuGreen),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.bone,
    selectedItemColor: AppColors.kombuGreen,
    unselectedItemColor: AppColors.mossGreen.withValues(alpha: 0.6),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(AppColors.bone),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.switchActiveTrack;
      }
      return AppColors.switchInactiveTrack;
    }),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.kombuGreen,
    contentTextStyle: GoogleFonts.raleway(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
