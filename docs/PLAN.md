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
| 6 | Estados vacíos, sin conexión, error de servidor, cola de notas sin conexión, login incorrecto | Pendiente |
| 7 | ♡ en las respuestas, panel de reportes, géneros y países (si alcanza) | Pendiente |
| 8 | Cierre: `CLAUDE.md`, `docs/SISTEMA.md`, pruebas y lista para Manuel | Pendiente |

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
- `artistMeta/{spotifyId}`: `country`, `genres` (lo escribe la función; la app solo lee).

## Qué despliega Manuel al final

- `firebase deploy --only firestore:rules,storage` (las reglas siguen sin desplegar; el modo de prueba vence hacia el 2026-10-21).
- `firebase deploy --only functions:recover,functions:account,functions:spotify` y los secretos de correo.
