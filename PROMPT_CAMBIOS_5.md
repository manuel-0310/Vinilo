# Prompt — ronda 5: disco, perfil en dos secciones, portadas de listas, fotos y perfiles de prueba

Pégalo en una sesión nueva abierta en esta carpeta. La ronda 4 ya está confirmada (commit "Ronda 4: terminar lo de Fable").

```text
Seguimos con la ronda 5 de Vinilo. Lee CLAUDE.md antes de empezar. No cambies la dirección visual salvo donde lo pido, y no rompas lo que ya funciona.

Reglas de esta ronda:
- No tomes capturas de pantalla ni las guardes en el repo, ni con tool/shot.sh ni de ninguna otra forma. Yo reviso el diseño en mi iPhone y te doy feedback. Verifica con flutter analyze, flutter test y, si necesitas comprobar un flujo, con el driver sin capturas (wait, gettext) en tu simulador.
- Para tus pruebas usa el simulador "Vinilo Fable" (823D97BF-4F44-427D-89A9-7DF3D25650B4) o crea otro como explica CLAUDE.md. Si queda un flutter run viejo conectado a ese simulador, mátalo antes de lanzar el tuyo.
- Al terminar cada bloque, instala la versión nueva en mi iPhone ("iPhone de Manuel", 00008120-001625D83AC3601E), siempre con --dart-define=SPOTIFY_FN_URL=https://us-central1-red-social-c786b.cloudfunctions.net/spotify, y dime en una lista corta qué debo revisar. Antes de compilar revisa pgrep -fl flutter_tools.snapshot: si yo ya tengo un flutter run conectado a mi iPhone, no lances otro build encima; avísame y lo recargo yo.
- Cubre con pruebas en test/ la lógica nueva que no dependa de la interfaz (por ejemplo, el filtro del buscador de favoritos).
- Nunca toques mi cuenta para probar nada destructivo: usa cuentas @vinilo.test.
- No hagas commit: lo reviso yo antes.

Bloque 1: arreglos y textos
1. Quita estos textos:
   - "En Vinilo desde …" debajo del nombre en el perfil.
   - La estadística "ESTE MES" del perfil (se quedan DISCOS y PROMEDIO).
   - El subtítulo "Lo último que la gente puso en su diario" del inicio.
   - El título "Popular en la comunidad" pasa a ser "Popular".
   - El subtítulo "Lo que califican las personas que sigues" de "Actividad" pasa a ser "De tus amigos".
2. En la ficha del artista, la foto, el nombre y la línea de géneros o "Artista" deben quedar centrados. Hoy, con nombres cortos, quedan pegados a la izquierda: en artist_screen.dart el Column del encabezado está dentro de un Stack que alinea arriba a la izquierda y el Column solo ocupa el ancho de su hijo más ancho. Que ocupe todo el ancho (o alinea el Stack arriba al centro). Revisa que no pase lo mismo en otros encabezados parecidos (disco, lista).
3. El resplandor de la ficha del artista debe verse igual que el del disco: hoy se ve como duplicado (el AmbientGlow con focus 110 más la sombra de color de ArtistAvatar, y además desalineados por el punto anterior). Usa los mismos parámetros y la misma colocación que album_screen.dart, dentro del primer sliver.
4. Las fotos de perfil de las personas no se ajustan bien: quedan como espacios en blanco alrededor. Busca la causa en UserAvatar (el borde o anillo que encoge la imagen, la imagen que no llena el círculo), en ImageCropper (que el recorte nunca rellene con blanco) y en cómo se guarda la foto, y corrígela en todos los sitios donde sale un avatar (perfil, inicio, comentarios, personas, notificaciones, seguidores). Si no logras reproducirlo, pídeme una captura antes de adivinar.
5. Unifica "Editar perfil" y "Configuración": en el encabezado del perfil propio queda un solo botón redondo (el engranaje) que abre Configuración, y dentro de Configuración, arriba, una entrada "Editar perfil" que abre el mismo formulario de hoy.
6. En la hoja de listas del disco (botón de arriba a la derecha), quita "Agregar canciones a una lista": elegir canciones ya se hace manteniendo pulsada una canción. Se quedan "Agregar el disco a una lista" y "Crear lista con este disco". Para que se descubra la pulsación larga, agrega una pista discreta en la sección "Canciones" del disco (por ejemplo, en el subtítulo: "12 canciones · 45 min · Mantén pulsada una para agregarla a una lista").

Bloque 2: calificar desde el disco
7. Al entrar a un disco sin calificar, quita el botón flotante "Calificar este disco" (y el hueco que reserva al final de la lista). En su lugar, un botón redondo a la derecha con un ícono de tomar notas (por ejemplo Icons.edit_note_rounded), en la misma fila donde aparece "Tu nota N ···· Editar" cuando ya hay nota, con el color de énfasis. Abre la misma hoja RatingSheet. Al guardar, el botón da paso a la fila "Tu nota" con una transición suave.

Bloque 3: perfil en dos secciones y listas
8. Separa el perfil en dos secciones con un selector debajo del encabezado: "Perfil" (discos y artistas favoritos, la gráfica y el diario) y "Listas" (mis listas, con "Nueva lista", y debajo "Guardadas", que solo veo en mi perfil). En el perfil de otra persona, "Listas" muestra solo sus listas.
9. Cambia el estilo de las listas en el perfil: en vez de tarjetas grandes en fila horizontal, filas compactas en vertical con un ícono pequeño a la izquierda (el mosaico o la portada, unos 52 pt) y, a la derecha, el nombre, el tipo ("Ranking de canciones") y el número de elementos. Reutiliza ListRowTile si encaja.
10. Al elegir mis discos favoritos, la hoja debe tener un buscador arriba para filtrar entre todos los discos que he calificado, por nombre del disco o del artista, sin distinguir mayúsculas ni tildes.
11. "Deshacer": al quitar un elemento de una lista (en "Editar") o al borrar una nota, sale un aviso con "Deshacer" durante unos segundos (con persist: false, ver CLAUDE.md). En la lista, el elemento vuelve a su misma posición. Con la nota, lo más seguro es no borrarla de Firestore hasta que el aviso se cierre sin deshacer, para que vuelva tal cual (puntuación, comentario, fecha y likes) y los promedios del disco no se muevan dos veces. Cubre con pruebas la lógica de devolver el elemento a su posición.

Bloque 4: fotos y portadas de listas
12. Cada vez que elija una foto (perfil, fondo o portada de lista), que primero me pregunte "Tomar foto" o "Elegir de la galería" (y "Quitar foto" cuando ya hay una), y después siga al recortador como hoy. image_picker ya soporta la cámara; en el simulador no hay cámara, así que muestra un mensaje claro en vez de fallar. Actualiza los textos de NSCameraUsageDescription y NSPhotoLibraryUsageDescription en Info.plist para que hablen de fotos de perfil, de fondo y de portadas de listas.
13. Quien creó una lista puede cambiarle la portada (desde el menú ··· de la lista: "Cambiar portada" y "Quitar portada", que vuelve al mosaico). Recórtala cuadrada 1:1 con ImageCropper, guárdala en Storage en lists/{listId}.jpg y su URL en el campo coverUrl del documento. La portada reemplaza al mosaico en todos los sitios donde sale la lista (pantalla de la lista, filas del perfil, selector de listas) y el resplandor de la lista sale de ella. Actualiza storage.rules (solo la autora de la lista escribe su portada; se puede comprobar con firestore.get sobre el documento de la lista) y firestore.rules (coverUrl es texto o nulo). Al borrar una lista, borra también su portada; y la función account debe borrar las portadas de las listas de la persona: actualízala y despliégala con firebase deploy --only functions:account.

Bloque 5: perfiles de prueba
14. Crea 6 perfiles falsos para que yo los siga y vea cómo se siente la app con gente: cuentas @vinilo.test con una contraseña que anotes en CLAUDE.md, nombres y @usuarios creíbles, colores distintos y sin fotos de personas reales. Cada uno con 10 a 20 notas sobre discos reales de Spotify (sacados con la función, para que ids y portadas sean los de verdad), notas variadas y más o menos la mitad con un comentario corto en español, 3 discos y 3 artistas favoritos, y una o dos listas (al menos un ranking de canciones y una lista de discos). Que se sigan entre ellos y se den algunos "me gusta" en notas y listas. Créalos con los mismos repositorios de la app (por ejemplo, un mensaje del driver "seed-fake-people"), no escribiendo directo en Firestore, para que los promedios, histogramas y contadores cuadren. Además, que 2 o 3 de ellos me sigan y le den "me gusta" a algunas de mis notas, para que yo vea notificaciones reales. Mi cuenta es la del uid bPFSJmdta6Sy7mQ6hbWdeSPFDFm2 (compruébalo con msg doc:users/<uid> antes de usarlo): con ella solo seguir y dar "me gusta", nada más. Deja también una forma de borrarlos todos de una vez con la función account (por ejemplo, un mensaje "delete-fake-people"), que debe dejar mis contadores y mis notas como estaban, y anótala en CLAUDE.md. Al final, dame la lista de sus @.

Al terminar, actualiza CLAUDE.md con lo que cambió (estructura, campos nuevos, reglas, rutas de Storage, perfiles de prueba) y dime qué quedó pendiente o qué no pudiste verificar.
```
