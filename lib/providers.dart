import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'models.dart';

class AuthNotifier extends Notifier<User?> {
  static const String apiBase = "https://waterparty.onrender.com";
  Database? _db;

  @override
  User? build() {
    _initAndLoadSession();
    return null;
  }

  Future<void> _initAndLoadSession() async {
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
        state = User.fromMap(jsonDecode(maps.first['user_json']));
      } catch (e) {
        await _db!.delete('session');
      }
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
    final response = await http.post(
      Uri.parse("$apiBase/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "password": password,
        ...user.toMap(),
      }),
    );

    if (response.statusCode == 200) {
      final loggedInUser = User.fromMap(jsonDecode(response.body));
      state = loggedInUser;
      await _saveSession(loggedInUser);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? "Registration failed");
    }
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$apiBase/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final loggedInUser = User.fromMap(jsonDecode(response.body));
      state = loggedInUser;
      await _saveSession(loggedInUser);
    } else {
      throw Exception("Invalid credentials");
    }
  }

  void logout() async {
    if (_db != null) await _db!.delete('session');
    state = null;
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
    if (state == null) return;
    state = state!.copyWith(realName: realName, bio: bio, profilePhotos: profilePhotos);
    await _saveSession(state!);
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

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
