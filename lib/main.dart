import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';
import 'match.dart';
import 'matches.dart';
import 'party.dart';
import 'profile.dart';
import 'auth_screen.dart'; 

void main() {
  runApp(const WaterPartyApp());
}

class WaterPartyApp extends StatefulWidget {
  const WaterPartyApp({super.key});

  @override
  State<WaterPartyApp> createState() => _WaterPartyAppState();
}

class _WaterPartyAppState extends State<WaterPartyApp> {
  bool _isAuthenticated = false; 

  void _login() {
    setState(() => _isAuthenticated = true);
  }

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
      home: _isAuthenticated 
          ? const MainScaffold() 
          : AuthScreen(onLoginSuccess: _login),
    );
  }
}

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
        // extendBody allows the content to flow behind the nav bar if needed
        extendBody: true, 
        body: IndexedStack(index: _currentIndex, children: _screens),
        
        // --- COMPACT STELLARIUM NAVIGATION BAR ---
        bottomNavigationBar: Container(
          height: 75, // Reduced from 90 for a sleeker profile
          margin: const EdgeInsets.only(bottom: 0), // Flat to the bottom
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5)),
          ),
          child: SafeArea(
            top: false, // Don't add padding for notch at top of bar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(Icons.style_rounded, "Feed", 0),
                _navItem(Icons.forum_rounded, "Chats", 1),
                _navItem(Icons.celebration_rounded, "Host", 2), // Changed to Party Icon
                _navItem(Icons.person_rounded, "Profile", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: MediaQuery.of(context).size.width / 4, // Equal spacing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact "Pill" background for the active item
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : Colors.white38, 
                size: 22, // Slightly smaller icon
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, // More compact text
                color: isSelected ? Colors.white : Colors.white30,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}