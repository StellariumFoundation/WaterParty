import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'models.dart';
import 'constants.dart';

class SocketService {
  static const String serverUrl = AppConstants.host;
  final Ref ref;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  SocketService(this.ref);

  void connect(String uid) {
    if (_isConnected) return;

    final uri = Uri.parse('wss://$serverUrl/ws?uid=$uid');
    print('[WebSocket] Connecting to: wss://$serverUrl/ws?uid=$uid');
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    _channel!.stream.listen(
      (data) {
        print('[WebSocket] Received data: $data');
        _handleIncomingMessage(data);
      },
      onDone: () => _reconnect(uid),
      onError: (err) => _reconnect(uid),
    );

    // Request latest user data and chats from server immediately after connection
    sendMessage('GET_USER', {});
    sendMessage('GET_CHATS', {});
    // Request user's parties (hosted and matched)
    sendMessage('GET_MY_PARTIES', {});
  }

  void _handleIncomingMessage(dynamic rawData) {
    print('[WebSocket] Raw message received: $rawData');
    final Map<String, dynamic> data = jsonDecode(rawData);

    final String event = data['Event'];
    final dynamic payload = data['Payload'];

    print('[WebSocket] Handling event: $event');

    switch (event) {
      case 'PROFILE_UPDATED':
        final user = User.fromMap(payload);
        ref.read(authProvider.notifier).updateUserProfile(user);
        break;
      case 'CHATS_LIST':
        final List<dynamic> roomsRaw = payload;
        final rooms = roomsRaw.map((r) => ChatRoom.fromMap(r)).toList();
        ref.read(chatProvider.notifier).setRooms(rooms);
        break;
      case 'NEW_CHAT_ROOM':
        print('[WebSocket] Processing NEW_CHAT_ROOM: $payload');
        final room = ChatRoom.fromMap(payload);
        print(
          '[WebSocket] Parsed room: ${room.id}, partyId: ${room.partyId}, title: ${room.title}',
        );
        ref.read(chatProvider.notifier).addRoom(room);
        print('[WebSocket] Room added to provider');
        break;
      case 'NEW_MESSAGE':
        final message = ChatMessage.fromMap(payload);
        ref.read(chatProvider.notifier).updateRoomWithNewMessage(message);
        break;
      case 'NEW_PARTY':
        final party = Party.fromMap(payload);
        ref.read(partyCacheProvider.notifier).updateParty(party);
        ref.read(partyFeedProvider.notifier).addParty(party);
        break;
      case 'FEED_UPDATE':
        print('[WebSocket] FEED_UPDATE payload: $payload');
        if (payload == null) {
          print('[WebSocket] FEED_UPDATE payload is null, skipping');
          break;
        }
        final List<dynamic> partiesRaw = payload;
        final parties = partiesRaw.map((p) => Party.fromMap(p)).toList();
        ref.read(partyCacheProvider.notifier).updateParties(parties);
        ref.read(partyFeedProvider.notifier).setParties(parties);
        break;
      case 'PARTY_LOCKED':
        // Logic for party locked
        break;
      case 'LOCATION_REVEALED':
        // Logic for location reveal
        break;
      case 'APPLICANTS_LIST':
        print('[WebSocket] APPLICANTS_LIST payload: $payload');
        final applicantsData = payload['Applicants'];
        if (applicantsData == null) {
          print('[WebSocket] Applicants is null, setting empty list');
          ref.read(partyApplicantsProvider.notifier).setApplicants([]);
          break;
        }
        final List<dynamic> appsRaw = applicantsData;
        final apps = appsRaw.map((a) => PartyApplication.fromMap(a)).toList();
        ref.read(partyApplicantsProvider.notifier).setApplicants(apps);
        break;
      case 'APPLICATION_UPDATED':
        final status = ApplicantStatus.values.firstWhere(
          (e) => e.toString().split('.').last == payload['Status'],
        );
        ref
            .read(partyApplicantsProvider.notifier)
            .updateStatus(payload['UserID'], status);
        break;
      case 'PARTY_CREATED':
        print('[WebSocket] PARTY_CREATED raw payload: $payload');
        print(
          '[WebSocket] PARTY_CREATED payload keys: ${payload.keys.toList()}',
        );
        print('[WebSocket] PARTY_CREATED Title value: "${payload['Title']}"');
        final party = Party.fromMap(payload);
        print(
          '[WebSocket] Parsed party: id=${party.id}, title="${party.title}"',
        );
        ref.read(partyCacheProvider.notifier).updateParty(party);
        ref.read(partyFeedProvider.notifier).addParty(party);
        ref.read(partyCreationProvider.notifier).setSuccess(party.id);
        break;
      case 'PARTY_DELETED':
        print('[WebSocket] PARTY_DELETED payload: $payload');
        final partyId = payload['PartyID'] ?? payload['partyId'];
        final chatRoomId = payload['ChatRoomID'] ?? payload['chatRoomId'];
        print('[WebSocket] Removing party: $partyId, chatRoom: $chatRoomId');
        ref.read(partyCacheProvider.notifier).removeParty(partyId);
        ref.read(chatProvider.notifier).removeRoom(chatRoomId);
        ref.read(partyFeedProvider.notifier).removeParty(partyId);
        ref.read(myPartiesProvider.notifier).removeParty(partyId);
        print('[WebSocket] Party removed from providers');
        break;
      case 'DELETE_PARTY_RESPONSE':
        print('[WebSocket] DELETE_PARTY_RESPONSE payload: $payload');
        final success = payload['success'] ?? payload['Success'] ?? true;
        if (success == true || success == 'true') {
          final partyId = payload['PartyID'] ?? payload['partyId'];
          final chatRoomId = payload['ChatRoomID'] ?? payload['chatRoomId'];
          ref.read(partyCacheProvider.notifier).removeParty(partyId);
          ref.read(chatProvider.notifier).removeRoom(chatRoomId);
          ref.read(partyFeedProvider.notifier).removeParty(partyId);
          ref.read(myPartiesProvider.notifier).removeParty(partyId);
          print('[WebSocket] Party deleted successfully');
        }
        break;
      case 'ERROR':
        final String message = payload['message'] ?? 'Unknown error';
        print('[WebSocket] ERROR received: $message');
        ref.read(partyCreationProvider.notifier).setError(message);
        break;
      case 'MY_PARTIES':
        print('[WebSocket] MY_PARTIES received: $payload');
        final List<dynamic> partiesRaw = payload as List<dynamic>;
        final parties = partiesRaw
            .map((p) => Party.fromMap(p as Map<String, dynamic>))
            .toList();
        print('[WebSocket] Parsed ${parties.length} my parties');
        // Update cache with all parties
        for (final party in parties) {
          print(
            '[WebSocket] My party: id=${party.id}, title=${party.title}, hostId=${party.hostId}',
          );
          ref.read(partyCacheProvider.notifier).updateParty(party);
        }
        // Update my parties provider
        ref.read(myPartiesProvider.notifier).setParties(parties);
        print(
          '[WebSocket] myPartiesProvider updated with ${parties.length} parties',
        );
        break;
      case 'MY_PARTIES_RESPONSE':
        // Alternative response format
        print('[WebSocket] MY_PARTIES_RESPONSE received: $payload');
        final List<dynamic> partiesRaw =
            payload['Parties'] ?? payload as List<dynamic>;
        final parties = partiesRaw
            .map((p) => Party.fromMap(p as Map<String, dynamic>))
            .toList();
        print('[WebSocket] Parsed ${parties.length} my parties from response');
        for (final party in parties) {
          print(
            '[WebSocket] My party: id=${party.id}, title=${party.title}, hostId=${party.hostId}',
          );
          ref.read(partyCacheProvider.notifier).updateParty(party);
        }
        ref.read(myPartiesProvider.notifier).setParties(parties);
        print(
          '[WebSocket] myPartiesProvider updated with ${parties.length} parties',
        );
        break;
    }
  }

  // Send message to Go Backend
  void sendMessage(String event, dynamic payload) {
    print('[WebSocket] Sending message: $event with payload: $payload');
    if (_channel != null) {
      final user = ref.read(authProvider).value;
      final msg = jsonEncode({
        'Event': event,
        'Payload': payload,
        'Token': user?.id ?? 'anonymous',
      });
      _channel!.sink.add(msg);
    }
  }

  void _reconnect(String token) {
    _isConnected = false;
    Future.delayed(const Duration(seconds: 3), () => connect(token));
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}

// Provider to access the socket anywhere
final socketServiceProvider = Provider((ref) => SocketService(ref));
