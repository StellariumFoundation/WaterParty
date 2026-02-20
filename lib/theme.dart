import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class AppColors {
  // --- Stellarium Palette ---
  static const Color deepBlack = Color(0xFF000000);
  static const Color stellariumPurple = Color(0xFF1A0B2E);
  static const Color deepForest = Color(0xFF001A00); 
  
  static const Color textPink = Color(0xFFD18BFF);
  static const Color textCyan = Color(0xFF00E5FF);
  static const Color gold = Color(0xFFFFD700);
  static const Color electricPurple = Color(0xFF7C3AED);

  // --- Aliases ---
  static const Color neonBlue = textCyan; 
  static const String fontFamily = 'Frutiger'; // Custom Font Family

  // --- Main Background Gradient ---
  static const LinearGradient stellariumGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepBlack, stellariumPurple, deepForest],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient oceanGradient = stellariumGradient;

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFDB931), Color(0xFFFFD700), Color(0xFFFDB931)],
  );
}

// --- Premium Typography Styles ---
class AppTypography {
  static const String fontFamily = 'Frutiger';

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get titleStyle => title;
  static TextStyle get mediumStyle => medium;
  static TextStyle get smallStyle => small;

  static TextTheme get textTheme => TextTheme(
        displayLarge: title.copyWith(fontSize: 32),
        displayMedium: title,
        titleLarge: title,
        bodyLarge: medium,
        bodyMedium: medium,
        bodySmall: small,
      );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.electricPurple,
      scaffoldBackgroundColor: AppColors.deepBlack,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricPurple,
        secondary: AppColors.textCyan,
        surface: AppColors.stellariumPurple,
        background: AppColors.deepBlack,
      ),
    );
  }
}

class WaterGlass extends StatelessWidget {
  final Widget child;
  final double height;
  final double? width;
  final double borderRadius;
  final double blur;
  final double border; 
  final Color? borderColor;

  const WaterGlass({
    super.key, 
    required this.child, 
    this.height = 100, 
    this.width,
    this.borderRadius = 20, 
    this.blur = 15,
    this.border = 1.5, 
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width ?? MediaQuery.of(context).size.width,
      height: height,
      borderRadius: borderRadius,
      blur: blur,
      alignment: Alignment.center,
      border: border, 
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (borderColor ?? Colors.white).withOpacity(0.2),
          Colors.transparent,
        ],
      ),
      child: child,
    );
  }
}