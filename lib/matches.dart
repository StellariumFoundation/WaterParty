import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'chat.dart';
import 'constants.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final allChatRooms = ref.watch(chatProvider);
    print('[MatchesScreen] chatProvider state: ${allChatRooms.length} rooms');
    for (var room in allChatRooms) {
      print(
        '[MatchesScreen] Room: ${room.id}, partyId: ${room.partyId}, title: ${room.title}',
      );
    }
    final partyChats = allChatRooms.where((room) => room.isGroup).toList();
    final directMessages = allChatRooms.where((room) => !room.isGroup).toList();

    // Handle automatic navigation to newly created party chat
    ref.listen(partyCreationProvider, (previous, next) {
      if (next.status == CreationStatus.success &&
          next.createdPartyId != null) {
        try {
          final newRoom = allChatRooms.firstWhere(
            (r) => r.partyId == next.createdPartyId,
          );
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ChatScreen(room: newRoom)),
          );
          // We don't reset partyCreationProvider here because we want to avoid double navigation
          // if the build method is triggered again. The PartyScreen already resets it.
        } catch (_) {
          // Room hasn't arrived yet
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "CONNECTIONS",
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: AppFontSizes.display,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            color: isSelected
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.xs + 1, // 11
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
        child: Text(
          "No connections yet",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white24),
        ),
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
    String timeLabel = _formatDateTime(room.lastMessageAt);
    final partyCache = ref.watch(partyCacheProvider);

    // Resolve dynamic title if it's a party
    String displayTitle = room.title;
    if (room.isGroup && room.partyId.isNotEmpty) {
      final party = partyCache[room.partyId];
      print(
        '[MatchesScreen] Looking up party ${room.partyId} in cache: ${party?.title ?? "NOT FOUND"}',
      );
      if (party != null) {
        displayTitle = party.title;
      }
    }

    if (displayTitle.isEmpty || displayTitle == "PARTY CHAT") {
      displayTitle = room.isGroup ? "PARTY CHAT" : "DIRECT MESSAGE";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WaterGlass(
        height: 100,
        borderRadius: 20,
        child: ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => ChatScreen(room: room)),
            );
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 5,
          ),
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(room.isGroup ? 12 : 30),
                child: CachedNetworkImage(
                  imageUrl: room.imageUrl.isEmpty
                      ? "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=1000"
                      : (room.imageUrl.startsWith("http")
                            ? room.imageUrl
                            : AppConstants.assetUrl(room.imageUrl)),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.black12),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              if (room.isGroup && room.partyId.isNotEmpty)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.celebration,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: AppFontSizes.md,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                  fontSize: AppFontSizes.xs + 1, // 11
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.lastMessageContent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: room.unreadCount > 0 ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
          trailing: room.unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.textCyan,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    room.unreadCount.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
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

// ==========================================
// GUEST MANAGEMENT SCREEN
// ==========================================

// GuestManagementScreen has been replaced by PartyManageScreen in chat.dart

// ==========================================
// EXTERNAL PROFILE VIEW
// ==========================================

class ExternalProfileScreen extends ConsumerWidget {
  final User user;
  const ExternalProfileScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 500,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildPhotoCarousel(user),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user.realName}, ${user.age}",
                        style: const TextStyle(
                          fontSize: AppFontSizes.display,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _statTile(
                            "ELO",
                            user.eloScore.toInt().toString(),
                            AppColors.gold,
                          ),
                          const SizedBox(width: 15),
                          _statTile(
                            "TRUST",
                            user.trustScore.toInt().toString(),
                            AppColors.textCyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "BIO",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.bio,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: AppFontSizes.lg,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 30),
                      _infoRow(Icons.work_outline, "JOB", user.jobTitle),
                      _infoRow(
                        Icons.business_outlined,
                        "COMPANY",
                        user.company,
                      ),
                      _infoRow(
                        Icons.school_outlined,
                        "EDUCATION",
                        "${user.school} (${user.degree})",
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        "LIFESTYLE",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _habitChip(Icons.straighten, "${user.heightCm}cm"),
                          _habitChip(
                            Icons.local_bar,
                            "Drinks: ${user.drinkingPref}",
                          ),
                          _habitChip(
                            Icons.smoking_rooms,
                            "Smoke: ${user.smokingPref}",
                          ),
                        ],
                      ),

                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Message Button
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: GestureDetector(
              onTap: () {
                final myUser = ref.read(authProvider).value;
                if (myUser == null) return;

                // Create deterministic DM ID
                final u1 = myUser.id;
                final u2 = user.id;
                final dmId = u1.compareTo(u2) < 0 ? "${u1}_$u2" : "${u2}_$u1";

                final dmRoom = ChatRoom(
                  id: dmId,
                  partyId: "",
                  hostId: u1,
                  title: user.realName,
                  imageUrl: user.thumbnail.isNotEmpty
                      ? AppConstants.assetUrl(user.thumbnail)
                      : (user.profilePhotos.isNotEmpty
                            ? AppConstants.assetUrl(user.profilePhotos.first)
                            : ""),
                  isGroup: false,
                  participantIds: [u1, u2],
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(room: dmRoom),
                  ),
                );
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [AppColors.textCyan, AppColors.electricPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textCyan.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  "SEND MESSAGE",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(User user) {
    return PageView.builder(
      itemCount: user.profilePhotos.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: AppConstants.assetUrl(user.profilePhotos[index]),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black12),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      },
    );
  }

  Widget _statTile(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.xs,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: AppFontSizes.md,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    if (val.isEmpty || val == " ()") return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: AppFontSizes.xs - 1, // 9
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                val,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSizes.md,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _habitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppFontSizes.sm,
            ),
          ),
        ],
      ),
    );
  }
}
