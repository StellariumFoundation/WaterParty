import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'api.dart';
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
    // Join the room via websocket and listen for delete feedback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Join the room
      ref.read(socketServiceProvider).sendMessage('JOIN_ROOM', {
        'RoomID': widget.room.id,
      });

      // Listen for delete feedback to show SnackBar messages
      ref.listen<DeleteFeedbackState>(deleteFeedbackProvider, (previous, next) {
        if (next.status == DeleteStatus.deleting) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleting party...'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (next.status == DeleteStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Party deleted successfully'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
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
      final myId = ref.read(authProvider).value?.id;
      final recipientId = widget.room.participantIds.firstWhere(
        (id) => id != myId,
      );
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
    final currentRoom = allChatRooms.firstWhere(
      (r) => r.id == widget.room.id,
      orElse: () => widget.room,
    );
    final user = ref.watch(authProvider).value;
    final partyCache = ref.watch(partyCacheProvider);

    // Resolve dynamic title if it's a party
    String displayTitle = currentRoom.title;
    if (currentRoom.isGroup && currentRoom.partyId.isNotEmpty) {
      final party = partyCache[currentRoom.partyId];
      if (party != null) {
        displayTitle = party.title;
      }
    }

    if (displayTitle.isEmpty || displayTitle == 'PARTY CHAT') {
      displayTitle = currentRoom.isGroup ? 'PARTY CHAT' : 'DIRECT MESSAGE';
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.stellariumGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: InkWell(
            onTap: () {
              if (currentRoom.isGroup) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PartySettingsScreen(room: currentRoom),
                  ),
                );
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      (currentRoom.imageUrl.isEmpty
                              ? const NetworkImage(
                                  "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=1000",
                                )
                              : (currentRoom.imageUrl.startsWith("http")
                                    ? NetworkImage(currentRoom.imageUrl)
                                    : NetworkImage(
                                        AppConstants.assetUrl(
                                          currentRoom.imageUrl,
                                        ),
                                      )))
                          as ImageProvider,
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: AppFontSizes.lg,
                        ),
                      ),
                      _buildPartyTimeSubtitle(currentRoom),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (currentRoom.isGroup)
              IconButton(
                icon: const Icon(
                  Icons.manage_accounts,
                  color: AppColors.textCyan,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserManagementScreen(room: currentRoom),
                    ),
                  );
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
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (!isMe && widget.room.isGroup)
          Padding(
            padding: const EdgeInsets.only(left: 45, bottom: 5),
            child: Text(
              msg.senderName,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: AppFontSizes.xs,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && widget.room.isGroup) ...[
              CircleAvatar(
                radius: 15,
                backgroundImage:
                    (msg.senderThumbnail.isEmpty
                            ? const NetworkImage(
                                "https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=100",
                              )
                            : NetworkImage(
                                AppConstants.assetUrl(msg.senderThumbnail),
                              ))
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.textCyan.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: Radius.circular(isMe ? 15 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 15),
                  ),
                  border: Border.all(
                    color: isMe
                        ? AppColors.textCyan.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildPartyTimeSubtitle(ChatRoom room) {
    DateTime? startTime = room.startTime;

    // Try to find more precise data from party feed if available
    if (startTime == null) {
      final parties = ref.watch(partyFeedProvider);
      try {
        final party = parties.firstWhere((p) => p.id == room.partyId);
        startTime = party.startTime;
      } catch (_) {}
    }

    if (startTime == null) return const SizedBox();

    final now = DateTime.now();
    String label = "";
    if (startTime.isAfter(now)) {
      final diff = startTime.difference(now);
      if (diff.inDays > 0) {
        label = "IN ${diff.inDays} DAYS";
      } else if (diff.inHours > 0) {
        label = "IN ${diff.inHours} HOURS";
      } else {
        label = "STARTING SOON";
      }
    } else {
      final diff = now.difference(startTime);
      if (diff.inDays > 0) {
        label = "HAPPENED ${diff.inDays}d AGO";
      } else if (diff.inHours > 0) {
        label = "STARTED ${diff.inHours}h AGO";
      } else {
        label = "HAPPENING NOW";
      }
    }
    return Text(
      label,
      style: const TextStyle(
        fontSize: AppFontSizes.xs,
        color: AppColors.textCyan,
        fontWeight: FontWeight.bold,
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
              icon: const Icon(
                FontAwesomeIcons.paperPlane,
                color: AppColors.textCyan,
                size:
                    28, // Slighly reduced from 30 to ensure it fits well in standard IconButton
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PARTY MANAGEMENT SCREEN
// ==========================================

// ==========================================
// USER MANAGEMENT SCREEN (GOING / APPLICANTS)
// ==========================================

class UserManagementScreen extends ConsumerStatefulWidget {
  final ChatRoom room;
  const UserManagementScreen({required this.room, super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  int _selectedTab = 0; // 0 for GOING, 1 for APPLICANTS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).sendMessage('GET_APPLICANTS', {
        'PartyID': widget.room.partyId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final allApps = ref.watch(partyApplicantsProvider);
    final partyCache = ref.watch(partyCacheProvider);
    final party = partyCache[widget.room.partyId];

    final going = allApps
        .where((a) => a.status == ApplicantStatus.ACCEPTED)
        .toList();
    final applicants = allApps
        .where((a) => a.status == ApplicantStatus.PENDING)
        .toList();

    // Sort by ELO
    going.sort(
      (a, b) => (b.user?.eloScore ?? 0).compareTo(a.user?.eloScore ?? 0),
    );
    applicants.sort(
      (a, b) => (b.user?.eloScore ?? 0).compareTo(a.user?.eloScore ?? 0),
    );

    final currentList = _selectedTab == 0 ? going : applicants;
    final isFull = party != null && going.length >= party.maxCapacity;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (party?.thumbnail.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: AppConstants.assetUrl(party!.thumbnail),
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(width: 36, height: 36, color: Colors.white12),
                    errorWidget: (context, url, error) => Container(
                      width: 36,
                      height: 36,
                      color: Colors.white12,
                      child: const Icon(
                        Icons.image,
                        color: Colors.white24,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "USER MANAGEMENT",
                  style: TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  (party?.title ??
                          (widget.room.title.isEmpty ||
                                  widget.room.title == "PARTY CHAT"
                              ? "PARTY CHAT"
                              : widget.room.title))
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _tabButton("GOING (${going.length})", 0),
                const SizedBox(width: 10),
                _tabButton("APPLIED (${applicants.length})", 1),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isFull && _selectedTab == 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                "ALL SLOTS FILLED! YOU CANNOT APPROVE MORE GUESTS.",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: AppFontSizes.xs,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Text(
                      _selectedTab == 0
                          ? "NO ONE GOING YET"
                          : "NO PENDING APPLICATIONS",
                      style: const TextStyle(
                        color: Colors.white10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final app = currentList[index];
                      return _buildUserCard(app, isFull && _selectedTab == 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.textCyan.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.textCyan.withValues(alpha: 0.5)
                  : Colors.white10,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textCyan : Colors.white38,
              fontSize: AppFontSizes.xs,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(PartyApplication app, bool disableAction) {
    final user = app.user;
    if (user == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WaterGlass(
        height: 100,
        borderRadius: 20,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExternalProfileScreen(user: user),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: user.thumbnail.isNotEmpty
                        ? AppConstants.assetUrl(user.thumbnail)
                        : (user.profilePhotos.isNotEmpty
                              ? AppConstants.assetUrl(user.profilePhotos.first)
                              : "https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=1000"),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${user.realName}, ${user.age}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSizes.md,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: AppColors.gold,
                            size: 12,
                          ),
                          Text(
                            " ${user.eloScore.toInt()} ELO",
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: AppFontSizes.xs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.shield,
                            color: AppColors.textCyan,
                            size: 12,
                          ),
                          Text(
                            " ${user.trustScore.toInt()}",
                            style: const TextStyle(
                              color: AppColors.textCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: AppFontSizes.xs,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_selectedTab == 1)
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: disableAction
                          ? Colors.white10
                          : AppColors.textPink,
                    ),
                    onPressed: disableAction ? null : () => _handleApprove(app),
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleApprove(PartyApplication app) {
    ref.read(socketServiceProvider).sendMessage('UPDATE_APPLICATION', {
      'PartyID': app.partyId,
      'UserID': app.userId,
      'Status': 'ACCEPTED',
    });
  }
}

// ==========================================
// PARTY SETTINGS SCREEN (HOST ACTIONS)
// ==========================================

class PartySettingsScreen extends ConsumerWidget {
  final ChatRoom room;
  const PartySettingsScreen({required this.room, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isHost = user?.id == room.hostId;
    final partyCache = ref.watch(partyCacheProvider);

    // Get full party data from cache
    Party? party;
    if (room.isGroup && room.partyId.isNotEmpty) {
      party = partyCache[room.partyId];
      // DEBUG: Log party null safety status after cache lookup
      print(
        '[DEBUG] After cache lookup - party: ${party == null ? "NULL" : "FOUND"}',
      );
    }

    // Resolve dynamic title
    String displayTitle = room.title;
    if (party != null && party.title.isNotEmpty) {
      displayTitle = party.title;
    } else if (room.partyId.isNotEmpty) {
      final p = partyCache[room.partyId];
      if (p != null) {
        displayTitle = p.title;
      }
    }
    if (displayTitle.isEmpty || displayTitle == "PARTY CHAT")
      displayTitle = "PARTY CHAT";

    String? thumbnailUrl;
    if (party != null && party.thumbnail.isNotEmpty) {
      thumbnailUrl = party.thumbnail.startsWith("http")
          ? party.thumbnail
          : AppConstants.assetUrl(party.thumbnail);
    } else if (party != null && party.partyPhotos.isNotEmpty) {
      thumbnailUrl = party.partyPhotos.first.startsWith("http")
          ? party.partyPhotos.first
          : AppConstants.assetUrl(party.partyPhotos.first);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "PARTY MANAGEMENT",
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Party Details Section
            if (party != null) ...[
              _buildInfoSection("PARTY DETAILS", [
                _buildInfoRow(
                  "Description",
                  party.description.isNotEmpty
                      ? party.description
                      : "No description",
                ),
                _buildInfoRow("Start Time", _formatDateTime(party.startTime)),
                _buildInfoRow("Duration", "${party.durationHours} hours"),
                _buildInfoRow("Address", party.address),
                _buildInfoRow("City", party.city),
                _buildInfoRow("Max Capacity", party.maxCapacity.toString()),
                _buildInfoRow(
                  "Current Guests",
                  party.currentGuestCount.toString(),
                ),
              ]),
              const SizedBox(height: 20),
              if (party.vibeTags.isNotEmpty) ...[
                const Text(
                  "VIBE TAGS",
                  style: TextStyle(
                    color: AppColors.textCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: AppFontSizes.sm,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: party.vibeTags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.textCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.textCyan,
                              fontSize: AppFontSizes.xs,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
            ],

            if (isHost) ...[
              const Text(
                "DANGER ZONE",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: AppFontSizes.sm,
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _showDeleteDialog(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.redAccent),
                      SizedBox(width: 15),
                      Text(
                        "DELETE PARTY",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              const Center(
                child: Text(
                  "ONLY THE HOST CAN MODIFY PARTY SETTINGS",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: AppFontSizes.xs,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: AppFontSizes.sm,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: AppFontSizes.xs,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.xs,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.stellariumPurple,
        title: const Text(
          "DELETE PARTY?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action is permanent and will remove the party for everyone. Proceed?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              print(
                '[ChatScreen] Sending DELETE_PARTY for party: ${room.partyId}, chatRoomId: ${room.id}',
              );
              // Set deleting feedback to show "Deleting..." message
              ref
                  .read(deleteFeedbackProvider.notifier)
                  .setDeleting(room.partyId);
              // Send DELETE_PARTY with both party ID and chat room ID
              ref.read(socketServiceProvider).sendMessage('DELETE_PARTY', {
                'PartyID': room.partyId,
                'ChatRoomID': room.id,
              });
              Navigator.pop(context); // Close dialog
              // Refresh the party list after deletion
              ref.read(socketServiceProvider).sendMessage('GET_MY_PARTIES', {});
              ref.read(socketServiceProvider).sendMessage('GET_FEED', {});
              // Small delay to allow server response before navigating back
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  Navigator.pop(context); // Close settings
                  Navigator.pop(context); // Close chat
                }
              });
            },
            child: const Text(
              "DELETE",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
