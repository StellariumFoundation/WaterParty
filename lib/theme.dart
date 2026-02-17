import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class AppColors {
  // Stellarium Palette
  static const Color deepBlack = Color(0xFF000000);
  static const Color stellariumPurple = Color(0xFF1A0B2E);
  static const Color deepForest = Color(0xFF001A00); // Bottom green glow
  
  static const Color textPink = Color(0xFFD18BFF);
  static const Color textCyan = Color(0xFF00E5FF);
  static const Color gold = Color(0xFFFFD700);

  static const LinearGradient stellariumGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      deepBlack,
      stellariumPurple,
      deepForest,
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

class WaterGlass extends StatelessWidget {
  final Widget child;
  final double height;
  final double? width;
  final double borderRadius;
  final double blur;
  final Color? borderColor;

  const WaterGlass({
    super.key, 
    required this.child, 
    this.height = 100, 
    this.width,
    this.borderRadius = 20, 
    this.blur = 15,
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
      border: 1.5,
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