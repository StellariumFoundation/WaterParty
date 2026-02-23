import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'models.dart';
import 'constants.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  static const String apiBase = AppConstants.apiBase;
  Database? _db;

  @override
  Future<User?> build() async {
    final localUser = await _initAndLoadSession();
    if (localUser != null) {
      // Trigger background refresh
      Future.microtask(() => refreshProfile(localUser.id));
      return localUser;
    }
    return null;
  }

  Future<User?> _initAndLoadSession() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'waterparty.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE session (id INTEGER PRIMARY KEY, user_json TEXT)',
        );
      },
    );

    final List<Map<String, dynamic>> maps = await _db!.query('session');
    if (maps.isNotEmpty) {
      try {
        return User.fromMap(jsonDecode(maps.first['user_json']));
      } catch (e) {
        await _db!.delete('session');
      }
    }
    return null;
  }

  Future<void> refreshProfile(String id) async {
    try {
      final response = await http.get(Uri.parse("$apiBase/profile?id=$id"));
      if (response.statusCode == 200) {
        final serverUser = User.fromMap(jsonDecode(response.body));
        state = AsyncValue.data(serverUser);
        await _saveSession(serverUser);
      }
    } catch (e) {
      // Keep local data if refresh fails
      debugPrint("Profile refresh failed: $e");
    }
  }

  Future<void> _saveSession(User user) async {
    if (_db == null) return;
    await _db!.delete('session'); // Clear old session
    await _db!.insert('session', {
      'id': 1,
      'user_json': jsonEncode(user.toMap()),
    });
  }

  Future<void> register(User user, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"password": password, "user": user.toMap()}),
      );

      if (response.statusCode == 200) {
        final loggedInUser = User.fromMap(jsonDecode(response.body));
        state = AsyncValue.data(loggedInUser);
        await _saveSession(loggedInUser);
      } else {
        String errorMsg = "Registration failed";
        try {
          if (response.headers['content-type']?.contains('application/json') ??
              false) {
            final error = jsonDecode(response.body);
            errorMsg = error['error'] ?? errorMsg;
          } else {
            errorMsg = response.body;
          }
        } catch (_) {
          errorMsg = "Server error (${response.statusCode})";
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final loggedInUser = User.fromMap(jsonDecode(response.body));
        state = AsyncValue.data(loggedInUser);
        await _saveSession(loggedInUser);
      } else {
        String errorMsg = "Invalid credentials";
        try {
          if (response.headers['content-type']?.contains('application/json') ??
              false) {
            final error = jsonDecode(response.body);
            errorMsg = error['error'] ?? errorMsg;
          } else {
            errorMsg = response.body;
          }
        } catch (_) {
          errorMsg = "Login failed (${response.statusCode})";
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      rethrow;
    }
  }

  void logout() async {
    if (_db != null) await _db!.delete('session');
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    final user = state.value;
    if (user == null) return;

    try {
      final response = await http.delete(
        Uri.parse("$apiBase/profile?id=${user.id}"),
      );

      if (response.statusCode == 200) {
        logout();
      } else {
        throw Exception("Failed to delete account");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> uploadImage(
    List<int> bytes,
    String mime, {
    bool thumbnail = false,
  }) async {
    final uri = Uri.parse(
      "$apiBase/upload${thumbnail ? '?thumbnail=true' : ''}",
    );
    final request = http.MultipartRequest("POST", uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          contentType: MediaType.parse(mime),
          filename: "upload.jpg",
        ),
      );

    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      return Map<String, String>.from(data);
    }
    throw Exception("Upload failed");
  }

  Future<void> updateUserProfile(User updatedUser) async {
    state = AsyncValue.data(updatedUser);
    await _saveSession(updatedUser);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

// --- CHAT SYSTEM ---

class ChatNotifier extends Notifier<List<ChatRoom>> {
  @override
  List<ChatRoom> build() {
    return [];
  }

  void setRooms(List<ChatRoom> rooms) {
    state = rooms;
  }

  void addRoom(ChatRoom room) {
    if (!state.any((r) => r.id == room.id)) {
      state = [room, ...state];
    }
  }

  void updateRoomWithNewMessage(ChatMessage msg) {
    state = [
      for (final room in state)
        if (room.id == msg.chatId)
          room.copyWith(
            lastMessageContent: msg.content,
            lastMessageAt: msg.createdAt,
            recentMessages: [...room.recentMessages, msg],
          )
        else
          room,
    ];
    // Sort by latest message
    state.sort((a, b) {
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });
  }

  void removeRoom(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatRoom>>(
  ChatNotifier.new,
);

// --- LOCATION SYSTEM ---

class UserLocation {
  final double lat;
  final double lon;
  final DateTime timestamp;
  const UserLocation({
    required this.lat,
    required this.lon,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lon': lon,
    'ts': timestamp.toIso8601String(),
  };

  factory UserLocation.fromMap(Map<String, dynamic> map) => UserLocation(
    lat: map['lat'],
    lon: map['lon'],
    timestamp: DateTime.parse(map['ts']),
  );
}

class LocationNotifier extends AsyncNotifier<UserLocation?> {
  @override
  Future<UserLocation?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('last_location');
    if (data != null) {
      return UserLocation.fromMap(jsonDecode(data));
    }
    return null;
  }

  Future<void> updateLocation(double lat, double lon) async {
    final loc = UserLocation(lat: lat, lon: lon, timestamp: DateTime.now());
    state = AsyncValue.data(loc);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_location', jsonEncode(loc.toMap()));
  }
}

final locationProvider = AsyncNotifierProvider<LocationNotifier, UserLocation?>(
  LocationNotifier.new,
);

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);

class PartyFeedNotifier extends Notifier<List<Party>> {
  final Set<String> _swipedIds = {};

  @override
  List<Party> build() => [];

  void setParties(List<Party> parties) {
    state = parties.where((p) => !_swipedIds.contains(p.id)).toList();
  }

  void addParty(Party party) {
    if (!_swipedIds.contains(party.id)) {
      state = [...state, party];
    }
  }

  void markAsSwiped(String id) {
    _swipedIds.add(id);
    state = state.where((p) => p.id != id).toList();
  }

  void removeParty(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final partyFeedProvider = NotifierProvider<PartyFeedNotifier, List<Party>>(
  PartyFeedNotifier.new,
);

class PartyApplicantsNotifier extends Notifier<List<PartyApplication>> {
  @override
  List<PartyApplication> build() => [];

  void setApplicants(List<PartyApplication> apps) => state = apps;

  void updateStatus(String userId, ApplicantStatus status) {
    state = [
      for (final app in state)
        if (app.userId == userId)
          PartyApplication(
            partyId: app.partyId,
            userId: app.userId,
            status: status,
            appliedAt: app.appliedAt,
            user: app.user,
          )
        else
          app,
    ];
  }
}

final partyApplicantsProvider =
    NotifierProvider<PartyApplicantsNotifier, List<PartyApplication>>(
      PartyApplicantsNotifier.new,
    );

class DraftPartyNotifier extends Notifier<DraftParty> {
  static const String _key = 'draft_party';

  @override
  DraftParty build() {
    _loadFromPrefs();
    return const DraftParty();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      state = DraftParty.fromMap(jsonDecode(json));
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toMap()));
  }

  void update(DraftParty draft) {
    state = draft;
    _saveToPrefs();
  }

  void clear() {
    state = const DraftParty();
    _saveToPrefs();
  }
}

final draftPartyProvider = NotifierProvider<DraftPartyNotifier, DraftParty>(
  DraftPartyNotifier.new,
);

enum CreationStatus { idle, loading, success, error }

class PartyCreationState {
  final CreationStatus status;
  final String? errorMessage;
  final String? createdPartyId;

  const PartyCreationState({
    this.status = CreationStatus.idle,
    this.errorMessage,
    this.createdPartyId,
  });
}

class PartyCreationNotifier extends Notifier<PartyCreationState> {
  @override
  PartyCreationState build() => const PartyCreationState();

  void setLoading() =>
      state = const PartyCreationState(status: CreationStatus.loading);

  void setSuccess(String id) => state = PartyCreationState(
    status: CreationStatus.success,
    createdPartyId: id,
  );

  void setError(String message) => state = PartyCreationState(
    status: CreationStatus.error,
    errorMessage: message,
  );

  void reset() => state = const PartyCreationState();
}

final partyCreationProvider =
    NotifierProvider<PartyCreationNotifier, PartyCreationState>(
      PartyCreationNotifier.new,
    );
