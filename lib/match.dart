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
    // This watches the partyFeedProvider which is updated in real-time by the WebSocket receiver
    final parties = ref.watch(partyFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      // extendBody allows content to sit behind the glass navbar
      extendBody: true, 
      body: Stack(
        children: [
          // LAYER 1: THE FULL-SCREEN IMMERSIVE SWIPER
          Positioned.fill(
            child: parties.isEmpty
                ? _buildEmptyState()
                : CardSwiper(
                    controller: controller,
                    cardsCount: parties.length,
                    numberOfCardsDisplayed: 1,
                    isDisabled: false,
                    padding: EdgeInsets.zero,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final party = parties[previousIndex];
                      // Logic: Notify Go Backend via WebSocket of the swipe
                      // ref.read(socketServiceProvider).sendMessage('SWIPE', {
                      //   'party_id': party.id,
                      //   'direction': direction.name,
                      // });
                      return true;
                    },
                    cardBuilder: (context, index, x, y) {
                      return _buildFeedCard(context, parties[index]);
                    },
                  ),
          ),

          // LAYER 2: GLOBAL ACTION BUTTONS (Floating above Bottom Nav)
          Positioned(
            bottom: 110, // Adjusted to sit perfectly above your custom navbar
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roundActionButton(Icons.close, AppColors.textPink, () {
                  controller.swipe(CardSwiperDirection.left);
                }),
                _roundActionButton(Icons.check, AppColors.textCyan, () {
                  controller.swipe(CardSwiperDirection.right);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, Party party) {
    // Map the Go []string for Photos to the first image or a placeholder
    final displayImage = party.partyPhotos.isNotEmpty 
        ? party.partyPhotos.first 
        : "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7";

    return GestureDetector(
      onTap: () {
        // Expand to "Whole Card" detailed view
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PartyDetailScreen(party: party)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The visual core
          Image.network(displayImage, fit: BoxFit.cover),
          
          // Deep gradient for data legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9)
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // HUD Overlay inside the card
          Positioned(
            bottom: 210,
            left: 25,
            right: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.title.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(party.city.toUpperCase(), AppColors.textCyan),
                    const SizedBox(width: 10),
                    _chip("${party.maxCapacity - party.currentGuestCount} SLOTS", AppColors.gold),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  party.vibeTags.take(3).join(" • ").toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _roundActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: WaterGlass(
        width: 75, height: 75,
        borderRadius: 40,
        borderColor: color.withOpacity(0.4),
        border: 2,
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.water_drop_outlined, color: AppColors.textCyan, size: 60),
          const SizedBox(height: 20),
          Text("SILENCE", style: GoogleFonts.playfairDisplay(fontSize: 24, color: Colors.white24, letterSpacing: 10)),
          const Text("NO PARTIES CURRENTLY LIVE", style: TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 2)),
        ],
      ),
    );
  }
}

// ==========================================
// THE DETAILED "WHOLE CARD" VIEW
// ==========================================

class PartyDetailScreen extends StatelessWidget {
  final Party party;
  const PartyDetailScreen({required this.party, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 550,
                pinned: true,
                backgroundColor: Colors.black,
                leading: const SizedBox(), // Hidden to use custom back button
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(party.partyPhotos.first, fit: BoxFit.cover),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(party.title, style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      // Logistics Grid
                      Row(
                        children: [
                          _detailStat(Icons.schedule, "STARTS", "${party.startTime.hour}:00"),
                          const Spacer(),
                          _detailStat(Icons.place, "CITY", party.city),
                          const Spacer(),
                          _detailStat(Icons.group, "LIMIT", "${party.maxCapacity}"),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      const Text("THE DESCRIPTION", style: TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 15),
                      Text(party.description, style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.white70)),
                      
                      const SizedBox(height: 40),
                      if (party.rotationPool != null) ...[
                        const Text("ROTATION POOL", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                        const SizedBox(height: 15),
                        WaterGlass(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet, color: AppColors.gold),
                              const SizedBox(width: 15),
                              Text(
                                "\$${party.rotationPool!.currentAmount.toInt()} / \$${party.rotationPool!.targetAmount.toInt()}",
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 200), // Space for bottom buttons
                    ],
                  ),
                ),
              )
            ],
          ),

          // LAYER 2: FLOATING BACK BUTTON
          Positioned(
            top: 60, left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: WaterGlass(width: 50, height: 50, borderRadius: 25, child: const Icon(Icons.close, color: Colors.white)),
            ),
          ),

          // LAYER 3: DECISION BUTTONS
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _decisionBtn(Icons.close, AppColors.textPink, "SKIP", () => Navigator.pop(context)),
                _decisionBtn(Icons.flash_on, AppColors.textCyan, "REQUEST", () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 12, color: Colors.white38), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10))]),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _decisionBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          WaterGlass(width: 80, height: 80, borderRadius: 40, borderColor: color, border: 2, child: Icon(icon, color: color, size: 30)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ],
      ),
    );
  }
}