import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Roboto'; 
  
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );
  
  static const TextStyle productName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );
  
  static const TextStyle productPrice = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.priceGreen,
  );
  
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: AppColors.darkText,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.darkText,
  );
}