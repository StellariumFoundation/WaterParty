import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:glassmorphism/glassmorphism.dart';

void main() {
  runApp(const WaterPartyApp());
}

// ==========================================
// 0. THEME & CONSTANTS
// ==========================================
class AppColors {
  static const Color deepBlue = Color(0xFF0F172A);
  static const Color electricPurple = Color(0xFF7C3AED);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color gold = Color(0xFFFFD700);
  
  // The background of the entire app (Deep Ocean)
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0C29), // Deep Midnight
      Color(0xFF302B63), // Royal Purple
      Color(0xFF24243E), // Dark Navy
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFDB931), Color(0xFFFFD700), Color(0xFFFDB931)],
  );
}

class WaterPartyApp extends StatelessWidget {
  const WaterPartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Party',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent, // Important for glass effect
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainScaffold(),
    );
  }
}

// ==========================================
// 1. REUSABLE GLASS COMPONENT (The Helper)
// ==========================================
// This widget standardizes the "Water" look across the app
class WaterGlass extends StatelessWidget {
  final Widget child;
  final double height;
  final double? width;
  final double borderRadius;
  final double blur;
  final double border;

  const WaterGlass({
    super.key,
    required this.child,
    this.height = 100,
    this.width,
    this.borderRadius = 20,
    this.blur = 20,
    this.border = 2,
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
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.1), // Fades out border for subtle effect
        ],
      ),
      child: child,
    );
  }
}

// ==========================================
// 2. MAIN SCAFFOLD (THE DOCK)
// ==========================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PartyFeedScreen(), 
    const MatchesScreen(),   
    const CreatePartyScreen(), 
    const ProfileScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        // Floating Glass Navbar
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: WaterGlass(
            height: 80,
            borderRadius: 40,
            blur: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(Icons.style, 0),
                _navItem(Icons.forum, 1),
                _navItem(Icons.add_circle, 2, isMain: true),
                _navItem(Icons.person, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, {bool isMain = false}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected && isMain 
            ? [BoxShadow(color: AppColors.electricPurple.withOpacity(0.4), blurRadius: 20)] 
            : []
        ),
        child: Icon(
          icon, 
          color: isSelected ? AppColors.gold : Colors.white54,
          size: isMain ? 32 : 26,
        ),
      ),
    );
  }
}

// ==========================================
// 3. PARTY FEED (SWIPE)
// ==========================================
class PartyFeedScreen extends StatelessWidget {
  const PartyFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _buildCard("Rooftop Jazz", "Sarah V.", "https://images.unsplash.com/photo-1514525253440-b39345208668", 3, ["#Classy", "#Wine"]),
      _buildCard("Neon Rage", "Mike T.", "https://images.unsplash.com/photo-1574155376612-bfa5f1d00d20", 5, ["#Techno", "#Loud"]),
      _buildCard("Board Games", "Alex", "https://images.unsplash.com/photo-1632501641765-e568d28b0015", 2, ["#Chill", "#Beer"]),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Tonight's Vibe", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 26)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.tune, color: AppColors.gold))],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding for navbar
          child: CardSwiper(
            cardsCount: cards.length,
            cardBuilder: (context, index, x, y) => cards[index],
            numberOfCardsDisplayed: 2,
            backCardOffset: const Offset(0, 40),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String host, String imgUrl, int slots, List<String> tags) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(imgUrl, fit: BoxFit.cover),
          
          // Overlay Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),

          // Glass Info Panel at Bottom
          Positioned(
            bottom: 20, left: 10, right: 10,
            child: WaterGlass(
              height: 140,
              borderRadius: 25,
              blur: 15,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                          child: Text("$slots SPOTS", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: tags.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.neonBlue)),
                    )).toList()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(radius: 10, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde")),
                        const SizedBox(width: 8),
                        Text("Hosted by $host", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. MATCHES SCREEN
// ==========================================
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Connections", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMatchTile("Friday Night Run", "Locked • Location Revealed", true),
          _buildMatchTile("Crypto & Coffee", "Host Reviewing...", false),
          _buildMatchTile("Sunset Drinks", "Event Ended", false),
        ],
      ),
    );
  }

  Widget _buildMatchTile(String title, String status, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: WaterGlass(
        height: 80,
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.gold.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(isActive ? Icons.lock_open : Icons.lock, color: isActive ? AppColors.gold : Colors.white54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(status, style: TextStyle(color: isActive ? AppColors.gold : Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. CREATE PARTY
// ==========================================
class CreatePartyScreen extends StatelessWidget {
  const CreatePartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Host an\nExperience", style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              
              _label("The Vibe"),
              _glassTextField("e.g. Midnight Jazz & Cocktails", Icons.music_note),
              
              const SizedBox(height: 20),
              _label("Guest Limit"),
              Row(children: [_slotChip("3", true), const SizedBox(width: 10), _slotChip("5", false), const SizedBox(width: 10), _slotChip("", false)]),
              
              const SizedBox(height: 20),
              _label("Rotation Fund (Entry Pool)"),
              _glassTextField("\$20.00", Icons.attach_money),

              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.electricPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))]
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, 
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {},
                  child: const Text("Mint Party Card", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16)));
  
  Widget _glassTextField(String hint, IconData icon) {
    return WaterGlass(
      height: 60,
      borderRadius: 16,
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _slotChip(String label, bool selected) {
    return SizedBox(
      width: 80,
      child: WaterGlass(
        height: 50,
        borderRadius: 15,
        border: selected ? 2 : 1,
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ==========================================
// 6. PROFILE
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Avatar with Gold Trust Ring
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient, boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 30)]),
                  ),
                  const CircleAvatar(
                    radius: 65,
                    backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e"),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold)),
                      child: const Text("98 TRUST", style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("John Victor", style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Architect of the Vibe", style: TextStyle(color: AppColors.gold)),
            
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statBox("12", "Hosted"),
                const SizedBox(width: 15),
                _statBox("45", "Attended"),
                const SizedBox(width: 15),
                _statBox("4.9", "Rating"),
              ],
            ),
            
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _optionTile(Icons.verified_user, "Verification Status", "Verified"),
                  _optionTile(Icons.wallet, "Wallet Balance", "\$120.00"),
                  _optionTile(Icons.settings, "Settings", ""),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statBox(String val, String label) {
    return SizedBox(
      width: 100,
      child: WaterGlass(
        height: 80,
        borderRadius: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: WaterGlass(
        height: 70,
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
              Text(trailing, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}