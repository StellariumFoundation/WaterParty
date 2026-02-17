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
      "description": "An evening of smooth jazz and vintage wine overlooking the city skyline. Dress code: Formal-ish.",
    },
    {
      "id": "2",
      "title": "Neon Rage",
      "host": "Mike T.",
      "image": "https://images.unsplash.com/photo-1574155376612-bfa5f1d00d20",
      "slots": 5,
      "tags": ["#Techno", "#Loud", "#Rave"],
      "description": "Heavy bass, high energy, and pure adrenaline. The bunker opens at midnight. Bring your own neon.",
    },
    {
      "id": "3",
      "title": "Board Games",
      "host": "Alex",
      "image": "https://images.unsplash.com/photo-1632501641765-e568d28b0015",
      "slots": 2,
      "tags": ["#Chill", "#Beer", "#Strategy"],
      "description": "Catan, Poker, and craft beers. A competitive but chill night for strategy lovers.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Tonight's Vibe", 
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 26)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.water_drop, color: AppColors.textCyan),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.tune, color: AppColors.gold))],
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: parties.length,
              numberOfCardsDisplayed: 2,
              backCardOffset: const Offset(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              cardBuilder: (context, index, x, y) {
                final party = parties[index];
                return _buildSwipeCard(context, party);
              },
            ),
          ),
          
          // Action Buttons (The Tinder Row)
          Padding(
            padding: const EdgeInsets.only(bottom: 110, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roundActionButton(Icons.close, AppColors.textPink, () {
                  controller.swipe(CardSwiperDirection.left);
                }),
                _roundActionButton(Icons.info_outline, Colors.white70, () {
                  // Optional: Trigger detail view for top card
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

  Widget _buildSwipeCard(BuildContext context, Map<String, dynamic> party) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PartyDetailScreen(party: party)),
        );
      },
      child: Hero(
        tag: "party_image_${party['id']}",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(party['image'], fit: BoxFit.cover),
              
              // Dark Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),

              // Bottom Info Glass
              Positioned(
                bottom: 20, left: 15, right: 15,
                child: WaterGlass(
                  height: 150,
                  borderRadius: 25,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(party['title'], 
                              style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 10)],
                              ),
                              child: Text("${party['slots']} SPOTS", 
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(party['tags'].join("  "), 
                          style: const TextStyle(color: AppColors.textCyan, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.white54),
                            SizedBox(width: 5),
                            Text("Location hidden until matched", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70, width: 70,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 35),
      ),
    );
  }
}

// ==========================================
// THE DETAIL VIEW (Opened on Click)
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
              expandedHeight: 400,
              pinned: true,
              backgroundColor: AppColors.deepBlack,
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: "party_image_${party['id']}",
                  child: Image.network(party['image'], fit: BoxFit.cover),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party['title'], 
                      style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde")),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(party['host'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const Text("Verified Host • 98 Trust Score", style: TextStyle(color: AppColors.gold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("VIBE DESCRIPTION", style: TextStyle(color: AppColors.textCyan, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(party['description'], style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70)),
                    
                    const SizedBox(height: 30),
                    const Text("ROTATION FUND", style: TextStyle(color: AppColors.textPink, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    WaterGlass(
                      height: 80,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: AppColors.gold),
                            SizedBox(width: 15),
                            Text("Goal: \$100.00 / \$25.00 pledged", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 120), // Padding for the fixed button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pop(context),
          backgroundColor: AppColors.textCyan,
          label: const Text("REQUEST TO JOIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}