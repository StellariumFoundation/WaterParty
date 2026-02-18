import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'models.dart';

class SocketService {
  final Ref ref;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  SocketService(this.ref);

  void connect(String token) {
    if (_isConnected) return;

    // Use your Go server URL (e.g., ws://api.waterparty.com/ws)
    final uri = Uri.parse('ws://YOUR_GO_SERVER_IP/ws?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    _channel!.stream.listen(
      (data) => _handleIncomingMessage(data),
      onDone: () => _reconnect(token),
      onError: (err) => _reconnect(token),
    );
  }

  void _handleIncomingMessage(dynamic rawData) {
    final Map<String, dynamic> data = jsonDecode(rawData);
    
    // This matches your Go: type WSMessage struct { Event string, Payload interface{} }
    final String event = data['Event'];
    final dynamic payload = data['Payload'];

    switch (event) {
      case 'NEW_MESSAGE':
        _handleNewChatMessage(payload);
        break;
      case 'PARTY_LOCKED':
        _handlePartyUpdate(payload);
        break;
      case 'LOCATION_REVEALED':
        _handleLocationReveal(payload);
        break;
      case 'POOL_UPDATE':
        _handlePoolUpdate(payload);
        break;
    }
  }

  void _handleNewChatMessage(dynamic payload) {
    // Convert payload to ChatMessage model and update Riverpod state
    final message = ChatMessage(
      id: payload['ID'],
      senderId: payload['SenderID'],
      content: payload['Content'],
      type: MessageType.values.byName(payload['Type']),
      createdAt: DateTime.parse(payload['CreatedAt']),
    );
    // Push to your ChatProvider (you would create this in providers.dart)
    // ref.read(chatProvider.notifier).addMessage(message);
  }

  void _handleLocationReveal(dynamic payload) {
    // payload would contain PartyID, Address, Lat, Lon
    // ref.read(partyFeedProvider.notifier).revealLocation(payload['PartyID'], payload['Address']);
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