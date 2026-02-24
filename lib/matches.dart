import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'chat.dart';
import 'constants.dart';
import 'match.dart';

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
    final myParties = ref.watch(myPartiesProvider);
    final currentUser = ref.watch(authProvider).value;

    // Get parties where user is admin (host) or matched (guest)
    final userParties = myParties.where((party) {
      if (currentUser == null) return false;
      print(
        '[MatchesScreen] Filtering party: ${party.id}, hostId=${party.hostId}, currentUserId=${currentUser.id}',
      );
      // User is admin/host of the party
      if (party.hostId == currentUser.id) {
        print('[MatchesScreen] Party ${party.id} included: user is host');
        return true;
      }
      // User is matched on the party (not host but included)
      print(
        '[MatchesScreen] Party ${party.id} included: showing all myParties',
      );
      return true; // Show all parties from myPartiesProvider
    }).toList();

    print('[MatchesScreen] Final userParties count: ${userParties.length}');

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
                  ? _buildPartyList(userParties)
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

  Widget _buildPartyList(List<Party> parties) {
    if (parties.isEmpty) {
      return Center(
        child: Text(
          "No parties yet",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white24),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('party_${_selectedTab}'),
      padding: const EdgeInsets.all(20),
      itemCount: parties.length,
      itemBuilder: (context, index) {
        final party = parties[index];
        return _buildPartyTile(party);
      },
    );
  }

  Widget _buildPartyTile(Party party) {
    final allChatRooms = ref.watch(chatProvider);
    final currentUser = ref.watch(authProvider).value;

    // Determine if user is the host/admin
    final isHost = currentUser != null && party.hostId == currentUser.id;

    // Get thumbnail
    String? thumbnailUrl;
    if (party.thumbnail.isNotEmpty) {
      thumbnailUrl = party.thumbnail.startsWith("http")
          ? party.thumbnail
          : AppConstants.assetUrl(party.thumbnail);
    } else if (party.partyPhotos.isNotEmpty) {
      thumbnailUrl = party.partyPhotos.first.startsWith("http")
          ? party.partyPhotos.first
          : AppConstants.assetUrl(party.partyPhotos.first);
    }

    // Calculate ETA
    String etaLabel = _formatETA(party.startTime);

    // Status color
    Color statusColor;
    switch (party.status) {
      case PartyStatus.OPEN:
        statusColor = AppColors.textCyan;
        break;
      case PartyStatus.LOCKED:
        statusColor = Colors.orange;
        break;
      case PartyStatus.LIVE:
        statusColor = Colors.green;
        break;
      case PartyStatus.COMPLETED:
        statusColor = Colors.grey;
        break;
      case PartyStatus.CANCELLED:
        statusColor = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: WaterGlass(
        height: 100,
        borderRadius: 20,
        child: ListTile(
          onTap: () {
            // Find the ChatRoom for this party
            try {
              final room = allChatRooms.firstWhere(
                (r) => r.partyId == party.id,
              );
              // Navigate to the actual party chat
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChatScreen(room: room)),
              );
            } catch (_) {
              // Fallback: navigate to party detail if no chat room found
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PartyDetailScreen(party: party),
                ),
              );
            }
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 5,
          ),
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textCyan,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildDefaultAvatar(true),
                      )
                    : _buildDefaultAvatar(true),
              ),
              // Host badge
              if (isHost)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              // Party status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.celebration, color: statusColor, size: 14),
                ),
              ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        party.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: AppFontSizes.md,
                        ),
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "HOST",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.gold,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ETA badge
              if (etaLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    etaLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                party.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people_outline, color: Colors.white38, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "${party.currentGuestCount}/${party.maxCapacity}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      fontSize: AppFontSizes.xs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white38,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      party.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                        fontSize: AppFontSizes.xs,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatRoom room) {
    String timeLabel = _formatDateTime(room.lastMessageAt);
    final partyCache = ref.watch(partyCacheProvider);
    final myParties = ref.watch(myPartiesProvider);
    final currentUser = ref.watch(authProvider).value;

    // Resolve dynamic title and party details if it's a party
    String displayTitle = room.title;
    String? partyThumbnail;
    DateTime? partyStartTime;
    if (room.isGroup && room.partyId.isNotEmpty) {
      // First check party cache
      final party = partyCache[room.partyId];
      if (party != null) {
        displayTitle = party.title;
        partyThumbnail = party.thumbnail.isNotEmpty
            ? party.thumbnail
            : (party.partyPhotos.isNotEmpty ? party.partyPhotos.first : null);
        partyStartTime = party.startTime;
      } else {
        // Fallback: check myPartiesProvider
        final myParty = myParties
            .where((p) => p.id == room.partyId)
            .firstOrNull;
        if (myParty != null) {
          displayTitle = myParty.title;
          partyThumbnail = myParty.thumbnail.isNotEmpty
              ? myParty.thumbnail
              : (myParty.partyPhotos.isNotEmpty
                    ? myParty.partyPhotos.first
                    : null);
          partyStartTime = myParty.startTime;
        }
      }
    }

    if (displayTitle.isEmpty || displayTitle == "PARTY CHAT") {
      displayTitle = room.isGroup ? "PARTY CHAT" : "DIRECT MESSAGE";
    }

    // Calculate ETA for party chats
    String? etaLabel;
    if (room.isGroup && partyStartTime != null) {
      etaLabel = _formatETA(partyStartTime);
    }

    // Check if last message is from current user
    String lastMessageText = room.lastMessageContent;
    bool isLastMessageFromMe =
        currentUser != null &&
        room.recentMessages.isNotEmpty &&
        room.recentMessages.last.senderId == currentUser.id;
    if (isLastMessageFromMe) {
      lastMessageText = "You: ${room.lastMessageContent}";
    }

    // Determine thumbnail URL
    String? thumbnailUrl;
    if (partyThumbnail != null) {
      thumbnailUrl = partyThumbnail.startsWith("http")
          ? partyThumbnail
          : AppConstants.assetUrl(partyThumbnail);
    } else if (room.imageUrl.isNotEmpty) {
      thumbnailUrl = room.imageUrl.startsWith("http")
          ? room.imageUrl
          : AppConstants.assetUrl(room.imageUrl);
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
                child: thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textCyan,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildDefaultAvatar(room.isGroup),
                      )
                    : _buildDefaultAvatar(room.isGroup),
              ),
              if (room.isGroup && room.partyId.isNotEmpty)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: AppColors.gold,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
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
                    if (etaLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          etaLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                  fontSize: AppFontSizes.xs + 1,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isLastMessageFromMe)
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.textCyan,
                      size: 14,
                    ),
                  if (isLastMessageFromMe) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lastMessageText.isEmpty
                          ? "No messages yet"
                          : lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isLastMessageFromMe
                            ? AppColors.textCyan
                            : (room.unreadCount > 0
                                  ? Colors.white
                                  : Colors.white54),
                        fontStyle: lastMessageText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildDefaultAvatar(bool isGroup) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGroup
              ? [
                  AppColors.gold.withValues(alpha: 0.3),
                  AppColors.textCyan.withValues(alpha: 0.3),
                ]
              : [
                  AppColors.textCyan.withValues(alpha: 0.3),
                  Colors.purple.withValues(alpha: 0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isGroup ? 12 : 30),
      ),
      child: Icon(
        isGroup ? Icons.celebration : Icons.person,
        color: Colors.white54,
        size: 28,
      ),
    );
  }

  String _formatETA(DateTime? startTime) {
    if (startTime == null) return "";
    final now = DateTime.now();
    final diff = startTime.difference(now);

    if (diff.isNegative) {
      // Party has started
      if (diff.inMinutes.abs() < 60) return "NOW";
      if (diff.inHours.abs() < 24) return "${diff.inHours.abs()}h";
      return "${diff.inDays.abs()}d";
    }

    // Party hasn't started yet
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${(diff.inDays / 7).floor()}w";
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
