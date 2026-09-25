# Rediseño de Vinilo: plan de trabajo (continuar desde la fase 6)

## Contexto

El diseñador de Manuel entregó un rediseño completo de la app. Sus archivos están copiados en la **raíz del proyecto**, sin versionar:
- **`Vinilo App.dc.html`**, el prototipo:
  - cada pantalla está en un bloque `data-screen-label="…"` (Bienvenida, Iniciar sesión, Crear cuenta, Inicio, Notificaciones, Buscar, Resultados de búsqueda, Disco · sin calificar, Disco · calificado, Calificar, Agregar a una lista, Nueva lista, Disco · final (scroll), Perfil de artista, Amigo · siguiendo, Amigo · sin seguir, Mi perfil, Mi perfil · listas, Lista, Ranking, Configuración, Web · disco compartido, Web · artista compartido, Web · enlace roto, Ícono);
  - `{{ accent }}` es el color de énfasis;
  - al final, el `<script>` tiene las fórmulas de las barras de Calificar y la paleta.
- **`support.js`**, el motor del lienzo del prototipo: solo hace falta para abrir el HTML en el navegador y no hay que leerlo.
- **`ESPECIFICACION.md`**, la **fuente de verdad** cuando difiere del HTML.
- **`viniloicon copy.icon/`**, el ícono que Manuel hizo en Icon Composer; se usa en la fase 9.

Los originales están en `~/Downloads/Red social de álbumes/` y `~/Downloads/viniloicon copy.icon`. `Vinilo Rediseño.dc.html`, que está en esa carpeta, es una versión anterior y **no se usa**. El `PROMPT.md` original del diseñador ya está incorporado en este plan; donde difieren, manda este plan.

Manuel solo acepta el rediseño si la app queda **idéntica** al prototipo.
- **Qué cambia:** solo la capa visual. La lógica, los datos y la navegación se quedan como están, salvo lo que el prototipo o la especificación piden (sección "Cambios de comportamiento acordados").
- **Resultado:** tema oscuro de "estuche editorial":
  - Archivo condensada, IBM Plex Mono y Newsreader itálica;
  - esquinas rectas y líneas de 1 px;
  - personas en círculos y discos en cuadrados;
  - el color de énfasis que elige cada persona.

**Ojo con `CLAUDE.md`:** su sección "Dirección visual" (Instrument Serif, Manrope, dial de surcos, resplandor, barra Liquid Glass) describe el diseño **anterior**. Donde choque con este plan o con la especificación, mandan ellos. `CLAUDE.md` se reescribe en la fase 9. Todo lo demás de `CLAUDE.md` sigue vigente: datos, servicios, trampas conocidas y, sobre todo, la regla de que las pruebas las hace Manuel.

### Decisiones tomadas con Manuel (2026-09-25)

- **Tema claro:** se quedan el claro y el oscuro, y Configuración conserva "Apariencia" como en el prototipo. El diseñador todavía no definió el claro, así que por ahora la paleta clara es igual a la oscura (`ViniloPalette.light = dark`). Todo color sale de los tokens para que después el claro entre sin tocar pantallas.
- **Verificación:** solo Manuel, en su iPhone. El agente no usa simulador, `flutter run`, driver, capturas ni pruebas golden, aunque el prompt original del diseñador pidiera capturas. Verifica con `flutter analyze` y `flutter test`.
- **Acceso:**
  - "Continuar con Apple", "Continuar con Google", "Correo o usuario" y los enlaces a Términos y Privacidad quedan tal cual el prototipo, aunque no funcionen (al tocarlos no pasa nada).
  - Si alguien escribe un @usuario y toca "Entrar", debajo del campo aparece "Por ahora entra con tu correo".
- **Mi perfil · listas:** el encabezado compacto (nombre y "N discos · promedio") más las pestañas se quedan fijos arriba al hacer scroll, en las dos pestañas.
- **Ícono:** `viniloicon copy.icon/`, en la raíz del proyecto, hecho por Manuel en Icon Composer, con versión clara y oscura (fase 9).
- **Cambios de comportamiento:** los 15 de su sección, más abajo, están aceptados.

## Estado de las fases

| # | Fase | Estado |
|---|---|---|
| 1 | Sistema base (fuentes, tokens, componentes, íconos, barra inferior) | **Hecha** (2026-09-25). Revisada por Manuel |
| 2 | Acceso: Bienvenida, Iniciar sesión, Crear cuenta | **Hecha** (2026-09-25). Revisada por Manuel. Falta desplegar `web` (`/portadas`) con su permiso |
| 3 | Inicio y búsqueda: Inicio, Notificaciones, Buscar, Resultados | **Hecha** (2026-09-25). Revisada por Manuel |
| 4 | Disco: sin calificar, calificado, Calificar, Agregar a una lista, Nueva lista, final | **Hecha** (2026-09-25). Falta que Manuel la revise |
| 5 | Perfil de artista | **Hecha** (2026-09-25). Falta que Manuel la revise |
| 6 | Perfiles: amigo (siguiendo y sin seguir), Mi perfil, Mi perfil · listas | Pendiente |
| 7 | Lista, Ranking y Configuración | Pendiente |
| 8 | Web: disco compartido, artista compartido, enlace roto | Pendiente |
| 9 | Ícono, limpieza y cierre | Pendiente |

**Estado del repo:**
- el proyecto está en la Mac de Manuel, en `/Users/manuelcastillo/Proyectos Personales/vinilo`, y en GitHub (`manuel-0310/Vinilo`);
- rama `rediseno`: las fases 1 a 3 están en el commit "Primeras 3 fases del rediseño"; las fases 4 y 5 las hizo un agente en la nube y las subió a `rediseno` (Manuel hace `git pull` para revisarlas);
- `flutter analyze` sin avisos y `flutter test` con 157 pruebas en verde (al cerrar la fase 5).

**Primer paso del agente que continúa:**
1. Leer completos este archivo, `CLAUDE.md` y `ESPECIFICACION.md`.
2. Comprobar que está en la rama `rediseno` (con `git pull`) y correr `flutter analyze` y `flutter test` para confirmar ese punto de partida.
3. Preguntarle a Manuel cómo le fue revisando las fases 4 y 5 en el iPhone.
4. Empezar la fase 6 solo cuando él lo diga.

**Cuándo leer cada archivo de diseño:**
- **Al empezar:** `ESPECIFICACION.md` completo, que es corto.
- **Antes de cada pantalla:** su bloque en `Vinilo App.dc.html`, buscando `data-screen-label="Nombre de la pantalla"`. No hace falta leer el HTML entero de una vez: tiene 770 líneas y cada fase usa sus pantallas.
- **Fase 4:** además, el `<script>` del final del HTML, que tiene las fórmulas de las barras de Calificar (ya están en `rating_bars.dart`).
- **Fase 7:** el mismo `<script>`, que tiene la paleta de los 14 colores.
- **Fase 9:** `viniloicon copy.icon/`.
- **`support.js`:** nunca. Solo sirve para abrir el prototipo en el navegador, si Manuel quiere verlo.

## Cómo contarle el avance a Manuel (obligatorio en todas las fases)

1. **Al empezar cada fase:** si el entorno lo permite, marcar un capítulo en la conversación ("Fase N de 9 · nombre") y escribirle en una o dos líneas qué se va a hacer y qué archivos se van a tocar.
2. **Mientras se trabaja:**
   - avisarle al empezar y al terminar cada pantalla o paso, con una línea de avance como esta: `Fase 3/9 · Inicio ✓ · Notificaciones ✓ · Buscar ⏳ · Resultados`;
   - nunca hacer muchas acciones seguidas sin decirle en qué se va.
3. **Si algo falla o se sale del plan:** decírselo en ese momento, con qué pasó y qué se va a hacer, no al final. Eso incluye que algo del prototipo no se pueda igualar.
4. **Al terminar cada fase:**
   - pasarle un resumen con lo que cambió, el resultado de `flutter analyze` y `flutter test`, y lo que todavía no quedó idéntico;
   - pasarle la lista de qué probar en el iPhone: pantalla, pasos, resultado esperado, y si basta con `R`, si hace falta `Shift+R` o si hay que relanzar `flutter run`;
   - marcar la fase como hecha en la tabla de arriba;
   - si el entorno lo permite, mandarle una notificación, para que se entere aunque no esté mirando.
5. **Entre fases:** esperar su visto bueno o sus correcciones antes de empezar la siguiente, salvo que él pida seguir sin esperar.

## Reglas para todas las fases

- **Antes de cada pantalla:**
  - releer su bloque en el HTML (`data-screen-label="Nombre"`) y copiar medidas, tamaños, ancho de la fuente (`font-stretch`), pesos, rellenos y colores;
  - si el HTML y la especificación difieren, manda la especificación (ver la sección de diferencias).
- **Colores:**
  - solo con tokens (`final c = VColors.of(context);`) y nunca hex sueltos en los widgets;
  - eso incluye lo que el prototipo escribe fijo: `#0f0e0d` sobre el acento es `c.onAccent`, `rgba(15,14,13,.55)` de los botones sobre la portada es `c.overButton`, y el borde del avatar es `c.bg`.
- **Forma:**
  - radio 0 en todo, salvo personas y artistas, que van en círculo;
  - nada de sombras, gradientes, desenfoques, píldoras ni tarjetas con fondo;
  - las portadas siempre son cuadradas.
- **Textos:**
  - todo texto visible va en los dos ARB: `lib/l10n/app_es.arb` con el texto literal del prototipo y `app_en.arb` con su traducción;
  - las etiquetas mono las pasa a mayúsculas `VMono`, así que en el ARB van en minúscula normal;
  - `test/l10n_test.dart` exige que los dos ARB tengan las mismas claves y los mismos marcadores;
  - para agregar textos sin reformatear, cargar y volcar con `json.dumps(…, ensure_ascii=False, indent=2)`.
- **Pruebas y llaves:** conservar las `ValueKey` que existen (las usa `tool/drive.mjs`) y ponerles llaves nuevas a los controles nuevos.
- **Migración sin romper la app:** los widgets viejos se quedan con el estilo nuevo hasta que su pantalla se reescribe, y se borran en la fase 9. La app compila y se puede usar al final de cada fase.
- **No hacer:**
  - simulador, `flutter run`, driver ni capturas;
  - `dart format` sobre `lib/` entero, ni `git checkout -- lib`.
- **Git:** trabajar en la rama `rediseno` y hacer commit solo si Manuel lo pide.
- **Despliegues:**
  - la función `web` la despliega el agente, pero solo después de preguntarle a Manuel en ese momento;
  - el hosting lo despliega Manuel (`firebase deploy --only hosting`).

## Lo que ya existe (fase 1): usar esto, no reinventarlo

### Colores y tipografía

**Fuentes** (`assets/fonts/`, declaradas en `pubspec.yaml`, con sus licencias OFL al lado):
- `Archivo`, variable: ejes `wdth` 62–125 y `wght` 100–900;
- `PlexMono`: pesos 500, 600 y 700;
- `Newsreader`: itálica variable, con `opsz` y `wght`;
- Instrument Serif y Manrope siguen declaradas hasta la fase 9.

**`lib/theme/oklch.dart`:**
- `Oklch(l, c, h)`, con `.fromColor`, `.toColor()` (reduce el croma si se sale de la gama) y `Oklch.distance`;
- `coverTone(color)`: misma tonalidad, L≈0,76; es el color de la nota grande y del artista del disco, la regla, el diario, la discografía, los números del ranking y las notas de los comentarios del disco;
- `coverShade(color, {lightness: 0.31})`: la franja de Lista y Ranking; para el banner sin foto se usa 0,35;
- `personTone(color)`: el fondo de los avatares sin foto.

**`lib/theme/vinilo_theme.dart`:**
- **`ViniloPalette`**, con los tokens:
  - fondos: `bg #0F0E0D`, `sheet #171615`, `surface #2A2826`;
  - tintas: `ink #EFEBE4`, `ink2` .62, `ink3` .58 (etiquetas), `ink4` .50;
  - líneas: `line` .14, `lineSoft` .08, `lineStrong` .28 y `buttonLine` .18;
  - apagados: `inactive` .55 y `placeholder` .45;
  - velos: `scrim` `rgba(8,8,7,.72)` y `overButton` `rgba(15,14,13,.55)`;
  - énfasis: `accent` y `onAccent #0F0E0D`;
  - estados: `success #76CF8A` y `danger #ED756E`;
  - utilidades: `inkA(alpha)` para las opacidades sueltas del prototipo y `withAccent`;
  - `ViniloPalette.light = dark`, pendiente del diseñador.
- **Alias temporales** que se borran en la fase 9: `text`, `text2`, `text3`, `surface2`, `surface3`, `seed`, `score()`, `scoreOnDark()`, `withSeed` y `defaultSeed`.
- **`VColors`:**
  - `VColors.accentPalette`: los 14 colores del prototipo, de `#FD6A3A` (por defecto) a `#EFEBE4`;
  - `VColors.nearest(color)`: el más cercano de esa paleta; `main.dart` lo usa con el color guardado del perfil, sin migrar Firestore.
- **`VText`:**
  - `display(size, {weight 800, stretch 62, height .9, tracking −.01 em})`;
  - `ui(size, {weight 400, height, stretch 100})`;
  - `mono(size, {weight 500, tracking .08 em})`;
  - `quote(size)`: Newsreader itálica con `opsz` igual al tamaño;
  - el interlineado se reparte como en CSS y, sin `height`, es el "normal" de la fuente (1,088 en Archivo, 1,3 en Plex y 1,0 en Newsreader, igual que en el navegador).
- **`VSpace`:** `page` = 20 y `tabBarClearance` = 24.
- **`buildViniloTheme`:** radio 0, sin elevación, sin salpicadura, campos con línea debajo, avisos planos y diálogos planos.

**`lib/theme/score.dart`:** `Score.label` (los veredictos nuevos: Terrible … Obra maestra), `Score.formatAverage` (coma en español) y `contrastRatio`. La escala de colores de notas ya no existe.

**`main.dart`:** fija el tamaño de letra en el estándar (`withClampedTextScaling`) y construye los temas con `VColors.nearest(profile.color)`.

### Componentes nuevos (`lib/widgets/`)

- **`v_icons.dart`:**
  - `VIconView(VIcon.x, size:, color:)` dibuja trazos SVG con el grosor del prototipo;
  - íconos del prototipo: `back`, `share`, `addToList`, `bell`, `search`, `close`, `settings`, `more`, `plus`, `check`, `list` y `ranking`;
  - propios, en el mismo estilo: `heart`, `heartFilled`, `arrowUpLeft` (↖), `pencil`, `trash`, `camera`, `image`, `drag`, `chevronRight`, `chevronDown`, `signOut` y `send`;
  - ♥, ♡, ✓ y ↖ no existen en Archivo ni en Plex Mono, así que siempre van como ícono.
- **`v_buttons.dart`:**
  - `Pressable`: imita el hover con el dedo encima;
  - `VPrimaryButton`: tinta; `.accent` y `.tone(color:)`, 56 de alto, texto a la izquierda y "→"; acepta `leading`, `center`, `busy`, `height` y `fontSize`;
  - `VSecondaryButton`: borde `lineStrong` que pasa a tinta al presionar; acepta `trailing`, `center`, `borderColor` y `color`;
  - `VIconButton`: 40×40, en estilo `bordered`, `filled` o `plain`; acepta `fill` y `child`.
- **`v_sections.dart`:**
  - `VMono`: texto mono en mayúsculas;
  - `VSectionHeader(label, action:, onAction:)`: mono, línea arriba, relleno 10 20;
  - `VBlockTitle(title, subtitle:, action:, trailing:)`: 30 px con ancho 70 % y peso 700;
  - `VTabs`: subrayado de acento de 2 px;
  - `VEmptyState` y `VSkeleton`.
- **`v_bottom_bar.dart`:** `VBottomBar`, que ya usa `ShellScreen`; la barra nativa Liquid Glass ya no se usa y su Swift sigue registrado sin uso.
- **`v_ruler.dart`:**
  - `Histogram10(counts:, height:, color:, barMargin:)`: la barra más alta mide `height − 4`; las columnas sin votos son una raya de 2 px en tinta .2;
  - `RulerNumbers(onlyEnds:)`;
  - `RulerCells(selected:, onTap:, selectedColor:, fill:, lines:)`: las celdas anteriores a la elegida usan `fillAlphas`, de .28 a .82.
- **`rating_bars.dart`:**
  - `RatingBarSpec.of(k, n)`: las fórmulas exactas de la especificación;
  - `RatingBars(value:, onChanged:)`: 220 ms ease-out, se toca o se arrastra, un háptico por columna; llaves `dial-N`;
  - todavía no se usa: la hoja de Calificar sigue con el dial viejo hasta la fase 4.
- **`sheet.dart`:**
  - `SheetScaffold`, con el estilo nuevo: fondo `sheet`, sin radio, asa de 40×4, título de 46, y `overline`, `footer` y `titleSize`;
  - `showVSheet`, con velo .72;
  - `showConfirmSheet(title:, message:, confirmLabel:, danger:)`, que reemplaza los `AlertDialog`;
  - `SheetAction`, una fila plana con `vicon`.
- **`line_field.dart`:** `LineField`, con etiqueta mono, línea de 1 px que pasa a 2 px de acento con foco, cursor de 2 px, `maxLength` con contador "13/60", `prefix` "@", `status` junto a la etiqueta, `trailing` y `error`.
- **`v_choices.dart`:**
  - `SegmentedBoxes`: los selectores de Configuración;
  - `ChoiceBox(icon:, title:, subtitle:, selected:)`: las cajas Lista y Ranking, con check de 14 px;
  - `DashedBox`.
- **`cover_stack.dart`:** `CoverStack(urls:, size:, offset:, separator:, single:)`, con portadas apiladas y una separación de 2 px del color de fondo.
- **Widgets viejos rediseñados que conservan su API:**
  - `AlbumCover` e `ArtistAvatar`: cuadrada y redondo, sin sombra;
  - `UserAvatar`: fondo `personTone`, `ring` de 4 px por fuera y `filled` para Configuración;
  - `ScoreBadge` y `ScoreNumeral`;
  - `misc.dart`: `SectionHeader` pasa a `VBlockTitle`, `GlassIconButton` a botón cuadrado, `AmbientGlow` no dibuja nada, `Pill` pasa a caja con borde, `ChoicePill` a texto subrayado, `SectionSwitch` a `VTabs`, y `Skeleton` y `EmptyState` quedan planos.

**Pruebas nuevas:** `test/theme_test.dart` (reescrita), `test/oklch_test.dart` y `test/rating_bars_test.dart`.

### Lo que sumaron las fases 2 y 3: usar esto también

- **Acceso (`widgets/auth_page.dart`):** `AuthScaffold(title:, body:, bottom:, showBack:, bodyTop:)` (volver, "VINILO" mono, título de 64, campos arriba y botones a 38 del borde, con scroll si sale el teclado), `AuthDivider` (la raya con "o"), `AuthSwitchLine` ("¿No tienes cuenta? Crear cuenta") y `AuthParagraph`. `WelcomeMasthead` (en `welcome_screen.dart`) lo comparte el splash.
- **`VTextLink`** (`v_buttons.dart`): enlace subrayado de una línea, con la raya donde la pone `text-underline-offset: 3px`. Dentro de un párrafo que se parte, `TextDecoration.underline`.
- **`LineField`:** ahora acepta `leading` (la lupa) y `errorKey`. **`UsernameField`** es un `LineField` con "✓ Disponible / Comprobando… / Ocupado" junto a la etiqueta.
- **`VPageHeader`** (`v_sections.dart`): encabezado de pantalla empujada (volver, título de 50, etiqueta mono y acción mono a la derecha). Lo usan Notificaciones, Popular y Ver todos.
- **`AlbumTile`** (`album_strip.dart`): portada, título 14/600 y artista (con media a la derecha, o "Artista · año" sin ella). **`AlbumStrip`** es el carrusel de 136 (separación 12) y **`AlbumGrid`** (`album_grid.dart`) la cuadrícula de 2 columnas (18 y 12) en filas, con `AlbumGridSkeleton`.
- **`FeedCard`** es la fila de actividad; **`LikeButton(showLabel:)`** (♥ en énfasis, "Te gusta"/"Me gusta" o el número) y **`RepliesButton(label:)`** son acciones mono con 8 de relleno arriba y abajo para el toque.
- **`PersonRow`:** fila como las de notificaciones (avatar de 36, nombre y @usuario mono, línea suave arriba); `trailing: SizedBox.shrink()` quita el botón de seguir.
- **`UserAvatar(initialSize:)`**, **`AlbumCover(placeholderColor:)`** y **`RulerCells(selectedWeight:)`**.
- **Datos:** `WebService` (`services.web.welcomeCovers()`, `GET /portadas` de la función `web`), `siblingFunctionUrl` (`util/function_url.dart`), `looksLikeEmail` (`util/email.dart`), `RatingsRepo.popularThisWeek` + `models/popular.dart`, `freshCount` (`models/feed.dart`), `dayGroup` (`util/format.dart`), `AppNotification.parts` (la frase en trozos con negritas), `SpotifyApi.searchArtistsPage` + `ArtistPage`.
- **Rutas nuevas:** `openPopular` y `openSearchAll(query:, kind:)`.
- **El prototipo no fija `box-sizing`:** un borde suma al tamaño (el punto de la campana es 8 + 2 de anillo por lado = 12).

### Lo que sumaron las fases 4 y 5: usar esto también

- **Tono de portada:** `PaletteService.dominant` devuelve el color dominante tal cual (sin los límites del resplandor viejo) y los grises van en su propio grupo, así una portada gris da un gris. Se usa `coverTone(color)` para la nota, el artista, el botón y los comentarios, y el color crudo para las celdas de la regla; sin color, el énfasis. `PaletteService.pick` es público para las pruebas (`test/palette_test.dart`).
- **`RulerCells(afterNumberColor:)`:** los números después de la nota elegida van apagados (tinta al 50 %) en el disco calificado.
- **`ShareButton(style:, fill:)`:** ya es un `VIconButton` cuadrado con `VIcon.share`; por defecto `filled` (sobre fotos) y `bordered` en pantallas lisas.
- **`AlbumStrip(yearOnly:)` / `AlbumTile(yearOnly:)`:** debajo del título solo el año ("Más de…").
- **`RepliesButton(label:)`:** el texto reemplaza solo "Comentar" cuando no hay respuestas; con respuestas siempre dice "N respuestas".
- **`CommentCard`:** la fila de "Comentarios destacados" (nota en 52 en `tone`, nombre, hora, cita Newsreader 21 entre comillas, ♥ y "Responder"), sin margen a los lados y con `last`. En el hilo, `onReply` y `replyKey` hacen que "Responder" escriba ahí mismo. La usan el disco, "Ver todos" (`comments_screen.dart`) y el hilo.
- **`VPageHeader(titleKey:, topTrailing:)`:** algo a la derecha del botón de volver (compartir en el hilo).
- **`showListPicker(overline:)`:** "Canción · Tabú", "Disco · Bocanada" o "3 canciones · Bocanada" sobre el título.
- **`ScoreHistogram`** (`histogram.dart`) ya dibuja `Histogram10` en énfasis con "1" y "10"; el perfil lo sigue usando hasta la fase 6.
- **Íconos nuevos:** `VIcon.track` (nota) y `VIcon.disc` (funda con su disco), para las cajas Canciones y Discos de Nueva lista.
- **`sortDiscography`** (`models/artist_stats.dart`): recientes (el orden de Spotify) o mejor calificados (promedio, luego más notas, sin notas al final).
- **Hoja de Calificar:** `rating_sheet.dart` ya usa `RatingBars`; `rating_dial.dart` quedó sin uso y se borra en la fase 9. `ratingNoteMaxLength` = 180.
- **Llaves nuevas:** `rating-close`, `rating-number`, `rating-verdict`, `album-meta`, `album-title`, `album-community`, `album-rate`, `album-ruler`, `album-bar`, `album-buttons`, `album-footer`, `album-retry`, `friends-average`, `more-artist`, `more-N`, `comment-like-N`, `ruler-N`, `reply-left`, `artist-overline`, `artist-name`, `artist-sort`, `artist-retry`. `rate-button` ahora es "Calificar este disco" (ya no hay lápiz flotante); `rating-edit` es "Tu nota · editar" y `rated-N` la nota al lado.

---

## Fase 2 — Acceso: Bienvenida, Iniciar sesión, Crear cuenta

**Archivos:**
- pantallas: `lib/screens/welcome_screen.dart`, `sign_in_screen.dart`, `sign_up_screen.dart`, `onboarding_screen.dart`, `username_screen.dart`, `link_account_screen.dart` y `splash_screen.dart`;
- widgets: `lib/widgets/auth_page.dart` (se convierte en `AuthScaffold`), `email_password_form.dart` y `username_field.dart`;
- fuera de `lib/`: `functions/web.js` y `firestore.rules`.

**Pantallas del prototipo:**
- **Bienvenida:**
  - arriba, "Nº 001 · Diario de discos" con línea debajo, y "VINILO" en 128 con peso 900 y ancho 62 %;
  - una rejilla de 4×2 portadas con separación de 2, y "Tu diario de discos empieza aquí." en 30 con ancho 80 % y peso 600;
  - el párrafo de 15 en `ink2` y la regla 1–10 (`RulerCells(lines: true)`) con el 10 en acento;
  - los botones "Crear cuenta →" (tinta) y "Ya tengo cuenta →" (con borde), a 38 del borde inferior.
- **Iniciar sesión:**
  - volver con borde, "VINILO" en mono y "Iniciar / sesión" en 64 con peso 800;
  - los campos "CORREO O USUARIO" y "CONTRASEÑA" con "MOSTRAR", y "¿Olvidaste tu contraseña?" subrayado;
  - abajo, "Entrar →", el divisor "o", "Continuar con Apple", "Continuar con Google" y "¿No tienes cuenta? Crear cuenta".
- **Crear cuenta:**
  - "Crear / cuenta" y los campos Nombre, Usuario (con "✓ Disponible" en `success`), Correo y Contraseña ("Mínimo 8 caracteres");
  - el texto de Términos y Privacidad, "Crear cuenta →" y "¿Ya tienes cuenta? Iniciar sesión".

**Comportamiento:**
- **Crear cuenta en una sola pantalla:**
  - el @usuario se comprueba en vivo con lo que ya existe (`UsernameField` y `UserRepo.isUsernameAvailable`);
  - al enviar: `AuthService.signUp`, después `UserRepo.create(name, username, colorValue: #FD6A3A)` y después `popUntil(first)`;
  - la contraseña nueva pide mínimo 8 caracteres; al entrar se aceptan 6 o más, para no dejar fuera a nadie;
  - si `create` falla porque alguien tomó el @usuario un instante antes, la cuenta ya existe y `main.dart` muestra `OnboardingScreen`, que ahora se ve igual (solo Nombre y Usuario) y termina el perfil.
- **Términos, Privacidad, Apple y Google:** se ven como en el prototipo y al tocarlos no pasa nada.
- **"Correo o usuario":** si lo escrito no es un correo, "Entrar" muestra "Por ahora entra con tu correo" debajo del campo.
- **"¿Olvidaste tu contraseña?":** usa `AuthService.sendPasswordReset`, que ya existe, en una `VSheet` en vez de un diálogo.
- **Portadas de la Bienvenida:**
  - una ruta nueva `GET /portadas` en `functions/web.js` devuelve las URLs de las 8 portadas más calificadas (datos públicos, caché de 1 h);
  - la app saca la URL de `SPOTIFY_FN_URL` cambiando `/spotify` por `/web`, como hace `AccountService`;
  - sin respuesta, se muestran los 8 colores planos del prototipo;
  - para desplegar la función hay que pedirle permiso a Manuel en ese momento.
- **`firestore.rules`:** `usernames/{u}` permite `get` sin cuenta (un documento a la vez, sin listar), porque el "✓ Disponible" se revisa antes de que exista la cuenta. Las reglas todavía no están desplegadas.
- **Pantallas sin diseño:**
  - la carga inicial muestra solo el fondo con "VINILO" en el mismo sitio que la Bienvenida;
  - elegir @usuario y guardar una sesión anónima usan el mismo `AuthScaffold`.

**Verificación:**
- `flutter analyze` y `flutter test`;
- `node tool/web_test.js`, con una prueba nueva para `/portadas`;
- `firebase deploy --only firestore:rules,storage --dry-run`.

**Qué prueba Manuel (`R`):**
1. Cerrar sesión y revisar la Bienvenida.
2. En Crear cuenta, con un correo de prueba desechable, comprobar: el @usuario disponible y el ocupado, una contraseña de 7 caracteres rechazada, y que al terminar entra al inicio. Después borrar esa cuenta en Configuración.
3. En Iniciar sesión, entrar con su cuenta y probar:
   - "Mostrar";
   - una contraseña equivocada, que tiene que mostrar el error;
   - "¿Olvidaste tu contraseña?";
   - escribir un @usuario;
   - tocar Apple y Google, que no deben hacer nada.

## Fase 3 — Inicio y búsqueda: Inicio, Notificaciones, Buscar, Resultados

**Archivos:**
- pantallas: `lib/screens/home_screen.dart`, `notifications_screen.dart` y `search_screen.dart`;
- widgets: `lib/widgets/feed_card.dart` (`FeedCard`, `LikeButton`, `RepliesButton`), `album_strip.dart`, `bell_button.dart` y `person_row.dart`;
- servicios: `lib/services/ratings_repo.dart` y `spotify_api.dart`;
- nuevos: `lib/screens/popular_screen.dart` y `search_all_screen.dart`, con sus rutas en `routes.dart` (`openPopular` y `openSearchAll`).

**Pantallas:**
- **Inicio:**
  - arriba, "VINILO" en 36 con peso 900 y ancho 62 %, y la campana de 22 sin borde con un punto de acento de 8 px con anillo del color de fondo;
  - "POPULAR ESTA SEMANA · VER TODO": carrusel de portadas de 136, separación 12, título 14/600, artista 12 y promedio en 28 con ancho 65 % en acento;
  - "ACTIVIDAD DE TUS AMIGOS · N NUEVAS": cada fila con avatar de 22, "Nombre calificó" y la hora en mono; debajo, la portada de 76, el título en 24 con ancho 75 %, "Artista · año", la nota en 64 en acento con el veredicto en mono, y "♥ TE GUSTA · COMENTAR".
- **Notificaciones:**
  - volver con borde, "Notificaciones" en 50, "N SIN LEER" y "BORRAR TODAS";
  - encabezados por día y filas con avatar de 36, texto 14,5 con nombres y disco en negrita, la hora en mono y un punto de acento de 8 en las no leídas;
  - las leídas van al 78 %.
- **Buscar:** "Buscar" en 56, campo con lupa y línea debajo, "RECIENTES" con ↖, y "PARA EMPEZAR" en 30 con ancho 70 %, separados por "/".
- **Resultados:**
  - el campo con × y "ARTISTAS · VER TODOS" con círculos de 80;
  - "ÁLBUMES · VER TODOS" en 2 columnas (separación 18 y 12) con título 14/600 y "Artista · año".

**Comportamiento:**
- **Popular esta semana:**
  - en `RatingsRepo`, un `popularThisWeek()` nuevo busca los `albums` con `lastRatedAt` de los últimos 7 días (índice de un solo campo) y los ordena en el cliente por `ratingsCount`;
  - "Ver todo" abre `PopularScreen`, una cuadrícula de 2 columnas.
- **"N nuevas":** son las notas de sus amigos de las últimas 24 h; si hay 0, no se muestra.
- **Fila de actividad:**
  - si la nota tiene comentario, va en Newsreader itálica, como en los comentarios;
  - "COMENTAR" pasa a "N RESPUESTAS" cuando hay respuestas;
  - el corazón es un ícono lleno o vacío.
- **Notificaciones:**
  - se agrupan por día (Hoy, Ayer, Esta semana, luego mes y año) con un `dayGroup()` nuevo en `lib/util/format.dart`;
  - los puntos de "sin leer" se quedan durante la visita, como ya hace `_wasUnread`;
  - deslizar para borrar se queda, con fondo plano, y "Borrar todas" usa `showConfirmSheet`.
- **Buscar:**
  - tocar un reciente lo escribe y busca;
  - "Personas" no está en el prototipo, así que va en filas como las de las notificaciones: avatar de 36, nombre y @usuario.
- **"Ver todos":** abre `SearchAllScreen`, que carga por páginas; en Álbumes usa `SpotifyApi.search(offset)`. Para Artistas, `SpotifyApi.searchArtists` acepta `offset` y devuelve una página (la función ya pagina en `/artists/search`).

**Verificación:**
- `flutter analyze` y `flutter test`;
- pruebas nuevas: `test/popular_test.dart` (ventana de 7 días y orden) y `dayGroup` en los dos idiomas.

**Qué prueba Manuel (`R`):**
- **Inicio:** el carrusel, "Ver todo", dar y quitar like en la actividad y "Comentar", que abre el hilo.
- **Notificaciones** (desde la campana): los grupos, los puntos, deslizar para borrar y "Borrar todas" (cancelando).
- **Buscar:** recientes, sugerencias y resultados; "Ver todos" de artistas y de álbumes; y buscar "@vale" para ver personas.

## Fase 4 — Disco: sin calificar, calificado, Calificar, Agregar a una lista, Nueva lista, final

**Archivos:**
- pantallas: `lib/screens/album_screen.dart` (el más grande), `list_picker_sheet.dart`, `list_form_sheet.dart`, `add_to_list_sheet.dart`, `comments_screen.dart` y `rating_thread_screen.dart`;
- widgets: `lib/widgets/rating_sheet.dart` (usar `RatingBars`), `histogram.dart` (que pasa a `Histogram10`), `comment_card.dart` y `mention_text.dart`;
- servicios: `lib/services/palette.dart`.

**Pantallas:**
- **Encabezado del disco:**
  - la portada va a todo el ancho y cuadrada desde el borde superior, debajo de la barra de estado;
  - los botones van en fila con relleno 4 16: volver, y compartir más listas con separación 4, en `VIconButtonStyle.filled`;
  - debajo de la portada, a 18: la meta en mono ("Álbum · 1999 · 15 canciones · 1 h 10 min"), el título en 64 con ancho 65 % y peso 800, y "Artista →" en 17/500 con el tono de portada.
- **Bloque de notas:**
  - lleva línea arriba; a la izquierda "TU NOTA" con "—" en tinta .28, o "TU NOTA · EDITAR" con la nota en 56 y el veredicto en mono, en el tono de portada;
  - a la derecha, "COMUNIDAD · N NOTAS" con el promedio en 56 y " /10" en 14;
  - debajo, el histograma de 44 en tinta .35.
- **Sin calificar:** números 1–10 y el botón "Calificar este disco" con "1–10 →" en `VPrimaryButton.tone` con el tono de portada.
- **Calificado:** `RulerCells` de 36 (las anteriores con el color de la portada de .28 a .82, la propia en el tono con el número oscuro, las posteriores vacías) y "TOCA PARA CAMBIAR · BARRAS: COMUNIDAD".
- **Canciones:** "CANCIONES · MANTÉN PULSADA PARA AGREGAR", con filas de número mono, título 15 y duración en mono.
- **Disco al final del scroll:**
  - **Barra fija:** aparece al pasar la portada, con volver, compartir y listas con borde, la portada en miniatura de 24 con el nombre en 14/600, y línea debajo.
  - **Calificado por:** "Calificado por" en 30 con "N amigos"; a la derecha "PROMEDIO AMIGOS" en el tono de portada; fotos de 56 con la nota en 30 en acento, y "TOCA UNA FOTO PARA VER SU CALIFICACIÓN".
  - **Comentarios destacados:** "Comentarios destacados" con "2 de N comentarios · VER TODOS"; en cada fila, la nota en 52 en el tono de portada, el nombre, la hora, la cita en Newsreader 21 con comillas “ ”, y "♥ N · RESPONDER".
  - **Más del artista y pie:** "MÁS DE {ARTISTA} · VER ARTISTA" con carrusel de 136, y un pie mono con el ℗, "Publicado el AAAA-MM-DD" y "Datos y portadas de Spotify".
- **Hojas:**
  - **Calificar:**
    - arriba, la portada de 48, el título y el artista con el año, y × con borde;
    - el número en 150 en acento con "TU NOTA" y el veredicto en 28;
    - las `RatingBars` y "TOCA O DESLIZA";
    - el comentario en un `LineField` con "0/180", "Guardar mi nota →" en acento, y "Borrar nota".
  - **Agregar a una lista:**
    - arriba, "CANCIÓN · X" o "DISCO · X", el título en 46 y "Tus listas de canciones" o "Tus listas de discos";
    - la fila "Nueva lista" lleva una `DashedBox` en acento;
    - las demás filas llevan `CoverStack` de 56 con `separator: c.sheet` y un + con borde de 36.
  - **Nueva lista:**
    - arriba, la explicación, Nombre en 22 con "13/60" y Descripción con "0/300";
    - luego las `ChoiceBox` de Tipo (Lista con "Sin orden fijo", Ranking con "Numerado, del 1 en adelante"); "CONTENIDO" con Canciones o Discos, cuando no viene fijado;
    - "Crear lista →" en el `footer`.

**Comportamiento:**
- **Tono de portada:** `PaletteService.dominant(portada)` pasado por `coverTone`; sin color, se usa el acento.
  - `PaletteService._pick` hoy aprieta el color para el resplandor viejo (saturación .35–.85 y luminosidad .32–.52): hay que devolver el color dominante sin esos límites para que `coverTone` reciba el color real (los grises tienen que seguir grises).
- **Sin nota:** el botón abre la hoja y el lápiz flotante (`_RatePencil`) desaparece.
- **Con nota:**
  - tocar otra celda guarda al instante con `RatingsRepo.rate` y el mismo comentario, con háptico y el aviso "Nota guardada";
  - "TU NOTA · EDITAR" abre la hoja.
- **Calificar por primera vez:** no hay columna elegida y el número es "—"; "Guardar mi nota" se activa al tocar una. Al editar, arranca en la nota actual.
- **Borrar nota:** mismo flujo con "Deshacer" de 4 s.
- **Calificado por:** tocar una foto abre esa calificación con `openThread(ratingId)`, en vez del perfil.
- **Comentarios destacados:** se muestran 2 (antes 3), igual que "2 de N comentarios"; "Ver todos" abre `CommentsScreen`.
- **Sin diseño:** comentarios completos e hilo (misma fila de comentario; el campo de respuesta es un `LineField` con enviar), selección de canciones (barra plana), menú de listas del disco (`SheetAction` plano) y agregar un disco a una lista.

**Verificación:** `flutter analyze` y `flutter test` (hecho: 155 pruebas al cerrar la fase 4; nuevas `test/palette_test.dart` y `test/rating_sheet_test.dart`).

**Qué prueba Manuel (`R`):**
1. Abrir un disco sin nota y revisar la portada, los botones, la meta, la comunidad y el botón.
2. Calificar tocando y arrastrando las barras, sentir los hápticos y guardar.
3. En el estado calificado, tocar otro número para cambiar la nota, editar el comentario, borrar la nota y deshacer.
4. Mantener pulsada una canción y probar "Agregar a una lista" y "Nueva lista" (con el teclado abierto).
5. Bajar hasta el final del disco y revisar:
   - la barra fija;
   - Calificado por (tocar una foto abre el hilo);
   - los comentarios (dar like y "Ver todos");
   - "Más de…" y el pie;
   - un hilo, respondiendo.

## Fase 5 — Perfil de artista

**Archivos:** `lib/screens/artist_screen.dart` (`_ArtistScoreBlock` y `_AlbumRow`) y `lib/widgets/artist_avatar.dart`. Se reutiliza `ArtistSummary` (`lib/models/artist_stats.dart`).

**Pantalla:**
- **Encabezado:**
  - arriba, volver y compartir con borde, y la foto redonda de 140;
  - luego "ARTISTA · N DISCOS" y el nombre en 64 con ancho 62 %.
- **Calificación:**
  - un bloque con línea arriba: "CALIFICACIÓN" en 72 en acento con " /10" y "N notas · M discos";
  - al lado, `Histogram10` de 60 en acento con margen de 1 px y "1" y "10" en las puntas.
- **Discografía:**
  - "DISCOGRAFÍA · N DISCOS · RECIENTES ↓";
  - filas con portada de 56, título 15/600, "2025 · ÁLBUM · 1 NOTA" o "SIN NOTAS" en mono, y la nota en 34 en el tono de su portada, o "—" en tinta .25.

**Comportamiento:**
- "RECIENTES ↓" alterna con "MEJOR CALIFICADOS ↓" y ordena por promedio los discos ya cargados; los que no tienen nota van al final.
- "N discos" sale de `AlbumPage.total`.
- El tono de cada fila se saca de la portada pequeña, con la caché de `PaletteService`.
- Se quitan los géneros (Spotify los manda vacíos) y el resplandor.

**Verificación:** `flutter analyze` y `flutter test` (hecho: 157 pruebas; `artist_stats_test.dart` cubre el orden).

**Qué prueba Manuel (`R`):** desde un disco, tocar el artista y revisar el encabezado, la calificación, la discografía, el cambio de orden, que siga cargando al bajar, y compartir.

## Fase 6 — Perfiles: amigo (siguiendo y sin seguir), Mi perfil, Mi perfil · listas

**Archivos:**
- `lib/screens/profile_screen.dart`: tiene 1840 líneas, así que se parte en `profile_header.dart`, `profile_tab.dart` y `profile_lists_tab.dart`;
- widgets: `lib/widgets/follow_button.dart`, `user_avatar.dart`, `diary_row.dart`, `list_row_tile.dart`, `list_mosaic.dart` (pasa a `CoverStack`) y `person_row.dart`;
- pantallas y hojas: `follow_list_screen.dart`, `diary_screen.dart`, `edit_profile_sheet.dart` y `profile_form.dart`;
- fotos: `photo_picker.dart` y `image_cropper.dart`, solo los controles.

**Pantallas:**
- **Encabezado:**
  - un banner de 156: la foto, o `coverShade(colorDeLaPersona, lightness: 0.35)` si no tiene;
  - botones `filled`: volver y compartir en el ajeno; compartir y ajustes (`VIcon.settings`) en el propio;
  - avatar de 88 con `ring`, montado 44 sobre el banner;
  - nombre en 50, "@usuario · TE SIGUE" y la biografía en 14,5 con `inkA(.78)`.
- **Botón de seguir:** 48 a lo ancho; "+ Seguir" con fondo de acento, o "✓ Siguiendo" con borde y texto en acento.
- **Cifras y afinidad:**
  - 4 cifras en una fila con líneas: DISCOS, PROMEDIO, SEGUIDORES y SEGUIDOS (o SEGUIDO);
  - la afinidad en 80 en acento con "AFINIDAD MUSICAL" y "Según N discos en común";
  - `VTabs` con Perfil y Listas.
- **Mi perfil:**
  - "Favoritos" con "Tres discos y tres artistas que me definen": DISCOS con portadas y nombre, ARTISTAS con círculos y nombre;
  - "CÓMO CALIFICO · PROMEDIO X" con `Histogram10` de 56 en acento y los números;
  - "Diario" con "N discos calificados", encabezados por mes ("SEPTIEMBRE 2026 · 4") y filas con el día en 24, el mes en mono, la portada de 48, el título y el artista, y la nota en 36 en el tono de portada.
- **Mi perfil · listas:**
  - "Mías²" y "Guardadas⁰" en 30 con la cifra en superíndice mono (en acento la elegida);
  - el buscador "BUSCAR por nombre o por lo que tiene" y los filtros "Todas · Listas · Rankings · Canciones · Discos";
  - "N LISTAS · RECIENTES ↓ · + NUEVA LISTA" y filas con `CoverStack` de 64, título en 21 con ancho 75 % y "LISTA · 12 CANCIONES".

**Comportamiento:**
- **"Te sigue":** sale de `FollowRepo.isFollowing(otra, yo)`.
- **Cifras:** seguidores y seguidos abren `openFollowList`.
- **Encabezado compacto:** con un `SliverPersistentHeader` fijo; cuando el encabezado grande sale de la pantalla, quedan fijos el nombre en 40, "N DISCOS · PROMEDIO" y las pestañas.
- **Favoritos:** en el propio perfil, "ELEGIR" en mono y acento junto a DISCOS y ARTISTAS abre los selectores que ya existen.
- **Perfil de un amigo:** bajo las pestañas, sus 3 favoritos en rejilla de separación 2 sin títulos, como el prototipo; debajo, artistas, Cómo califica y Diario, en el orden de Mi perfil.
- **Diario:** "VER TODO" abre `DiaryScreen`, que también se rediseña.
- **Listas:**
  - los filtros van en una sola fila y con una opción a la vez: Listas y Rankings fijan `kind`, Canciones y Discos fijan `itemType`, y Todas limpia;
  - "recientes ↓" pasa por los órdenes de `ListSort`;
  - se reutilizan `ListQuery` y `applyListQuery`.
- **Editar perfil:** los campos pasan a `LineField` y la foto y el banner a selectores planos; la biografía conserva su límite de 160.

**Verificación:** `flutter analyze` y `flutter test`; `music_list_test.dart` cubre la correspondencia del filtro único.

**Qué prueba Manuel (`R`):**
1. En su perfil revisar el banner, la foto, la biografía y las cifras (que abren seguidores). Elegir favoritos, revisar Cómo califico y el Diario, y abrir "Ver todo".
2. Bajar para ver el encabezado compacto fijo, en las dos pestañas.
3. En la pestaña Listas probar Mías y Guardadas, buscar, los filtros, el orden y "+ Nueva lista".
4. Abrir el perfil de alguien que sigue y el de alguien que no, y probar seguir y dejar de seguir. Revisar "te sigue" y la afinidad.
5. Abrir "Editar perfil" desde Configuración.

## Fase 7 — Lista, Ranking y Configuración

**Archivos:**
- `lib/screens/list_screen.dart` (`_Actions`, `_ActionPill` y `_ItemRow`);
- `lib/screens/settings_screen.dart` (`_ProfileRow`, `_AppearanceRow`, `_LanguageRow` y `_AccountCard`), junto con `ColorSwatches` de `profile_form.dart`;
- `lib/screens/delete_account_sheet.dart`.

**Pantallas:**
- **Lista y Ranking:**
  - una franja plana de 300 con `coverShade`, sacado de la portada de la lista o de su primer elemento;
  - los botones `filled` con `fill: c.bg.withValues(alpha: .45)`: volver, compartir y ···;
  - la portada de 150 sin sombra, y "LISTA" o "RANKING" con la cantidad en 44 y "CANCIONES" o "DISCOS";
  - el título en 52 si es corto y en 40 si es largo (el prototipo usa las dos medidas);
  - "Tu lista @usuario" con un avatar de 22, y los botones "+ Agregar" (tinta) y "Editar" (con borde) a 44;
  - en una lista, filas con portada de 44, título, artista y duración;
  - en un ranking, los números 1 a 3 en el tono de portada (el 1 en 60 con el título en 24 y ancho 75 %, el 2 y el 3 en 40) y del 4 en adelante en 28 con `ink4`.
- **Configuración:**
  - volver, "Configuración" en 50 y el subtítulo;
  - PERFIL: `UserAvatar(filled: true)` de 44 y "Editar perfil →" en acento;
  - APARIENCIA e IDIOMA en `SegmentedBoxes`;
  - COLOR DE ÉNFASIS: el texto y los 14 cuadros en 7 columnas con un contorno de 2 px desplazado 2 en el elegido (el elegido es `VColors.nearest` del color guardado);
  - CUENTA: el @usuario y el correo.

**Comportamiento:**
- **Listas de otras personas:** los mismos dos botones pasan a "♥ Me gusta · N" y "Guardar" o "Guardada".
- **Modo edición:** asa de arrastre y ×; al quitar, un aviso plano con "Deshacer".
- **Menú ···:** una `VSheet` con filas; borrar se confirma con `showConfirmSheet`.
- **Apariencia:** sigue guardando `users.theme`; "Claro" se ve oscuro hasta que llegue el diseño del claro.
- **Configuración, abajo del prototipo:** "Cerrar sesión" (botón secundario) y "Eliminar cuenta" (en `danger`), que abre la hoja rediseñada.

**Qué prueba Manuel (`R`):**
1. Abrir una lista suya y un ranking. Probar agregar, editar (reordenar, quitar y deshacer), la portada desde ··· y borrar (cancelando).
2. Abrir la lista de otra persona y probar "Me gusta" y "Guardar".
3. En Configuración:
   - cambiar el color y revisar botones, enlaces, pestaña, notas y avatar;
   - probar Apariencia ("Claro" se ve oscuro: se espera);
   - probar Idioma inglés y español.
4. **No** borrar su cuenta.

## Fase 8 — Web: disco compartido, artista compartido, enlace roto

**Archivos:** `functions/web.js` (CSS, `page()`, `albumPage`, `artistPage`, `notFoundPage`, `listPage`, `ratingPage`, `profilePage`, `commentCard`, `histogram` y `communityBlock`), `hosting/index.html`, `hosting/404.html` y `tool/web_test.js`.

**Diseño:**
- **Base:**
  - fuentes de Google Fonts: Archivo con `wdth` y `wght`, Plex Mono 400/500 y Newsreader itálica;
  - ancho 1200 con márgenes de 48;
  - una franja de 6 px con el color de la portada (calculado en el navegador, como el `GLOW_SCRIPT` de ahora) o `#FD6A3A`;
  - encabezado con "VINILO" en 32 y "CALIFICA TUS DISCOS DEL 1 AL 10".
- **Disco:**
  - la portada de 520;
  - el título en 120, el artista en el tono de portada, el promedio en 112, el histograma de 70 y los comentarios en 3 columnas (nota 64, nombre y cita Newsreader 28).
- **Artista:** la foto redonda de 400, el nombre en 128, el promedio en acento y "CALIFICADOS EN VINILO", con filas de portada de 88 y nota en 72.
- **Cierre de cada página:** "¿Todavía no tienes Vinilo?" con "Muy pronto en el App Store" (o el botón de descarga si hay `APP_STORE_URL`) y el pie "Datos de discos y artistas: Spotify.".
- **Enlace roto:**
  - "ERROR 404 · LADO C", "No encontramos esto" en 132 e "Ir al inicio →";
  - una columna con 3 portadas y la invitación;
  - vale para el 404 de la función y para `hosting/404.html`.
- **Sin diseño:**
  - en el móvil (menos de 820 px) todo se apila con la misma tipografía escalada, porque la mayoría abre los enlaces en el teléfono;
  - lista, nota y perfil con los mismos bloques;
  - `hosting/index.html` con el mismo estilo;
  - se quitan el resplandor y los gradientes.
- **Textos:** el diccionario `STRINGS`, con el español literal y el inglés.

**Verificación:** `node tool/web_test.js`, que cubre cada tipo de página, el escapado, el idioma y el 404.

**Despliegue:** la función `web` la despliega el agente, pero solo después de preguntarle a Manuel en ese momento. El hosting lo despliega Manuel con `firebase deploy --only hosting`.

**Qué prueba Manuel:**
- Abrir en el Mac y en el teléfono enlaces compartidos de un disco, un artista, una lista, una nota y un perfil, y uno roto (`/d/nada`).
- Mirar la vista previa en WhatsApp.

## Fase 9 — Ícono, limpieza y cierre

1. **Ícono de iOS:**
   - copiar `viniloicon copy.icon/` (en la raíz del proyecto) a `ios/Runner/AppIcon.icon` y agregarlo al target Runner con la gema `xcodeproj`, como se hizo con `NativeTabBar.swift`;
   - retirar `Assets.xcassets/AppIcon.appiconset` para que el nombre `AppIcon` apunte al `.icon`; Xcode genera las imágenes para iOS anteriores a 26;
   - revisar el proyecto con `plutil -lint ios/Runner.xcodeproj/project.pbxproj`.
2. **Android y web:**
   - generar las `mipmap-*` y el ícono adaptable a partir de la versión oscura (V en tinta sobre `#0F0E0D`);
   - en la web: `favicon.png`, `web/icons/*` y `manifest.json`, con el nombre "Vinilo" y los colores `#0F0E0D`.
3. **Limpieza:**
   - borrar Instrument Serif, Manrope, `GlassIconButton`, `AmbientGlow`, `Pill`, `ChoicePill`, `SectionSwitch`, `glass_bar.dart`, `native_tab_bar.dart`, `rating_dial.dart`, `vinyl_disc.dart` y los alias temporales de colores;
   - `NativeTabBar.swift` se puede sacar ahora del proyecto, porque este paso ya exige relanzar. Preguntarle a Manuel antes.
4. **Documentación:**
   - `CLAUDE.md`: reescribir "Dirección visual" (tokens, fuentes, componentes, barra inferior, tono de portada, decisiones), actualizar la estructura de `lib/`, las llaves nuevas y el número de pruebas;
   - marcar este plan como terminado.
5. **Informe final:** la lista de lo que no se pudo igualar y por qué, empezando por la sección de más abajo y sumando lo que aparezca en el camino.

**Qué prueba Manuel:**
- Relanzar con `flutter run -d 00008120-001625D83AC3601E --release --dart-define=SPOTIFY_FN_URL=https://us-central1-red-social-c786b.cloudfunctions.net/spotify`.
- Revisar el ícono en la pantalla de inicio, en modo claro y oscuro.
- Hacer una pasada completa por todas las pantallas comparándolas con el prototipo.

---

## Cambios de comportamiento acordados

1. **Crear cuenta en una sola pantalla** (fase 2):
   - la contraseña nueva pide mínimo 8 caracteres;
   - el color arranca en bermellón y la foto se pone después.
2. **Portadas de la Bienvenida:** desde `GET /portadas` de la función `web`, con colores planos si no responde (fase 2).
3. **Popular esta semana** con "Ver todo" (fase 3).
4. **"N nuevas":** las notas de amigos de las últimas 24 h (fase 3).
5. **Disco calificado:** la regla se toca para cambiar la nota al instante, y "Tu nota · editar" abre la hoja (fase 4).
6. **Calificar por primera vez:** arranca sin columna elegida (fase 4).
7. **Calificado por:** tocar una foto abre esa calificación (fase 4).
8. **"@usuario · te sigue"** en perfiles ajenos (fase 6).
9. **Notificaciones agrupadas por día** (fase 3).
10. **"Ver todos"** en Resultados, más la sección Personas con el mismo estilo (fase 3).
11. **Discografía:** "Recientes ↓" alterna con "Mejor calificados ↓" (fase 5).
12. **Filtros de listas** en una sola fila, con una opción a la vez (fase 6).
13. **"Elegir"** junto a Discos y Artistas en el perfil propio (fase 6).
14. **Perfil de un amigo:** sus 3 favoritos en rejilla y después el orden de Mi perfil (fase 6).
15. **Textos en español como en el prototipo** (los veredictos ya se cambiaron en la fase 1); el inglés se traduce igual.

Van también los ajustes chicos que se anotaron en cada fase: 2 comentarios destacados en vez de 3, el mensaje "Por ahora entra con tu correo" y que el lápiz flotante desaparezca.

## Diferencias entre el HTML y la especificación (manda la especificación)

- **Portada de Lista y Ranking:** sin la sombra que tiene en el HTML.
- **Hoja de Calificar:** `#171615` y velo al 72 % (el HTML usa `#161513` y 60 %).
- **Barras de Calificar:** 220 ms ease-out, sin el rebote de 0,45 s.
- **Campo con foco:** línea de 2 px en acento en todas partes (el HTML la pone en tinta en acceso y buscar).
- **Etiqueta activa de la barra inferior:** tinta 600 con la raya de acento (el HTML a veces la pinta de acento).
- **Subrayado de las pestañas:** siempre en acento ("Mi perfil · listas" lo tiene en tinta).
- **Excepción:** las barras de la comunidad en el disco quedan como en el HTML, en tinta al 35 %, porque conviven con la regla del tono de portada. Cambiarlas a acento es una línea.

## Lo que ya se sabe que no quedará idéntico al píxel

- **Zona superior:** la barra de estado, la isla y el indicador de inicio son del sistema, así que el contenido empieza unos 5 pt más abajo que en el prototipo.
- **Ancho:** el iPhone no mide 390, así que los carruseles muestran otra fracción de la tercera portada.
- **Cortes de línea:** Flutter no tiene `text-wrap: pretty`, así que algún párrafo puede cortar en otra palabra.
- **Hover:** no existe en pantalla táctil; se usa como estado presionado (`Pressable`).
- **Símbolos:** ♥, ♡, ✓ y ↖ son íconos propios, con una forma parecida pero no igual a la fuente del sistema del navegador.
- **Portadas y tonos:** van las portadas reales en vez de colores con rayas, y los tonos se calculan (en el prototipo se eligieron a mano).
- **Suavizado del texto:** difiere en subpíxeles entre Chrome en Mac y Flutter en iOS.
- **Tema claro:** por ahora se ve igual que el oscuro, hasta que llegue su diseño.
- **Botones de acceso:** Apple, Google, Términos y Privacidad se ven pero no hacen nada, por decisión de Manuel.
- **Disco (fase 4):**
  - el pie muestra el texto de derechos tal como lo manda Spotify ("℗ 1999 …", "(P) 1999 …" o "© …"), y no muestra el sello (el modo desarrollo de Spotify no lo manda);
  - las canciones con artistas invitados llevan una segunda línea con ellos, que el prototipo no tiene (sus canciones no tienen invitados);
  - "Comentarios destacados": si un comentario tiene respuestas, dice "N respuestas" en vez de "Responder";
  - la barra fija aparece con un fundido corto al pasar la portada, y la portada no rebota al tirar hacia abajo (así no se ve el fondo encima);
  - sin diseño en el prototipo: la selección de canciones (casillas cuadradas y una barra plana abajo), el menú de listas del disco, "Ver todos" los comentarios, el hilo y agregar desde una lista.
- **Artista (fase 5):** sin notas, el bloque dice "—" y "Sin notas" (el prototipo no tiene ese estado); el tono de cada disco se calcula de su portada pequeña.

## Verificación (resumen)

- **Cada fase:** `flutter analyze` sin avisos y `flutter test` en verde (131 pruebas al terminar la fase 1, más las nuevas de cada fase).
- **Fases 2 y 8:** además, `node tool/web_test.js`.
- **Fase 2:** además, el `--dry-run` de las reglas.
- **Fase 9:** además, `plutil -lint` del proyecto de Xcode.
- **Revisión de Manuel:** sin simulador, driver ni capturas. Revisa en el iPhone con la lista de cada fase.
- **Cómo se ven los cambios:**
  - la fase 9 exige relanzar `flutter run` por el ícono, y la fase 1 también lo exigía por las fuentes;
  - las demás se ven con `R`, o con `Shift+R` si cambió una clase `const`; hay que decírselo en cada cierre.
