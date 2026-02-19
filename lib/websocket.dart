import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'models.dart';

class SocketService {
  static const String serverUrl = "waterparty.onrender.com";
  final Ref ref;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  SocketService(this.ref);

  void connect(String uid) {
    if (_isConnected) return;

    final uri = Uri.parse('wss://$serverUrl/ws?uid=$uid');
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    _channel!.stream.listen(
      (data) => _handleIncomingMessage(data),
      onDone: () => _reconnect(uid),
      onError: (err) => _reconnect(uid),
    );
  }

  void _handleIncomingMessage(dynamic rawData) {
    final Map<String, dynamic> data = jsonDecode(rawData);
    
    final String event = data['Event'];
    final dynamic payload = data['Payload'];

    switch (event) {
      case 'NEW_MESSAGE':
        final message = ChatMessage.fromMap(payload);
        ref.read(chatProvider.notifier).updateRoomWithNewMessage(message);
        break;
      case 'NEW_PARTY':
        final party = Party.fromMap(payload);
        ref.read(partyFeedProvider.notifier).addParty(party);
        break;
      case 'FEED_UPDATE':
        final List<dynamic> partiesRaw = payload;
        final parties = partiesRaw.map((p) => Party.fromMap(p)).toList();
        ref.read(partyFeedProvider.notifier).setParties(parties);
        break;
      case 'PARTY_LOCKED':
        // Logic for party locked
        break;
      case 'LOCATION_REVEALED':
        // Logic for location reveal
        break;
    }
  }

  // Send message to Go Backend
  void sendMessage(String event, dynamic payload) {
    if (_channel != null) {
      final msg = jsonEncode({
        'Event': event,
        'Payload': payload,
        'Token': 'auth_token_here',
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