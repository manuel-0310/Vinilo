import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.clave`: los textos de la app en el idioma elegido (español o
/// inglés). Todo texto visible va en `app_es.arb` y `app_en.arb`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
