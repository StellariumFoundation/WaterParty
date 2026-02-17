import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'theme.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
          Image.network(imgUrl, fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
          Positioned(
            bottom: 20, left: 10, right: 10,
            child: WaterGlass(
              height: 140, borderRadius: 25,
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
                    Row(children: tags.map((t) => Padding(padding: const EdgeInsets.only(right: 8), child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.neonBlue)))).toList()),
                    const SizedBox(height: 8),
                    Row(children: [const CircleAvatar(radius: 10, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde")), const SizedBox(width: 8), Text("Hosted by $host", style: const TextStyle(fontSize: 14, color: Colors.white70))]),
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