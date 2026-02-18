import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.stellariumGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Title
                Text(
                  "WATER PARTY",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                const Text(
                  "The Operating System for\nHuman Connection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPink,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),
                
                // Input Fields
                WaterGlass(
                  height: 60,
                  borderRadius: 15,
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Email or Phone",
                      prefixIcon: Icon(Icons.person_outline),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                WaterGlass(
                  height: 60,
                  borderRadius: 15,
                  child: const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Main Action Button
                GestureDetector(
                  onTap: widget.onLoginSuccess,
                  child: WaterGlass(
                    height: 60,
                    borderRadius: 30,
                    borderColor: AppColors.textCyan,
                    child: Text(
                      isLogin ? "ENTER THE VIBE" : "JOIN THE COLLECTIVE",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.textCyan,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Toggle Login/Register
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? "New here? Register Account" : "Already a member? Login",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),

                const SizedBox(height: 40),
                const Text(
                  "By entering, you agree to the\nUniversal Standard Protocol",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
