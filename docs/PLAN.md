# Vinilo: plan de cambios después del rediseño (desde el 2026-09-25)

## Contexto

El rediseño terminó el 2026-09-25 (commit `941238a`, rama `rediseno`). Manuel pidió tres cosas nuevas:
1. **Nueve cambios en la app móvil** (bienvenida interactiva, campos con doble raya, un desborde, la regla del disco, portada que se estira, portadas de listas de canciones, artista centrado, discos en común y el ícono en modo oscuro).
2. **La landing de la página web** (`hosting/index.html`), igual al prototipo `Vinilo Landing.dc.html` y también en inglés.
3. **Las imágenes para compartir** en historias de Instagram, WhatsApp y otras apps, iguales al prototipo `Vinilo Compartir.dc.html`.

**Archivos de diseño, en la raíz del proyecto:**
- `Vinilo App.dc.html` + `support.js`: el prototipo de la app (ya implementado).
- **`Vinilo Landing.dc.html`**: la landing. Nav, portada con el disco que gira, "VINILO" letra por letra, la cinta que corre, las secciones 01 a 04 y el pie. Al final, el `<script>` tiene la paleta que va rotando, la secuencia de notas y las fórmulas de las barras.
- **`Vinilo Compartir.dc.html`**: la hoja de compartir y las imágenes. Pantallas `data-screen-label`: "Hoja de compartir"; historias 9:16 ("Historia · disco", "Historia · reseña", "Historia · lista", "Historia · artista", "Historia · mi perfil", "Historia · amigo" e "Historia · mi semana"); y cuadrados 1:1 ("Cuadrado · disco" y "Cuadrado · lista").
- **`ESPECIFICACION.md`**: se actualizó el 2026-09-25 con la versión nueva del diseñador. Suma la sección **"Modo claro"** y dice que el ícono y el splash se quedan oscuros en los dos modos.
- `Vinilo Rediseño.dc.html` (en `~/Downloads/`) es una versión vieja y **no se usa**. Las capturas de `uploads/` son de la app antigua y tampoco se usan.
- `support.js`: nunca se lee. Solo sirve para abrir los prototipos en el navegador.

**Lo que hay que leer primero:** `CLAUDE.md`, este plan, `ESPECIFICACION.md` y `docs/SISTEMA.md` (componentes con sus parámetros, decisiones y lo que no quedó idéntico).

## Estado de las fases

| # | Fase | Estado |
|---|---|---|
| 1 | Arreglos rápidos: doble raya, desborde, regla sin toque, artista centrado, portadas de listas de canciones | Hecha (2026-09-25) |
| 2 | Bienvenida interactiva | Hecha (2026-09-25) |
| 3 | Portada y banner que se estiran | Hecha (2026-09-25) |
| 4 | Discos en común | Hecha (2026-09-25) |
| 5 | Ícono en modo oscuro | Hecha (2026-09-25): se queda claro y oscuro, decisión de Manuel |
| 6 | Landing web en español e inglés | Hecha (2026-09-25), falta que Manuel despliegue el hosting |
| 7 | Imágenes para compartir: las tarjetas | Hecha (2026-09-25) |
| 8 | Imágenes para compartir: hoja y envío (nativo) | Hecha (2026-09-25) |
| 9 | Tema claro (opcional: solo si Manuel lo pide) | Hecha (2026-09-25) |
| 10 | Cierre: documentación | Pendiente |

**Primer paso del agente:**
1. Leer completos `CLAUDE.md`, este plan, `ESPECIFICACION.md` y `docs/SISTEMA.md`.
2. Comprobar que está en la rama `rediseno` (hacer `git pull`) y correr `flutter analyze`, `flutter test` (163 pruebas) y `node tool/web_test.js` para confirmar el punto de partida.
3. Empezar por la fase 1.

## Cómo contarle el avance a Manuel (obligatorio)

1. **Al empezar cada fase:**
   - si el entorno lo permite, marcar un capítulo ("Fase N de 10 · nombre");
   - decirle en una o dos líneas qué se va a hacer y qué archivos se van a tocar.
2. **Mientras se trabaja:** una línea de avance al empezar y al terminar cada punto, por ejemplo `Fase 1/10 · doble raya ✓ · desborde ⏳ · regla · artista · listas`. Nunca hacer muchas acciones seguidas sin decir en qué se va.
3. **Si algo falla o se sale del plan:** decírselo en ese momento, con qué pasó y qué se va a hacer.
4. **Al terminar cada fase:**
   - pasarle un resumen de lo que cambió, con el resultado de `flutter analyze` y `flutter test`;
   - pasarle la lista de qué probar: pantalla, pasos y resultado esperado;
   - decirle si basta con `R`, si hace falta `Shift+R` (cambió una clase `const`) o si hay que relanzar `flutter run` (cambió Swift, Kotlin, `Info.plist`, el manifiesto o el ícono);
   - marcar la fase como hecha en la tabla de arriba;
   - si el entorno lo permite, mandarle una notificación.
5. **Entre fases:** esperar su visto bueno o sus correcciones, salvo que él pida seguir sin esperar.

## Reglas para todas las fases

- **Pruebas:** las hace Manuel en su iPhone.
  - El agente no usa simulador, `flutter run`, el driver ni capturas.
  - Verifica con `flutter analyze`, `flutter test` y `node tool/web_test.js` (web); para las reglas, con el `--dry-run` de `CLAUDE.md`.
  - Cubre con pruebas en `test/` la lógica nueva que no dependa de la pantalla.
- **Diseño:** todo lo nuevo tiene que parecer salido de los prototipos ("Dirección visual" de `CLAUDE.md`):
  - solo tokens (`VColors.of(context)`), nunca hex en los widgets;
  - radio 0, líneas de 1 px, sin sombras ni gradientes;
  - usar los componentes que ya existen (`docs/SISTEMA.md`).
  - Lo que el prototipo no dibuja se arma con esas mismas piezas y se anota en "Lo que no quedó idéntico" de `docs/SISTEMA.md`.
- **Textos:** todo texto visible va en los dos ARB (`app_es.arb` con el texto del prototipo y `app_en.arb` con su traducción). Las etiquetas mono van en minúscula normal (las pasa a mayúsculas `VMono`). Para agregar textos sin reformatear, usar `json.dumps(…, ensure_ascii=False, indent=2)`.
- **Llaves:** conservar las `ValueKey` que existen y ponerles llaves nuevas a los controles nuevos.
- **Paquetes:** no agregar paquetes con código nativo, porque obligan a correr `pod install` y a recompilar Firebase (unos 20 minutos). Lo nativo va en Swift dentro de `ios/Runner/AppDelegate.swift` y en Kotlin dentro de `MainActivity.kt`, como el canal `vinilo/share`.
- **No hacer:** `dart format` sobre `lib/` entero ni `git checkout -- lib`.
- **Git:** trabajar en `rediseno` y hacer commit solo si Manuel lo pide.
- **Despliegues:**
  - una función (`functions:web`) la despliega el agente, pero solo después de preguntarle a Manuel en ese momento;
  - el hosting (`firebase deploy --only hosting`) lo despliega Manuel.
- **Cuentas:** nunca probar nada destructivo con @manuel ni con @holaaaa.

---

## Fase 1 — Arreglos rápidos (cambios 2, 3, 4, 6 y 7)

### 1.1 Campos con dos rayas (cambio 2, en toda la app)

**Causa, ya encontrada:**
- `LineField` (`lib/widgets/line_field.dart`) dibuja su propia línea: el borde de abajo del `Container`, con relleno 8/10.
- Su `TextField` usa `InputDecoration.collapsed`, que solo quita `border`. `enabledBorder` y `focusedBorder` los hereda de `inputDecorationTheme` (`lib/theme/vinilo_theme.dart`, líneas ~458–467), que pinta un `UnderlineInputBorder`.
- Resultado: dos rayas, la del `TextField` pegada al texto y la del `LineField` más abajo. Todos los campos de la app son `LineField`, así que el arreglo en un solo sitio los corrige todos.

**Arreglo:**
- **Quién decide:** Manuel pidió dejar "solo una, sobre la que escribo". Quedará **una sola línea**, la de `LineField`, que es la que cambia a 2 px de énfasis con foco y a `danger` con error.
- **En `LineField`:** pasar una `InputDecoration` sin ningún borde (`isCollapsed: true`, `contentPadding: EdgeInsets.zero` y `border`, `enabledBorder`, `focusedBorder`, `disabledBorder`, `errorBorder` y `focusedErrorBorder` en `InputBorder.none`).
- **En el tema:** quitar también los bordes de `inputDecorationTheme` (dejar `InputBorder.none`), para que ningún campo futuro vuelva a heredar una raya.
- **Distancia de la línea:** revisar que quede donde la pone el prototipo (8 arriba y 10 abajo del texto, en los bloques "Iniciar sesión" y "Crear cuenta"). Si a Manuel la línea le queda lejos del texto al probarlo, se ajusta el relleno de abajo.
- **Prueba:** un widget test que monte un `LineField` y compruebe que la decoración efectiva del `TextField` no tiene borde (por ejemplo, `InputDecorator` con `decoration.enabledBorder == InputBorder.none`, o que solo haya un `Border` inferior).

### 1.2 "BOTTOM OVERFLOWED BY 8.0 PIXELS" (cambio 3)

**Dónde:** la captura de Manuel muestra la tarjeta "Un Verano Sin Ti · 9.0" del carrusel "Popular esta semana". Es `AlbumStrip` (`lib/widgets/album_strip.dart`), que fija el alto a mano con `heightFor(size) = size + 8 + 31`, sumando el alto "normal" de Archivo (título 14 → 15,2 y artista 12 → 13,1).

**Causa probable:** cuando el texto usa un carácter que Archivo no tiene (el "…" del corte u otro glifo), Flutter lo dibuja con una fuente de respaldo de interlineado mayor y la línea crece. El alto fijo no alcanza.

**Arreglo:**
- darle al título y al artista de `AlbumTile` un `StrutStyle(forceStrutHeight: true)` con la misma fuente, tamaño y alto de línea, para que cada línea mida siempre lo mismo;
- calcular `heightFor` con esos mismos números;
- revisar que la media (28, alto 0,9) no pase de esa altura;
- revisar también el carrusel "Más de…" del disco (`yearOnly`), `AlbumStripSkeleton` y cualquier otro alto fijo con texto adentro (`grep -rn "heightFor\|height:" lib/widgets`).

**Prueba:** un widget test que monte `AlbumStrip` con un título largo, un artista largo y una media, y compruebe que no hay excepción de desborde (`tester.takeException()` en null).

### 1.3 La regla del disco calificado ya no cambia la nota (cambio 4)

**Hoy:** en `lib/screens/album_screen.dart`, `_Scores` pasa `onTap: onQuickRate` a `RulerCells` y `_quickRate` guarda la nota al instante ("Nota guardada").

**Cambio:**
- la regla solo muestra la nota: quitar `onQuickRate`, `_quickRate`, `_quickScore` y lo que dependa de ellos;
- "TU NOTA · EDITAR" (`rating-edit`) sigue abriendo la hoja de Calificar, que es la única forma de cambiarla;
- en la fila de abajo de la regla, quitar "Toca para cambiar" (`albumTapToChange`, en los dos ARB) y dejar solo "Barras: comunidad" a la derecha;
- confirmar que `RulerCells` sin `onTap` no reacciona al toque (sin estado presionado ni háptico).

**Documentación:** en `CLAUDE.md` ("Calificar") y en `docs/SISTEMA.md` (cambio de comportamiento 5), dejar escrito que la nota solo se cambia con "Editar".

### 1.4 Perfil de artista centrado (cambio 7)

**Archivo:** `lib/screens/artist_screen.dart`. Hoy el encabezado va alineado a la izquierda (`crossAxisAlignment: start`, línea ~152).

**Cambio:**
- centrar la foto de 140, "ARTISTA · N DISCOS", el nombre (con `textAlign: center`, en varias líneas si es largo) y el bloque de calificación;
- el bloque de calificación centrado: la cifra en 72 con " /10", "N notas · M discos" debajo y el histograma de 60 centrado debajo, con el mismo ancho que la regla;
- la discografía se queda como está (filas a lo ancho);
- los botones de arriba (volver y compartir) se quedan en su sitio.

El prototipo no tiene esta versión: anotarla en "Lo que no quedó idéntico".

### 1.5 Portadas apiladas también en listas y rankings de canciones (cambio 6)

**Causa, ya encontrada:**
- `MusicList.covers` (`lib/models/music_list.dart`, ~línea 246) junta hasta 4 portadas **distintas** por URL.
- Las canciones se agregan desde un disco (`ListItem.fromTrack(track, album)` usa la portada del disco), así que las canciones del mismo disco comparten portada. Una lista de canciones de uno o dos discos da una sola portada, y `CoverStack` la muestra sola.
- Además, si la autora eligió portada (`coverUrl`), `CoverStack(single:)` muestra solo esa, en cualquier tipo de lista.

**Cambio:**
- en las listas de canciones, `covers` toma las portadas de discos distintos (por `albumId`) y, si hay menos de 3, repite las que hay hasta llegar a `min(3, items.length)`, para que el efecto de las 3 portadas aparezca siempre que la lista tenga 2 o más canciones;
- las listas de discos siguen igual;
- revisar con Manuel si la portada elegida (`coverUrl`) debe seguir mostrándose sola en la fila o ir arriba de la pila. Por defecto se queda como está.
- **Dónde se usa:** `ListRowTile` (perfil, pestaña Listas) y `list_picker_sheet.dart` (Agregar a una lista).
- **Prueba:** en `test/music_list_test.dart`, una lista de canciones de un solo disco con 3 canciones da 3 portadas; una de dos discos da 3; una de una canción da 1; y las de discos no cambian.

**Qué prueba Manuel (`R`):**
1. **Campos:** Iniciar sesión, Crear cuenta, Buscar, Nueva lista, Editar perfil y el comentario de Calificar. Cada campo tiene que tener una sola raya, que se pone de énfasis con el foco.
2. **Desborde:** el carrusel "Popular esta semana" del inicio, sin la franja amarilla y negra, incluso con títulos largos.
3. **Regla:** en un disco calificado, tocar la regla no hace nada; "Tu nota · editar" abre la hoja y cambia la nota.
4. **Artista:** abrir un artista y revisar que la foto, el nombre, los datos y la calificación estén centrados.
5. **Listas:** en el perfil, pestaña Listas, las listas y rankings de canciones muestran 3 portadas apiladas.

## Fase 2 — Bienvenida interactiva (cambio 1)

**Archivos:** `lib/screens/welcome_screen.dart` y `lib/widgets/rating_bars.dart`. La pantalla de carga usa `WelcomeMasthead` y no cambia.

**Lo que pidió Manuel:**
- quitar la regla de números 1–10 (`RulerCells(selected: 10, lines: true)`);
- en su lugar, el selector de calificar (`RatingBars`, el de la hoja de Calificar) con una invitación a tocarlo;
- cuando la persona pone una nota, la gráfica se desliza hacia abajo y los botones "Crear cuenta" e "Iniciar sesión" suben con un rebote.

**Diseño (el prototipo no lo tiene; se arma con las piezas de Calificar):**
- **Arriba:** se quedan el cabezal, las portadas, "Tu diario de discos empieza aquí." y el párrafo.
- **Abajo, en el hueco de los botones (a 38 del borde, como hoy):**
  - una línea mono con la invitación, por ejemplo "Pruébalo · ¿qué nota le pones al último disco que escuchaste?" (textos nuevos en los dos ARB, con la traducción al inglés);
  - a la derecha, el número elegido en `VText.display` en énfasis con el veredicto (`Score.label`), que aparece al elegir (antes se ve "—");
  - debajo, `RatingBars` sin columna elegida (`value: null`), con "TOCA O DESLIZA" debajo, como en la hoja.
- **Alto:** la gráfica ocupa más o menos lo mismo que los dos botones (56 + 8 + 56), para que el cambio no mueva lo de arriba. En un iPhone chico la pantalla ya se desplaza (`SliverFillRemaining`).

**Animación:**
1. Al soltar el dedo (fin del toque o del arrastre), se deja ver la nota y el veredicto unos 700 ms. Si hace falta, sumar a `RatingBars` un `onEnd` o `onCommitted` que avise al soltar; `onChanged` sigue avisando por columna.
2. La gráfica, la invitación y la nota se deslizan hacia abajo y se desvanecen (unos 320 ms, `Curves.easeIn`).
3. Los dos botones suben desde abajo con rebote: "Crear cuenta" primero y "Ya tengo cuenta" unos 70 ms después (unos 650 ms con un resorte o `Curves.easeOutBack`, que se pasa un poco y vuelve). Un háptico suave al llegar.
4. Una vez hecho, no se repite mientras la bienvenida siga abierta: al volver atrás desde Iniciar sesión se ven los botones. Al cerrar sesión arranca de nuevo con la gráfica.

**Salida sin tocar la gráfica:** nadie puede quedarse sin poder entrar. Por defecto, un enlace mono discreto "Ya tengo cuenta →" bajo "TOCA O DESLIZA" hace la misma animación. Confirmar con Manuel al empezar la fase si lo quiere así o prefiere que los botones aparezcan solos tras unos segundos.

**Llaves:** `welcome-bars`, `welcome-invite`, `welcome-score` y `welcome-skip`. Se conservan `welcome-signup` y `welcome-signin`.

**Prueba:** un widget test que monte la bienvenida, toque una barra y compruebe que, al terminar la animación (`pumpAndSettle`), `welcome-signup` y `welcome-signin` son visibles y `welcome-bars` ya no.

**Qué prueba Manuel (`R`):** cerrar sesión, tocar y arrastrar las barras (hápticos por columna), soltar, ver la nota y la animación de salida y el rebote de los botones. Entrar a Iniciar sesión, volver (los botones siguen) y probar "Ya tengo cuenta →" sin tocar la gráfica.

## Fase 3 — Portada del disco y banner del perfil que se estiran (cambio 5)

**Lo que pidió Manuel:** en un disco o en un perfil, si ya está arriba del todo y sigue tirando hacia abajo, la portada del disco o el banner de la persona se agrandan.

**Archivos:** `lib/screens/album_screen.dart` (el `CustomScrollView` de la línea ~455, hoy con `ClampingScrollPhysics`), `lib/screens/profile_screen.dart` (línea ~173, también `Clamping`) y `lib/screens/profile_header.dart` (el banner de `topPad + 102`).

**Cómo:**
- **Física:** cambiar a `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` en esas dos pantallas, en iOS y en Android, para que exista el desplazamiento negativo.
- **Disco:**
  - con `extra = max(0, -offset)`, la portada queda pegada al borde de arriba y crece a un cuadrado de `ancho + extra`, centrada a lo ancho (`Transform.scale` con el origen abajo al centro y traslado de `-extra`, o un alto de `ancho + extra` con `BoxFit.cover`);
  - no se tiene que ver el fondo por encima; esa era la razón del `Clamping`, y el estiramiento la resuelve;
  - los botones de arriba (volver, compartir y listas) se quedan fijos;
  - la barra fija que aparece al pasar la portada no tiene que parpadear con desplazamientos negativos;
  - revisar el `Hero` de la portada al entrar y al salir.
- **Perfil:**
  - el banner (foto o `coverShade`) crece hacia abajo lo mismo que se tira, con la foto en `BoxFit.cover` escalada desde arriba al centro;
  - el avatar, el nombre y lo demás bajan con él;
  - la barra compacta fija sigue apareciendo igual;
  - vale para el perfil propio y el ajeno.
- **Al soltar:** vuelve con el rebote normal de iOS.
- **Extensión:** Manuel solo pidió el disco y el perfil. Preguntarle si quiere lo mismo en la franja de Lista y Ranking y en la foto del artista.

**Documentación:** en `docs/SISTEMA.md` se quita "la portada no rebota al tirar hacia abajo".

**Qué prueba Manuel (`R`):** en un disco y en su perfil (y en el de un amigo), estando arriba del todo, tirar hacia abajo: la portada o el banner crecen sin que se vea fondo detrás y vuelven al soltar. Revisar también que la barra fija y el encabezado compacto sigan funcionando al bajar.

## Fase 4 — Discos en común con un amigo (cambio 8)

**Lo que pidió Manuel:** en el perfil de un amigo, junto a la afinidad ("Según N discos en común"), ver cuáles son esos discos en miniatura.

**Archivos:** `lib/models/affinity.dart`, `lib/screens/profile_header.dart` (`_Affinity`, línea ~291) y `test/affinity_test.dart`.

**Datos:** `affinityBetween` ya recorre las dos listas de notas. Hay que sumarle la lista de discos en común: por cada uno, el `Album` (de `RatingEntry.album`), mi nota y la suya. Orden por defecto: primero los que tienen la misma nota, después por diferencia creciente y, a igual diferencia, el más reciente. Esa misma lista la usa después "Historia · amigo" (fase 7).

**Diseño (no está en el prototipo; se arma con piezas existentes):**
- debajo de "Según N discos en común", una fila de portadas cuadradas de 40 con separación 2, como la rejilla de favoritos del amigo;
- se muestran hasta 6, y si hay más, una última celda del mismo tamaño con "+N" en mono sobre `surface`;
- tocar una portada abre el disco (`openAlbum`, con un `heroTag` propio);
- opcional: debajo de cada portada, "8 · 9" (mi nota y la suya) en mono de 10. Preguntarle a Manuel;
- sin discos en común, no se muestra la fila.

**Llaves:** `common-album-N` y `common-more`.

**Prueba:** en `test/affinity_test.dart`, que la lista de discos en común sea la correcta, con el orden de arriba y sin repetidos.

**Qué prueba Manuel (`R`):** abrir el perfil de alguien con discos en común y ver las miniaturas; tocar una abre el disco. En un perfil sin discos en común no aparece la fila.

## Fase 5 — Ícono en modo oscuro (cambio 9)

**Lo que se sabe:**
- `ios/Runner/AppIcon.icon` es el ícono de Manuel en Icon Composer, con fondo claro (`#EFEBE4`) y oscuro (`#0F0E0D`).
- Compilado con `actool`, el `Assets.car` **sí trae** la versión oscura (`UIAppearanceDark`) y la teñida. El proyecto está bien.
- La especificación nueva dice: "**Ícono de app y splash: se mantienen oscuros en ambos modos.**"

**Por qué puede verse siempre blanco:**
1. **Ajuste del iPhone:** en iOS 18 y posteriores, los íconos tienen su propio modo (mantener pulsada la pantalla de inicio → Editar → Personalizar → Claro, Oscuro o Automático), aparte del modo oscuro del sistema. Si está en "Claro", los íconos no cambian aunque el sistema esté en oscuro.
2. **Caché de íconos:** iOS guarda el ícono de una app instalada encima. Hace falta borrar la app y volver a instalarla, o reiniciar el teléfono.

**Qué hacer:**
1. Pedirle a Manuel que revise el punto 1, antes de tocar nada.
2. Seguir la especificación (**recomendado**): que el ícono sea oscuro en los dos modos. En `ios/Runner/AppIcon.icon/icon.json` (y en la copia `viniloicon copy.icon/`), la especialización por defecto toma los valores de la oscura: fondo `#0F0E0D`, y las capas con la opacidad y la mezcla de la variante oscura. Así se ve oscuro en cualquier ajuste del teléfono. Confirmar con Manuel antes, porque la versión clara la hizo él.
3. Comprobar con `actool` como dice `CLAUDE.md` y, en el `Assets.car` que genera, que las variantes clara y oscura den el mismo fondo (`xcrun assetutil --info`).
4. Android y la web ya usan la versión oscura; no cambian.

**Qué prueba Manuel (relanzar):**
- borrar la app del iPhone y reinstalarla con `flutter run -d 00008120-001625D83AC3601E --release --dart-define=SPOTIFY_FN_URL=https://us-central1-red-social-c786b.cloudfunctions.net/spotify`;
- revisar el ícono con la pantalla de inicio en claro, en oscuro y en automático.

## Fase 6 — Landing web en español e inglés

**Archivos:** `hosting/index.html` (hoy es la bienvenida en grande, con las portadas de `/portadas` y el idioma según el navegador), `hosting/404.html` si comparte estilos, y `tool/web_test.js` si se prueba algo de la función. Prototipo: `Vinilo Landing.dc.html`.

**Diseño (copiar medidas, `clamp()`, pesos y anchos del prototipo):**
- **Diferencia con la app:** la landing sí usa `*{box-sizing:border-box}` (así lo trae el prototipo).
- **Nav:** "VINILO" en 32/900 al 62 % con la raya de acento de 18×3, y el botón "Descargar ↓" con borde, que baja a `#descargar`.
- **Portada (`header`):**
  - el disco que gira: surcos con `repeating-radial-gradient`, la etiqueta de acento con la "V" y el agujero, girando en 5 s;
  - el disco es la excepción a "sin gradientes" y "sin animaciones" que puso el diseñador en su prototipo;
  - "● Disponible en iOS y Android" (ver "Tiendas" abajo);
  - "VINILO" en `clamp(96px,22vw,340px)`, letra por letra con `vUp` y la "O" en acento;
  - la frase "Califica cada disco que escuchas. Del 1 al 10. Sin estrellas, sin rodeos." y los botones "App Store →" (tinta) y "Google Play →" (con borde).
- **Cinta:** franja de acento con las 8 palabras (CALIFICA, RESEÑA, SIGUE, DESCUBRE, COLECCIONA, COMPARA, ESCUCHA, COMPARTE) corriendo en 28 s.
- **01 — Califica:** "Diez columnas. Una nota.", el párrafo y la demo, con las mismas fórmulas de las barras de la app (alto, opacidad, tamaño y peso según la distancia):
  - se puede pasar el mouse o tocar;
  - sola, recorre la secuencia 8, 3, 6, 10, 5, 9, 7 cada 1,4 s y se detiene mientras hay mouse o toque encima;
  - la portada de 64 puede ser una real de `/portadas`, con "Tu próximo disco" encima.
- **02 — Reseña:** la cita en Newsreader itálica.
- **03 — Sigue:** "Lo que escuchan tus amigos." con las 4 filas del prototipo (Lucía, Mateo, Valentina y Diego son de ejemplo; en inglés se quedan los nombres).
- **04 — Descarga:** "Pon la aguja." y las dos filas App Store / Google Play.
- **Pie:** © 2026 VINILO, PRIVACIDAD, TÉRMINOS y CONTACTO.
- **Color de acento:** rota cada 3,2 s entre los 6 colores del `<script>`. Esos colores son OKLCH, que los navegadores actuales entienden. Dejar un respaldo en hex para los viejos.
- **Aparición:** las secciones con `data-reveal` aparecen al entrar en pantalla (`IntersectionObserver`).
- **Movimiento reducido:** respetar `prefers-reduced-motion` (sin giro, sin cinta, sin rotación de color y todo visible de una vez). El prototipo no lo trae; es accesibilidad básica.

**Idiomas:**
- **Cómo se elige:** los textos van en un diccionario ES/EN dentro del HTML (como `STRINGS` de `web.js`). El idioma se elige en este orden: `?lang=es|en`, lo último que eligió la persona (`localStorage`, dentro de `try/catch`) y el del navegador.
- **Selector:** "ES · EN" en mono en el nav, junto a "Descargar", con el activo en tinta y el otro en `ink4`. Al cambiar, no recarga, y actualiza `<html lang>`, `<title>` y la descripción.
- **Traducciones al inglés:** las hace el agente, en el mismo tono (por ejemplo "Rate every record you listen to. From 1 to 10. No stars, no fuss." y "Ten columns. One score.") y se las muestra a Manuel en el resumen de la fase.
- **Etiquetas Open Graph:** `og:title`, `og:description` y la imagen, en español (la tarjeta de WhatsApp no ejecuta JavaScript).

**Tiendas:**
- La app todavía no está en ninguna tienda. Con la cuenta gratuita de Apple no hay App Store.
- Las URLs van como constantes arriba del script (`APP_STORE_URL` y `PLAY_STORE_URL`, vacías).
- **Vacías:** los botones y las filas de descarga dicen "Muy pronto" en vez de la flecha y no enlazan a nada, y "Disponible en iOS y Android" pasa a "Muy pronto en iOS y Android".
- **Con URL:** se ven como en el prototipo.

**Pie:** no existen páginas de privacidad ni de términos, y tampoco un correo de contacto. Preguntarle a Manuel qué hacer. Por defecto, esos tres enlaces se ocultan (no se deja un `href="#"` que no lleva a nada).

**Verificación:**
- abrir el HTML sin servidor no es probar en la app, así que el agente no toma capturas;
- comprobar que es HTML válido y que no hay errores de JavaScript (por ejemplo `node --check` sobre el script extraído);
- revisar que no queden textos en un solo idioma;
- la web la revisa Manuel en el Mac y en el teléfono.

**Despliegue:** Manuel, con `firebase deploy --only hosting`.

**Qué prueba Manuel:** después de desplegar, abrir `https://red-social-c786b.web.app` en el Mac y en el teléfono y revisar:
- las animaciones de entrada, el disco, la cinta y la rotación del color;
- la demo de las barras con el mouse y con el dedo;
- el cambio ES · EN, que tiene que recordarse al recargar;
- `?lang=en`;
- el ancho de teléfono, sin desplazamiento horizontal.

## Fase 7 — Imágenes para compartir: las tarjetas

**Prototipo:** `Vinilo Compartir.dc.html`.
- **Historias:** se dibujan a 360×640 y se exportan a 3× (1080×1920).
- **Cuadrados:** 360×360, exportados a 1080×1080.
- **Tonos de portada:** el fondo usa un tono oscuro de la portada (L 0,24), la nota un tono claro (L 0,78) y el artista L 0,76.

**Archivos nuevos:**
- `lib/share_cards/`, un archivo por tarjeta más `share_card_data.dart` con los datos ya armados;
- `lib/services/share_image.dart`, que dibuja la tarjeta fuera de pantalla y devuelve el PNG;
- pruebas en `test/share_cards_test.dart`.

**Tarjetas y de dónde sale cada dato:**

| Tarjeta | Se comparte desde | Datos |
|---|---|---|
| Historia · disco y Cuadrado · disco | Disco con mi nota (`share-album`) y hilo de una nota sin texto (`share-rating`) | portada, título, artista · año, nota, fecha de la nota ("CALIFIQUÉ · 21 SEP 2026"), la regla de 10 (`RatingBarSpec`) y @usuario de quien calificó |
| Historia · reseña | Hilo de una nota con texto (`share-rating`) | portada de 72, título, "ARTISTA · AÑO", nota, el comentario entre “ ” y @usuario de la autora |
| Historia · lista y Cuadrado · lista | Lista o ranking (`share-list`) | "LISTA DE @USUARIO" (o "RANKING DE…"), nombre, rejilla de 9 portadas (4 en el cuadrado), "24 DISCOS · 18 GUARDADOS" (`items.length`, `savedBy.length`, con "canciones" si es de canciones) |
| Historia · artista | Artista (`share-artist`), solo si califiqué algún disco suyo | foto redonda, nombre, "MI NOTA PROMEDIO · N DE M DISCOS" (mis notas de sus discos sobre `AlbumPage.total`) y mis 3 mejores |
| Historia · mi perfil | Mi perfil (`share-profile`) | banner, avatar, nombre, "@USUARIO · EN VINILO DESDE 2025" (`createdAt`), DISCOS, RESEÑAS (notas con texto), NOTA MEDIA, favoritos y "Sígueme en Vinilo" |
| Historia · mi semana | Mi perfil (segunda tarjeta), solo si califiqué algo en los últimos 7 días | fondo de acento, "MI SEMANA · 15–21 SEP", "N discos." y hasta 5 filas |
| Historia · amigo | Perfil de un amigo (`share-profile`), solo con discos en común | la afinidad (fase 4) como "87 %", mi avatar y el suyo, una frase según el porcentaje, y 3 filas: 2 "coincidimos" y 1 "no coincidimos" (de la lista de la fase 4) |

**Reglas de las tarjetas:**
- **Construcción:** son widgets de Flutter de tamaño fijo (360×640 o 360×360 lógicos), con `VText`, los tokens y `coverTone`/`coverShade` (con lightness 0,24 y 0,78, sumando un parámetro si hace falta).
- **Colores:** los del prototipo que no son tokens (el fondo de "mi semana" en acento con texto `onAccent`, y la línea `rgba(15,14,13,.2)`) salen de `c.onAccent.withValues(...)`.
- **Textos:** van en los ARB, con fechas y números en el idioma de la persona (`monthYear`, `Score.formatAverage`).
- **Favoritos:** el prototipo dice "MIS 4 FAVORITOS", pero la app guarda 3. Va "Mis 3 favoritos" en una rejilla de 3 (anotarlo).
- **Frase de "amigo":** por ejemplo ≥ 80 % "coincidimos en casi todo", 50–79 % "coincidimos bastante" y < 50 % "somos opuestos musicales". Mostrárselas a Manuel.
- **Portadas reales:** van las fotos en vez de las rayas del prototipo. Antes de dibujar, esperar a que carguen (`precacheImage`) y las fuentes. Si una portada no carga, se usa `surface`.
- **Tonos:** con `PaletteService.dominant` de la portada (disco, reseña) o de la primera portada (lista), o `personTone` (perfil sin banner). Sin color, el acento.
- **Dibujo:** la tarjeta va dentro de un `RepaintBoundary` a su tamaño lógico y se captura con `toImage(pixelRatio: 3)` → PNG. La vista previa de la hoja es la misma tarjeta escalada por fuera del `RepaintBoundary`, así se captura a tamaño completo.
- **Pruebas:** que cada tarjeta se monte sin desbordes con textos largos, en los dos idiomas; que "mi semana" solo tome los últimos 7 días (con un máximo de 5 filas); que "amigo" elija 2 coincidencias y 1 diferencia; y que el promedio del artista cuente solo mis notas de sus discos.

Esta fase no tiene nada que probar en el teléfono todavía: las tarjetas se ven en la fase 8. Si Manuel quiere verlas antes, se puede hacer una pantalla de depuración oculta. Preguntarle.

## Fase 8 — Imágenes para compartir: la hoja y el envío

**Hoja "Compartir"** (prototipo "Hoja de compartir"):
- una `SheetScaffold` alta (empieza a 96 del borde de arriba) con "Compartir" en 40/800 al 62 %;
- a la derecha, las pestañas "Historia | Cuadrado" (subrayado de acento de 2). "Cuadrado" solo aparece para disco y lista;
- en el centro, la vista previa a 0,6 (216×384) con contorno `line`;
- debajo, 4 destinos en cajas de 56 con borde `lineStrong`, ícono de 22 y etiqueta mono de 9,5: HISTORIAS, WHATSAPP, GUARDAR y ENLACE;
- abajo, el botón de acento "Compartir en Historias →". En "Cuadrado" dice "Compartir imagen →" y abre la hoja del sistema;
- donde hay dos tarjetas (mi perfil y mi semana), la vista previa se desliza de lado con dos puntos debajo;
- íconos: los trazos SVG de los destinos (`targets` en el `<script>`) se suman a `v_icons.dart` (`VIcon.story`, `VIcon.chat`, `VIcon.download` y `VIcon.link`).

**Dónde se abre:**
- `ShareButton` (`share-album`, `share-rating`, `share-list`, `share-artist`, `share-profile`) abre esta hoja cuando hay tarjeta;
- cuando no la hay (disco sin mi nota, artista sin mis notas, perfil ajeno sin discos en común, y en la web), hace lo de hoy: texto y enlace;
- en la hoja, ENLACE hace lo de hoy (`shareAlbumMessage`, etc.).

**Envío, en el canal `vinilo/share`** (`lib/services/share_service.dart`, `ShareChannel` en `ios/Runner/AppDelegate.swift` y `android/.../MainActivity.kt`), sin paquetes nuevos. Los bytes del PNG pasan por el canal y el lado nativo escribe el archivo temporal (así no hace falta `path_provider`).
- **`shareImage(png, text)`:** la hoja del sistema con la imagen y el texto con el enlace. Se usa en WHATSAPP (la persona elige WhatsApp; si sin paquetes se puede abrir WhatsApp directo con la imagen, mejor) y en "Compartir imagen".
- **`instagramStory(png)` para HISTORIAS:**
  - usa el esquema `instagram-stories://share?source_application=<App ID de Meta>` con la imagen en el portapapeles (`com.instagram.sharedSticker.backgroundImage`, con vencimiento de 5 minutos);
  - necesita un **App ID de Meta**, que Manuel crea gratis en developers.facebook.com. Va como `--dart-define=META_APP_ID=…` o en `Info.plist`;
  - sin App ID, o si Instagram no está instalado, cae a `shareImage`: en la hoja del sistema, Instagram también ofrece "Historia";
  - en Android es el intent `com.instagram.share.ADD_TO_STORY` con la imagen por `FileProvider`.
- **`saveImage(png)` para GUARDAR:** en iOS, `UIImageWriteToSavedPhotosAlbum`; en Android, `MediaStore`. Aviso "Imagen guardada" o el error traducido.
- **iOS:** en `Info.plist`, `NSPhotoLibraryAddUsageDescription` (texto en español, como los demás permisos) y `LSApplicationQueriesSchemes` con `instagram-stories` y `whatsapp`.
- **Android:** en `AndroidManifest.xml`, el `FileProvider` con `res/xml/file_paths.xml` (caché), y `<queries>` para Instagram y WhatsApp.
- **Comprobar que compila sin Xcode:** el `swiftc -typecheck` de `CLAUDE.md`. Android no se compila aquí; revisarlo con cuidado y decírselo a Manuel.

**Llaves:** `share-sheet`, `share-tab-story`, `share-tab-square`, `share-preview`, `share-target-story`, `share-target-whatsapp`, `share-target-save`, `share-target-link` y `share-primary`.

**Qué prueba Manuel (relanzar, porque cambian Swift, Kotlin, `Info.plist` y el manifiesto):**
1. Compartir desde:
   - un disco que calificó (Historia y Cuadrado);
   - el hilo de una nota con comentario (reseña);
   - una lista y un ranking;
   - un artista que calificó;
   - su perfil (mi perfil y mi semana);
   - el perfil de un amigo con discos en común.
2. Probar los 4 destinos:
   - Historias, que abre Instagram con la imagen de fondo (o la hoja del sistema, si no hay App ID);
   - WhatsApp, con la imagen y el enlace;
   - Guardar, que la guarda en Fotos (la primera vez pide permiso);
   - Enlace.
3. Revisar la imagen guardada en Fotos: 1080×1920 o 1080×1080, nítida y con portadas reales.
4. Compartir un disco sin nota, que sigue compartiendo solo el enlace.

## Fase 9 — Tema claro (opcional: solo si Manuel lo pide)

Manuel no lo pidió en esta ronda, pero el diseñador ya lo definió en `ESPECIFICACION.md` ("Modo claro"): mismos tokens con otros valores, `accent-text` a L 0,52 para el acento usado como texto o línea fina, el color de portada a L ~0,48 y el ícono y el splash oscuros.

Si Manuel lo pide:
- llenar `ViniloPalette.light` con esos valores;
- sumar `accentText`, usarlo donde el acento es texto o línea ("Ver todo", notas, "Siguiendo", foco de los campos) y agregarlo a las pruebas de contraste de `test/theme_test.dart`;
- hacer que `coverTone` dependa del brillo;
- revisar `overlayStyleFor` (barra de estado oscura sobre fondo claro).

Todo color ya sale de los tokens, así que no debería hacer falta tocar pantallas. Buscar con `grep` los que no.

## Fase 10 — Cierre

- **`CLAUDE.md`:** actualizar lo que cambió:
  - la bienvenida, la regla sin toque, el estiramiento, los discos en común, el ícono, la landing y compartir con imágenes (el canal, el App ID de Meta y los permisos nuevos);
  - las llaves nuevas y el número de pruebas;
  - quitar la línea de "Trabajo en curso".
- **`docs/SISTEMA.md`:** los componentes nuevos (tarjetas, hoja de compartir, `RatingBars(onEnd)` si se sumó) y "Lo que no quedó idéntico" con lo nuevo.
- **Este plan:** borrarlo cuando Manuel dé todo por bueno, o dejarlo marcado como terminado si él prefiere.
- **Informe final:** lo que no se pudo igualar y por qué.
