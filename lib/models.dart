// models.dart
import 'package:flutter/material.dart';

// --- USER MODEL ---
class User {
  final String id;
  final String name;
  final String handle;
  final String bio;
  final String imageUrl;
  final double reputation;
  final int hostedCount;
  final int joinedCount;

  const User({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.imageUrl,
    this.reputation = 100.0,
    this.hostedCount = 0,
    this.joinedCount = 0,
  });

  // Helper to copy object with changes (Immutability)
  User copyWith({String? name, String? bio, String? handle}) {
    return User(
      id: this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      imageUrl: this.imageUrl,
      reputation: this.reputation,
      hostedCount: this.hostedCount,
      joinedCount: this.joinedCount,
    );
  }
}

// --- PARTY MODEL ---
class Party {
  final String id;
  final String title;
  final String description;
  final String hostName;
  final String imageUrl;
  final DateTime date;
  final TimeOfDay time;
  final int capacity;
  final List<String> tags;
  final double entryFee;

  const Party({
    required this.id,
    required this.title,
    required this.description,
    required this.hostName,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.capacity,
    required this.tags,
    this.entryFee = 0.0,
  });
}

// --- CHAT MODEL ---
class Chat {
  final String id;
  final String title;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final String imageUrl;
  final bool isGroup; // True for Party, False for DM
  final bool isOnline; // For DMs

  const Chat({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timeAgo,
    required this.imageUrl,
    this.unreadCount = 0,
    this.isGroup = false,
    this.isOnline = false,
  });
}