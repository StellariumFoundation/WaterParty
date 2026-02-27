import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'constants.dart';

// ============================================
// CACHE CONFIGURATION & KEYS
// ============================================

/// Cache keys for all providers to ensure consistency
class CacheKeys {
  CacheKeys._();

  // Auth & User
  static const String userSession = 'cache_user_session';
  static const String userProfile = 'cache_user_profile';
  static const String lastLocation = 'cache_last_location';

  // Parties
  static const String partyFeed = 'cache_party_feed';
  static const String myParties = 'cache_my_parties';
  static const String partiesAround = 'cache_parties_around';
  static const String partyCache = 'cache_party_map';
  static const String draftParty = 'cache_draft_party';

  // Chat & Messaging
  static const String chatRooms = 'cache_chat_rooms';
  static const String chatHistory = 'cache_chat_history';
  static const String dmConversations = 'cache_dm_conversations';
  static const String dmHistory = 'cache_dm_history';

  // Social
  static const String notifications = 'cache_notifications';
  static const String blockedUsers = 'cache_blocked_users';
  static const String matchedUsers = 'cache_matched_users';

  // Metadata
  static const String cacheMetadata = 'cache_metadata';
  static const String providerVersions = 'cache_provider_versions';
}

/// Cache metadata for tracking sync state
class CacheMetadata {
  final DateTime lastSyncAt;
  final DateTime lastWriteAt;
  final int version;
  final String? syncError;
  final int syncAttempts;

  const CacheMetadata({
    required this.lastSyncAt,
    required this.lastWriteAt,
    this.version = 1,
    this.syncError,
    this.syncAttempts = 0,
  });

  factory CacheMetadata.fromMap(Map<String, dynamic> map) {
    return CacheMetadata(
      lastSyncAt: DateTime.parse(map['lastSyncAt']),
      lastWriteAt: DateTime.parse(map['lastWriteAt']),
      version: map['version'] ?? 1,
      syncError: map['syncError'],
      syncAttempts: map['syncAttempts'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'lastSyncAt': lastSyncAt.toIso8601String(),
    'lastWriteAt': lastWriteAt.toIso8601String(),
    'version': version,
    'syncError': syncError,
    'syncAttempts': syncAttempts,
  };

  CacheMetadata copyWith({
    DateTime? lastSyncAt,
    DateTime? lastWriteAt,
    int? version,
    String? syncError,
    int? syncAttempts,
  }) => CacheMetadata(
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastWriteAt: lastWriteAt ?? this.lastWriteAt,
    version: version ?? this.version,
    syncError: syncError,
    syncAttempts: syncAttempts ?? this.syncAttempts,
  );
}

// ============================================
// CACHE MANAGER
// ============================================

/// Centralized cache manager for SharedPreferences operations
class CacheManager {
  static SharedPreferences? _prefs;
  static final Map<String, CacheMetadata> _metadataCache = {};
  static final _metadataController = StreamController<String>.broadcast();

  static Stream<String> get metadataStream => _metadataController.stream;

  /// Initialize the cache manager
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadMetadataCache();
  }

  /// Load metadata cache into memory
  static Future<void> _loadMetadataCache() async {
    final metadataJson = _prefs?.getString(CacheKeys.cacheMetadata);
    if (metadataJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(metadataJson);
        for (final entry in data.entries) {
          _metadataCache[entry.key] = CacheMetadata.fromMap(entry.value);
        }
      } catch (e) {
        debugPrint('[CacheManager] Error loading metadata: $e');
      }
    }
  }

  /// Persist metadata cache
  static Future<void> _saveMetadataCache() async {
    final data = <String, dynamic>{
      for (final entry in _metadataCache.entries)
        entry.key: entry.value.toMap(),
    };
    await _prefs?.setString(CacheKeys.cacheMetadata, jsonEncode(data));
  }

  /// Get metadata for a specific key
  static CacheMetadata? getMetadata(String key) => _metadataCache[key];

  /// Update metadata for a specific key
  static Future<void> updateMetadata(
    String key, {
    DateTime? lastSyncAt,
    String? syncError,
    bool incrementVersion = false,
    bool incrementAttempts = false,
    bool clearAttempts = false,
  }) async {
    final existing = _metadataCache[key];
    final now = DateTime.now();

    _metadataCache[key] = CacheMetadata(
      lastSyncAt: lastSyncAt ?? existing?.lastSyncAt ?? now,
      lastWriteAt: now,
      version: incrementVersion
          ? (existing?.version ?? 0) + 1
          : (existing?.version ?? 1),
      syncError: syncError,
      syncAttempts: clearAttempts
          ? 0
          : incrementAttempts
          ? (existing?.syncAttempts ?? 0) + 1
          : existing?.syncAttempts ?? 0,
    );

    await _saveMetadataCache();
    _metadataController.add(key);
  }

  /// Generic method to get cached data
  static T? get<T>(String key, T Function(dynamic) fromJson) {
    final json = _prefs?.getString(key);
    if (json == null) return null;
    try {
      return fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('[CacheManager] Error parsing cache for $key: $e');
      return null;
    }
  }

  /// Generic method to cache data
  static Future<bool> set<T>(
    String key,
    T data,
    dynamic Function(T) toJson,
  ) async {
    try {
      final json = jsonEncode(toJson(data));
      final result = await _prefs?.setString(key, json) ?? false;
      if (result) {
        await updateMetadata(key);
      }
      return result;
    } catch (e) {
      debugPrint('[CacheManager] Error caching data for $key: $e');
      return false;
    }
  }

  /// Cache a list of items
  static Future<bool> setList<T>(
    String key,
    List<T> items,
    dynamic Function(T) toJson,
  ) => set<List<T>>(key, items, (list) => list.map(toJson).toList());

  /// Get a cached list
  static List<T>? getList<T>(String key, T Function(dynamic) fromJson) {
    final data = get<List<dynamic>>(key, (json) => json);
    if (data == null) return null;
    try {
      return data.map((item) => fromJson(item)).toList();
    } catch (e) {
      debugPrint('[CacheManager] Error parsing list cache for $key: $e');
      return null;
    }
  }

  /// Cache a map
  static Future<bool> setMap<K, V>(
    String key,
    Map<K, V> map,
    dynamic Function(V) valueToJson,
  ) => set<Map<K, V>>(
    key,
    map,
    (m) => m.map((k, v) => MapEntry(k.toString(), valueToJson(v))),
  );

  /// Get a cached map
  static Map<K, V>? getMap<K, V>(
    String key,
    K Function(String) keyFromString,
    V Function(dynamic) valueFromJson,
  ) {
    final data = get<Map<String, dynamic>>(key, (json) => json);
    if (data == null) return null;
    try {
      return data.map((k, v) => MapEntry(keyFromString(k), valueFromJson(v)));
    } catch (e) {
      debugPrint('[CacheManager] Error parsing map cache for $key: $e');
      return null;
    }
  }

  /// Remove cached data
  static Future<bool> remove(String key) async {
    _metadataCache.remove(key);
    await _saveMetadataCache();
    return await _prefs?.remove(key) ?? false;
  }

  /// Clear all cached data
  static Future<void> clear() async {
    _metadataCache.clear();
    await _prefs?.remove(CacheKeys.cacheMetadata);
  }

  /// Check if cache is stale (older than specified duration)
  static bool isStale(String key, Duration maxAge) {
    final metadata = _metadataCache[key];
    if (metadata == null) return true;
    return DateTime.now().difference(metadata.lastSyncAt) > maxAge;
  }

  /// Get cache age
  static Duration? getCacheAge(String key) {
    final metadata = _metadataCache[key];
    if (metadata == null) return null;
    return DateTime.now().difference(metadata.lastSyncAt);
  }
}

// ============================================
// STATE SYNCHRONIZER
// ============================================

/// Result of a synchronization operation
class SyncResult<T> {
  final T? data;
  final bool fromCache;
  final bool fromServer;
  final String? error;
  final DateTime? serverTimestamp;

  const SyncResult({
    this.data,
    required this.fromCache,
    required this.fromServer,
    this.error,
    this.serverTimestamp,
  });

  bool get isSuccess => error == null;
  bool get isPartial => fromCache && !fromServer;
}

/// Handles bidirectional synchronization between cache and server
class StateSynchronizer {
  /// Load data with cache-first strategy
  static Future<SyncResult<T>> loadWithCacheFirst<T>({
    required String cacheKey,
    required T? Function() getCached,
    required Future<T> Function() fetchFromServer,
    required Future<void> Function(T data) updateCache,
    required void Function(T data) updateState,
    Duration staleThreshold = const Duration(minutes: 5),
    int maxRetries = 3,
  }) async {
    T? cachedData = getCached();
    final isStale = CacheManager.isStale(cacheKey, staleThreshold);

    // Emit cached data immediately if available
    if (cachedData != null && !isStale) {
      updateState(cachedData);
      return SyncResult<T>(
        data: cachedData,
        fromCache: true,
        fromServer: false,
      );
    }

    // If stale or no cache, try server with retries
    int attempts = 0;
    String? lastError;

    while (attempts < maxRetries) {
      try {
        final serverData = await fetchFromServer();
        await updateCache(serverData);
        await CacheManager.updateMetadata(
          cacheKey,
          lastSyncAt: DateTime.now(),
          clearAttempts: true,
        );
        updateState(serverData);
        return SyncResult<T>(
          data: serverData,
          fromCache: cachedData != null,
          fromServer: true,
          serverTimestamp: DateTime.now(),
        );
      } catch (e) {
        lastError = e.toString();
        attempts++;
        await CacheManager.updateMetadata(
          cacheKey,
          syncError: lastError,
          incrementAttempts: true,
        );

        if (attempts < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }
    }

    // All retries failed, use stale cache if available
    if (cachedData != null) {
      updateState(cachedData);
      return SyncResult<T>(
        data: cachedData,
        fromCache: true,
        fromServer: false,
        error: 'Server sync failed after $maxRetries attempts: $lastError',
      );
    }

    return SyncResult<T>(
      fromCache: false,
      fromServer: false,
      error: 'No cache available and server sync failed: $lastError',
    );
  }

  /// Merge server data with local state using version-based conflict resolution
  static T mergeWithOptimisticLocking<T>({
    required T localData,
    required T serverData,
    required int localVersion,
    required int serverVersion,
    required T Function(T local, T server) mergeStrategy,
  }) {
    // Server wins if it has a higher version
    if (serverVersion > localVersion) {
      return serverData;
    }
    // If versions are equal, apply custom merge strategy
    if (serverVersion == localVersion) {
      return mergeStrategy(localData, serverData);
    }
    // Local has higher version (shouldn't happen often)
    return localData;
  }

  /// Smart merge for lists - adds new items, updates existing, removes deleted
  static List<T> mergeLists<T>({
    required List<T> local,
    required List<T> remote,
    required String Function(T) getId,
    required T Function(T local, T remote) mergeItem,
    DateTime? localTimestamp,
    DateTime? remoteTimestamp,
  }) {
    final Map<String, T> merged = {};

    // Add all local items
    for (final item in local) {
      merged[getId(item)] = item;
    }

    // Merge remote items
    for (final remoteItem in remote) {
      final id = getId(remoteItem);
      if (merged.containsKey(id)) {
        merged[id] = mergeItem(merged[id]!, remoteItem);
      } else {
        merged[id] = remoteItem;
      }
    }

    return merged.values.toList();
  }
}

// ============================================
// BASE CACHED NOTIFIER CLASSES
// ============================================

/// Mixin for cache-enabled notifiers
mixin CacheableNotifierMixin<T> {
  String get cacheKey;
  Duration get staleThreshold => const Duration(minutes: 5);
  int get maxRetries => 3;

  /// Serialize state to JSON
  dynamic serialize(T state);

  /// Deserialize state from JSON
  T deserialize(dynamic json);

  /// Save state to cache
  Future<void> persistState(T state) async {
    await CacheManager.set<T>(cacheKey, state, serialize);
  }

  /// Load state from cache
  T? loadFromCache() => CacheManager.get<T>(cacheKey, deserialize);

  /// Check if cache is stale
  bool get isCacheStale => CacheManager.isStale(cacheKey, staleThreshold);

  /// Get cache metadata
  CacheMetadata? get cacheMetadata => CacheManager.getMetadata(cacheKey);
}

/// Base class for cached synchronous notifiers
abstract class CachedNotifier<T> extends Notifier<T>
    with CacheableNotifierMixin<T> {
  bool _isHydrated = false;

  bool get isHydrated => _isHydrated;

  @override
  T build() {
    _hydrateFromCache();
    return buildInitial();
  }

  /// Build the initial state before hydration
  T buildInitial();

  /// Hydrate state from cache asynchronously
  Future<void> _hydrateFromCache() async {
    if (_isHydrated) return;

    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
    _isHydrated = true;

    // Trigger background sync
    Future.microtask(() => syncWithServer());
  }

  /// Sync with server - implement in subclasses
  Future<void> syncWithServer();

  /// Update state and persist to cache
  void setStateAndPersist(T newState) {
    state = newState;
    persistState(newState);
  }
}

/// Base class for cached asynchronous notifiers
abstract class CachedAsyncNotifier<T> extends AsyncNotifier<T>
    with CacheableNotifierMixin<T> {
  bool _cacheHydrated = false;

  bool get cacheHydrated => _cacheHydrated;

  @override
  Future<T> build() async {
    return await buildWithCache();
  }

  /// Build state with cache-first strategy
  Future<T> buildWithCache() async {
    // First try to load from cache
    final cached = loadFromCache();

    if (cached != null && !isCacheStale) {
      _cacheHydrated = true;
      // Return cached data immediately
      // Background sync will happen after
      Future.microtask(() => _backgroundSync());
      return cached;
    }

    // Cache miss or stale - fetch from server
    try {
      final serverData = await fetchFromServer();
      await persistState(serverData);
      await CacheManager.updateMetadata(
        cacheKey,
        lastSyncAt: DateTime.now(),
        clearAttempts: true,
      );
      _cacheHydrated = true;
      return serverData;
    } catch (e) {
      // Server fetch failed - use stale cache if available
      if (cached != null) {
        await CacheManager.updateMetadata(
          cacheKey,
          syncError: e.toString(),
          incrementAttempts: true,
        );
        _cacheHydrated = true;
        return cached;
      }
      rethrow;
    }
  }

  /// Fetch fresh data from server - implement in subclasses
  Future<T> fetchFromServer();

  /// Background sync to refresh stale data
  Future<void> _backgroundSync() async {
    if (!isCacheStale) return;

    try {
      final serverData = await fetchFromServer();
      final currentData = state.value;

      if (currentData != null) {
        final merged = mergeWithServer(currentData, serverData);
        state = AsyncValue.data(merged);
        await persistState(merged);
      } else {
        state = AsyncValue.data(serverData);
        await persistState(serverData);
      }

      await CacheManager.updateMetadata(
        cacheKey,
        lastSyncAt: DateTime.now(),
        clearAttempts: true,
      );
    } catch (e) {
      await CacheManager.updateMetadata(
        cacheKey,
        syncError: e.toString(),
        incrementAttempts: true,
      );
    }
  }

  /// Merge local state with server data - override for custom merge logic
  T mergeWithServer(T local, T server) => server;

  /// Force a refresh from server
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final serverData = await fetchFromServer();
      state = AsyncValue.data(serverData);
      await persistState(serverData);
      await CacheManager.updateMetadata(
        cacheKey,
        lastSyncAt: DateTime.now(),
        clearAttempts: true,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ============================================
// AUTHENTICATION SYSTEM
// ============================================

class AuthNotifier extends AsyncNotifier<User?> {
  static const String apiBase = AppConstants.apiBase;
  static const String _sessionKey = 'auth_user_session';

  @override
  Future<User?> build() async {
    // Initialize cache manager first
    await CacheManager.initialize();
    return await _initAndLoadSession();
  }

  Future<User?> _initAndLoadSession() async {
    // Try to load from SharedPreferences cache first
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_sessionKey);

    if (userJson != null) {
      try {
        final cachedUser = User.fromMap(jsonDecode(userJson));

        // Trigger background refresh from server
        Future.microtask(() => refreshProfile(cachedUser.id));
        return cachedUser;
      } catch (e) {
        // Invalid cached data, clear it
        await prefs.remove(_sessionKey);
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
        await CacheManager.updateMetadata(
          CacheKeys.userProfile,
          lastSyncAt: DateTime.now(),
          clearAttempts: true,
        );
      }
    } catch (e) {
      debugPrint("Profile refresh failed: $e");
      await CacheManager.updateMetadata(
        CacheKeys.userProfile,
        syncError: e.toString(),
        incrementAttempts: true,
      );
    }
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toMap()));
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

  Future<void> logout() async {
    debugPrint('[logout] Starting logout process');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    debugPrint('[logout] Session deleted from SharedPreferences');

    // Clear all user-specific cached data
    ref.read(myPartiesProvider.notifier).clear();
    ref.read(chatProvider.notifier).clear();
    ref.read(chatHistoryProvider.notifier).clear();
    ref.read(dmHistoryProvider.notifier).clear();
    ref.read(dmConversationsProvider.notifier).clear();
    ref.read(notificationsProvider.notifier).clear();
    ref.read(partyFeedProvider.notifier).clear();
    ref.read(partiesAroundProvider.notifier).clear();
    ref.read(matchedUsersProvider.notifier).clear();
    ref.read(blockedUsersProvider.notifier).clear();
    ref.read(partyCacheProvider.notifier).clear();
    debugPrint('[logout] All user-specific caches cleared');

    state = const AsyncValue.data(null);
    debugPrint('[logout] Auth state set to null');
  }

  Future<void> deleteAccount() async {
    final user = state.value;
    if (user == null) return;

    try {
      debugPrint('[deleteAccount] Attempting to delete user: ${user.id}');
      final response = await http.delete(
        Uri.parse("$apiBase/profile?id=${user.id}"),
      );

      debugPrint('[deleteAccount] Response status: ${response.statusCode}');
      debugPrint('[deleteAccount] Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('[deleteAccount] Deletion successful, calling logout');
        await logout();
      } else {
        debugPrint(
          '[deleteAccount] Deletion failed with status: ${response.statusCode}',
        );
        throw Exception("Failed to delete account: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('[deleteAccount] Exception: $e');
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
      final hash = data['hash'] as String;
      final thumbnailHash = data['thumbnailHash'] as String?;

      final imageUrl = "$apiBase/assets/$hash";
      final result = <String, String>{'hash': hash, 'url': imageUrl};

      if (thumbnailHash != null) {
        result['thumbnailHash'] = thumbnailHash;
        result['thumbnailUrl'] = "$apiBase/assets/$thumbnailHash";
      }

      return result;
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

// ============================================
// CHAT SYSTEM - With Cache
// ============================================

class ChatNotifier extends Notifier<List<ChatRoom>>
    with CacheableNotifierMixin<List<ChatRoom>> {
  @override
  String get cacheKey => CacheKeys.chatRooms;

  @override
  Duration get staleThreshold => const Duration(minutes: 2);

  @override
  dynamic serialize(List<ChatRoom> state) =>
      state.map((r) => r.toMap()).toList();

  @override
  List<ChatRoom> deserialize(dynamic json) =>
      (json as List).map((e) => ChatRoom.fromMap(e)).toList();

  @override
  List<ChatRoom> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Server sync is handled by the SocketService
    // This is a placeholder for manual sync if needed
  }

  void setRooms(List<ChatRoom> rooms) {
    state = rooms;
    persistState(rooms);
  }

  void addRoom(ChatRoom room) {
    if (!state.any((r) => r.id == room.id)) {
      state = [room, ...state];
      persistState(state);
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
    persistState(state);
  }

  void removeRoom(String id) {
    state = state.where((r) => r.id != id).toList();
    persistState(state);
  }

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatRoom>>(
  ChatNotifier.new,
);

// ============================================
// LOCATION SYSTEM - With Cache
// ============================================

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

class LocationNotifier extends AsyncNotifier<UserLocation?>
    with CacheableNotifierMixin<UserLocation?> {
  @override
  String get cacheKey => CacheKeys.lastLocation;

  @override
  Duration get staleThreshold => const Duration(hours: 1);

  @override
  dynamic serialize(UserLocation? state) => state?.toMap();

  @override
  UserLocation? deserialize(dynamic json) =>
      json != null ? UserLocation.fromMap(json) : null;

  @override
  Future<UserLocation?> build() async {
    // Try to load from cache first
    final cached = loadFromCache();
    if (cached != null && !isCacheStale) {
      // Trigger background refresh if stale
      if (isCacheStale) {
        Future.microtask(() => _refreshLocation());
      }
      return cached;
    }
    return null;
  }

  Future<void> _refreshLocation() async {
    // Location is device-specific, no server fetch needed
    // Just update the sync metadata
    await CacheManager.updateMetadata(cacheKey, lastSyncAt: DateTime.now());
  }

  Future<UserLocation?> fetchFromServer() async {
    // Location is device-specific, no server fetch
    return state.value;
  }

  Future<void> updateLocation(double lat, double lon) async {
    final loc = UserLocation(lat: lat, lon: lon, timestamp: DateTime.now());
    state = AsyncValue.data(loc);
    await persistState(loc);
  }
}

final locationProvider = AsyncNotifierProvider<LocationNotifier, UserLocation?>(
  LocationNotifier.new,
);

// ============================================
// NAVIGATION SYSTEM
// ============================================

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);

// ============================================
// PARTY FEED SYSTEM - With Cache
// ============================================

class PartyFeedNotifier extends Notifier<List<Party>>
    with CacheableNotifierMixin<List<Party>> {
  final Set<String> _swipedIds = {};

  @override
  String get cacheKey => CacheKeys.partyFeed;

  @override
  Duration get staleThreshold => const Duration(minutes: 5);

  @override
  dynamic serialize(List<Party> state) => state.map((p) => p.toMap()).toList();

  @override
  List<Party> deserialize(dynamic json) =>
      (json as List).map((e) => Party.fromMap(e)).toList();

  @override
  List<Party> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached.where((p) => !_swipedIds.contains(p.id)).toList();
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setParties(List<Party> parties) {
    state = parties.where((p) => !_swipedIds.contains(p.id)).toList();
    persistState(state);
  }

  void addParty(Party party) {
    if (!_swipedIds.contains(party.id) && !state.any((p) => p.id == party.id)) {
      state = [...state, party];
      persistState(state);
    }
  }

  void markAsSwiped(String id) {
    _swipedIds.add(id);
    state = state.where((p) => p.id != id).toList();
    persistState(state);
  }

  void removeParty(String id) {
    state = state.where((p) => p.id != id).toList();
    persistState(state);
  }

  void clear() {
    state = [];
    _swipedIds.clear();
    CacheManager.remove(cacheKey);
  }
}

final partyFeedProvider = NotifierProvider<PartyFeedNotifier, List<Party>>(
  PartyFeedNotifier.new,
);

// ============================================
// PARTY APPLICANTS SYSTEM
// ============================================

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

  void clear() {
    state = [];
  }
}

final partyApplicantsProvider =
    NotifierProvider<PartyApplicantsNotifier, List<PartyApplication>>(
      PartyApplicantsNotifier.new,
    );

// ============================================
// DRAFT PARTY SYSTEM - With Cache
// ============================================

class DraftPartyNotifier extends Notifier<DraftParty>
    with CacheableNotifierMixin<DraftParty> {
  @override
  String get cacheKey => CacheKeys.draftParty;

  @override
  Duration get staleThreshold => const Duration(days: 7);

  @override
  dynamic serialize(DraftParty state) => state.toMap();

  @override
  DraftParty deserialize(dynamic json) => DraftParty.fromMap(json);

  @override
  DraftParty build() {
    _hydrate();
    return const DraftParty();
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Draft is local-only
  }

  void update(DraftParty draft) {
    state = draft;
    persistState(draft);
  }

  void clear() {
    state = const DraftParty();
    persistState(state);
  }
}

final draftPartyProvider = NotifierProvider<DraftPartyNotifier, DraftParty>(
  DraftPartyNotifier.new,
);

// ============================================
// PARTY CREATION STATUS
// ============================================

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

// ============================================
// PARTY CACHE SYSTEM - With Persistent Cache
// ============================================

class PartyCacheNotifier extends Notifier<Map<String, Party>>
    with CacheableNotifierMixin<Map<String, Party>> {
  @override
  String get cacheKey => CacheKeys.partyCache;

  @override
  Duration get staleThreshold => const Duration(minutes: 10);

  @override
  dynamic serialize(Map<String, Party> state) =>
      state.map((k, v) => MapEntry(k, v.toMap()));

  @override
  Map<String, Party> deserialize(dynamic json) => (json as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, Party.fromMap(v)));

  @override
  Map<String, Party> build() {
    _hydrate();
    return {};
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Individual party updates handled via socket
  }

  void updateParty(Party party) {
    state = {...state, party.id: party};
    persistState(state);
  }

  void updateParties(List<Party> parties) {
    state = {...state, for (final p in parties) p.id: p};
    persistState(state);
  }

  void removeParty(String id) {
    if (state.containsKey(id)) {
      final newState = Map<String, Party>.from(state);
      newState.remove(id);
      state = newState;
      persistState(state);
    }
  }

  Party? getParty(String id) => state[id];

  void clear() {
    state = {};
    CacheManager.remove(cacheKey);
  }
}

final partyCacheProvider =
    NotifierProvider<PartyCacheNotifier, Map<String, Party>>(
      PartyCacheNotifier.new,
    );

// ============================================
// MY PARTIES SYSTEM - With Cache
// ============================================

class MyPartiesNotifier extends Notifier<List<Party>>
    with CacheableNotifierMixin<List<Party>> {
  @override
  String get cacheKey => CacheKeys.myParties;

  @override
  Duration get staleThreshold => const Duration(minutes: 5);

  @override
  dynamic serialize(List<Party> state) => state.map((p) => p.toMap()).toList();

  @override
  List<Party> deserialize(dynamic json) =>
      (json as List).map((e) => Party.fromMap(e)).toList();

  @override
  List<Party> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setParties(List<Party> parties) {
    state = parties;
    persistState(parties);
  }

  void addParty(Party party) {
    final existingIndex = state.indexWhere((p) => p.id == party.id);
    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) party else state[i],
      ];
    } else {
      state = [...state, party];
    }
    persistState(state);
  }

  void removeParty(String partyId) {
    state = state.where((p) => p.id != partyId).toList();
    persistState(state);
  }

  void updateParty(Party party) {
    final index = state.indexWhere((p) => p.id == party.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) party else state[i],
      ];
      persistState(state);
    }
  }

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final myPartiesProvider = NotifierProvider<MyPartiesNotifier, List<Party>>(
  MyPartiesNotifier.new,
);

// ============================================
// PARTIES AROUND SYSTEM - With Cache
// ============================================

class PartiesAroundNotifier extends Notifier<List<Party>>
    with CacheableNotifierMixin<List<Party>> {
  @override
  String get cacheKey => CacheKeys.partiesAround;

  @override
  Duration get staleThreshold => const Duration(minutes: 3);

  @override
  dynamic serialize(List<Party> state) => state.map((p) => p.toMap()).toList();

  @override
  List<Party> deserialize(dynamic json) =>
      (json as List).map((e) => Party.fromMap(e)).toList();

  @override
  List<Party> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setParties(List<Party> parties) {
    state = parties;
    persistState(parties);
  }

  void addParty(Party party) {
    if (!state.any((p) => p.id == party.id)) {
      state = [...state, party];
      persistState(state);
    }
  }

  void removeParty(String partyId) {
    state = state.where((p) => p.id != partyId).toList();
    persistState(state);
  }

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final partiesAroundProvider =
    NotifierProvider<PartiesAroundNotifier, List<Party>>(
      PartiesAroundNotifier.new,
    );

// ============================================
// DELETE FEEDBACK SYSTEM
// ============================================

class DeleteFeedbackNotifier extends Notifier<DeleteFeedbackState> {
  @override
  DeleteFeedbackState build() => DeleteFeedbackState();

  void setDeleting(String partyId) {
    state = DeleteFeedbackState(
      status: DeleteStatus.deleting,
      partyId: partyId,
    );
  }

  void setDeleted(String partyId) {
    state = DeleteFeedbackState(status: DeleteStatus.deleted, partyId: partyId);
    Future.delayed(const Duration(seconds: 2), () {
      if (state.partyId == partyId) {
        state = DeleteFeedbackState();
      }
    });
  }

  void clear() {
    state = DeleteFeedbackState();
  }
}

enum DeleteStatus { idle, deleting, deleted }

class DeleteFeedbackState {
  final DeleteStatus status;
  final String? partyId;

  DeleteFeedbackState({this.status = DeleteStatus.idle, this.partyId});
}

final deleteFeedbackProvider =
    NotifierProvider<DeleteFeedbackNotifier, DeleteFeedbackState>(
      DeleteFeedbackNotifier.new,
    );

// ============================================
// GEOCODE SYSTEM
// ============================================

class GeocodeResult {
  final String address;
  final String city;
  final String lat;
  final String lon;

  GeocodeResult({
    this.address = '',
    this.city = '',
    this.lat = '',
    this.lon = '',
  });
}

class GeocodeResultNotifier extends Notifier<GeocodeResult> {
  @override
  GeocodeResult build() => GeocodeResult();

  void setGeocodeResult(GeocodeResult result) {
    state = result;
  }

  void clear() {
    state = GeocodeResult();
  }
}

final geocodeResultProvider =
    NotifierProvider<GeocodeResultNotifier, GeocodeResult>(
      GeocodeResultNotifier.new,
    );

// ============================================
// NOTIFICATION SYSTEM - With Cache
// ============================================

class NotificationsNotifier extends Notifier<List<Notification>>
    with CacheableNotifierMixin<List<Notification>> {
  @override
  String get cacheKey => CacheKeys.notifications;

  @override
  Duration get staleThreshold => const Duration(minutes: 5);

  @override
  dynamic serialize(List<Notification> state) =>
      state.map((n) => n.toMap()).toList();

  @override
  List<Notification> deserialize(dynamic json) =>
      (json as List).map((e) => Notification.fromMap(e)).toList();

  @override
  List<Notification> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setNotifications(List<Notification> notifications) {
    state = notifications;
    persistState(notifications);
  }

  void addNotification(Notification notification) {
    if (!state.any((n) => n.id == notification.id)) {
      state = [notification, ...state];
      persistState(state);
    }
  }

  void markAsRead(String notificationId) {
    state = [
      for (final n in state)
        if (n.id == notificationId) n.copyWith(isRead: true) else n,
    ];
    persistState(state);
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
    persistState(state);
  }

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<Notification>>(
      NotificationsNotifier.new,
    );

// ============================================
// DM CONVERSATIONS SYSTEM - With Cache
// ============================================

class DMConversationsNotifier extends Notifier<List<DMConversation>>
    with CacheableNotifierMixin<List<DMConversation>> {
  @override
  String get cacheKey => CacheKeys.dmConversations;

  @override
  Duration get staleThreshold => const Duration(minutes: 2);

  @override
  dynamic serialize(List<DMConversation> state) =>
      state.map((c) => c.toMap()).toList();

  @override
  List<DMConversation> deserialize(dynamic json) =>
      (json as List).map((e) => DMConversation.fromMap(e)).toList();

  @override
  List<DMConversation> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setConversations(List<DMConversation> conversations) {
    state = conversations;
    persistState(conversations);
  }

  void addConversation(DMConversation conversation) {
    if (!state.any((c) => c.chatId == conversation.chatId)) {
      state = [conversation, ...state];
      persistState(state);
    }
  }

  void updateConversation(DMConversation conversation) {
    state = [
      for (final c in state)
        if (c.chatId == conversation.chatId) conversation else c,
    ];
    persistState(state);
  }

  void removeConversation(String chatId) {
    state = state.where((c) => c.chatId != chatId).toList();
    persistState(state);
  }

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final dmConversationsProvider =
    NotifierProvider<DMConversationsNotifier, List<DMConversation>>(
      DMConversationsNotifier.new,
    );

// ============================================
// PARTY ANALYTICS SYSTEM
// ============================================

class PartyAnalyticsNotifier extends Notifier<Map<String, PartyAnalytics>> {
  @override
  Map<String, PartyAnalytics> build() => {};

  void setAnalytics(String partyId, PartyAnalytics analytics) {
    state = {...state, partyId: analytics};
  }

  void clear() {
    state = {};
  }
}

final partyAnalyticsProvider =
    NotifierProvider<PartyAnalyticsNotifier, Map<String, PartyAnalytics>>(
      PartyAnalyticsNotifier.new,
    );

// ============================================
// MATCHED USERS SYSTEM
// ============================================

class MatchedUsersNotifier extends Notifier<List<MatchedUser>>
    with CacheableNotifierMixin<List<MatchedUser>> {
  @override
  String get cacheKey => CacheKeys.matchedUsers;

  @override
  Duration get staleThreshold => const Duration(minutes: 5);

  @override
  dynamic serialize(List<MatchedUser> state) =>
      state.map((u) => u.toMap()).toList();

  @override
  List<MatchedUser> deserialize(dynamic json) =>
      (json as List).map((e) => MatchedUser.fromMap(e)).toList();

  @override
  List<MatchedUser> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setMatchedUsers(List<MatchedUser> users) {
    state = users;
    persistState(users);
  }

  void removeUser(String userId) {
    state = state.where((u) => u.userId != userId).toList();
    persistState(state);
  }

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final matchedUsersProvider =
    NotifierProvider<MatchedUsersNotifier, List<MatchedUser>>(
      MatchedUsersNotifier.new,
    );

// ============================================
// BLOCKED USERS SYSTEM - With Cache
// ============================================

class BlockedUsersNotifier extends Notifier<List<String>>
    with CacheableNotifierMixin<List<String>> {
  @override
  String get cacheKey => CacheKeys.blockedUsers;

  @override
  Duration get staleThreshold => const Duration(minutes: 10);

  @override
  dynamic serialize(List<String> state) => state;

  @override
  List<String> deserialize(dynamic json) => List<String>.from(json);

  @override
  List<String> build() {
    _hydrate();
    return [];
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setBlockedUsers(List<String> userIds) {
    state = userIds;
    persistState(userIds);
  }

  void addBlockedUser(String userId) {
    if (!state.contains(userId)) {
      state = [...state, userId];
      persistState(state);
    }
  }

  void removeBlockedUser(String userId) {
    state = state.where((id) => id != userId).toList();
    persistState(state);
  }

  bool isBlocked(String userId) => state.contains(userId);

  void clear() {
    state = [];
    CacheManager.remove(cacheKey);
  }
}

final blockedUsersProvider =
    NotifierProvider<BlockedUsersNotifier, List<String>>(
      BlockedUsersNotifier.new,
    );

// ============================================
// SEARCH RESULTS SYSTEM
// ============================================

class UserSearchNotifier extends Notifier<List<User>> {
  @override
  List<User> build() => [];

  void setResults(List<User> users) {
    state = users;
  }

  void clear() {
    state = [];
  }
}

final userSearchProvider = NotifierProvider<UserSearchNotifier, List<User>>(
  UserSearchNotifier.new,
);

// ============================================
// CHAT HISTORY SYSTEM
// ============================================

class ChatHistoryNotifier extends Notifier<Map<String, List<ChatMessage>>>
    with CacheableNotifierMixin<Map<String, List<ChatMessage>>> {
  @override
  String get cacheKey => CacheKeys.chatHistory;

  @override
  Duration get staleThreshold => const Duration(minutes: 2);

  @override
  dynamic serialize(Map<String, List<ChatMessage>> state) =>
      state.map((k, v) => MapEntry(k, v.map((m) => m.toMap()).toList()));

  @override
  Map<String, List<ChatMessage>> deserialize(dynamic json) =>
      (json as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => ChatMessage.fromMap(e)).toList(),
        ),
      );

  @override
  Map<String, List<ChatMessage>> build() {
    _hydrate();
    return {};
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setMessages(String chatId, List<ChatMessage> messages) {
    state = {...state, chatId: messages};
    persistState(state);
  }

  void addMessage(String chatId, ChatMessage message) {
    final currentMessages = state[chatId] ?? [];
    state = {
      ...state,
      chatId: [...currentMessages, message],
    };
    persistState(state);
  }

  void removeMessage(String chatId, String messageId) {
    final currentMessages = state[chatId] ?? [];
    state = {
      ...state,
      chatId: currentMessages.where((m) => m.id != messageId).toList(),
    };
    persistState(state);
  }

  void clear() {
    state = {};
    CacheManager.remove(cacheKey);
  }
}

final chatHistoryProvider =
    NotifierProvider<ChatHistoryNotifier, Map<String, List<ChatMessage>>>(
      ChatHistoryNotifier.new,
    );

// ============================================
// DM HISTORY SYSTEM
// ============================================

class DMHistoryNotifier extends Notifier<Map<String, List<ChatMessage>>>
    with CacheableNotifierMixin<Map<String, List<ChatMessage>>> {
  @override
  String get cacheKey => CacheKeys.dmHistory;

  @override
  Duration get staleThreshold => const Duration(minutes: 2);

  @override
  dynamic serialize(Map<String, List<ChatMessage>> state) =>
      state.map((k, v) => MapEntry(k, v.map((m) => m.toMap()).toList()));

  @override
  Map<String, List<ChatMessage>> deserialize(dynamic json) =>
      (json as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => ChatMessage.fromMap(e)).toList(),
        ),
      );

  @override
  Map<String, List<ChatMessage>> build() {
    _hydrate();
    return {};
  }

  Future<void> _hydrate() async {
    final cached = loadFromCache();
    if (cached != null) {
      state = cached;
    }
  }

  Future<void> syncWithServer() async {
    // Sync handled by socket service
  }

  void setMessages(String otherUserId, List<ChatMessage> messages) {
    state = {...state, otherUserId: messages};
    persistState(state);
  }

  void addMessage(String otherUserId, ChatMessage message) {
    final currentMessages = state[otherUserId] ?? [];
    state = {
      ...state,
      otherUserId: [...currentMessages, message],
    };
    persistState(state);
  }

  void clear() {
    state = {};
    CacheManager.remove(cacheKey);
  }
}

final dmHistoryProvider =
    NotifierProvider<DMHistoryNotifier, Map<String, List<ChatMessage>>>(
      DMHistoryNotifier.new,
    );

// ============================================
// EXTENSION METHODS FOR MODELS
// ============================================

extension ChatRoomSerialization on ChatRoom {
  Map<String, dynamic> toMap() => {
    'ID': id,
    'PartyID': partyId,
    'HostID': hostId,
    'Title': title,
    'ImageUrl': imageUrl,
    'IsGroup': isGroup,
    'ParticipantIDs': participantIds,
    'IsActive': isActive,
    'RecentMessages': recentMessages.map((m) => m.toMap()).toList(),
    'LastMessageContent': lastMessageContent,
    'LastMessageAt': lastMessageAt?.toIso8601String(),
    'UnreadCount': unreadCount,
    'StartTime': startTime?.toIso8601String(),
  };
}

extension ChatMessageSerialization on ChatMessage {
  Map<String, dynamic> toMap() => {
    'ID': id,
    'ChatID': chatId,
    'SenderID': senderId,
    'SenderName': senderName,
    'SenderThumbnail': senderThumbnail,
    'Type': type.toString().split('.').last,
    'Content': content,
    'MediaURL': mediaUrl,
    'ThumbnailURL': thumbnailUrl,
    'Metadata': metadata,
    'ReplyToID': replyToId,
    'CreatedAt': createdAt.toIso8601String(),
  };
}

// ============================================
// PROVIDER INITIALIZATION
// ============================================

/// Initialize all providers on app startup
Future<void> initializeProviders() async {
  await CacheManager.initialize();
  debugPrint('[Providers] Cache manager initialized');
}

/// Provider to track cache initialization state
final cacheInitializedProvider = Provider<bool>((ref) {
  // This provider is used to ensure cache is ready before other operations
  return true;
});
