# Sistema visual de Vinilo: referencia

Lo que dejó el rediseño (terminado el 2026-09-25) y sigue vigente: decisiones de Manuel, componentes con sus parámetros, diferencias con el prototipo y lo que no quedó idéntico. Las menciones a "fase N" son del rediseño y quedan como historia. Para cómo se ve la app manda `CLAUDE.md` ("Dirección visual") junto con `ESPECIFICACION.md` y los prototipos (`Vinilo App.dc.html`, `Vinilo Landing.dc.html`, `Vinilo Compartir.dc.html`).

## Decisiones tomadas con Manuel (2026-09-25)

- **Tema claro:** se quedan el claro y el oscuro, y Configuración conserva "Apariencia" como en el prototipo. Por ahora la paleta clara es igual a la oscura (`ViniloPalette.light = dark`); el diseñador ya definió el claro en `ESPECIFICACION.md` ("Modo claro", entregado el 2026-09-25) y falta implementarlo. Todo color sale de los tokens para que después el claro entre sin tocar pantallas.
- **Verificación:** solo Manuel, en su iPhone. El agente no usa simulador, `flutter run`, driver, capturas ni pruebas golden, aunque el prompt original del diseñador pidiera capturas. Verifica con `flutter analyze` y `flutter test`.
- **Acceso:**
  - "Continuar con Apple", "Continuar con Google", "Correo o usuario" y los enlaces a Términos y Privacidad quedan tal cual el prototipo, aunque no funcionen (al tocarlos no pasa nada).
  - Si alguien escribe un @usuario y toca "Entrar", debajo del campo aparece "Por ahora entra con tu correo".
- **Mi perfil · listas:** el encabezado compacto (nombre y "N discos · promedio") más las pestañas se quedan fijos arriba al hacer scroll, en las dos pestañas.
- **Ícono:** `viniloicon copy.icon/`, en la raíz del proyecto, hecho por Manuel en Icon Composer, con versión clara y oscura (fase 9).
- **Cambios de comportamiento:** los 15 de su sección, más abajo, están aceptados.

## Componentes y tokens: usar esto, no reinventarlo

### Colores y tipografía

**Fuentes** (`assets/fonts/`, declaradas en `pubspec.yaml`, con sus licencias OFL al lado):
- `Archivo`, variable: ejes `wdth` 62–125 y `wght` 100–900;
- `PlexMono`: pesos 500, 600 y 700;
- `Newsreader`: itálica variable, con `opsz` y `wght`;

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
  - `RatingBars(value:, onChanged:, onEnd:)`: 220 ms ease-out, se toca o se arrastra, un háptico por columna; `onEnd` avisa al soltar el dedo (lo usa la bienvenida); llaves `dial-N`;
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
- **`pull_stretch.dart`** (2026-09-25): `pullPhysics` (rebote en iOS y Android), `pullExtent(controller)` (cuánto se tiró de más arriba), `PullStretch(controller:, height:)` (escala desde el centro del borde de abajo: crece hacia arriba lo que se tira) y `PullPinned` (se queda quieto al tirar). Lo usan el disco, el perfil (`ProfileHeader(scroll:)`), la lista y el artista.
- **`cover_stack.dart`:** `CoverStack(urls:, size:, offset:, separator:, single:)`, con portadas apiladas y una separación de 2 px del color de fondo.
- **Widgets viejos rediseñados que conservan su API:**
  - `AlbumCover` e `ArtistAvatar`: cuadrada y redondo, sin sombra;
  - `UserAvatar`: fondo `personTone`, `ring` de 4 px por fuera y `filled` para Configuración;

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
- **Íconos nuevos:** `VIcon.track` (nota) y `VIcon.disc` (funda con su disco), para las cajas Canciones y Discos de Nueva lista.
- **`sortDiscography`** (`models/artist_stats.dart`): recientes (el orden de Spotify) o mejor calificados (promedio, luego más notas, sin notas al final).
- **Revisión de las fases 4 y 5 (2026-09-25, en la Mac):** `SheetScaffold` pone el botón fijo (`footer`) a 38 del borde de abajo como el prototipo (a 20 del teclado si está abierto), y `PaletteService.cached(url)` da el color ya sacado sin esperar: el disco y la discografía lo usan para no pasar un cuadro por el énfasis antes del tono.
- **Hoja de Calificar:** `rating_sheet.dart` ya usa `RatingBars`. `ratingNoteMaxLength` = 180.
- **Llaves nuevas:** `rating-close`, `rating-number`, `rating-verdict`, `album-meta`, `album-title`, `album-community`, `album-rate`, `album-ruler`, `album-bar`, `album-buttons`, `album-footer`, `album-retry`, `friends-average`, `more-artist`, `more-N`, `comment-like-N`, `ruler-N`, `reply-left`, `artist-overline`, `artist-name`, `artist-sort`, `artist-retry`. `rate-button` ahora es "Calificar este disco" (ya no hay lápiz flotante); `rating-edit` es "Tu nota · editar" y `rated-N` la nota al lado.

### Lo que sumaron las fases 6 y 7: usar esto también

- **Perfil partido en tres:** `profile_screen.dart` (datos, pestañas y la barra compacta fija: aparece cuando las pestañas del contenido llegan a donde van las suyas, medido con una `GlobalKey`), `profile_header.dart` (`ProfileHeader`: banner de `topPad + 102`, avatar de 88 montado 44, nombre, "@usuario · te sigue", biografía, `FollowButton`, las cuatro cifras y la afinidad; `ProfileCompactBar`), `profile_tab.dart` (`ProfileTab`, un `SliverMainAxisGroup`) y `profile_lists_tab.dart` (`ProfileListsTab`). Los selectores de favoritos y artistas viven en `favorites_pickers.dart` (`showFavoritesPicker`, `showArtistsPicker`).
- **`affinityBetween`** (`models/affinity.dart`, que desde el 2026-09-25 devuelve también `albums`: los `CommonAlbum` con mi nota y la suya, misma nota primero, luego menos diferencia y, empatados, el más reciente), **`CommonAlbumsRow`** (`profile_header.dart`) y **`ListFilter`** + `ListQuery.filter`/`withFilter` + `nextListSort` (`models/music_list.dart`), con sus pruebas.
- **`FollowButton`:** 48 a lo ancho ("+ Seguir" en énfasis, "✓ Siguiendo" con borde de énfasis); `compact` es de 32 para las filas.
- **`DiaryList`/`DiaryRow`:** encabezado por mes con cifra (`monthCounts`), filas de 48 con la nota en el tono de la portada (con `PaletteService.cached`).
- **`ListRowTile`:** `CoverStack` de 64, título de 21 y "Lista · 12 canciones". `list_mosaic.dart` y `histogram.dart` ya no existen.
- **`LineField(leadingGap:)`**, **`RulerCells(keyPrefix:)`** y `SheetScaffold` con alto fijo que se encoge con el teclado.
- **`ColorSwatches`:** cuadros en filas de 7 (separación 6) con el contorno de 2 px separado 2 en el elegido (`VColors.nearest`).
- **Lista y Ranking:** franja `coverShade` del color de la portada (la elegida o la del primer elemento), portada de 150, barra fija al pasar la franja (como el disco), filas de lista con portada de 44 y de ranking con el número en el tono.
- **Configuración:** secciones con línea y etiqueta mono, `SegmentedBoxes`, avatar relleno del énfasis, y debajo "Cerrar sesión" y "Eliminar cuenta" (hoja rediseñada con `LineField` y `VPrimaryButton.tone` en `danger`).

## Cambios de comportamiento acordados

1. **Crear cuenta en una sola pantalla** (fase 2):
   - la contraseña nueva pide mínimo 8 caracteres;
   - el color arranca en bermellón y la foto se pone después.
2. **Portadas de la Bienvenida:** desde `GET /portadas` de la función `web`, con colores planos si no responde (fase 2).
3. **Popular esta semana** con "Ver todo" (fase 3).
4. **"N nuevas":** las notas de amigos de las últimas 24 h (fase 3).
5. **Disco calificado:** la regla solo muestra la nota; se cambia únicamente con "Tu nota · editar", que abre la hoja (fase 4; hasta el 2026-09-25 la regla también la cambiaba al tocarla, lo quitó Manuel).
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
- **Bienvenida interactiva (2026-09-25, pedido de Manuel):** el prototipo tiene la regla 1–10 y los botones a la vista. En la app, en el hueco de los botones van "Pruébalo · ¿qué nota le pones…?" con la nota y su veredicto a la derecha (ancho fijo de 96), las barras de Calificar y "Toca o desliza"; al soltar el dedo con una nota se ve 700 ms, las barras bajan y se desvanecen (320 ms) y los botones suben con rebote (`Curves.easeOutBack`, 650 ms, el segundo 70 ms después) con un háptico suave. Es `WelcomeActions` en `welcome_screen.dart`. Por decisión de Manuel no hay otra forma de ver los botones: hay que tocar la gráfica. Las barras siguen ocupando su hueco después de irse, así nada se mueve; entre el párrafo y ellas hay 22 (antes 28 sobre los botones) para que quepa sin desplazarse en un iPhone de 874 de alto.
- **Disco (fase 4):**
  - el pie muestra el texto de derechos tal como lo manda Spotify ("℗ 1999 …", "(P) 1999 …" o "© …"), y no muestra el sello (el modo desarrollo de Spotify no lo manda);
  - las canciones con artistas invitados llevan una segunda línea con ellos, que el prototipo no tiene (sus canciones no tienen invitados);
  - "Comentarios destacados": si un comentario tiene respuestas, dice "N respuestas" en vez de "Responder";
  - la barra fija aparece con un fundido corto al pasar la portada;
  - al tirar hacia abajo estando arriba, la portada crece pegada al borde de arriba (no se ve el fondo) y vuelve con el rebote al soltar; el prototipo no lo tiene (pedido de Manuel, 2026-09-25). Lo mismo el banner del perfil, la franja de Lista y Ranking y la foto del artista; los botones de encima se quedan quietos;
  - sin diseño en el prototipo: la selección de canciones (casillas cuadradas y una barra plana abajo), el menú de listas del disco, "Ver todos" los comentarios, el hilo y agregar desde una lista.
- **Artista (fase 5):** sin notas, el bloque dice "—" y "Sin notas" (el prototipo no tiene ese estado); el tono de cada disco se calcula de su portada pequeña. Desde el 2026-09-25, a pedido de Manuel, el encabezado va centrado (foto, "Artista · N discos", nombre y calificación, con el histograma a lo ancho debajo), aunque el prototipo lo alinea a la izquierda; la discografía sigue igual.
- **Perfiles (fase 6):**
  - la barra compacta fija aparece de golpe (sin fundido) y no lleva volver: en el perfil de otra persona se vuelve deslizando desde el borde;
  - el superíndice de "Mías²" se alinea arriba de la línea, parecido al `vertical-align: super` del navegador;
  - sin diseño en el prototipo: el perfil ajeno en la pestaña Listas ("Listas" con su cifra) y "Cómo califica", los huecos vacíos de favoritos (con +), la afinidad sin discos en común ("—"), los selectores de favoritos y artistas, "Editar perfil", el diario completo (con la regla del 1 al 10 para filtrar) y seguidores/seguidos;
  - el mes del diario va en tres letras ("SEP"), como el prototipo;
  - sin diseño en el prototipo (2026-09-25, pedido de Manuel): bajo la afinidad del perfil ajeno, los discos en común en portadas de 40 con separación 2 (a lo ancho, empezando en el margen), hasta 6 y una celda "+N" sobre `surface` si hay más; tocar una abre el disco. Por decisión de Manuel no llevan las notas debajo. Sin discos en común no aparece la fila.
- **Lista, Ranking y Configuración (fase 7):**
  - el título va en 52 hasta 22 letras y en 40 si es más largo; la descripción (si la hay) va debajo, aunque el prototipo no la muestra;
  - en las listas de discos, a la derecha va el año en vez de la duración;
  - en la lista de otra persona, "♥ Me gusta · N" va en tinta (en énfasis si ya te gusta) y "Guardar" con borde ("✓ Guardada" en énfasis); la autora ya no ve cuántos "me gusta" tiene su lista;
  - sin diseño: la barra fija de la lista, el menú ···, el modo edición (× y asa) y, en Configuración, "Cerrar sesión" y "Eliminar cuenta" con su hoja.
  - en las listas y rankings de canciones, las portadas apiladas de la fila salen una por disco y, si hay menos de 3, se repiten hasta 3 (con 2 canciones o más siempre se ve la pila); la portada que elige la autora sigue yendo sola (2026-09-25).
- **Web (fase 8):**
  - la franja y el tono de portada se calculan en el navegador cuando carga la portada: un instante se ven en bermellón; si Spotify no dejara leer la imagen, se quedan en bermellón;
  - el prototipo parte el título a mano ("OK / Computer"); la página lo parte donde le toca;
  - los histogramas atenúan (al 60 %) las barras que no son la más votada, como el ejemplo del disco;
  - sin diseño: lista, nota y perfil (armados con los mismos bloques) y la versión para teléfono; `hosting/index.html` era la bienvenida de la app en grande hasta que llegó la landing del diseñador (ver "Landing");
  - la función `web` quedó desplegada; el hosting (`index.html` y `404.html`) lo despliega Manuel.
- **Landing (`hosting/index.html`, 2026-09-25):** es el prototipo `Vinilo Landing.dc.html` con estas diferencias:
  - el prototipo pone el giro y la aparición del disco en el mismo elemento, y la aparición, al terminar, deja fija la transformación y tapa el giro; aquí el contenedor aparece y el disco de dentro gira;
  - sin URLs de tienda (`APP_STORE_URL` y `PLAY_STORE_URL`, vacías arriba del script), los botones y las filas de descarga dicen "Muy pronto" en vez de la flecha y no enlazan; el estado dice "Muy pronto en iOS y Android";
  - las filas de descarga dicen "iOS 15+" y "Android 7+", lo que la app admite de verdad (el prototipo decía 16+ y 9+);
  - la portada de 64 de la demo es el cuadro liso del prototipo (la función solo da URLs, no nombres, y "Artista · 2026" junto a una portada real confundiría);
  - PRIVACIDAD, TÉRMINOS y CONTACTO se ven pero no llevan a ningún lado (decisión de Manuel: no existen esas páginas ni el correo);
  - suma el selector "ES · EN" en el nav (textos en un diccionario del script; manda `?lang=`, luego lo elegido en `localStorage` y luego el navegador), el respaldo en hex de los 6 colores OKLCH, `prefers-reduced-motion` (sin giro, sin cinta, sin rotación ni demo sola, todo visible) y el dedo en la demo (tocar o deslizar de lado);
  - la tarjeta de WhatsApp (Open Graph, en español) usa el ícono oscuro de 512 (`hosting/icon-512.png`, copia de `web/icons/Icon-512.png`), que también es el favicon grande.
- **Ícono (fase 9):** es el de Manuel en Icon Composer (la V y la barra corridas a la izquierda y abajo, con versión clara y oscura), no el boceto del prototipo (V y barra centradas); fue su decisión. Android y la web usan la versión oscura. La especificación nueva dice que el ícono se queda oscuro en los dos modos; el 2026-09-25 Manuel decidió conservar la versión clara y la oscura. El `Assets.car` que genera `actool` trae las variantes clara, oscura y teñida. Si en el iPhone se ve siempre claro, es el ajuste de íconos de iOS 18+ (mantener pulsada la pantalla de inicio → Editar → Personalizar → Oscuro o Automático) o la caché de íconos (borrar la app y reinstalarla).

