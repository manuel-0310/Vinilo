/// Si lo escrito tiene forma de correo (algo@algo.algo, sin espacios). No
/// lo valida del todo: eso lo hace Firebase al entrar o al crear la cuenta.
bool looksLikeEmail(String raw) {
  final s = raw.trim();
  final at = s.indexOf('@');
  return at > 0 &&
      s.indexOf('.', at) > at + 1 &&
      !s.endsWith('.') &&
      !s.contains(' ');
}
