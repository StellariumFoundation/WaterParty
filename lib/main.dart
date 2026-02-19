// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'providers.dart';
import 'match.dart'; // Feed
import 'matches.dart'; // Chat
import 'party.dart'; // Create
import 'profile.dart'; // Profile
import 'auth.dart'; // Auth Screen
import 'websocket.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(child: WaterPartyApp()),
  );
}

class WaterPartyApp extends ConsumerWidget {
  const WaterPartyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'Water Party',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        fontFamily: 'Frutiger',
      ),
      home: user != null 
          ? const MainScaffold() 
          : const AuthScreen(),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref.read(socketServiceProvider).connect(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navIndexProvider);

    final List<Widget> screens = [
      const PartyFeedScreen(), 
      const MatchesScreen(),   
      const CreatePartyScreen(), 
      const ProfileScreen(),   
    ];

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, 
        body: IndexedStack(index: currentIndex, children: screens),
        
        bottomNavigationBar: Container(
          height: 75,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(Icons.style_rounded, "Feed", 0),
                _navItem(Icons.forum_rounded, "Chats", 1),
                _navItem(Icons.celebration_rounded, "Host", 2),
                _navItem(Icons.person_rounded, "Profile", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final currentIndex = ref.watch(navIndexProvider);
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(navIndexProvider.notifier).setIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : Colors.white38, 
                size: 22, 
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label, 
                style: const TextStyle(
                  fontSize: 10, 
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
