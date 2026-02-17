import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
// Import the PartyCard defined above

class PartyFeedScreen extends StatefulWidget {
  const PartyFeedScreen({super.key});

  @override
  State<PartyFeedScreen> createState() => _PartyFeedScreenState();
}

class _PartyFeedScreenState extends State<PartyFeedScreen> {
  final CardSwiperController controller = CardSwiperController();

  // Mock Data - In real app, this comes from Supabase based on GeoLocation
  final List<Map<String, dynamic>> parties = [
    {
      "title": "Rooftop Jazz & Drinks",
      "host": "Sarah V.",
      "image": "https://images.unsplash.com/photo-1514525253440-b39345208668",
      "tags": ["#Chill", "#Jazz", "#Cocktails"],
      "slots": 3,
    },
    {
      "title": "Friday Night Rage",
      "host": "Mike T.",
      "image": "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7",
      "tags": ["#Rage", "#Techno", "#LateNight"],
      "slots": 5,
    },
     {
      "title": "Board Game Wars",
      "host": "Alex & Jen",
      "image": "https://images.unsplash.com/photo-1632501641765-e568d28b0015",
      "tags": ["#GeekOut", "#Strategy", "#Beer"],
      "slots": 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Midnight Blue
      appBar: AppBar(
        title: const Text("Water Party 🥂"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline))
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: parties.length,
                onSwipe: _onSwipe,
                undoable: true,
                numberOfCardsDisplayed: 2, // Stack depth
                backCardOffset: const Offset(0, 40), // Visual depth
                padding: const EdgeInsets.all(24.0),
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final party = parties[index];
                  return PartyCard(
                    title: party['title'],
                    hostName: party['host'],
                    imageUrl: party['image'],
                    vibeTags: party['tags'],
                    slotsOpen: party['slots'],
                  );
                },
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(Icons.close, Colors.red, () => controller.swipe(CardSwiperDirection.left)),
                  _actionButton(Icons.refresh, Colors.yellow, () => controller.undo()),
                  _actionButton(Icons.local_bar, Colors.blueAccent, () => controller.swipe(CardSwiperDirection.right)), // "Apply"
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // The Logic Hook
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) {
      // TODO: Trigger API Call -> Apply for Slot
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application Sent! 🥂"), duration: Duration(milliseconds: 500)),
      );
    }
    return true;
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
             BoxShadow(color: color.withOpacity(0.3), blurRadius: 15)
          ]
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}