import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'chat.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // Watch the global chat state
    final allChatRooms = ref.watch(chatProvider);

    // Filter based on the Go 'isGroup' flag
    final partyChats = allChatRooms.where((room) => room.isGroup).toList();
    final directMessages = allChatRooms.where((room) => !room.isGroup).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("CONNECTIONS",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  letterSpacing: 2,
                  color: Colors.white,
                )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TAB TOGGLE ---
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
              child: _selectedTab == 0 
                ? _buildList(partyChats, true) 
                : _buildList(directMessages, false),
            ),
          ),
        ],
      ),
    );
  }

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
            style: const TextStyle(
              
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isSelected ? AppColors.textCyan : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ChatRoom> rooms, bool isPartyTab) {
    if (rooms.isEmpty) {
      return Center(
        child: Text("No connections yet",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white24)),
      );
    }

    return ListView.builder(
      key: ValueKey(_selectedTab),
      padding: const EdgeInsets.all(20),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildChatTile(room);
      },
    );
  }

  Widget _buildChatTile(ChatRoom room) {
    // Helper to format DateTime to "2m ago" style
    String timeLabel = _formatDateTime(room.lastMessageAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WaterGlass(
        height: 90,
        borderRadius: 20,
        child: ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => ChatScreen(room: room)),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(room.isGroup ? 12 : 30),
                child: Image.network(room.imageUrl,
                    width: 60, height: 60, fit: BoxFit.cover),
              ),
              // Show online status or locked status based on Go model data
              if (room.isGroup && room.partyId.isNotEmpty)
                const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.lock, color: AppColors.gold, size: 18)),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Text(timeLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white30, fontSize: 11)),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(room.lastMessageContent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: room.unreadCount > 0
                            ? Colors.white
                            : Colors.white54)),
              ),
              if (room.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: AppColors.textCyan, shape: BoxShape.circle),
                  child: Text(room.unreadCount.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "";
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}