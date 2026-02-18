// match.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class PartyFeedScreen extends ConsumerStatefulWidget {
  const PartyFeedScreen({super.key});

  @override
  ConsumerState<PartyFeedScreen> createState() => _PartyFeedScreenState();
}

class _PartyFeedScreenState extends ConsumerState<PartyFeedScreen> {
  final CardSwiperController controller = CardSwiperController();

  @override
  Widget build(BuildContext context) {
    // WATCH THE DATA
    final parties = ref.watch(partyFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: parties.isEmpty 
              ? const Center(child: Text("No parties nearby.")) 
              : CardSwiper(
                  controller: controller,
                  cardsCount: parties.length,
                  numberOfCardsDisplayed: 1,
                  padding: EdgeInsets.zero,
                  cardBuilder: (context, index, x, y) {
                    final party = parties[index];
                    return _buildFullScreenCard(context, party);
                  },
                ),
          ),
          
          // Header Overlay
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.water_drop, color: AppColors.textCyan, size: 30),
                      Text("TONIGHT", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22, letterSpacing: 4)),
                      const Icon(Icons.tune, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Positioned(
            bottom: 120, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roundActionButton(Icons.close, AppColors.textPink, () => controller.swipe(CardSwiperDirection.left)),
                _roundActionButton(Icons.check, AppColors.textCyan, () => controller.swipe(CardSwiperDirection.right)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenCard(BuildContext context, Party party) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(party.imageUrl, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
            ),
          ),
        ),
        Positioned(
          bottom: 220, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(party.title.toUpperCase(), style: GoogleFonts.playfairDisplay(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white70, size: 16),
                  const SizedBox(width: 5),
                  Text("Hosted by ${party.hostName}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 10),
              Text(party.tags.join("  "), style: const TextStyle(color: AppColors.textCyan, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: WaterGlass(
        width: 80, height: 80, borderRadius: 40,
        borderColor: color,
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }
}