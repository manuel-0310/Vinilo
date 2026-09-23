/// Reglas del @usuario: en minúsculas, de 3 a 20 caracteres, solo letras,
/// números, punto y guion bajo. Es único en toda la app (colección
/// `usernames/{usuario}` → uid) y se puede cambiar desde el perfil.
const int usernameMin = 3;
const int usernameMax = 20;

final RegExp _allowed = RegExp(r'^[a-z0-9._]+$');

/// Lo que la persona escribió, listo para validar: sin espacios alrededor,
/// sin la arroba inicial y en minúsculas.
String normalizeUsername(String raw) {
  var s = raw.trim();
  if (s.startsWith('@')) s = s.substring(1);
  return s.toLowerCase();
}

/// Quita todo lo que no puede ir en un @usuario (para el formateador del
/// campo de texto): pasa a minúsculas y elimina espacios, tildes, arrobas…
String stripUsername(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    if (_allowed.hasMatch(ch)) buffer.write(ch);
  }
  return buffer.toString();
}

enum UsernameProblem { empty, tooShort, tooLong, badChars }

/// Null si el nombre ya normalizado es válido.
UsernameProblem? usernameProblem(String username) {
  if (username.isEmpty) return UsernameProblem.empty;
  if (!_allowed.hasMatch(username)) return UsernameProblem.badChars;
  if (username.length < usernameMin) return UsernameProblem.tooShort;
  if (username.length > usernameMax) return UsernameProblem.tooLong;
  return null;
}

bool isValidUsername(String username) => usernameProblem(username) == null;

String usernameProblemMessage(UsernameProblem problem) => switch (problem) {
      UsernameProblem.empty => 'Elige tu @usuario.',
      UsernameProblem.tooShort => 'Mínimo $usernameMin caracteres.',
      UsernameProblem.tooLong => 'Máximo $usernameMax caracteres.',
      UsernameProblem.badChars =>
        'Solo letras minúsculas, números, punto y guion bajo.',
    };
