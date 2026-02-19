import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'providers.dart';

enum AuthMode { email, phone }

class AuthScreen extends ConsumerStatefulWidget {
  final String? initError;
  const AuthScreen({this.initError, super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.email;
  bool isLogin = true;
  bool isLoading = false;
  bool otpSent = false;
  bool useMock = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  Future<void> _handleAuth() async {
    if (widget.initError != null || useMock) {
       // Bypass Firebase and use mock login
       ref.read(authProvider.notifier).mockLogin();
       return;
    }

    setState(() => isLoading = true);
    try {
      if (_mode == AuthMode.email) {
        await ref.read(authProvider.notifier).authWithEmail(
          _emailController.text.trim(), _passwordController.text.trim(), isLogin);
      } else {
        if (!otpSent) {
          await ref.read(authProvider.notifier).sendOtp(_phoneController.text.trim(), (id) {
            setState(() => otpSent = true);
          });
        } else {
          await ref.read(authProvider.notifier).verifyOtp(_otpController.text.trim());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
                Text("WATER PARTY", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                const Text("HUMAN CONNECTION OS", style: TextStyle(color: AppColors.textPink, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 50),

                // --- TAB TOGGLE ---
                WaterGlass(
                  height: 50, borderRadius: 25,
                  child: Row(
                    children: [
                      _toggleTab("EMAIL", AuthMode.email),
                      _toggleTab("PHONE", AuthMode.phone),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- DYNAMIC INPUTS ---
                if (_mode == AuthMode.email) ...[
                  _inputField(_emailController, "Email", Icons.email_outlined),
                  const SizedBox(height: 15),
                  _inputField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                ] else ...[
                  if (!otpSent) 
                    _inputField(_phoneController, "+1 555 555 5555", Icons.phone_android_outlined)
                  else
                    _inputField(_otpController, "6-Digit Code", Icons.vibration_outlined),
                ],

                const SizedBox(height: 30),

                // --- MAIN ACTION ---
                GestureDetector(
                  onTap: isLoading ? null : _handleAuth,
                  child: WaterGlass(
                    height: 60, borderRadius: 30, borderColor: AppColors.textCyan,
                    child: isLoading ? const CircularProgressIndicator(color: AppColors.textCyan) : 
                    Text(widget.initError != null ? "ENTER AS GUEST" : (otpSent ? "VERIFY CODE" : (isLogin ? "ENTER THE VIBE" : "JOIN COLLECTIVE")), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textCyan, letterSpacing: 1.5)),
                  ),
                ),

                if (widget.initError != null) ...[
                  const SizedBox(height: 20),
                  const Text("FIREBASE CONFIG MISSING", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ],

                const SizedBox(height: 40),
                const Text("OR", style: TextStyle(color: Colors.white24, fontSize: 10)),
                const SizedBox(height: 20),

                // --- GOOGLE ONLY ---
                GestureDetector(
                  onTap: () => ref.read(authProvider.notifier).signInWithGoogle(),
                  child: WaterGlass(
                    width: 60, height: 60, borderRadius: 30,
                    child: Icon(FontAwesomeIcons.google, color: Colors.white, size: 24),
                  ),
                ),

                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? "New here? Register" : "Have account? Login", style: const TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleTab(String label, AuthMode mode) {
    bool selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _mode = mode; otpSent = false; }),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? Colors.white10 : Colors.transparent, borderRadius: BorderRadius.circular(25)),
          child: Text(label, style: TextStyle(color: selected ? AppColors.textCyan : Colors.white30, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return WaterGlass(
      height: 60, borderRadius: 15,
      child: TextField(
        controller: controller, obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white24), prefixIcon: Icon(icon, color: Colors.white70), border: InputBorder.none, contentPadding: const EdgeInsets.all(20)),
      ),
    );
  }
}