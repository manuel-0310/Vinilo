# Vinilo: plan de la ronda 8 (pantallas nuevas, desde el 2026-10-02)

El plan anterior (landing, imágenes para compartir, tema claro y los 9 cambios) quedó terminado; está en el historial de git (`git log -- docs/PLAN.md`).

## Contexto

Manuel pasó el prompt del diseñador ("Prompt implementación Vinilo.md", en `~/Downloads/Red social de álbumes/`): implementar las pantallas de cuatro prototipos nuevos, que ya están copiados en la raíz del proyecto:

- `Vinilo Nuevas.dc.html`: Splash, Calificar con comparación, Detalle de respuesta, Afinidad musical (**ya hecho en la ronda 7**; falta el ♡ de las respuestas).
- `Vinilo Onboarding.dc.html`: Onboarding (2 pasos), Perfil · Estadísticas, Compartir estadísticas.
- `Vinilo Moderación.dc.html`: Reportar y bloquear (7 pantallas).
- `Vinilo Estados.dc.html`: Recuperar contraseña, estados vacíos, errores y cargas.

Si el prompt y el HTML difieren, **gana el HTML**. Las reglas de siempre siguen valiendo (`CLAUDE.md`): solo tokens, textos en los dos ARB, sin paquetes nativos, las pruebas en el teléfono las hace Manuel, sin commits ni despliegues sin que él lo pida.

## Estado de las fases

| # | Fase | Estado |
|---|---|---|
| 1 | Base: esqueletos con brillo, spinner, interruptor, filtros de texto, tokens nuevos | Hecha (2026-10-02) |
| 2 | Moderación: reportar, bloquear, silenciar, ocultar, filtro de palabras, Privacidad y seguridad, reglas | Hecha (2026-10-02) |
| 3 | Onboarding: gustos (paso 1) y seguir gente (paso 2) | Hecha (2026-10-02) |
| 4 | Estadísticas del perfil y Compartir estadísticas | Hecha (2026-10-02) |
| 5 | Recuperar contraseña (app + función `recover`) | Hecha (2026-10-02); falta que Manuel configure el correo y despliegue |
| 6 | Estados vacíos, sin conexión, error de servidor, cola de notas sin conexión, login incorrecto | Hecha (2026-10-02) |
| 7 | ♡ en las respuestas, panel de reportes, géneros y países | Hecha (2026-10-02); géneros y países dependen de desplegar `spotify` |
| 8 | Cierre: `CLAUDE.md`, `docs/SISTEMA.md`, pruebas y lista para Manuel | Hecha (2026-10-02) |

**La ronda 8 está terminada.** Lo que queda es de Manuel: desplegar (abajo) y probar en el teléfono (al final).

### Fase 6 (sin conexión, errores y vacíos)

- `ConnectivityService` (en `Services.connectivity`) comprueba al arrancar, al volver al frente y cuando una petición a Spotify falla o sale bien. Inicio, sin conexión: la franja "Sin conexión · mostrando lo último guardado · Reintentar" y lo de debajo al 55 %.
- Buscar y "Ver todos": sin conexión, "Sin conexión" (`OfflineState`) con "Reintentar" ("Conectando…") y "Ver mis discos guardados" (el diario); con un 5xx de la función, "Se rayó el disco" (`ServerErrorState`) con el código `VN-<estado>-<4 hex>`, "Intentar de nuevo" y "Reportar el problema" (`problems/`; si no se puede, copia el código y dice el correo de soporte).
- Cola de notas: si Calificar no puede guardar por la red (o ya se sabe que no hay conexión), la nota va a `users/{uid}/outbox/{albumId}` (Firestore la deja en el teléfono) y la hoja muestra "No pudimos guardar tu nota · Reintentar", sin barras ni comentario, como el prototipo. El disco muestra "Tu nota · por subir". `OutboxSync` (en `ShellScreen`) la sube con la transacción de siempre al volver la señal y la saca de la cola; borrar la nota también la saca.
- Vacíos: Inicio sin seguir a nadie ("Tu inicio está muy callado", con "Encontrar gente" → sugerencias y "Calificar un disco" → Buscar; reemplaza también "Popular esta semana", como el prototipo), mi perfil sin notas ("Tu diario está en blanco"; los favoritos del onboarding se siguen viendo), Buscar sin resultados ("¿Quisiste decir?" con búsquedas parecidas y "Pídenos que lo agreguemos" → `requests/`) y Notificaciones ("Al día · Nada nuevo por ahora").
- Inicio cargando: el esqueleto del prototipo (tres portadas, una raya y seis filas bajo un solo brillo).
- Login incorrecto ya estaba desde la fase 5 (contraseña en rojo con "La contraseña no coincide con ese usuario." y "¿Olvidaste tu contraseña?" en tinta).
- No se hizo "Cargando disco": el disco siempre abre con el álbum en la mano (portada y título); lo que carga son las canciones, que ya tienen su esqueleto.

### Fase 7

- ♡ en las respuestas: ya estaba hecho en la fase 2 (`reply-like-N`, `likedBy`, sin aviso).
- Panel de moderación (`moderation_panel_screen.dart`): la fila "Moderación" de Configuración solo aparece con `admins/{uid}`. Pestañas Reportes (Ver, Sin cambios, Retirar: la nota queda sin texto y con `moderated: true`; la respuesta se borra y baja `repliesCount`), Problemas y Discos pedidos (agrupados por lo que se buscó; tocar uno lo busca).
- Géneros y países: ruta `GET /artists/meta?ids=` de la función `spotify` (`functions/meta.js`), que busca en MusicBrainz por el enlace de Spotify del artista (una petición por segundo, 4 artistas por llamada), guarda en `artistMeta/{id}` (también lo que no encuentra, `missing: true`) y devuelve `pending`. La pestaña Estadísticas pide los que faltan (hasta 8 vueltas por sesión) y pinta lo que llega. Sin desplegar `spotify`, los bloques no aparecen (como hasta ahora).
- `account` también borra los problemas y pedidos de la persona y quita sus ♡ en respuestas ajenas (índice nuevo de grupo de colecciones sobre `replies.likedBy`).

## Decisiones tomadas por defecto (Manuel puede cambiarlas)

1. **Correo de soporte:** el prototipo dice `soporte@vinilo.app`. Va en una sola constante (`lib/util/support.dart`). Manuel tiene que confirmar que ese buzón existe o dar otro antes de publicar.
2. **Recuperar contraseña con código:** Firebase solo manda enlaces, así que el código de 6 dígitos lo manda una función nueva, `recover` (`functions/recover.js`), por SMTP (`nodemailer`, secretos `SMTP_URL` y `MAIL_FROM`). Mientras la función no esté desplegada o configurada, "¿Olvidaste tu contraseña?" sigue mandando el enlace de Firebase.
3. **"Buscar en tus contactos":** la fila se ve como en el prototipo y abre la búsqueda de personas por nombre o @usuario. Cruzar la agenda real exige guardar teléfonos o correos, permiso nativo y relanzar: queda para cuando Manuel lo decida.
4. **Géneros y países de las estadísticas:** Spotify (modo desarrollo) no manda géneros ni país del artista. Los bloques quedan hechos y solo aparecen si hay datos (`artistMeta/{id}`); la fuente (MusicBrainz desde la función `spotify`) es la fase 7 y se activa solo si Manuel despliega.
5. **Bloqueo:** se aplica en la app (inicio, búsqueda, notificaciones, respuestas, afinidad, perfil) y las reglas impiden seguir, responder y avisar a quien te bloqueó. Lo que Firestore no puede filtrar en una consulta (las notas de quien bloquea) lo oculta la app.
6. **Panel interno de reportes:** los reportes van a `reports/`; quien tenga un documento en `admins/{uid}` ve "Moderación" en Configuración. Sin eso, se revisan en la consola de Firebase.
7. **Estadísticas solo en el perfil propio** (los textos del prototipo van en segunda persona).
8. **Discos del onboarding:** los primeros 3 elegidos son los favoritos; todos (hasta 9) se guardan en `users.tastes` para las sugerencias.

## Datos nuevos en Firestore

- `users/{uid}`: `onboarding` (`tastes` | `follow`; ausente = terminado), `tastes` (álbumes compactos), `filterOffensive` (bool; ausente = true).
- `users/{uid}/mutes/{otro}`: `uid`, `info` (`PersonInfo`), `createdAt`. Solo la dueña.
- `users/{uid}/hidden/{id}`: `kind` (`rating` | `reply`), `ratingId`, `createdAt`. Solo la dueña.
- `users/{uid}/outbox/{albumId}`: la nota que no se pudo guardar (`score`, `note`, `album`, `createdAt`). Solo la dueña.
- `blocks/{quien}_{aQuien}`: `blocker`, `blocked`, `blockedInfo`, `createdAt`. La leen las dos partes; la crea y la borra quien bloquea.
- `reports/{id}`: `reporter`, `targetType` (`user` | `rating` | `reply`), `targetId`, `targetUid`, `targetInfo`, `ratingId`, `reason`, `details`, `number`, `status` (`open` | `resolved`), `createdAt`.
- `admins/{uid}`: existe = puede revisar reportes (se crea a mano en la consola).
- `ratings/{id}.album.durationMs`: la duración del disco, para "Tiempo escuchando".
- `ratings/{id}/replies/{id}.likedBy`: uids.
- `passwordResets/{hash}`: solo la función `recover`.
- `artistMeta/{spotifyId}`: `country`, `genres`, `mbid`, `missing`, `source`, `updatedAt` (lo escribe la función `spotify` desde MusicBrainz; la app solo lee).
- `ratings/{id}.moderated`: true si quien modera retiró el comentario (la nota se queda sin texto).
- `problems/{id}`: `uid`, `code`, `detail`, `createdAt` ("Reportar el problema"). Lo lee quien modera.
- `requests/{id}`: `uid`, `query`, `createdAt` ("Pídenos que lo agreguemos"). Lo lee quien modera.

## Qué despliega Manuel al final

En este orden (desde la Mac, con `firebase` y la sesión de Manuel):

1. `firebase deploy --only firestore:indexes` (el nuevo de `replies.likedBy`; `account` lo necesita).
2. `firebase deploy --only firestore:rules,storage` (las reglas siguen sin desplegar; el modo de prueba vence hacia el 2026-10-21). La primera vez, aceptar que Storage lea Firestore.
3. Los secretos del correo de `recover`: `firebase functions:secrets:set SMTP_URL` (por ejemplo `smtps://usuario%40gmail.com:clave-de-aplicacion@smtp.gmail.com:465`) y `firebase functions:secrets:set MAIL_FROM` (`Vinilo <usuario@gmail.com>`).
4. `firebase deploy --only functions:recover,functions:account,functions:spotify`.
5. Para ver el panel de moderación: crear a mano en la consola el documento `admins/9G1HedDHpPQz3Jk4XPFrqrqesNF3` (vacío vale).
6. Confirmar que `soporte@vinilo.app` existe o cambiarlo en `lib/util/support.dart` (o `--dart-define=SUPPORT_EMAIL=…`).

## Qué probar (Manuel, en el iPhone)

No hay cambios nativos: con `flutter run` abierto basta `R`; si no, reinstalar con el comando de siempre (`CLAUDE.md`).

**Onboarding (fase 3):** crear una cuenta nueva → "Elige 3 discos que te encanten": filtrar por género, buscar, elegir 3 o más (número de orden y contorno), "Continuar" → "Sigue a gente con tu oído": seguir a alguien, "Buscar en tus contactos" abre la búsqueda de personas, "Empezar" o "Saltar" lleva a la app. Esperado: los 3 primeros quedan de favoritos en el perfil.

**Moderación (fase 2):** en el perfil de otra persona, "···" → Compartir, Silenciar, Reportar, Bloquear. Reportar: elegir motivo, detalles y "Enviar" → "Reporte Nº …" y "Ver mis reportes". Bloquear: la hoja explica qué pasa; el perfil queda gris con "Desbloquear". En un hilo, "···" de una respuesta → Ocultar (con "Deshacer") y Reportar. Configuración → Privacidad y seguridad: el interruptor del filtro (un comentario con un insulto se ve con puntos), "Mis reportes", "Cuentas silenciadas" y las bloqueadas con "Desbloquear".

**Estadísticas (fase 4):** Perfil → pestaña "Estadísticas": Este mes / Este año / Siempre, "Cómo calificas" (tocar una barra), artistas, décadas, ritmo, tiempo escuchando (se va completando), afinidad con amigos y "Compartir mis estadísticas" (tres fondos, guardar, historias, WhatsApp, copiar enlace). Con `spotify` desplegada, al volver a abrirla aparecen "Géneros" y "De dónde vienen" (la primera vez tarda: van llegando de a 4 artistas).

**Recuperar contraseña (fase 5):** Iniciar sesión → "¿Olvidaste tu contraseña?". Sin `recover` desplegada: manda el enlace de Firebase de siempre. Con ella: llega un código de 6 dígitos, el teclado propio, "Código incorrecto · te quedan N intentos", "Reenviar en 0:45", la contraseña nueva con sus reglas y "Todo listo". Probar con una cuenta de prueba, nunca con @manuel ni @holaaaa. Contraseña mal en Iniciar sesión: la línea y el texto en rojo.

**Sin conexión (fase 6):** con modo avión:
- Inicio: aparece la franja "Sin conexión · mostrando lo último guardado"; lo de abajo se apaga. "Reintentar" muestra el spinner. Al quitar el modo avión la franja se va sola en unos segundos.
- Buscar algo: pantalla "Sin conexión"; "Ver mis discos guardados" abre el diario.
- Calificar un disco: "Guardar mi nota" tarda un momento y muestra "No pudimos guardar tu nota"; cerrar la hoja: el disco dice "Tu nota · por subir". Quitar el modo avión: en segundos pasa a "Tu nota · editar" y aparece en el diario y en el promedio del disco.

**Vacíos (fase 6):** una cuenta de prueba sin seguir a nadie: Inicio dice "Tu inicio está muy callado" ("Encontrar gente" abre sugerencias; "Calificar un disco" va a Buscar). Sin notas, Mi perfil dice "Tu diario está en blanco" y el botón va a Buscar. Buscar "ceratti bocanda": "0 resultados", "¿Quisiste decir?" con discos parecidos y "Pídenos que lo agreguemos" (cambia a "Anotado…"). Notificaciones vacías: "Al día · Nada nuevo por ahora".

**Respuestas y moderación interna (fase 7):** en un hilo, ♡ de una respuesta suma y resta. Con `admins/{uid}` creado: Configuración → "Moderación": reportes abiertos ("Ver", "Sin cambios", "Retirar" con confirmación), Problemas y Discos pedidos.

**Error del servidor (fase 6):** solo se ve si la función de Spotify responde 5xx; no hace falta forzarlo.
