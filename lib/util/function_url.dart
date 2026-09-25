/// Las Cloud Functions de Vinilo viven una junto a otra, así que la URL de
/// `spotify` (la que llega con `SPOTIFY_FN_URL`) sirve para sacar la de las
/// demás: `…/spotify` → `…/account`, `…/web`. Null si no hay URL o si no
/// termina en `/spotify` (no se inventa nada).
Uri? siblingFunctionUrl(String spotifyUrl, String name) {
  if (spotifyUrl.isEmpty) return null;
  final uri = Uri.parse(spotifyUrl);
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || segments.last != 'spotify') return null;
  segments[segments.length - 1] = name;
  return uri.replace(pathSegments: segments);
}
