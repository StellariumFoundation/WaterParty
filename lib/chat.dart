import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'websocket.dart';

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
          leading: BackButton(color: AppColors.textCyan),
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(currentRoom.imageUrl),
                radius: 18,
              ),
              const SizedBox(width: 12),
              Text(currentRoom.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
            ],
          ),
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
