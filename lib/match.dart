import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'theme.dart';

class PartyFeedScreen extends StatefulWidget {
  const PartyFeedScreen({super.key});

  @override
  State<PartyFeedScreen> createState() => _PartyFeedScreenState();
}

class _PartyFeedScreenState extends State<PartyFeedScreen> {
  final CardSwiperController controller = CardSwiperController();

  final List<Map<String, dynamic>> parties = [
    {
      "id": "1",
      "title": "Rooftop Jazz",
      "host": "Sarah V.",
      "image": "https://images.unsplash.com/photo-1514525253440-b39345208668",
      "slots": 3,
      "tags": ["#Classy", "#Wine", "#Jazz"],
      "description": "An evening of smooth jazz and vintage wine overlooking the city skyline.",
    },
    {
      "id": "2",
      "title": "Neon Rage",
      "host": "Mike T.",
      "image": "https://images.unsplash.com/photo-1574155376612-bfa5f1d00d20",
      "slots": 5,
      "tags": ["#Techno", "#Loud", "#Rave"],
      "description": "Heavy bass, high energy, and pure adrenaline. The bunker opens at midnight.",
    },
    {
      "id": "3",
      "title": "Board Game Wars",
      "host": "Alex",
      "image": "https://images.unsplash.com/photo-1632501641765-e568d28b0015",
      "slots": 2,
      "tags": ["#Chill", "#Beer", "#Strategy"],
      "description": "Catan, Poker, and craft beers. A competitive but chill night.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // We use Stack to layer UI over the Full-Screen Swiper
      body: Stack(
        children: [
          // LAYER 1: THE FULL SCREEN SWIPER
          Positioned.fill(
            child: CardSwiper(
              controller: controller,
              cardsCount: parties.length,
              numberOfCardsDisplayed: 1, // Single card for full immersion
              isDisabled: false,
              padding: EdgeInsets.zero, // Fill the edges
              cardBuilder: (context, index, x, y) {
                final party = parties[index];
                return _buildFullScreenCard(context, party);
              },
            ),
          ),

          // LAYER 2: THE HEADER OVERLAY (HUD)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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
                      Text("TONIGHT", 
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w900, 
                          color: Colors.white, 
                          fontSize: 22,
                          letterSpacing: 4
                        )
                      ),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.tune, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: ACTION BUTTONS (X and √ Only)
          Positioned(
            bottom: 120, // Positioned above the Bottom Nav
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

  Widget _buildFullScreenCard(BuildContext context, Map<String, dynamic> party) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PartyDetailScreen(party: party)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The Background Image
          Image.network(party['image'], fit: BoxFit.cover),
          
          // Bottom Vibe Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),

          // THE INFO DECK (Overlayed inside the card)
          Positioned(
            bottom: 220, // Pushed up to clear the buttons
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(party['title'].toUpperCase(), 
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white,
                          height: 1
                        )
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text("${party['slots']} LEFT", 
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde")),
                    const SizedBox(width: 10),
                    Text("Hosted by ${party['host']}", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(party['tags'].join("  "), 
                  style: const TextStyle(color: AppColors.textCyan, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: WaterGlass(
        width: 80, height: 80,
        borderRadius: 40,
        blur: 10,
        border: 2,
        borderColor: color,
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }
}

// ==========================================
// THE DETAIL VIEW (Kept for Full Info)
// ==========================================
class PartyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> party;
  const PartyDetailScreen({required this.party, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.stellariumGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.height * 0.6,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(party['image'], fit: BoxFit.cover),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party['title'], style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(party['description'], style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.white70)),
                    const SizedBox(height: 40),
                    WaterGlass(
                      height: 100,
                      child: Center(
                        child: Text("ROTATION POOL: \$100 GOAL", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.gold)),
                      ),
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: AppColors.textCyan,
        label: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text("REQUEST TO JOIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}