/// El correo de soporte que se muestra en "Privacidad y seguridad" y en los
/// errores. Es el del prototipo: antes de publicar, Manuel tiene que
/// confirmar que ese buzón existe o cambiarlo aquí (o con
/// `--dart-define=SUPPORT_EMAIL=…`).
const String supportEmail = String.fromEnvironment(
  'SUPPORT_EMAIL',
  defaultValue: 'soporte@vinilo.app',
);
