import 'package:flutter/material.dart';

/// Centralized color tokens for Wefaq.
abstract final class AppColors {
  // Primary brand palette
  static const green = Color(0xFF1D5E4B);
  static const greenLight = Color(0xFF28735D);
  static const dark = Color(0xFF12382E);
  static const background = Color(0xFFF8F6F0);
  static const gold = Color(0xFFB58A45);

  /// Accessible WCAG AA (>= 4.5:1) bronze-gold for text and meaningful icons
  /// on white, cream, and tinted gold containers.
  static const goldText = Color(0xFF7D591C);
  static const muted = Color(0xFF55645E);

  // Surface and container backgrounds
  static const surfaceWhite = Colors.white;
  static const surfaceTinted = Color(0xFFF1F5F2);
  static const surfaceWarm = Color(0xFFF7F2E8);
  static const cardBorder = Color(0xFFE5EAE5);
  static const chipBorder = Color(0xFFD6E0D9);

  /// Accessible 3:1 UI component boundary border for inputs, chips, and option cards.
  static const inputBorder = Color(0xFF7D8E86);
  static const progressTrack = Color(0xFFE1E8E1);
  static const tagBackground = Color(0xFFE5EFE9);
  static const iconContainerGreen = Color(0xFFE7F0EA);
  static const iconContainerGold = Color(0xFFF6ECDC);
  static const noticeBackground = Color(0xFFF5ECDD);
  static const tipBackground = Color(0xFFEFF4F0);

  // Harmonious topic palette accents (all WCAG AA >= 4.5:1 on their backgrounds)
  static const topicTeal = Color(0xFF175C61);
  static const topicTealBg = Color(0xFFE3F1F1);
  static const topicSage = Color(0xFF3E5E36);
  static const topicSageBg = Color(0xFFEAF1E6);
  static const topicBronze = Color(0xFF7D591C);
  static const topicBronzeBg = Color(0xFFF6ECDD);
  static const topicTerracotta = Color(0xFF7D4830);
  static const topicTerracottaBg = Color(0xFFF5EAE3);

  // Elevation and shadows
  static const cardShadow = Color(0x0A12382E);
  static const cardShadowDeep = Color(0x1412382E);
}
