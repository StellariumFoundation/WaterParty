import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

void main() {
  runApp(const WaterPartyApp());
}

// ==========================================
// THEME & CONSTANTS
// ==========================================
class AppColors {
  static const Color deepBlue = Color(0xFF0F172A);
  static const Color electricPurple = Color(0xFF7C3AED);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color gold = Color(0xFFFFD700);
  static const Color glassWhite = Color(0x1AFFFFFF);
  
  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0C29), // Deepest Midnight
      Color(0xFF302B63), // Royal Purple
      Color(0xFF24243E), // Dark Blue
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
        scaffoldBackgroundColor: Colors.transparent, 
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainScaffold(),
    );
  }
}

// ==========================================
// MAIN SCAFFOLD (THE DOCK)
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
      decoration: const BoxDecoration(gradient: AppColors.waterGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let gradient show through
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        extendBody: true, // Allows content to go behind the glass navbar
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                selectedItemColor: AppColors.gold,
                unselectedItemColor: Colors.white54,
                showUnselectedLabels: false,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Vibe'),
                  BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Matches'),
                  BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40), label: 'Host'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. PARTY FEED (SWIPE)
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
          padding: const EdgeInsets.all(16.0),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                begin: Alignment.center, end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Slots Badge
          Positioned(
            top: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 10)]
              ),
              child: Text("$slots SPOTS", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),

          // Content
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: tags.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(t, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                )).toList()),
                Text(title, style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde")),
                    const SizedBox(width: 8),
                    Text("Hosted by $host", style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. MATCHES SCREEN
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
          _buildGlassTile("Friday Night Run", "Locked • Location Revealed", true),
          _buildGlassTile("Crypto & Coffee", "Host Reviewing...", false),
          _buildGlassTile("Sunset Drinks", "Event Ended", false),
        ],
      ),
    );
  }

  Widget _buildGlassTile(String title, String status, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppColors.gold.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(isActive ? Icons.lock_open : Icons.lock, color: isActive ? AppColors.gold : Colors.white54),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(status, style: TextStyle(color: isActive ? AppColors.gold : Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
      ),
    );
  }
}

// ==========================================
// 3. CREATE PARTY
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
    return Container(
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(16)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.electricPurple : AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? Colors.transparent : Colors.white10),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

// ==========================================
// 4. PROFILE
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
                    width: 130, height: 130,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient, boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 30)]),
                  ),
                  const CircleAvatar(
                    radius: 60,
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
                const SizedBox(width: 20),
                _statBox("45", "Attended"),
                const SizedBox(width: 20),
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
    return Container(
      width: 90, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(children: [
        Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ]),
    );
  }

  Widget _optionTile(IconData icon, String title, String trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(trailing, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
      ),
    );
  }
}