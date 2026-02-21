import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'websocket.dart';
import 'matches.dart'; // To access ExternalProfileScreen
import 'constants.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatRoom room;
  const ChatScreen({required this.room, super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Join the room via websocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).sendMessage('JOIN_ROOM', {'RoomID': widget.room.id});
    });
  }

  void _sendMessage() {
    if (_msgCtrl.text.isEmpty) return;

    if (widget.room.isGroup) {
      ref.read(socketServiceProvider).sendMessage('SEND_MESSAGE', {
        'ChatID': widget.room.id,
        'Content': _msgCtrl.text,
        'Type': 'TEXT',
      });
    } else {
      // Logic for DM
      final recipientId = widget.room.participantIds.firstWhere((id) => id != ref.read(authProvider)?.id);
      ref.read(socketServiceProvider).sendMessage('SEND_DM', {
        'RecipientID': recipientId,
        'Content': _msgCtrl.text,
      });
    }
    
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final allChatRooms = ref.watch(chatProvider);
    final currentRoom = allChatRooms.firstWhere((r) => r.id == widget.room.id, orElse: () => widget.room);
    final user = ref.watch(authProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.stellariumGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(currentRoom.imageUrl.isNotEmpty ? currentRoom.imageUrl : "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=1000"),
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(currentRoom.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
              ),
            ],
          ),
          actions: [
            if (currentRoom.isGroup)
              IconButton(
                icon: const Icon(Icons.people_outline, color: AppColors.textCyan),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RoomParticipantsScreen(room: currentRoom)));
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(20),
                itemCount: currentRoom.recentMessages.length,
                itemBuilder: (context, index) {
                  final msg = currentRoom.recentMessages[index];
                  final isMe = msg.senderId == user?.id;
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.textCyan.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          border: Border.all(
              color: isMe
                  ? AppColors.textCyan.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05)),
        ),
        child: Text(msg.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                )),
      ),
    );
  }

  Widget _buildInputArea() {
    return WaterGlass(
      height: 90,
      borderRadius: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                decoration: InputDecoration(
                  hintText: "TRANSMIT MESSAGE...",
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white24,
                        fontWeight: FontWeight.bold,
                      ),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(FontAwesomeIcons.paperPlane,
                  color: AppColors.textCyan, size: 20),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ROOM PARTICIPANTS LIST
// ==========================================

class RoomParticipantsScreen extends ConsumerStatefulWidget {
  final ChatRoom room;
  const RoomParticipantsScreen({required this.room, super.key});

  @override
  ConsumerState<RoomParticipantsScreen> createState() => _RoomParticipantsScreenState();
}

class _RoomParticipantsScreenState extends ConsumerState<RoomParticipantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).sendMessage('GET_APPLICANTS', {'PartyID': widget.room.partyId});
    });
  }

  @override
  Widget build(BuildContext context) {
    // We reuse the partyApplicantsProvider here because participants are just accepted applicants
    final members = ref.watch(partyApplicantsProvider).where((a) => a.status == ApplicantStatus.ACCEPTED).toList();
    final myId = ref.read(authProvider).value?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("ECOSYSTEM MEMBERS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: members.isEmpty 
        ? const Center(child: Text("ONLY YOU IN THIS VIBE", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.bold)))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              final user = m.user;
              if (user == null || user.id == myId) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: WaterGlass(
                  height: 80,
                  borderRadius: 15,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ExternalProfileScreen(user: user)));
                    },
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profilePhotos.isNotEmpty ? AppConstants.assetUrl(user.profilePhotos.first) : "https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=1000"),
                    ),
                    title: Text(user.realName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${user.jobTitle} @ ${user.company}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
                  ),
                ),
              );
            },
          ),
    );
  }
}
