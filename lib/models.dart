// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

// ==========================================
// ENUMS & CONSTANTS (Synced with models.go)
// ==========================================

enum PartyStatus { OPEN, LOCKED, LIVE, COMPLETED, CANCELLED }

enum ApplicantStatus { PENDING, ACCEPTED, DECLINED, WAITLIST }

enum MessageType { TEXT, IMAGE, VIDEO, AUDIO, SYSTEM, AI, PAYMENT }

extension PartyStatusExt on PartyStatus {
  String get value => toString().split('.').last;
}

// ==========================================
// CORE ENTITIES
// ==========================================

@immutable
class WalletInfo {
  final String type;
  final String data;

  const WalletInfo({this.type = '', this.data = ''});

  factory WalletInfo.fromMap(Map<String, dynamic> map) {
    return WalletInfo(type: map['Type'] ?? '', data: map['Data'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'Type': type, 'Data': data};
  }
}

@immutable
class User {
  final String id;
  final String realName;
  final String phoneNumber;
  final String email;
  final List<String> profilePhotos;
  final int age;
  final DateTime? dateOfBirth;
  final int heightCm;
  final String gender;
  final String drinkingPref;
  final String smokingPref;
  final List<String> topArtists;
  final String jobTitle;
  final String company;
  final String school;
  final String degree;
  final String instagramHandle;
  final String linkedinHandle;
  final String xHandle;
  final String tiktokHandle;
  final bool isVerified;
  final double trustScore;
  final double eloScore;
  final int partiesHosted;
  final int flakeCount;
  final WalletInfo walletData;
  final double locationLat;
  final double locationLon;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final String bio;
  final String thumbnail;

  const User({
    required this.id,
    required this.realName,
    this.phoneNumber = '',
    this.email = '',
    this.profilePhotos = const [],
    this.age = 0,
    this.dateOfBirth,
    this.heightCm = 0,
    this.gender = '',
    this.drinkingPref = '',
    this.smokingPref = '',
    this.topArtists = const [],
    this.jobTitle = '',
    this.company = '',
    this.school = '',
    this.degree = '',
    this.instagramHandle = '',
    this.linkedinHandle = '',
    this.xHandle = '',
    this.tiktokHandle = '',
    this.isVerified = false,
    this.trustScore = 0.0,
    this.eloScore = 0.0,
    this.partiesHosted = 0,
    this.flakeCount = 0,
    this.walletData = const WalletInfo(),
    this.locationLat = 0.0,
    this.locationLon = 0.0,
    this.lastActiveAt,
    this.createdAt,
    this.bio = '',
    this.thumbnail = '',
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['ID'] ?? map['id'] ?? '',
      realName: map['RealName'] ?? map['real_name'] ?? '',
      phoneNumber: map['PhoneNumber'] ?? map['phone_number'] ?? '',
      email: map['Email'] ?? map['email'] ?? '',
      profilePhotos: List<String>.from(
        map['ProfilePhotos'] ?? map['profile_photos'] ?? [],
      ),
      age: map['Age'] ?? map['age'] ?? 0,
      dateOfBirth: (map['DateOfBirth'] ?? map['date_of_birth']) != null
          ? DateTime.parse(map['DateOfBirth'] ?? map['date_of_birth'])
          : null,
      heightCm: map['HeightCm'] ?? map['height_cm'] ?? 0,
      gender: map['Gender'] ?? map['gender'] ?? '',
      drinkingPref: map['DrinkingPref'] ?? map['drinking_pref'] ?? '',
      smokingPref: map['SmokingPref'] ?? map['smoking_pref'] ?? '',
      topArtists: List<String>.from(
        map['TopArtists'] ?? map['top_artists'] ?? [],
      ),
      jobTitle: map['JobTitle'] ?? map['job_title'] ?? '',
      company: map['Company'] ?? map['company'] ?? '',
      school: map['School'] ?? map['school'] ?? '',
      degree: map['Degree'] ?? map['degree'] ?? '',
      instagramHandle: map['InstagramHandle'] ?? map['instagram_handle'] ?? '',
      linkedinHandle: map['LinkedinHandle'] ?? map['linkedin_handle'] ?? '',
      xHandle: map['XHandle'] ?? map['x_handle'] ?? '',
      tiktokHandle: map['TikTokHandle'] ?? map['tiktok_handle'] ?? '',
      isVerified: map['IsVerified'] ?? map['is_verified'] ?? false,
      trustScore: (map['TrustScore'] ?? map['trust_score'] ?? 0.0).toDouble(),
      eloScore: (map['EloScore'] ?? map['elo_score'] ?? 0.0).toDouble(),
      partiesHosted: map['PartiesHosted'] ?? map['parties_hosted'] ?? 0,
      flakeCount: map['FlakeCount'] ?? map['flake_count'] ?? 0,
      walletData: (map['WalletData'] ?? map['wallet_data']) != null
          ? WalletInfo.fromMap(map['WalletData'] ?? map['wallet_data'])
          : const WalletInfo(),
      locationLat: (map['LocationLat'] ?? map['location_lat'] ?? 0.0)
          .toDouble(),
      locationLon: (map['LocationLon'] ?? map['location_lon'] ?? 0.0)
          .toDouble(),
      lastActiveAt: (map['LastActiveAt'] ?? map['last_active_at']) != null
          ? DateTime.parse(map['LastActiveAt'] ?? map['last_active_at'])
          : null,
      createdAt: (map['CreatedAt'] ?? map['created_at']) != null
          ? DateTime.parse(map['CreatedAt'] ?? map['created_at'])
          : null,
      bio: map['Bio'] ?? map['bio'] ?? '',
      thumbnail: map['Thumbnail'] ?? map['thumbnail'] ?? '',
    );
  }

  User copyWith({
    String? realName,
    String? bio,
    List<String>? profilePhotos,
    double? trustScore,
    String? instagramHandle,
    String? linkedinHandle,
    String? xHandle,
    String? tiktokHandle,
    String? phoneNumber,
    int? age,
    int? heightCm,
    String? gender,
    String? drinkingPref,
    String? smokingPref,
    String? jobTitle,
    String? company,
    String? school,
    String? degree,
    List<String>? topArtists,
    String? thumbnail,
  }) {
    return User(
      id: id,
      realName: realName ?? this.realName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email,
      profilePhotos: profilePhotos ?? this.profilePhotos,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      drinkingPref: drinkingPref ?? this.drinkingPref,
      smokingPref: smokingPref ?? this.smokingPref,
      topArtists: topArtists ?? this.topArtists,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      school: school ?? this.school,
      degree: degree ?? this.degree,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      linkedinHandle: linkedinHandle ?? this.linkedinHandle,
      xHandle: xHandle ?? this.xHandle,
      tiktokHandle: tiktokHandle ?? this.tiktokHandle,
      isVerified: isVerified,
      trustScore: trustScore ?? this.trustScore,
      eloScore: eloScore,
      partiesHosted: partiesHosted,
      flakeCount: flakeCount,
      walletData: walletData,
      locationLat: locationLat,
      locationLon: locationLon,
      lastActiveAt: lastActiveAt,
      createdAt: createdAt,
      bio: bio ?? this.bio,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'RealName': realName,
      'PhoneNumber': phoneNumber,
      'Email': email,
      'ProfilePhotos': profilePhotos,
      'Age': age,
      'DateOfBirth': dateOfBirth?.toUtc().toIso8601String(),
      'HeightCm': heightCm,
      'Gender': gender,
      'DrinkingPref': drinkingPref,
      'SmokingPref': smokingPref,
      'TopArtists': topArtists,
      'JobTitle': jobTitle,
      'Company': company,
      'School': school,
      'Degree': degree,
      'InstagramHandle': instagramHandle,
      'LinkedinHandle': linkedinHandle,
      'XHandle': xHandle,
      'TikTokHandle': tiktokHandle,
      'IsVerified': isVerified,
      'TrustScore': trustScore,
      'EloScore': eloScore,
      'PartiesHosted': partiesHosted,
      'FlakeCount': flakeCount,
      'WalletData': walletData.toMap(),
      'LocationLat': locationLat,
      'LocationLon': locationLon,
      'Bio': bio,
      'Thumbnail': thumbnail,
    };
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
  final int durationHours;
  final PartyStatus status;
  final bool isLocationRevealed;
  final String address;
  final String city;
  final double geoLat;
  final double geoLon;
  final int maxCapacity;
  final int currentGuestCount;
  final bool autoLockOnFull;
  final List<String> vibeTags;
  final List<String> rules;
  final Crowdfunding? rotationPool;
  final String chatRoomId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String thumbnail;

  const Party({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    this.partyPhotos = const [],
    required this.startTime,
    required this.durationHours,
    this.status = PartyStatus.OPEN,
    this.isLocationRevealed = false,
    this.address = '',
    this.city = '',
    this.geoLat = 0.0,
    this.geoLon = 0.0,
    this.maxCapacity = 0,
    this.currentGuestCount = 0,
    this.autoLockOnFull = false,
    this.vibeTags = const [],
    this.rules = const [],
    this.rotationPool,
    this.chatRoomId = '',
    this.createdAt,
    this.updatedAt,
    this.thumbnail = '',
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['ID'] ?? map['id'] ?? '',
      hostId: map['HostID'] ?? map['host_id'] ?? '',
      title: map['Title'] ?? map['title'] ?? '',
      description: map['Description'] ?? map['description'] ?? '',
      partyPhotos: List<String>.from(
        map['PartyPhotos'] ?? map['party_photos'] ?? [],
      ),
      startTime: DateTime.parse(map['StartTime'] ?? map['start_time']),
      durationHours:
          (map['DurationHours'] ?? map['duration_hours'] as num?)?.toInt() ?? 2,
      status: PartyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['Status'] ?? map['status']),
        orElse: () => PartyStatus.OPEN,
      ),
      isLocationRevealed:
          map['IsLocationRevealed'] ?? map['is_location_revealed'] ?? false,
      address: map['Address'] ?? map['address'] ?? '',
      city: map['City'] ?? map['city'] ?? '',
      geoLat: (map['GeoLat'] ?? map['geo_lat'] ?? 0.0).toDouble(),
      geoLon: (map['GeoLon'] ?? map['geo_lon'] ?? 0.0).toDouble(),
      maxCapacity: map['MaxCapacity'] ?? map['max_capacity'] ?? 0,
      currentGuestCount:
          map['CurrentGuestCount'] ?? map['current_guest_count'] ?? 0,
      autoLockOnFull:
          map['AutoLockOnFull'] ?? map['auto_lock_on_full'] ?? false,
      vibeTags: List<String>.from(map['VibeTags'] ?? map['vibe_tags'] ?? []),
      rules: List<String>.from(map['Rules'] ?? map['rules'] ?? []),
      rotationPool:
          (map['RotationPool'] ??
                  map['rotation_pool'] ??
                  map['RotationPool']) !=
              null
          ? Crowdfunding.fromMap(map['RotationPool'] ?? map['rotation_pool'])
          : null,
      chatRoomId: map['ChatRoomID'] ?? map['chat_room_id'] ?? '',
      createdAt: (map['CreatedAt'] ?? map['created_at']) != null
          ? DateTime.parse(map['CreatedAt'] ?? map['created_at'])
          : null,
      updatedAt: (map['UpdatedAt'] ?? map['updated_at']) != null
          ? DateTime.parse(map['UpdatedAt'] ?? map['updated_at'])
          : null,
      thumbnail: map['Thumbnail'] ?? map['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'HostID': hostId,
      'Title': title,
      'Description': description,
      'PartyPhotos': partyPhotos,
      'StartTime': startTime.toIso8601String(),
      'DurationHours': durationHours,
      'Status': status.toString().split('.').last,
      'IsLocationRevealed': isLocationRevealed,
      'Address': address,
      'City': city,
      'GeoLat': geoLat,
      'GeoLon': geoLon,
      'MaxCapacity': maxCapacity,
      'CurrentGuestCount': currentGuestCount,
      'AutoLockOnFull': autoLockOnFull,
      'VibeTags': vibeTags,
      'Rules': rules,
      'RotationPool': rotationPool?.toMap(),
      'ChatRoomID': chatRoomId,
      'Thumbnail': thumbnail,
    };
  }
}

class ChatRoom {
  final String id;
  final String partyId;
  final String hostId;
  final String title;
  final String imageUrl;
  final bool isGroup;
  final List<String> participantIds;
  final bool isActive;
  final List<ChatMessage> recentMessages;
  final String lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.partyId,
    required this.hostId,
    this.title = '',
    this.imageUrl = '',
    this.isGroup = true,
    this.participantIds = const [],
    this.isActive = true,
    this.recentMessages = const [],
    this.lastMessageContent = '',
    this.lastMessageAt,
    this.unreadCount = 0,
    this.startTime,
  });

  final DateTime? startTime;

  ChatRoom copyWith({
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int? unreadCount,
    List<ChatMessage>? recentMessages,
  }) {
    return ChatRoom(
      id: id,
      partyId: partyId,
      hostId: hostId,
      title: title,
      imageUrl: imageUrl,
      isGroup: isGroup,
      participantIds: participantIds,
      isActive: isActive,
      recentMessages: recentMessages ?? this.recentMessages,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      startTime: startTime ?? this.startTime,
    );
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['ID'] ?? map['id'] ?? '',
      partyId: map['PartyID'] ?? map['party_id'] ?? '',
      hostId: map['HostID'] ?? map['host_id'] ?? '',
      title: map['Title'] ?? map['title'] ?? '',
      imageUrl: map['ImageUrl'] ?? map['image_url'] ?? '',
      isGroup: map['IsGroup'] ?? map['is_group'] ?? true,
      participantIds: List<String>.from(
        map['ParticipantIDs'] ?? map['participant_ids'] ?? [],
      ),
      isActive: map['IsActive'] ?? map['is_active'] ?? true,
      recentMessages: _parseRecentMessages(
        map['RecentMessages'] ?? map['recent_messages'],
      ),
      lastMessageContent:
          map['LastMessageContent'] ?? map['last_message_content'] ?? '',
      lastMessageAt: (map['LastMessageAt'] ?? map['last_message_at']) != null
          ? DateTime.parse(map['LastMessageAt'] ?? map['last_message_at'])
          : null,
      unreadCount: map['UnreadCount'] ?? map['unread_count'] ?? 0,
      startTime:
          (map['StartTime'] ??
                  map['start_time'] ??
                  map['PartyStartTime'] ??
                  map['party_start_time']) !=
              null
          ? DateTime.parse(
              map['StartTime'] ??
                  map['start_time'] ??
                  map['PartyStartTime'] ??
                  map['party_start_time'],
            )
          : null,
    );
  }

  static List<ChatMessage> _parseRecentMessages(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    try {
      return data
          .map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String content;
  final String mediaUrl;
  final String thumbnailUrl;
  final Map<String, dynamic> metadata;
  final String replyToId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl = '',
    this.thumbnailUrl = '',
    this.metadata = const {},
    this.replyToId = '',
    required this.createdAt,
    this.senderName = '',
    this.senderThumbnail = '',
  });

  final String senderName;
  final String senderThumbnail;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['ID'] ?? map['id'] ?? '',
      chatId: map['ChatID'] ?? map['chat_id'] ?? '',
      senderId: map['SenderID'] ?? map['sender_id'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['Type'] ?? map['type']),
        orElse: () => MessageType.TEXT,
      ),
      content: map['Content'] ?? map['content'] ?? '',
      mediaUrl: map['MediaURL'] ?? map['media_url'] ?? '',
      thumbnailUrl: map['ThumbnailURL'] ?? map['thumbnail_url'] ?? '',
      metadata: Map<String, dynamic>.from(
        map['Metadata'] ?? map['metadata'] ?? {},
      ),
      replyToId: map['ReplyToID'] ?? map['reply_to_id'] ?? '',
      createdAt: DateTime.parse(map['CreatedAt'] ?? map['created_at']),
      senderName: map['SenderName'] ?? map['sender_name'] ?? '',
      senderThumbnail: map['SenderThumbnail'] ?? map['sender_thumbnail'] ?? '',
    );
  }
}

class Crowdfunding {
  final String id;
  final String partyId;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final List<Contribution> contributors;
  final bool isFunded;

  const Crowdfunding({
    required this.id,
    this.partyId = '',
    required this.targetAmount,
    required this.currentAmount,
    this.currency = 'USD',
    this.contributors = const [],
    this.isFunded = false,
  });

  factory Crowdfunding.fromMap(Map<String, dynamic> map) {
    return Crowdfunding(
      id: map['ID'] ?? '',
      partyId: map['PartyID'] ?? '',
      targetAmount: (map['TargetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['CurrentAmount'] ?? 0.0).toDouble(),
      currency: map['Currency'] ?? 'USD',
      contributors: (map['Contributors'] as List? ?? [])
          .map((c) => Contribution.fromMap(c))
          .toList(),
      isFunded: map['IsFunded'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'PartyID': partyId,
      'TargetAmount': targetAmount,
      'CurrentAmount': currentAmount,
      'Currency': currency,
      'IsFunded': isFunded,
    };
  }
}

class Contribution {
  final String userId;
  final double amount;
  final DateTime paidAt;

  const Contribution({
    required this.userId,
    required this.amount,
    required this.paidAt,
  });

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      userId: map['UserID'] ?? '',
      amount: (map['Amount'] ?? 0.0).toDouble(),
      paidAt: DateTime.parse(map['PaidAt']),
    );
  }
}

class PartyApplication {
  final String partyId;
  final String userId;
  final ApplicantStatus status;
  final DateTime appliedAt;
  final User? user; // Optional: include user details for UI

  const PartyApplication({
    required this.partyId,
    required this.userId,
    required this.status,
    required this.appliedAt,
    this.user,
  });

  factory PartyApplication.fromMap(Map<String, dynamic> map) {
    return PartyApplication(
      partyId: map['PartyID'] ?? '',
      userId: map['UserID'] ?? '',
      status: ApplicantStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['Status'],
        orElse: () => ApplicantStatus.PENDING,
      ),
      appliedAt: DateTime.parse(map['AppliedAt']),
      user: map['User'] != null ? User.fromMap(map['User']) : null,
    );
  }
}

@immutable
class DraftParty {
  final String title;
  final String description;
  final String city;
  final String address;
  final List<String> photos;
  final double capacity;
  final bool autoLock;
  final bool hasPool;
  final String poolAmount;
  final List<String> selectedTags;
  final String partyType;
  final List<String> rules;
  final double? geoLat;
  final double? geoLon;
  final DateTime? date;
  final int? hour;
  final int? minute;
  final double durationHours;

  const DraftParty({
    this.title = '',
    this.description = '',
    this.city = '',
    this.address = '',
    this.photos = const [],
    this.capacity = 10,
    this.autoLock = true,
    this.hasPool = false,
    this.poolAmount = '',
    this.selectedTags = const [],
    this.partyType = '',
    this.rules = const [],
    this.geoLat,
    this.geoLon,
    this.date,
    this.hour,
    this.minute,
    this.durationHours = 6,
    this.thumbnail = '',
  });

  final String thumbnail;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'city': city,
      'address': address,
      'photos': photos,
      'capacity': capacity,
      'autoLock': autoLock,
      'hasPool': hasPool,
      'poolAmount': poolAmount,
      'selectedTags': selectedTags,
      'partyType': partyType,
      'rules': rules,
      'geoLat': geoLat,
      'geoLon': geoLon,
      'date': date?.toIso8601String(),
      'hour': hour,
      'minute': minute,
      'durationHours': durationHours,
      'thumbnail': thumbnail,
    };
  }

  factory DraftParty.fromMap(Map<String, dynamic> map) {
    return DraftParty(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      capacity: (map['capacity'] ?? 10.0).toDouble(),
      autoLock: map['autoLock'] ?? true,
      hasPool: map['hasPool'] ?? false,
      poolAmount: map['poolAmount'] ?? '',
      selectedTags: List<String>.from(map['selectedTags'] ?? []),
      partyType: map['partyType'] ?? '',
      rules: List<String>.from(map['rules'] ?? []),
      geoLat: map['geoLat'],
      geoLon: map['geoLon'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      hour: map['hour'],
      minute: map['minute'],
      durationHours: (map['durationHours'] ?? 6.0).toDouble(),
      thumbnail: map['thumbnail'] ?? '',
    );
  }

  DraftParty copyWith({
    String? title,
    String? description,
    String? city,
    String? address,
    List<String>? photos,
    double? capacity,
    bool? autoLock,
    bool? hasPool,
    String? poolAmount,
    List<String>? selectedTags,
    String? partyType,
    List<String>? rules,
    double? geoLat,
    double? geoLon,
    DateTime? date,
    int? hour,
    int? minute,
    double? durationHours,
    String? thumbnail,
  }) {
    return DraftParty(
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      photos: photos ?? this.photos,
      capacity: capacity ?? this.capacity,
      autoLock: autoLock ?? this.autoLock,
      hasPool: hasPool ?? this.hasPool,
      poolAmount: poolAmount ?? this.poolAmount,
      selectedTags: selectedTags ?? this.selectedTags,
      partyType: partyType ?? this.partyType,
      rules: rules ?? this.rules,
      geoLat: geoLat ?? this.geoLat,
      geoLon: geoLon ?? this.geoLon,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      durationHours: durationHours ?? this.durationHours,
    );
  }
}
