import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // Toggle state: 0 for Party Chats, 1 for DMs
  int _selectedTab = 0;

  // Mock Data: Party Chats (Group conversations)
  final List<Map<String, dynamic>> partyChats = [
    {
      "title": "Rooftop Jazz & Drinks ",
      "lastMessage": "Sarah: I'm bringing the vintage red!",
      "time": "2m ago",
      "unread": 3,
      "image": "https://images.unsplash.com/photo-1514525253440-b39345208668",
      "status": "Locked",
    },
    {
      "title": "Techno Bunker ",
      "lastMessage": "Mike: Basement entrance is open.",
      "time": "15m ago",
      "unread": 0,
      "image": "https://images.unsplash.com/photo-1574155376612-bfa5f1d00d20",
      "status": "Live",
    },
  ];

  // Mock Data: Direct Messages (1-on-1)
  final List<Map<String, dynamic>> directMessages = [
    {
      "name": "Marcus Aurelius",
      "lastMessage": "That rooftop set was legendary.",
      "time": "5m ago",
      "unread": 1,
      "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      "online": true,
    },
    {
      "name": "Elena V.",
      "lastMessage": "Are you going to the Jazz night?",
      "time": "1h ago",
      "unread": 0,
      "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
      "online": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Connections", 
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 32)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TAB TOGGLE: PARTIES VS DIRECT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: WaterGlass(
              height: 50,
              borderRadius: 25,
              child: Row(
                children: [
                  _toggleButton("PARTY CHATS", 0),
                  _toggleButton("DIRECT MESSAGES", 1),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- CONTENT AREA ---
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedTab == 0 ? _buildPartyList() : _buildDMList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENT: TAB TOGGLE BUTTON ---
  Widget _toggleButton(String label, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isSelected ? AppColors.textCyan : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  // --- LIST: PARTY CHATS ---
  Widget _buildPartyList() {
    return ListView.builder(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(20),
      itemCount: partyChats.length,
      itemBuilder: (context, index) {
        final chat = partyChats[index];
        return _buildChatTile(
          title: chat['title'],
          subtitle: chat['lastMessage'],
          time: chat['time'],
          unread: chat['unread'],
          imageUrl: chat['image'],
          isParty: true,
          status: chat['status'],
        );
      },
    );
  }

  // --- LIST: DIRECT MESSAGES ---
  Widget _buildDMList() {
    return ListView.builder(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      itemCount: directMessages.length,
      itemBuilder: (context, index) {
        final dm = directMessages[index];
        return _buildChatTile(
          title: dm['name'],
          subtitle: dm['lastMessage'],
          time: dm['time'],
          unread: dm['unread'],
          imageUrl: dm['image'],
          isParty: false,
          isOnline: dm['online'],
        );
      },
    );
  }

  // --- COMPONENT: UNIVERSAL CHAT TILE ---
  Widget _buildChatTile({
    required String title,
    required String subtitle,
    required String time,
    required int unread,
    required String imageUrl,
    required bool isParty,
    String? status,
    bool? isOnline,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WaterGlass(
        height: 90,
        borderRadius: 20,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(isParty ? 12 : 30), // Square for parties, Round for DMs
                child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
              ),
              if (isParty && status == "Locked")
                Positioned(bottom: 0, right: 0, child: Icon(Icons.lock, color: AppColors.gold, size: 18)),
              if (!isParty && isOnline == true)
                Positioned(
                  bottom: 2, right: 2, 
                  child: Container(
                    width: 12, height: 12, 
                    decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2))
                  )
                ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
              ),
              Text(time, style: const TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(subtitle, 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: unread > 0 ? Colors.white : Colors.white54, fontSize: 14)),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.textCyan, shape: BoxShape.circle),
                  child: Text(unread.toString(), 
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
      ),
    );
  }
}