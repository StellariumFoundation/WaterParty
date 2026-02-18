// providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

const _uuid = Uuid();

// --- 1. AUTH PROVIDER ---
// Manages: Is the user logged in? Who are they?
class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => null; // Initially not logged in

  void login() {
    // Simulate fetching user from backend
    state = const User(
      id: 'u1',
      name: "John Victor",
      handle: "@john_v",
      bio: "Architect of the Vibe.",
      imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      reputation: 98.4,
      hostedCount: 12,
      joinedCount: 45,
    );
  }

  void logout() => state = null;

  void updateUserProfile(String name, String bio, String handle) {
    if (state != null) {
      state = state!.copyWith(name: name, bio: bio, handle: handle);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);


// --- 2. PARTY FEED PROVIDER ---
// Manages: The list of parties visible in the swiper
class PartyFeedNotifier extends Notifier<List<Party>> {
  @override
  List<Party> build() {
    // Initial Mock Data
    return [
      Party(
        id: 'p1',
        title: "Rooftop Jazz",
        hostName: "Sarah V.",
        imageUrl: "https://images.unsplash.com/photo-1514525253440-b39345208668",
        capacity: 15,
        tags: ["#Classy", "#Wine", "#Jazz"],
        description: "Smooth jazz and vintage wine.",
        date: DateTime.now(),
        time: const TimeOfDay(hour: 20, minute: 0),
      ),
      Party(
        id: 'p2',
        title: "Neon Rage",
        hostName: "Mike T.",
        imageUrl: "https://images.unsplash.com/photo-1574155376612-bfa5f1d00d20",
        capacity: 100,
        tags: ["#Techno", "#Rave"],
        description: "Heavy bass, high energy.",
        date: DateTime.now(),
        time: const TimeOfDay(hour: 23, minute: 0),
      ),
    ];
  }

  void addParty(Party party) {
    // Adds new party to the TOP of the stack
    state = [party, ...state];
  }

  void removeParty(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final partyFeedProvider = NotifierProvider<PartyFeedNotifier, List<Party>>(PartyFeedNotifier.new);


// --- 3. NAV BAR PROVIDER ---
// Simple state for the bottom navigation index
final navIndexProvider = StateProvider<int>((ref) => 0);