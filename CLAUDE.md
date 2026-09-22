# Vinilo — calificar álbumes del 1 al 10

App tipo Letterboxd pero para álbumes de música: buscar un álbum, ponerle nota de 1 a 10, ver lo que califica la comunidad y llevar un diario propio. El diseño es parte del objetivo, no un extra.

## Dirección visual

"Estuche de vinilo, editorial y oscuro". Fondo carbón cálido (`VColors.bg`, nunca negro puro), la portada manda y un resplandor sacado de sus colores (`PaletteService` + `AmbientGlow`) tiñe la pantalla de detalle. Tipografía: Instrument Serif para títulos y numerales grandes, Manrope (variable) para la interfaz; ambas en `assets/fonts`, se usan a través de `VText.display` y `VText.ui`. La nota se elige con un dial de surcos (`RatingDial`) con hápticos; el color de la nota va de rosa apagado a ámbar a dorado (`Score.color`). Nada de estrellas. Transiciones con Hero de la portada y entradas escalonadas con `flutter_animate`.

## Estado técnico (probado el 2026-09-21)

- Flutter 3.41, paquete `no_retiene` (nombre heredado del scaffold), bundle iOS `com.buildday.noRetiene`, nombre visible "Vinilo". Plataformas: ios, android, web.
- Firebase: proyecto `red-social-c786b` (plan Blaze), `lib/firebase_options.dart` ya generado. No volver a correr `flutterfire configure`. `.firebaserc` apunta al proyecto.
- Verificados desde el simulador: Auth anónimo, Firestore y Storage (bucket `red-social-c786b.firebasestorage.app`).
- Paquetes con pods ya compilados: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `video_player`, `image_picker`, `flutter_animate`, `http`. `flutter_driver` está en dev_dependencies (solo Dart).
- `ios/Runner/Info.plist` declara permisos de galería, cámara y micrófono.

### Reglas de seguridad

Firestore y Storage siguen en **modo de prueba** (vencen ~30 días después del 2026-09-21). En el repo hay reglas listas para reemplazarlo: `firestore.rules`, `storage.rules` y `firestore.indexes.json`. Para desplegarlas hay que agregar las secciones `firestore` y `storage` a `firebase.json` y correr `firebase deploy --only firestore:rules,storage`. No están desplegadas todavía.

## Estructura de `lib/`

- `main.dart`: inicializa Firebase, hace login anónimo, escucha el perfil (`users/{uid}`) y decide entre `SplashScreen`, `OnboardingScreen` y `ShellScreen`. `CurrentUser` (InheritedWidget) vive por encima de `MaterialApp` para que las rutas empujadas lo vean.
- `theme/`: `vinilo_theme.dart` (colores, tipografía, `ThemeData`) y `score.dart` (etiquetas, color y formato de la nota).
- `models/`: `Album`/`AlbumDetail`/`Track`/`AlbumPage` (de la función), `RatingEntry`/`AlbumStats`/`RaterInfo`, `UserProfile`.
- `services/`: `SpotifyApi` (http a la Cloud Function, cachés en memoria), `AuthService`, `UserRepo`, `RatingsRepo` (transacciones que mantienen los agregados), `PaletteService` (color dominante sin paquetes nativos), `services.dart` (`Services`, `ServicesScope`, `CurrentUser`).
- `widgets/`: `AlbumCover`, `VinylDisc`/`SpinningVinyl`, `UserAvatar`, `ScoreBadge`/`ScoreNumeral`, `ScoreHistogram`, `RatingDial`, `RatingSheet` (`showRatingSheet`), `FeedCard`/`LikeButton`, `AlbumStrip`, y `misc.dart` (`SectionHeader`, `Skeleton`, `EmptyState`, `GlassIconButton`, `AmbientGlow`, `Pill`).
- `screens/`: `shell_screen.dart` (3 pestañas con barra flotante), `home_screen.dart`, `search_screen.dart`, `album_screen.dart`, `profile_screen.dart` (propio y ajeno, con afinidad), `onboarding_screen.dart` + `profile_form.dart`, `splash_screen.dart`, `routes.dart` (`openAlbum`, `openUser`).

## Datos en Firestore

- `users/{uid}`: `name`, `color` (int ARGB), `avatarUrl`, `createdAt`, `ratingsCount`, `ratingsSum`, `favorites` (hasta 4 álbumes compactos), `recentSearches`.
- `albums/{spotifyId}`: copia compacta del álbum + `ratingsCount`, `ratingsSum`, `hist` (mapa "1".."10" → conteo), `lastRatedAt`.
- `ratings/{uid}_{albumId}`: `uid`, `albumId`, `score`, `note` (≤180), `album` y `user` denormalizados, `createdAt`, `updatedAt`, `likedBy` (uids).
- Todas las consultas usan índices de un solo campo (feed por `updatedAt`, álbumes por `lastRatedAt`/`ratingsCount`, filtros por `uid`/`albumId` ordenados en el cliente). No hacen falta índices compuestos.

## Spotify

- Cloud Function HTTP `spotify` (2ª gen, Node 22, us-central1) en `functions/index.js`. Guarda `SPOTIFY_CLIENT_ID` y `SPOTIFY_CLIENT_SECRET` en Secret Manager, pide el token con client credentials y exige un ID token de Firebase Auth en `Authorization: Bearer`.
- URL: `https://us-central1-red-social-c786b.cloudfunctions.net/spotify`. Rutas: `/search?q=&offset=`, `/album/:id`, `/artist/:id/albums?offset=`, `/new?offset=` (álbumes del año en curso), `/` (salud).
- Desplegar: `firebase deploy --only functions`. Si `npm install` falla por permisos de `~/.npm/_cacache`, usar `npm install --cache /tmp/npm-cache`.
- Límites del modo desarrollo de Spotify comprobados: máximo 10 resultados por página (`limit` mayor da 400), `/browse/new-releases` y `/albums?ids=` devuelven 403, el objeto álbum no trae `label` ni `popularity`. La función pagina hasta offset 50 y completa las canciones con `/albums/:id/tracks`.

## Correr la app

- iOS: `flutter run -d 9B5FCCD2-D3ED-4B32-AD82-D6764E4A46B4 --dart-define=SPOTIFY_FN_URL=https://us-central1-red-social-c786b.cloudfunctions.net/spotify` (iPhone 18 Pro). También está encendido el iPhone 18 Pro Max `AB81FF4C-42BD-434A-8181-29B24B7CCBF3`. En Xcode 27 el simulador se ve desde DeviceHub.app.
- Web: `flutter run -d chrome --dart-define=SPOTIFY_FN_URL=…`.
- Sin `SPOTIFY_FN_URL` la app arranca pero la búsqueda muestra un error explicando qué falta.

## Probar sin tocar el simulador

- Arrancar con la extensión de Flutter Driver: `flutter run -t test_driver/app.dart -d <id> --pid-file /tmp/vinilo.pid --dart-define=SPOTIFY_FN_URL=…`.
- Manejar la app: `node tool/drive.mjs <ws-url-del-vm-service> tap key:tab-1 -- tap key:search-field -- type "ok computer" -- wait key:result-0 -- tap key:result-0`. Comandos: `tap`, `type`, `wait`, `gone`, `scroll`, `into`, `home [tab]`, `gettext`, `sleep`. Llaves útiles: `tab-0/1/2`, `search-field`, `result-N`, `name-field`, `profile-submit`, `color-<argb>`, `dial-N`, `note-field`, `rating-save`, `back`.
- Capturar pantalla: `SIM_DEVICE=<id> tool/shot.sh nombre` deja `/tmp/vinilo_shots/nombre_s.png`.
- Hot reload: `kill -USR1 $(cat /tmp/vinilo.pid)`; hot restart: `kill -USR2 …`.
- Los finders del driver no ven pestañas ocultas del `IndexedStack`; usar `home N` primero.

## Trampas conocidas (Xcode 27)

- No usar `flutter build ios --simulator`: falla porque el Flutter.framework del simulador no trae `x86_64`. `flutter run` sí funciona.
- Los comandos de CocoaPods necesitan `export LANG=en_US.UTF-8`.
- El `Podfile` fuerza `IPHONEOS_DEPLOYMENT_TARGET = 15.0` en todos los pods; no quitarlo.
- Agregar un paquete nativo nuevo obliga a correr `pod install` y a recompilar los pods de Firebase, que toma unos 20 minutos. Preferir paquetes de Dart puro.
- El `bottomNavigationBar` del Scaffold recibe toda la altura de la pantalla: no envolver la barra en `Center` (se queda a media pantalla); usar `Row`.
- Un `setState(() => campo = future)` dispara el assert "callback argument returned a Future"; usar cuerpo con llaves.
