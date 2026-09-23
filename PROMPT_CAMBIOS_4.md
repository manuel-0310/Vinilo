# Prompt para Fable — ronda 4, continuación: identificador, amigos, listas, notificaciones y eliminar cuenta

Pégalo en la sesión de Fable abierta en esta carpeta. El bloque de cuentas ya está hecho.

```text
Seguimos con la ronda 4 de Vinilo. El bloque de cuentas con correo y contraseña ya está hecho y el proveedor ya está habilitado en Firebase; no lo toques salvo para arreglar algo que rompan estos cambios. Lee CLAUDE.md antes de empezar. No cambies la dirección visual salvo donde lo pido, y no rompas lo que ya funciona.

Qué cambió desde el prompt anterior:
- Borré todos los simuladores, así que no hay sesión anónima que guardar.
- Ahora uso la app en mi iPhone físico ("iPhone de Manuel", 00008120-001625D83AC3601E). Para tus pruebas automáticas, crea tu propio simulador como explica CLAUDE.md.

Reglas de esta ronda:
- No tomes capturas de pantalla ni las guardes en el repo, ni con tool/shot.sh ni de ninguna otra forma. Yo reviso el diseño en mi iPhone y te doy feedback. Verifica con flutter analyze, flutter test y, si necesitas comprobar un flujo, con el driver sin capturas (wait, gettext) en tu simulador.
- Al terminar cada bloque, instala la versión nueva en mi iPhone, siempre con --dart-define=SPOTIFY_FN_URL=https://us-central1-red-social-c786b.cloudfunctions.net/spotify, y dime en una lista corta qué debo revisar.
- Cubre con pruebas en test/ la lógica nueva que no dependa de la interfaz: contadores de seguidores, agregar a listas sin duplicados y reordenar.
- Nunca pruebes el borrado de cuenta ni nada destructivo con mi cuenta: crea cuentas de prueba para eso y bórralas al final.
- No hagas commit: lo reviso yo antes.

Bloque 1: nuevo identificador de la app
1. Cambia el bundle ID de iOS de com.buildday.noRetiene a com.manuelcastillo.vinilo, y el applicationId y namespace de Android a com.manuelcastillo.vinilo (moviendo el paquete de MainActivity). Registra las apps nuevas en Firebase con flutterfire configure (para este paso sí hay que volver a correrlo, aunque CLAUDE.md diga lo contrario) y verifica que firebase_options.dart, GoogleService-Info.plist y google-services.json queden con el identificador nuevo. La Cloud Function no cambia.
2. Instálala en mi iPhone. Como el identificador cambia, va a aparecer como una app nueva junto a la vieja: avísame para que borre la vieja e inicie sesión o cree mi cuenta. Si la firma falla por el cambio de identificador, dime exactamente qué tengo que hacer en Xcode. Actualiza CLAUDE.md con el identificador y los comandos nuevos.

Bloque 2: seguir amigos
3. En el buscador, una sección "Personas" que encuentra usuarios por nombre o por @usuario.
4. En el perfil de otra persona, un botón Seguir / Siguiendo. Nadie puede seguirse a sí mismo.
5. En todos los perfiles, "N seguidores · N seguidos". Al tocarlos se abre la lista correspondiente, con el botón de seguir en cada persona. Mantén los contadores en el documento del usuario y actualízalos en la misma transacción o lote que crea o borra el seguimiento.
6. La sección "Actividad" del inicio pasa a mostrar solo lo que hacen las personas que sigo, no toda la comunidad. "Popular en la comunidad" se queda como está. Si no sigo a nadie, la sección invita a buscar amigos y lleva a "Personas". Ten en cuenta el límite de 30 valores de las consultas "in" de Firestore por si alguien sigue a muchas personas.
7. Actualiza firestore.rules: cada persona solo crea o borra seguimientos en los que ella es quien sigue.

Bloque 3: listas y rankings
Cada persona puede crear listas de dos tipos: "Lista" (normal) y "Ranking" (numerada; el orden importa y se cambia arrastrando). Cada lista es de canciones o de discos, sin mezclarlos.
8. En el perfil, una sección "Listas" con un botón "Nueva lista" en el propio (nombre, descripción opcional, tipo y si es de canciones o de discos). Una lista vacía debe tener una forma clara de agregar contenido, por ejemplo buscar un disco y elegirlo a él o a sus canciones.
9. Desde un disco: "Crear lista con este disco", que pregunta el tipo, propone como nombre el del disco y crea una lista de canciones con todas las del disco en su orden, lista para reordenar si es un ranking.
10. Desde un disco: poder seleccionar varias canciones y "Agregar a lista", eligiendo una de mis listas de canciones o creando una nueva ahí mismo. Y poder agregar el disco completo a una de mis listas de discos, por ejemplo "Mis 10 discos de 2026". Si algo ya está en la lista, no se duplica y me lo dices.
11. Pantalla de lista: un mosaico con hasta 4 portadas, nombre, descripción, tipo, autor y número de elementos. Cada canción muestra portada, nombre, artista y duración; cada disco, portada, nombre, artista y año; en los rankings, también su posición. Quien la creó puede reordenar, quitar elementos, editar nombre y descripción, y borrar la lista con confirmación. Las demás personas la ven en modo lectura desde el perfil de su autor.
12. Likes y guardar: en las listas de otras personas puedo dar like (se ve el número de likes) y guardarlas. Las guardadas aparecen en mi perfil en una sección "Guardadas", visible solo para mí, y siguen reflejando lo que su autor cambie; si el autor la borra, desaparece de mis guardadas sin errores. No se puede dar like ni guardar una lista propia.
13. Guarda las listas en Firestore con los datos de cada canción o disco copiados (id de Spotify, nombre, artistas, portada y, según el caso, disco, duración o año), para no llamar a Spotify al abrirlas. Pon un límite razonable de elementos por lista para que quepa en un solo documento. Actualiza firestore.rules: solo quien creó una lista puede modificar su contenido.

Bloque 4: notificaciones dentro de la app
14. Una campana en el encabezado del inicio, con un punto cuando hay algo sin leer, abre la pantalla "Notificaciones". Ahí aparecen, de la más reciente a la más antigua: "X empezó a seguirte", "A X le gustó tu nota de <disco>", "A X le gustó tu lista <nombre>" y "X guardó tu lista <nombre>". Al tocar una, lleva al perfil, la nota o la lista correspondiente. Al abrir la pantalla se marcan como leídas.
15. Nadie recibe notificaciones de sus propias acciones. Nadie puede crear una notificación a nombre de otra persona: si las generas desde la app, las reglas deben impedirlo; si prefieres generarlas con funciones que reaccionen a los cambios en Firestore, está bien, pero despliégalas y dime.
16. Son solo dentro de la app: nada de notificaciones push por ahora.

Bloque 5: eliminar cuenta
17. En Configuración, "Eliminar cuenta", con una confirmación clara de que no se puede deshacer y pidiendo la contraseña otra vez (Firebase exige un inicio de sesión reciente para borrar).
18. Borra todo lo de esa persona: perfil, @usuario, avatar y banner en Storage, sus notas (ajustando los promedios e histogramas de los discos), sus likes, sus listas y guardadas, sus seguimientos en ambos sentidos (ajustando los contadores de las otras personas) y sus notificaciones. Hazlo en la Cloud Function con el Admin SDK, verificando el token, y no desde la app, para que no queden datos a medias si algo falla. Al terminar, la app vuelve a la pantalla de bienvenida.

Al terminar, actualiza CLAUDE.md con lo que cambió (estructura, colecciones nuevas, rutas de la función y reglas) y dime qué quedó pendiente o qué no pudiste verificar.
```
