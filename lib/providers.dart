import 'dart:convert';
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
    return _initAndLoadSession();
  }

  Future<User?> _initAndLoadSession() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'waterparty.db');

    _db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE session (id INTEGER PRIMARY KEY, user_json TEXT)');
    });

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
        body: jsonEncode({
          "password": password,
          "user": user.toMap(),
        }),
      );

      if (response.statusCode == 200) {
        final loggedInUser = User.fromMap(jsonDecode(response.body));
        state = AsyncValue.data(loggedInUser);
        await _saveSession(loggedInUser);
      } else {
        String errorMsg = "Registration failed";
        try {
          if (response.headers['content-type']?.contains('application/json') ?? false) {
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
          if (response.headers['content-type']?.contains('application/json') ?? false) {
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

  Future<String> uploadImage(List<int> bytes, String mime) async {
    final uri = Uri.parse("$apiBase/upload");
    final request = http.MultipartRequest("POST", uri)
      ..files.add(http.MultipartFile.fromBytes("file", bytes, contentType: MediaType.parse(mime), filename: "upload.jpg"));
    
    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      return data['hash'];
    }
    throw Exception("Upload failed");
  }

  Future<void> updateUserProfile({String? realName, String? bio, List<String>? profilePhotos}) async {
    if (state.value == null) return;
    final newUser = state.value!.copyWith(realName: realName, bio: bio, profilePhotos: profilePhotos);
    state = AsyncValue.data(newUser);
    await _saveSession(newUser);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

// --- CHAT SYSTEM ---

class ChatNotifier extends Notifier<List<ChatRoom>> {
  @override
  List<ChatRoom> build() {
    return [];
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
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatRoom>>(ChatNotifier.new);

// --- LOCATION SYSTEM ---

class UserLocation {
  final double lat;
  final double lon;
  final DateTime timestamp;
  const UserLocation({required this.lat, required this.lon, required this.timestamp});

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

final locationProvider = AsyncNotifierProvider<LocationNotifier, UserLocation?>(LocationNotifier.new);

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);

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
}

final partyFeedProvider = NotifierProvider<PartyFeedNotifier, List<Party>>(PartyFeedNotifier.new);

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
          app
    ];
  }
}

final partyApplicantsProvider = NotifierProvider<PartyApplicantsNotifier, List<PartyApplication>>(PartyApplicantsNotifier.new);
