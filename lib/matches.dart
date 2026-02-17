import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  // Mock Data for the Chat System
  final List<Map<String, dynamic>> chats = const [
    {
      "title": "Rooftop Jazz & Drinks 🥂",
      "lastMessage": "Sarah: I'm bringing the vintage red!",
      "time": "2m ago",
      "unread": 3,
      "image": "https://images.unsplash.com/photo-1514525253440-b39345208668",
      "status": "Locked",
    },
    {
      "title": "Techno Bunker 🔊",
      "lastMessage": "Mike: Basement entrance is open.",
      "time": "15m ago",
      "unread": 0,
      "image": "https://images.unsplash.com/photo-1574155376612-bfa5f1d00d20",
      "status": "Live",
    },
    {
      "title": "Board Game Wars 🎲",
      "lastMessage": "You: Who has the Catan expansion?",
      "time": "1h ago",
      "unread": 0,
      "image": "https://images.unsplash.com/photo-1632501641765-e568d28b0015",
      "status": "Matched",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Connections", 
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white70)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECTION: NEW MATCHES (Horizontal) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text("NEW CONNECTIONS", 
              style: GoogleFonts.outfit(color: AppColors.textCyan, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => _buildNewMatchCircle(),
            ),
          ),

          const SizedBox(height: 20),

          // --- SECTION: ACTIVE CHATS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("PARTY CHATS", 
              style: GoogleFonts.outfit(color: AppColors.textPink, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatTile(chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW MATCH COMPONENT ---
  Widget _buildNewMatchCircle() {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.textCyan, AppColors.textPink]),
                ),
                child: const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde"),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 15, width: 15,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 5),
          const Text("Sarah", style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  // --- CHAT TILE COMPONENT ---
  Widget _buildChatTile(Map<String, dynamic> chat) {
    bool hasUnread = chat['unread'] > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: WaterGlass(
        height: 90,
        borderRadius: 20,
        child: ListTile(
          onTap: () {
            // Navigator to ChatRoomScreen
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(chat['image'], width: 55, height: 55, fit: BoxFit.cover),
              ),
              if (chat['status'] == "Locked")
                Positioned(
                  bottom: -2, right: -2,
                  child: Icon(Icons.lock, size: 16, color: AppColors.gold),
                )
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(chat['title'], 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text(chat['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(chat['lastMessage'], 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: hasUnread ? Colors.white : Colors.white54, fontSize: 14)),
                ),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.textCyan, shape: BoxShape.circle),
                    child: Text(chat['unread'].toString(), 
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}