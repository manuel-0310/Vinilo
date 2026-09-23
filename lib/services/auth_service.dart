import 'package:firebase_auth/firebase_auth.dart';

/// Sesión de la persona. La app entra con correo y contraseña; las sesiones
/// anónimas que quedaron de antes se conservan solo para vincularlas
/// (`linkEmail`) y no perder sus notas, favoritos y perfil.
class AuthService {
  AuthService() {
    // Los correos que manda Firebase (recuperar contraseña) salen en español.
    _auth.setLanguageCode('es');
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emite también cuando la sesión cambia sin cerrarse (por ejemplo al
  /// vincular un correo a una sesión anónima), no solo al entrar y salir.
  Stream<User?> get changes => _auth.userChanges();
  User? get current => _auth.currentUser;
  String? get uid => current?.uid;
  String? get email => current?.email;
  bool get isAnonymous => current?.isAnonymous ?? false;

  Future<User> signUp({required String email, required String password}) async {
    // Una sesión anónima sin datos que quedó de antes no sirve de nada: se
    // cierra para que la cuenta nueva empiece limpia. Las que sí tienen
    // datos pasan por `linkEmail`, no por aquí.
    if (_auth.currentUser?.isAnonymous ?? false) await _auth.signOut();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!;
  }

  Future<User> signIn({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!;
  }

  /// Vincula un correo y contraseña a la sesión actual: el uid no cambia, así
  /// que las notas, los favoritos y el perfil siguen siendo los mismos.
  Future<User> linkEmail({required String email, required String password}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay sesión que vincular.');
    final cred = await user.linkWithCredential(
      EmailAuthProvider.credential(email: email.trim(), password: password),
    );
    return cred.user ?? user;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Vuelve a comprobar la contraseña (Firebase lo exige antes de borrar la
  /// cuenta o cambiar datos sensibles).
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw StateError('No hay sesión.');
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> idToken() =>
      _auth.currentUser?.getIdToken() ?? Future.value(null);
}
