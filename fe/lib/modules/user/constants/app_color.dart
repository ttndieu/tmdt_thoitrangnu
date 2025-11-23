// lib/modules/user/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary - Tone hồng pastel nhẹ nhàng
  static const Color primary = Color(0xFFE8B4BC);
  static const Color primaryLight = Color(0xFFF5E1E4);
  static const Color primaryDark = Color(0xFFD49BA3);

  // Background
  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFBF5);

  // Text
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ✅ THÊM: Border & Divider
  static const Color border = Color(0xFFEEEEEE);        // Border mặc định - tone xám nhạt
  static const Color borderLight = Color(0xFFF5F5F5);   // Border rất nhạt
  static const Color divider = Color(0xFFE0E0E0);       // Divider line

  // Accent
  static const Color accent = Color(0xFFC9A690); // Rose gold
  static const Color accentLight = Color(0xFFE5D4C1);

  // Semantic
  static const Color success = Color(0xFF81C784);
  static const Color error = Color(0xFFE57373);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);

  // Special
  static const Color wishlistActive = Color(0xFFFF6B9D);
  static const Color badge = Color(0xFFFF5252);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8B4BC), Color(0xFFF5E1E4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFBF5), Color(0xFFFFF8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}