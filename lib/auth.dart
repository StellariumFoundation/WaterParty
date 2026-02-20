import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  int currentStep = 0;

  // Controllers for all fields
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _realNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _compCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _instaCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();

  // Multi-select lists
  final List<String> _musicGenres = [];
  final List<String> _interests = [];
  final List<String> _lookingFor = [];
  final List<String> _vibeTags = [];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _userCtrl.dispose();
    _realNameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _genderCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _compCtrl.dispose();
    _schoolCtrl.dispose();
    _degreeCtrl.dispose();
    _instaCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    _tiktokCtrl.dispose();
    _walletCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleAuth() async {
    if (isLogin) {
      if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
        _showError("Credentials required");
        return;
      }
      if (!_isValidEmail(_emailCtrl.text)) {
        _showError("Please enter a valid email address");
        return;
      }
      setState(() => isLoading = true);
      try {
        await ref.read(authProvider.notifier).login(_emailCtrl.text, _passCtrl.text);
      } catch (e) {
        _showError(e.toString().replaceAll("Exception: ", ""));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      // Registration logic
      if (currentStep == 0) {
        if (_realNameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
          _showError("Name, Email and Password are required");
          return;
        }
        if (!_isValidEmail(_emailCtrl.text)) {
          _showError("Please enter a valid email address");
          return;
        }
      }

      if (currentStep < 3) {
        setState(() => currentStep++);
        return;
      }
      
      setState(() => isLoading = true);
      try {
        final newUser = User(
          id: "", // Server generates
          username: _userCtrl.text.isEmpty ? _emailCtrl.text.split('@')[0] : _userCtrl.text,
          realName: _realNameCtrl.text,
          email: _emailCtrl.text,
          phoneNumber: _phoneCtrl.text,
          age: int.tryParse(_ageCtrl.text) ?? 0,
          heightCm: int.tryParse(_heightCtrl.text) ?? 0,
          gender: _genderCtrl.text,
          bio: _bioCtrl.text,
          jobTitle: _jobCtrl.text,
          company: _compCtrl.text,
          school: _schoolCtrl.text,
          degree: _degreeCtrl.text,
          instagramHandle: _instaCtrl.text,
          linkedinHandle: _linkedInCtrl.text,
          xHandle: _xCtrl.text,
          tiktokHandle: _tiktokCtrl.text,
          walletAddress: _walletCtrl.text,
          musicGenres: _musicGenres,
          interests: _interests,
          lookingFor: _lookingFor,
          vibeTags: _vibeTags,
          trustScore: 100.0,
        );
        
        await ref.read(authProvider.notifier).register(newUser, _passCtrl.text);
        // On success, switch to profile tab
        ref.read(navIndexProvider.notifier).setIndex(3);
      } catch (e) {
        _showError(e.toString().replaceAll("Exception: ", ""));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent white bar/jumping on keyboard
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.stellariumGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(30, 20, 30, 150), // Extra bottom padding for fixed button
                      child: isLogin ? _buildLoginFields() : _buildRegisterStepper(),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomAction(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text("WATER PARTY",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                )),
        Text("MATCH YOUR PARTY",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPink,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )),
      ],
    );
  }

  Widget _buildLoginFields() {
    return Column(
      children: [
        const SizedBox(height: 100),
        _input(_emailCtrl, "EMAIL", Icons.email_outlined),
        const SizedBox(height: 20),
        _input(_passCtrl, "PASSWORD", Icons.lock_outline, obscure: true),
      ],
    );
  }

  Widget _buildRegisterStepper() {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            _stepHeader("STEP 1: CORE IDENTITY"),
            _input(_realNameCtrl, "FULL NAME", Icons.badge_outlined),
            const SizedBox(height: 15),
            _input(_emailCtrl, "EMAIL", Icons.email_outlined),
            const SizedBox(height: 15),
            _input(_passCtrl, "PASSWORD", Icons.lock_outline, obscure: true),
          ],
        );
      case 1:
        return Column(
          children: [
            _stepHeader("STEP 2: VIBE CHECK"),
            _input(_userCtrl, "USERNAME", Icons.person_outline),
            const SizedBox(height: 15),
            _input(_phoneCtrl, "PHONE NUMBER", Icons.phone_outlined),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: _input(_ageCtrl, "AGE", Icons.cake_outlined,
                        type: TextInputType.number)),
                const SizedBox(width: 15),
                Expanded(
                    child: _input(_heightCtrl, "HEIGHT (CM)",
                        Icons.straighten_outlined,
                        type: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 15),
            _input(_genderCtrl, "GENDER", Icons.wc_outlined),
          ],
        );
      case 2:
        return Column(
          children: [
            _stepHeader("STEP 3: LIFESTYLE"),
            _input(_bioCtrl, "BIO / MANIFESTO", Icons.notes, maxLines: 3),
            const SizedBox(height: 15),
            _input(_jobCtrl, "JOB TITLE", Icons.work_outline),
            const SizedBox(height: 15),
            _input(_compCtrl, "COMPANY", Icons.business_outlined),
            const SizedBox(height: 15),
            _input(_instaCtrl, "INSTAGRAM", FontAwesomeIcons.instagram),
            const SizedBox(height: 15),
            _input(_xCtrl, "X / TWITTER", FontAwesomeIcons.xTwitter),
          ],
        );
      case 3:
        return Column(
          children: [
            _stepHeader("FINAL: ECOSYSTEM"),
            _input(_walletCtrl, "WALLET ADDRESS", FontAwesomeIcons.wallet),
            const SizedBox(height: 30),
            Text("SELECT YOUR FREQUENCIES",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textCyan,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 15),
            _vibeChips(),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _stepHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Text(text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
      );

  Widget _input(TextEditingController c, String h, IconData i,
      {bool obscure = false,
      int maxLines = 1,
      TextInputType type = TextInputType.text}) {
    return WaterGlass(
      height: maxLines == 1 ? 65 : 120,
      borderRadius: 15,
      child: TextField(
        controller: c,
        obscureText: obscure,
        maxLines: maxLines,
        keyboardType: type,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
        decoration: InputDecoration(
          hintText: h,
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white10,
                fontSize: 11,
              ),
          prefixIcon: Icon(i, color: Colors.white24, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _vibeChips() {
    final List<String> options = [
      "#TECH",
      "#ART",
      "#WEB3",
      "#RAVE",
      "#DEEP",
      "#CHILL"
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((v) {
        bool active = _vibeTags.contains(v);
        return GestureDetector(
          onTap: () =>
              setState(() => active ? _vibeTags.remove(v) : _vibeTags.add(v)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: active ? AppColors.textCyan : Colors.white10),
              color: active
                  ? AppColors.textCyan.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Text(v,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: active ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.bold,
                    )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0),
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isLoading ? null : _handleAuth,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                    colors: [AppColors.textCyan, AppColors.electricPurple]),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textCyan.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : Text(
                      isLogin
                          ? "ENTER THE VIBE"
                          : (currentStep < 3
                              ? "CONTINUE"
                              : "INITIATE PROTOCOL"),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() {
              isLogin = !isLogin;
              currentStep = 0;
            }),
            child: Text(
                isLogin ? "NO ACCOUNT? CREATE ONE" : "ALREADY ENROLLED? SIGN IN",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                    )),
          ),
        ],
      ),
    );
  }
}
