import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with WidgetsBindingObserver {
  bool isLogin = true;
  bool isLoading = false;
  int currentStep = 0;
  String? errorMessage;

  // Controllers for all fields
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _realNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _compCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _instaCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _walletTypeCtrl = TextEditingController();
  final _walletDataCtrl = TextEditingController();

  DateTime? _selectedBirthDate;
  String _selectedGender = "OTHER";
  String _selectedPaymentType = "PAYPAL";

  // Multi-select lists
  final List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Add listeners for real-time draft saving
    final ctrls = [
      _realNameCtrl, _emailCtrl, _phoneCtrl, _bioCtrl, _jobCtrl, _compCtrl,
      _schoolCtrl, _degreeCtrl, _instaCtrl, _twitterCtrl, _xCtrl, _tiktokCtrl,
      _linkedInCtrl, _walletTypeCtrl, _walletDataCtrl
    ];
    for (var c in ctrls) {
      c.addListener(() {
        if (errorMessage != null) setState(() => errorMessage = null);
        _saveDraft();
      });
    }
    
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentStep = prefs.getInt('reg_step') ?? 0;
      _realNameCtrl.text = prefs.getString('reg_name') ?? '';
      _emailCtrl.text = prefs.getString('reg_email') ?? '';
      _phoneCtrl.text = prefs.getString('reg_phone') ?? '';
      _bioCtrl.text = prefs.getString('reg_bio') ?? '';
      _jobCtrl.text = prefs.getString('reg_job') ?? '';
      _compCtrl.text = prefs.getString('reg_company') ?? '';
      _schoolCtrl.text = prefs.getString('reg_school') ?? '';
      _degreeCtrl.text = prefs.getString('reg_degree') ?? '';
      _instaCtrl.text = prefs.getString('reg_insta') ?? '';
      _twitterCtrl.text = prefs.getString('reg_twitter') ?? '';
      _xCtrl.text = prefs.getString('reg_x') ?? '';
      _tiktokCtrl.text = prefs.getString('reg_tiktok') ?? '';
      _linkedInCtrl.text = prefs.getString('reg_linkedin') ?? '';
      _walletTypeCtrl.text = prefs.getString('reg_pay_type_text') ?? '';
      _walletDataCtrl.text = prefs.getString('reg_wallet') ?? '';
      _selectedGender = prefs.getString('reg_gender') ?? 'OTHER';
      _selectedPaymentType = prefs.getString('reg_pay_type') ?? 'PAYPAL';
      final bday = prefs.getString('reg_bday');
      if (bday != null) _selectedBirthDate = DateTime.parse(bday);
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reg_step', currentStep);
    await prefs.setString('reg_name', _realNameCtrl.text);
    await prefs.setString('reg_email', _emailCtrl.text);
    await prefs.setString('reg_phone', _phoneCtrl.text);
    await prefs.setString('reg_bio', _bioCtrl.text);
    await prefs.setString('reg_job', _jobCtrl.text);
    await prefs.setString('reg_company', _compCtrl.text);
    await prefs.setString('reg_school', _schoolCtrl.text);
    await prefs.setString('reg_degree', _degreeCtrl.text);
    await prefs.setString('reg_insta', _instaCtrl.text);
    await prefs.setString('reg_twitter', _twitterCtrl.text);
    await prefs.setString('reg_x', _xCtrl.text);
    await prefs.setString('reg_tiktok', _tiktokCtrl.text);
    await prefs.setString('reg_linkedin', _linkedInCtrl.text);
    await prefs.setString('reg_pay_type_text', _walletTypeCtrl.text);
    await prefs.setString('reg_wallet', _walletDataCtrl.text);
    await prefs.setString('reg_gender', _selectedGender);
    await prefs.setString('reg_pay_type', _selectedPaymentType);
    if (_selectedBirthDate != null) {
      await prefs.setString('reg_bday', _selectedBirthDate!.toIso8601String());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDraft();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _realNameCtrl.dispose();
    _phoneCtrl.dispose();
    _heightCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _compCtrl.dispose();
    _schoolCtrl.dispose();
    _degreeCtrl.dispose();
    _instaCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    _twitterCtrl.dispose();
    _tiktokCtrl.dispose();
    _walletTypeCtrl.dispose();
    _walletDataCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _saveDraft();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isPasswordStrong(String pass) {
    if (pass.length < 8) return false;
    bool hasLetter = pass.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = pass.contains(RegExp(r'[0-9]'));
    return hasLetter && hasNumber;
  }

  int _calculateAge(DateTime birthDate) {
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleAuth() async {
    setState(() => errorMessage = null);
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
        if (mounted) _showError(e.toString().replaceAll("Exception: ", ""));
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
        if (!_isPasswordStrong(_passCtrl.text)) {
          _showError("Password must be 8+ chars with letters & numbers");
          return;
        }
      }

      if (currentStep == 1) {
        if (_selectedBirthDate == null) {
          _showError("Your birthday is required");
          return;
        }
      }

      if (currentStep < 3) {
        _saveDraft();
        setState(() => currentStep++);
        return;
      }
      
      if (_selectedBirthDate == null) {
        _showError("Please select your birthday");
        return;
      }

      setState(() => isLoading = true);
      try {
        final newUser = User(
          id: "", 
          realName: _realNameCtrl.text,
          email: _emailCtrl.text,
          phoneNumber: _phoneCtrl.text,
          age: _calculateAge(_selectedBirthDate!),
          dateOfBirth: _selectedBirthDate,
          heightCm: int.tryParse(_heightCtrl.text) ?? 0,
          gender: _selectedGender,
          bio: _bioCtrl.text,
          jobTitle: _jobCtrl.text,
          company: _compCtrl.text,
          school: _schoolCtrl.text,
          degree: _degreeCtrl.text,
          instagramHandle: _instaCtrl.text,
          linkedinHandle: _linkedInCtrl.text,
          xHandle: _xCtrl.text,
          twitterHandle: _twitterCtrl.text,
          tiktokHandle: _tiktokCtrl.text,
          walletData: WalletInfo(type: _walletTypeCtrl.text, data: _walletDataCtrl.text),
          interests: _interests,
          trustScore: 100.0,
        );
        
        await ref.read(authProvider.notifier).register(newUser, _passCtrl.text);
        
        if (!mounted) return;

        // Clear draft on success
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((k) => k.startsWith('reg_'));
        for (var k in keys) { await prefs.remove(k); }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful! Welcome!"), backgroundColor: Colors.green),
        );

        // On success, switch to profile tab
        ref.read(navIndexProvider.notifier).setIndex(3);
      } catch (e) {
        if (mounted) _showError(e.toString().replaceAll("Exception: ", ""));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showError(String m) {
    setState(() => errorMessage = m);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                      padding: const EdgeInsets.fromLTRB(30, 20, 30, 180),
                      child: Column(
                        children: [
                          _buildErrorBanner(),
                          if (isLogin) _buildLoginFields() else _buildRegisterStepper(),
                        ],
                      ),
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

  Widget _buildErrorBanner() {
    if (errorMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => errorMessage = null),
            child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.waves_rounded, color: AppColors.textCyan, size: 60),
        const SizedBox(height: 12),
        Text("WATER PARTY",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: Colors.white,
                )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.textPink.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text("SWIPE AND MATCH YOUR PARTY AROUND",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  )),
        ),
      ],
    );
  }

  Widget _buildLoginFields() {
    return Column(
      children: [
        const SizedBox(height: 50),
        const Icon(Icons.login_rounded, color: Colors.white12, size: 100),
        const SizedBox(height: 40),
        _input(_emailCtrl, "EMAIL", Icons.alternate_email_rounded),
        const SizedBox(height: 20),
        _input(_passCtrl, "PASSWORD", Icons.fingerprint_rounded, obscure: true),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text("FORGOT PASSWORD?", 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textCyan.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterStepper() {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            _stepHeader("STEP 1: IDENTITY"),
            _input(_realNameCtrl, "FULL NAME", Icons.badge_rounded),
            const SizedBox(height: 15),
            _input(_emailCtrl, "EMAIL", Icons.alternate_email_rounded),
            const SizedBox(height: 15),
            _input(_passCtrl, "PASSWORD", Icons.fingerprint_rounded, obscure: true),
          ],
        );
      case 1:
        return Column(
          children: [
            _stepHeader("STEP 2: BIOMETRICS"),
            _input(_phoneCtrl, "PHONE NUMBER", Icons.phone_android_rounded),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: AppColors.textCyan,
                                onPrimary: Colors.black,
                                surface: Color(0xFF111111),
                                onSurface: Colors.white),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) setState(() => _selectedBirthDate = date);
                    },
                    child: WaterGlass(
                      height: 65,
                      borderRadius: 15,
                      child: Center(
                        child: Text(
                          _selectedBirthDate == null
                              ? "BIRTHDAY"
                              : DateFormat('MMM d, yyyy').format(_selectedBirthDate!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedBirthDate == null ? Colors.white24 : Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _input(_heightCtrl, "HEIGHT (CM)", Icons.height_rounded,
                      type: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("GENDER",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              children: [
                _genderChip("MALE"),
                const SizedBox(width: 10),
                _genderChip("FEMALE"),
                const SizedBox(width: 10),
                _genderChip("OTHER"),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _stepHeader("STEP 3: LIFESTYLE"),
            _input(_bioCtrl, "BIO / MANIFESTO", Icons.auto_awesome_rounded, maxLines: 3),
            const SizedBox(height: 15),
            _input(_jobCtrl, "JOB TITLE", Icons.work_rounded),
            const SizedBox(height: 15),
            _input(_compCtrl, "COMPANY", Icons.business_center_rounded),
            const SizedBox(height: 25),
            _stepHeader("SOCIAL HANDLES"),
            _input(_instaCtrl, "INSTAGRAM", FontAwesomeIcons.instagram),
            const SizedBox(height: 15),
            _input(_tiktokCtrl, "TIKTOK", FontAwesomeIcons.tiktok),
            const SizedBox(height: 15),
            _input(_linkedInCtrl, "LINKEDIN", FontAwesomeIcons.linkedinIn),
          ],
        );
      case 3:
        return Column(
          children: [
            _stepHeader("FINAL: ECOSYSTEM"),
            Text("PAYMENT RECEPTION",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 15),
            _input(_walletTypeCtrl, "METHOD (PAYPAL, ZELLE, ETC)",
                Icons.account_balance_wallet_rounded),
            const SizedBox(height: 15),
            _input(_walletDataCtrl, "DATA (USERNAME, IBAN)", Icons.qr_code_rounded),
            const SizedBox(height: 35),
            Text("WHAT KIND OF PARTIES DO YOU LIKE?",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textCyan, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 15),
            _interestChips(),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _genderChip(String label) {
    bool active = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border:
                Border.all(color: active ? AppColors.textCyan : Colors.white10, width: 2),
            color: active ? AppColors.textCyan.withOpacity(0.15) : Colors.black12,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: active ? Colors.white : Colors.white24,
                  fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _stepHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 25, top: 10),
        child: Row(
          children: [
            Container(width: 4, height: 20, color: AppColors.textCyan),
            const SizedBox(width: 10),
            Text(text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
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
              fontWeight: FontWeight.bold,
            ),
        decoration: InputDecoration(
          hintText: h,
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white10,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
          prefixIcon: Icon(i, color: AppColors.textCyan.withOpacity(0.4), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _interestChips() {
    final List<String> options = [
      "RAVES",
      "HOUSE PARTIES",
      "DINNER PARTIES",
      "NETWORKING",
      "OUTDOOR",
      "CHILL"
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((v) {
        bool active = _interests.contains(v);
        return GestureDetector(
          onTap: () =>
              setState(() => active ? _interests.remove(v) : _interests.add(v)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: active ? AppColors.electricPurple : Colors.white10, width: 2),
              color: active
                  ? AppColors.electricPurple.withOpacity(0.15)
                  : Colors.transparent,
            ),
            child: Text(v,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: active ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
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
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isLoading ? null : _handleAuth,
            child: Container(
              height: 65,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                    colors: [AppColors.textCyan, AppColors.electricPurple]),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textCyan.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 3))
                  : Text(
                      isLogin
                          ? "ENTER THE VIBE"
                          : (currentStep < 3
                              ? "CONTINUE"
                              : "SIGN UP"),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () => setState(() {
              isLogin = !isLogin;
              currentStep = 0;
              errorMessage = null;
            }),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                children: [
                  TextSpan(text: isLogin ? "NO ACCOUNT? " : "ALREADY ENROLLED? "),
                  TextSpan(
                      text: isLogin ? "CREATE ONE" : "SIGN IN",
                      style: const TextStyle(color: AppColors.textCyan)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
