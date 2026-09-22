# Prompt para Fable — ronda de cambios de diseño

Pégalo en la sesión de Fable abierta en esta carpeta.

```text
Vamos a hacer una ronda de cambios en Vinilo. Lee CLAUDE.md antes de empezar. No cambies la dirección visual salvo donde lo pido, y no rompas lo que ya funciona: buscar, calificar, likes y perfiles ajenos.

Paso 0: la barra de navegación con Liquid Glass
Quiero que la barra de navegación inferior se vea como la nativa de iOS 26, con Liquid Glass; la actual no me gusta. Antes de construir nada, investiga y dime qué opción recomiendas:
- Nativa de verdad: un UITabBar de iOS incrustado como platform view, con un paquete mantenido (por ejemplo cupertino_native; verifica que exista, esté mantenido y funcione con Flutter 3.41) o con código Swift propio en ios/Runner. Un paquete nativo obliga a correr pod install y recompilar los pods de Firebase (unos 20 minutos). El mínimo de la app es iOS 15, así que hace falta una alternativa para versiones anteriores a iOS 26.
- Imitación en Dart puro (por ejemplo liquid_glass_renderer, o un BackdropFilter mejor hecho): sin pods nuevos, pero no es la nativa.
Muéstrame cómo se vería cada una si puedes, y espera mi respuesta antes de instalar cualquier paquete nativo. Si elegimos la nativa, instálala antes que los demás cambios para que la recompilación larga pase una sola vez.

Después, hazlo en este orden. Prueba cada bloque en el simulador y muéstrame una captura antes de pasar al siguiente.

Bloque 1: ajustes rápidos
1. Inicio, encabezado: el título "Vinilo" centrado. Quita la foto de perfil y el saludo ("Buenas noches…").
2. Inicio, secciones:
   - Cambia "Sonando en la comunidad" por "Popular en la comunidad".
   - Quita por completo la sección "Lo nuevo de 2026", incluidos sus estados de carga y error.
   - En "Actividad", quita el subtítulo "El diario de toda la comunidad".
3. Detalle de un disco sin calificaciones: muestra solo el texto "Nadie ha calificado este disco todavía", sin promedio, histograma ni espacios vacíos.
4. Perfil: quita el título "Distribución" y el subtítulo "Cómo repartes tus notas". La gráfica se queda.
5. Barra de navegación: la pestaña de perfil deja de mostrar mi foto y usa un ícono, como las otras dos.

Bloque 2: comportamiento
6. Degradado (AmbientGlow) en el detalle del disco y en el perfil, que son las pantallas que lo usan: hoy queda fijo detrás del contenido, así que al hacer scroll las canciones y el diario pasan por encima del degradado. Quiero que el degradado sea parte del encabezado y se desplace con él: al bajar, sube junto con la portada y desaparece, y el resto del contenido queda sobre el fondo liso.
7. Detalle de un disco que ya califiqué: mi nota se muestra compacta, en una sola fila: "Tu nota 8 ··········· Editar". Editar abre el mismo selector de hoy. El dial grande solo aparece si todavía no lo he calificado.
8. Diario del perfil: muestra solo las últimas 5 calificaciones. Si hay más, un botón "Ver más" abre una pantalla nueva con todas, donde puedo buscar por disco o artista, filtrar por nota y ordenar por fecha o por nota.

Bloque 3: funciones nuevas
9. Favoritos en el perfil: 3 discos favoritos (hoy son 4) y 3 artistas favoritos, con la foto del artista. Para los artistas hace falta buscarlos en Spotify: agrega esa ruta a la Cloud Function y vuelve a desplegarla. Los perfiles que ya tienen 4 discos guardados deben seguir funcionando (muestra los 3 primeros). Los perfiles ajenos también muestran ambos.
10. Banner del perfil: poder poner una foto de fondo detrás de la foto de perfil, como en Twitter/X. Se elige desde la edición del perfil con image_picker (ya instalado) y se sube a Storage igual que el avatar. Si no hay banner, se ve el degradado del color del perfil como hoy.
11. Modo claro: la app debe tener tema claro además del oscuro, con una opción en el perfil: Sistema, Claro u Oscuro. Hoy los colores son constantes en VColors, así que habrá que convertirlos en colores que dependan del tema; revisa todas las pantallas para que no quede texto ilegible ni superficies oscuras sueltas. Guarda la preferencia en el documento del usuario en Firestore, para no agregar un paquete nativo como shared_preferences. La barra de estado también debe cambiar según el tema. El modo claro tiene que verse igual de cuidado que el oscuro: el mismo carácter editorial, no un tema por defecto de Material.

Bloque 4: la barra de navegación
12. Implementa la opción que elegimos en el paso 0, si no la hiciste ya al principio.

Al terminar, actualiza CLAUDE.md con lo que cambió (estructura, datos en Firestore y rutas de la función) y dime qué quedó pendiente o qué no pudiste verificar.
```
