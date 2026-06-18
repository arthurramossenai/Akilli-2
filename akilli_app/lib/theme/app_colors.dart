import 'package:flutter/material.dart';

/// Paleta de cores Akilli — extraída da PALETA.png
class AppColors {
  AppColors._();

  // ─── Cores Primárias ───────────────────────────────────────────────
  /// Café Noir – #4C3D19
  static const Color cafeNoir = Color(0xFF4C3D19);

  /// Kombu Green (escuro principal) – #354024
  static const Color kombuGreen = Color(0xFF354024);

  /// Moss Green – #889063
  static const Color mossGreen = Color(0xFF889063);

  /// Tan (bege quente) – #CFBB99
  static const Color tan = Color(0xFFCFBB99);

  /// Bone (bege claro) – #E5D7C4
  static const Color bone = Color(0xFFE5D7C4);

  // ─── Derivadas / Utilitárias ──────────────────────────────────────
  /// Fundo escuro (baseado no Kombu Green ligeiramente ajustado)
  static const Color darkBackground = Color(0xFF3A3F27);

  /// Texto claro sobre fundo escuro
  static const Color lightText = Color(0xFFE5D7C4);

  /// Texto escuro sobre fundo claro
  static const Color darkText = Color(0xFF354024);

  /// Divider / underline dos campos
  static const Color fieldDivider = Color(0xFF6B7050);

  /// Toggle ativo (pílula selecionada)
  static const Color toggleActive = Color(0xFFCFBB99);

  /// Toggle inativo (pílula não selecionada)
  static const Color toggleInactive = Color(0xFF5A5F3E);

  /// Cor do botão principal
  static const Color buttonBackground = Color(0xFFCFBB99);

  /// Cor do texto do botão principal
  static const Color buttonText = Color(0xFF354024);

  /// Cor do switch track quando ativo
  static const Color switchActiveTrack = Color(0xFFCFBB99);

  /// Cor do switch track quando inativo
  static const Color switchInactiveTrack = Color(0xFF6B7050);

  /// Cor do logo (stroke do SVG)
  static const Color logoColor = Color(0xFF364025);
}
