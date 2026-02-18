import 'package:flutter/material.dart';

// ==========================================
// ENUMS & CONSTANTS
// ==========================================

enum PartyStatus { OPEN, LOCKED, LIVE, COMPLETED, CANCELLED }

enum ApplicantStatus { PENDING, ACCEPTED, DECLINED, WAITLIST }

enum MessageType { TEXT, IMAGE, VIDEO, AUDIO, SYSTEM, AI, PAYMENT }

// Extension to handle Go's string-based enums
extension PartyStatusExt on PartyStatus {
  String get value => toString().split('.').last;
}

// ==========================================
// WEBSOCKET ENVELOPE
// ==========================================

class WSMessage {
  final String event;
  final dynamic payload;
  final String? token;

  WSMessage({required this.event, required this.payload, this.token});

  Map<String, dynamic> toMap() => {
    'Event': event,
    'Payload': payload,
    'Token': token,
  };

  factory WSMessage.fromMap(Map<String, dynamic> map) {
    return WSMessage(
      event: map['Event'] ?? '',
      payload: map['Payload'],
      token: map['Token'],
    );
  }
}

// ==========================================
// CORE ENTITIES
// ==========================================

@immutable
class User {
  final String id;
  final String username;
  final String realName;
  final String phoneNumber;
  final String email;
  final List<String> profilePhotos;
  final int age;
  final DateTime? dateOfBirth;
  final int heightCm;
  final String gender;
  final List<String> lookingFor;
  final String drinkingPref;
  final String smokingPref;
  final String cannabisPref;
  final List<String> musicGenres;
  final List<String> topArtists;
  final String jobTitle;
  final String company;
  final String school;
  final String degree;
  final String instagramHandle;
  final String twitterHandle;
  final String linkedinHandle;
  final String xHandle;
  final String tiktokHandle;
  final bool isVerified;
  final double trustScore;
  final double eloScore;
  final int partiesHosted;
  final int flakeCount;
  final String walletAddress;
  final double locationLat;
  final double locationLon;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final String bio;
  final List<String> interests;
  final List<String> vibeTags;

  const User({
    required this.id,
    required this.username,
    required this.realName,
    this.phoneNumber = '',
    this.email = '',
    this.profilePhotos = const [],
    this.age = 0,
    this.dateOfBirth,
    this.heightCm = 0,
    this.gender = '',
    this.lookingFor = const [],
    this.drinkingPref = '',
    this.smokingPref = '',
    this.cannabisPref = '',
    this.musicGenres = const [],
    this.topArtists = const [],
    this.jobTitle = '',
    this.company = '',
    this.school = '',
    this.degree = '',
    this.instagramHandle = '',
    this.twitterHandle = '',
    this.linkedinHandle = '',
    this.xHandle = '',
    this.tiktokHandle = '',
    this.isVerified = false,
    this.trustScore = 0.0,
    this.eloScore = 0.0,
    this.partiesHosted = 0,
    this.flakeCount = 0,
    this.walletAddress = '',
    this.locationLat = 0.0,
    this.locationLon = 0.0,
    this.lastActiveAt,
    this.createdAt,
    this.bio = '',
    this.interests = const [],
    this.vibeTags = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['ID'] ?? '',
      username: map['Username'] ?? '',
      realName: map['RealName'] ?? '',
      phoneNumber: map['PhoneNumber'] ?? '',
      email: map['Email'] ?? '',
      profilePhotos: List<String>.from(map['ProfilePhotos'] ?? []),
      age: map['Age'] ?? 0,
      dateOfBirth: map['DateOfBirth'] != null ? DateTime.parse(map['DateOfBirth']) : null,
      heightCm: map['HeightCm'] ?? 0,
      gender: map['Gender'] ?? '',
      lookingFor: List<String>.from(map['LookingFor'] ?? []),
      drinkingPref: map['DrinkingPref'] ?? '',
      smokingPref: map['SmokingPref'] ?? '',
      cannabisPref: map['CannabisPref'] ?? '',
      musicGenres: List<String>.from(map['MusicGenres'] ?? []),
      topArtists: List<String>.from(map['TopArtists'] ?? []),
      jobTitle: map['JobTitle'] ?? '',
      company: map['Company'] ?? '',
      school: map['School'] ?? '',
      degree: map['Degree'] ?? '',
      instagramHandle: map['InstagramHandle'] ?? '',
      twitterHandle: map['TwitterHandle'] ?? '',
      linkedinHandle: map['LinkedinHandle'] ?? '',
      xHandle: map['XHandle'] ?? '',
      tiktokHandle: map['TikTokHandle'] ?? '',
      isVerified: map['IsVerified'] ?? false,
      trustScore: (map['TrustScore'] ?? 0.0).toDouble(),
      eloScore: (map['EloScore'] ?? 0.0).toDouble(),
      partiesHosted: map['PartiesHosted'] ?? 0,
      flakeCount: map['FlakeCount'] ?? 0,
      walletAddress: map['WalletAddress'] ?? '',
      locationLat: (map['LocationLat'] ?? 0.0).toDouble(),
      locationLon: (map['LocationLon'] ?? 0.0).toDouble(),
      lastActiveAt: map['LastActiveAt'] != null ? DateTime.parse(map['LastActiveAt']) : null,
      createdAt: map['CreatedAt'] != null ? DateTime.parse(map['CreatedAt']) : null,
      bio: map['Bio'] ?? '',
      interests: List<String>.from(map['Interests'] ?? []),
      vibeTags: List<String>.from(map['VibeTags'] ?? []),
    );
  }

  User copyWith({String? bio, String? realName, List<String>? profilePhotos}) {
    return User(
      id: id,
      username: username,
      realName: realName ?? this.realName,
      bio: bio ?? this.bio,
      profilePhotos: profilePhotos ?? this.profilePhotos,
      // ... keep other fields same
    );
  }
}

@immutable
class Party {
  final String id;
  final String hostId;
  final String title;
  final String description;
  final List<String> partyPhotos;
  final DateTime startTime;
  final DateTime endTime;
  final PartyStatus status;
  final bool isLocationRevealed;
  final String address;
  final String city;
  final double geoLat;
  final double geoLon;
  final int maxCapacity;
  final int currentGuestCount;
  final Map<String, int> slotRequirements;
  final bool autoLockOnFull;
  final List<String> vibeTags;
  final List<String> musicGenres;
  final String mood;
  final List<String> rules;
  final Crowdfunding? rotationPool;
  final String chatRoomId;

  const Party({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    this.partyPhotos = const [],
    required this.startTime,
    required this.endTime,
    this.status = PartyStatus.OPEN,
    this.isLocationRevealed = false,
    this.address = '',
    this.city = '',
    this.geoLat = 0.0,
    this.geoLon = 0.0,
    this.maxCapacity = 0,
    this.currentGuestCount = 0,
    this.slotRequirements = const {},
    this.autoLockOnFull = false,
    this.vibeTags = const [],
    this.musicGenres = const [],
    this.mood = '',
    this.rules = const [],
    this.rotationPool,
    this.chatRoomId = '',
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['ID'] ?? '',
      hostId: map['HostID'] ?? '',
      title: map['Title'] ?? '',
      description: map['Description'] ?? '',
      partyPhotos: List<String>.from(map['PartyPhotos'] ?? []),
      startTime: DateTime.parse(map['StartTime']),
      endTime: DateTime.parse(map['EndTime']),
      status: PartyStatus.values.firstWhere((e) => e.toString().split('.').last == map['Status'], orElse: () => PartyStatus.OPEN),
      isLocationRevealed: map['IsLocationRevealed'] ?? false,
      address: map['Address'] ?? '',
      city: map['City'] ?? '',
      geoLat: (map['GeoLat'] ?? 0.0).toDouble(),
      geoLon: (map['GeoLon'] ?? 0.0).toDouble(),
      maxCapacity: map['MaxCapacity'] ?? 0,
      currentGuestCount: map['CurrentGuestCount'] ?? 0,
      slotRequirements: Map<String, int>.from(map['SlotRequirements'] ?? {}),
      autoLockOnFull: map['AutoLockOnFull'] ?? false,
      vibeTags: List<String>.from(map['VibeTags'] ?? []),
      musicGenres: List<String>.from(map['MusicGenres'] ?? []),
      mood: map['Mood'] ?? '',
      rules: List<String>.from(map['Rules'] ?? []),
      rotationPool: map['RotationPool'] != null ? Crowdfunding.fromMap(map['RotationPool']) : null,
      chatRoomId: map['ChatRoomID'] ?? '',
    );
  }
}

// ==========================================
// CHAT & FINANCIALS
// ==========================================

class ChatRoom {
  final String id;
  final String partyId;
  final String hostId;
  final List<String> participantIds;
  final bool isActive;
  final List<ChatMessage> recentMessages;
  final String lastMessageContent;
  final DateTime? lastMessageAt;

  const ChatRoom({
    required this.id,
    required this.partyId,
    required this.hostId,
    this.participantIds = const [],
    this.isActive = true,
    this.recentMessages = const [],
    this.lastMessageContent = '',
    this.lastMessageAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['ID'] ?? '',
      partyId: map['PartyID'] ?? '',
      hostId: map['HostID'] ?? '',
      participantIds: List<String>.from(map['ParticipantIDs'] ?? []),
      isActive: map['IsActive'] ?? true,
      recentMessages: (map['RecentMessages'] as List? ?? []).map((m) => ChatMessage.fromMap(m)).toList(),
      lastMessageContent: map['LastMessageContent'] ?? '',
      lastMessageAt: map['LastMessageAt'] != null ? DateTime.parse(map['LastMessageAt']) : null,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String content;
  final String mediaUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl = '',
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['ID'] ?? '',
      chatId: map['ChatID'] ?? '',
      senderId: map['SenderID'] ?? '',
      type: MessageType.values.firstWhere((e) => e.toString().split('.').last == map['Type'], orElse: () => MessageType.TEXT),
      content: map['Content'] ?? '',
      mediaUrl: map['MediaURL'] ?? '',
      createdAt: DateTime.parse(map['CreatedAt']),
    );
  }
}

class Crowdfunding {
  final String id;
  final double targetAmount;
  final double currentAmount;
  final List<Contribution> contributors;

  const Crowdfunding({
    required this.id,
    required this.targetAmount,
    required this.currentAmount,
    this.contributors = const [],
  });

  factory Crowdfunding.fromMap(Map<String, dynamic> map) {
    return Crowdfunding(
      id: map['ID'] ?? '',
      targetAmount: (map['TargetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['CurrentAmount'] ?? 0.0).toDouble(),
      contributors: (map['Contributors'] as List? ?? []).map((c) => Contribution.fromMap(c)).toList(),
    );
  }
}

class Contribution {
  final String userId;
  final double amount;
  final DateTime paidAt;

  const Contribution({required this.userId, required this.amount, required this.paidAt});

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      userId: map['UserID'] ?? '',
      amount: (map['Amount'] ?? 0.0).toDouble(),
      paidAt: DateTime.parse(map['PaidAt']),
    );
  }
}