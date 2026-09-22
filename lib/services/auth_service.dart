import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get changes => _auth.authStateChanges();
  User? get current => _auth.currentUser;
  String? get uid => current?.uid;

  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<String?> idToken() => _auth.currentUser?.getIdToken() ?? Future.value(null);
}
