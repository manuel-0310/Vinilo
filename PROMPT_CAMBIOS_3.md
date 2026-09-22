# Prompt para Fable — ronda 4: cuentas, amigos, listas y notificaciones

Antes de pegarlo: habilita el correo y la contraseña en Firebase.
https://console.firebase.google.com/project/red-social-c786b/authentication/providers → **Correo electrónico/contraseña** → Habilitar → Guardar. Deja apagado el "vínculo del correo electrónico".

```text
Vamos con otra ronda en Vinilo: cuentas de verdad, seguir amigos, listas y notificaciones. Lee CLAUDE.md antes de empezar. No cambies la dirección visual salvo donde lo pido, y no rompas lo que ya funciona.

Reglas de esta ronda:
- No tomes capturas de pantalla ni las guardes en el repo, ni con tool/shot.sh ni de ninguna otra forma. Yo reviso el diseño en mi iPhone y te doy feedback. Verifica con flutter analyze, flutter test y, si necesitas comprobar un flujo, con el driver sin capturas (wait, gettext).
- Al terminar cada bloque, recarga mi app en el iPhone 18 Pro y dime en una lista corta qué debo revisar.
- Cubre con pruebas en test/ la lógica nueva que no dependa de la interfaz: validación del @usuario, contadores de seguidores, agregar a listas sin duplicados y reordenar.
- Nunca pruebes el borrado de cuenta ni nada destructivo con mi cuenta: crea cuentas de prueba para eso y bórralas al final.
- No hagas commit: lo reviso yo antes.

Bloque 1: cuentas con correo y contraseña
Ya habilité el proveedor de correo y contraseña en la consola de Firebase. Hoy la app entra con una sesión anónima automática; eso se acaba.
1. Pantalla de bienvenida con "Crear cuenta" e "Iniciar sesión", con el mismo carácter visual de la app.
2. Crear cuenta: correo y contraseña, y después el perfil que ya existe (nombre, color, foto) más un @usuario único. El @usuario va en minúsculas, de 3 a 20 caracteres, solo letras, números, punto y guion bajo. Valida en vivo si está disponible y resérvalo en una transacción (por ejemplo, una colección usernames/{usuario} → uid) para que dos personas no lo tomen a la vez. Se puede cambiar después desde la edición del perfil, liberando el anterior.
3. Iniciar sesión con correo y contraseña, con "¿Olvidaste tu contraseña?", que manda el correo de recuperación de Firebase. Los errores (correo ya usado, contraseña débil, datos incorrectos, sin conexión) se muestran en español y claros.
4. Cerrar sesión desde Configuración.
5. Quien ya tiene una sesión anónima con datos (yo, por ejemplo) no debe perderlos: al abrir la app ve una pantalla para guardar su cuenta con correo y contraseña, que vincula la sesión anónima con linkWithCredential y así conserva el mismo uid, sus notas, favoritos y perfil. Después elige su @usuario.
6. Actualiza firestore.rules para las cuentas y la colección de @usuarios. No las despliegues.
Cuando termines este bloque, detente y espera a que te confirme que ya guardé mi cuenta: el bloque 2 cambia el identificador de la app y una sesión anónima sin vincular se perdería.

Bloque 2: nuevo identificador de la app
7. Cambia el bundle ID de iOS de com.buildday.noRetiene a com.manuelcastillo.vinilo, y el applicationId y namespace de Android a com.manuelcastillo.vinilo (moviendo el paquete de MainActivity). Registra las apps nuevas en Firebase con flutterfire configure (para este paso sí hay que volver a correrlo, aunque CLAUDE.md diga lo contrario) y verifica que firebase_options.dart, GoogleService-Info.plist y google-services.json queden con el identificador nuevo. La Cloud Function no cambia.
8. Relanza la app en el iPhone 18 Pro. Va a aparecer como una app nueva: avísame para que borre la vieja del simulador e inicie sesión con mi correo. Actualiza CLAUDE.md con el identificador y los comandos nuevos.

Bloque 3: seguir amigos
9. En el buscador, una sección "Personas" que encuentra usuarios por nombre o por @usuario.
10. En el perfil de otra persona, un botón Seguir / Siguiendo. Nadie puede seguirse a sí mismo.
11. En todos los perfiles, "N seguidores · N seguidos". Al tocarlos se abre la lista correspondiente, con el botón de seguir en cada persona. Mantén los contadores en el documento del usuario y actualízalos en la misma transacción o lote que crea o borra el seguimiento.
12. La sección "Actividad" del inicio pasa a mostrar solo lo que hacen las personas que sigo, no toda la comunidad. "Popular en la comunidad" se queda como está. Si no sigo a nadie, la sección invita a buscar amigos y lleva a "Personas". Ten en cuenta el límite de 30 valores de las consultas "in" de Firestore por si alguien sigue a muchas personas.
13. Actualiza firestore.rules: cada persona solo crea o borra seguimientos en los que ella es quien sigue.

Bloque 4: listas y rankings
Cada persona puede crear listas de dos tipos: "Lista" (normal) y "Ranking" (numerada; el orden importa y se cambia arrastrando). Cada lista es de canciones o de discos, sin mezclarlos.
14. En el perfil, una sección "Listas" con un botón "Nueva lista" en el propio (nombre, descripción opcional, tipo y si es de canciones o de discos). Una lista vacía debe tener una forma clara de agregar contenido, por ejemplo buscar un disco y elegirlo a él o a sus canciones.
15. Desde un disco: "Crear lista con este disco", que pregunta el tipo, propone como nombre el del disco y crea una lista de canciones con todas las del disco en su orden, lista para reordenar si es un ranking.
16. Desde un disco: poder seleccionar varias canciones y "Agregar a lista", eligiendo una de mis listas de canciones o creando una nueva ahí mismo. Y poder agregar el disco completo a una de mis listas de discos, por ejemplo "Mis 10 discos de 2026". Si algo ya está en la lista, no se duplica y me lo dices.
17. Pantalla de lista: un mosaico con hasta 4 portadas, nombre, descripción, tipo, autor y número de elementos. Cada canción muestra portada, nombre, artista y duración; cada disco, portada, nombre, artista y año; en los rankings, también su posición. Quien la creó puede reordenar, quitar elementos, editar nombre y descripción, y borrar la lista con confirmación. Las demás personas la ven en modo lectura desde el perfil de su autor.
18. Likes y guardar: en las listas de otras personas puedo dar like (se ve el número de likes) y guardarlas. Las guardadas aparecen en mi perfil en una sección "Guardadas", visible solo para mí, y siguen reflejando lo que su autor cambie; si el autor la borra, desaparece de mis guardadas sin errores. No se puede dar like ni guardar una lista propia.
19. Guarda las listas en Firestore con los datos de cada canción o disco copiados (id de Spotify, nombre, artistas, portada y, según el caso, disco, duración o año), para no llamar a Spotify al abrirlas. Pon un límite razonable de elementos por lista para que quepa en un solo documento. Actualiza firestore.rules: solo quien creó una lista puede modificar su contenido.

Bloque 5: notificaciones dentro de la app
20. Una campana en el encabezado del inicio, con un punto cuando hay algo sin leer, abre la pantalla "Notificaciones". Ahí aparecen, de la más reciente a la más antigua: "X empezó a seguirte", "A X le gustó tu nota de <disco>", "A X le gustó tu lista <nombre>" y "X guardó tu lista <nombre>". Al tocar una, lleva al perfil, la nota o la lista correspondiente. Al abrir la pantalla se marcan como leídas.
21. Nadie recibe notificaciones de sus propias acciones. Nadie puede crear una notificación a nombre de otra persona: si las generas desde la app, las reglas deben impedirlo; si prefieres generarlas con funciones que reaccionen a los cambios en Firestore, está bien, pero despliégalas y dime.
22. Son solo dentro de la app: nada de notificaciones push por ahora.

Bloque 6: eliminar cuenta
23. En Configuración, "Eliminar cuenta", con una confirmación clara de que no se puede deshacer y pidiendo la contraseña otra vez (Firebase exige un inicio de sesión reciente para borrar).
24. Borra todo lo de esa persona: perfil, @usuario, avatar y banner en Storage, sus notas (ajustando los promedios e histogramas de los discos), sus likes, sus listas y guardadas, sus seguimientos en ambos sentidos (ajustando los contadores de las otras personas) y sus notificaciones. Hazlo en la Cloud Function con el Admin SDK, verificando el token, y no desde la app, para que no queden datos a medias si algo falla. Al terminar, la app vuelve a la pantalla de bienvenida.

Al terminar, actualiza CLAUDE.md con lo que cambió (estructura, colecciones nuevas, rutas de la función y reglas) y dime qué quedó pendiente o qué no pudiste verificar.
```
