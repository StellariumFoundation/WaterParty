import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class AuthNotifier extends Notifier<User?> {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  String? _verificationId; // Stores the ID for SMS verification

  @override
  User? build() {
    _auth.authStateChanges().listen((fbUser) {
      if (fbUser != null) state = _mapFirebaseUser(fbUser);
      else state = null;
    });
    return null;
  }

  // --- Google ---
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  // --- Email/Password ---
  Future<void> authWithEmail(String email, String password, bool isLogin) async {
    if (isLogin) {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } else {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    }
  }

  // --- SMS Authentication (Phone) ---
  Future<void> sendOtp(String phoneNumber, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (fb.FirebaseException e) => throw e,
      codeSent: (String vid, int? resendToken) {
        _verificationId = vid;
        onCodeSent(vid);
      },
      codeAutoRetrievalTimeout: (String vid) => _verificationId = vid,
    );
  }

  Future<void> verifyOtp(String smsCode) async {
    if (_verificationId == null) return;
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  void logout() async => await _auth.signOut();

  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  Future<void> updateUserProfile({String? realName, String? bio, List<String>? profilePhotos}) async {
    if (state == null) return;
    state = state!.copyWith(realName: realName, bio: bio, profilePhotos: profilePhotos);
  }

  User _mapFirebaseUser(fb.User fbUser) {
    return User(
      id: fbUser.uid,
      username: fbUser.phoneNumber ?? fbUser.email?.split('@')[0] ?? "user_${fbUser.uid.substring(0,5)}",
      realName: fbUser.displayName ?? "Water User",
      email: fbUser.email ?? "",
      phoneNumber: fbUser.phoneNumber ?? "",
      profilePhotos: fbUser.photoURL != null ? [fbUser.photoURL!] : [],
      trustScore: 100.0,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

// Add this to your providers.dart

class ChatNotifier extends Notifier<List<ChatRoom>> {
  @override
  List<ChatRoom> build() {
    // Initial Mock Data using the Go-compatible Models
    return [
      ChatRoom(
        id: "c1",
        partyId: "p1",
        hostId: "u2",
        title: "Rooftop Jazz & Drinks", // Derived from Party Title
        imageUrl: "https://images.unsplash.com/photo-1514525253440-b39345208668",
        isGroup: true,
        lastMessageContent: "Sarah: I'm bringing the vintage red!",
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
        unreadCount: 3,
      ),
      ChatRoom(
        id: "dm1",
        partyId: "",
        hostId: "u1",
        title: "Marcus Aurelius", // Derived from User RealName
        imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
        isGroup: false,
        lastMessageContent: "That rooftop set was legendary.",
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 1,
      ),
    ];
  }

  // This will be called by your SocketService when a NEW_MESSAGE event arrives
  void updateRoomWithNewMessage(ChatMessage msg) {
    state = [
      for (final room in state)
        if (room.id == msg.chatId)
          room.copyWith(
            lastMessageContent: msg.content,
            lastMessageAt: msg.createdAt,
            // unreadCount: room.unreadCount + 1, // Logic for unread
          )
        else
          room,
    ];
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
  @override
  List<Party> build() => [];
  
  void addParty(Party party) {
    state = [...state, party];
  }
}

final partyFeedProvider = NotifierProvider<PartyFeedNotifier, List<Party>>(PartyFeedNotifier.new);