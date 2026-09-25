# Vinilo — Especificación visual

Referencia visual: `Vinilo App.dc.html` (ábrelo en el navegador junto a `support.js`). Cada pantalla tiene su nombre encima; úsalo para ubicarla en el código.

## Principios
- Modo oscuro único. Sin tarjetas redondeadas, sin botones tipo pastilla, sin sombras ni gradientes.
- Las secciones se separan con líneas de 1px. Todas las esquinas son rectas (radio 0).
- **Las personas son círculos** (avatares, fotos de artistas). **Los discos son cuadrados** (portadas).
- Las pestañas son texto con subrayado de 2px, no controles segmentados.
- Los iconos son de trazo fino (1.5–1.6px) y van dentro de botones cuadrados de 40×40 con borde de 1px.

## Colores
| Token | Valor | Uso |
|---|---|---|
| `bg` | `#0f0e0d` | Fondo de la app |
| `sheet` | `#171615` | Fondo de paneles inferiores (bottom sheets) |
| `surface` | `#2a2826` | Placeholder de fotos |
| `ink` | `#efebe4` | Texto principal, botón primario neutro |
| `ink-2` | `rgba(239,235,228,.62)` | Texto secundario / descripciones |
| `ink-3` | `rgba(239,235,228,.58)` | Etiquetas mono |
| `ink-4` | `rgba(239,235,228,.50)` | Texto terciario, contadores |
| `line` | `rgba(239,235,228,.14)` | Separadores principales |
| `line-soft` | `rgba(239,235,228,.08)` | Separadores entre filas |
| `line-strong` | `rgba(239,235,228,.28)` | Bordes de botones secundarios e inputs |
| `scrim` | `rgba(8,8,7,.72)` | Fondo detrás de un bottom sheet |
| `accent` | variable, por defecto `oklch(0.7 0.19 38)` (bermellón ≈ `#f0602e`) | Ver abajo |

### Color de énfasis (variable global)
Se elige en **Configuración** y se guarda en el perfil. Debe ser un token global (theme/context) porque afecta: botones primarios, enlaces ("Ver todo"), pestaña activa de la barra inferior (línea superior de 2px × 32px), punto de notificaciones, botón "Siguiendo", notas numéricas del inicio y de "Calificado por", barras de gráficas, borde de input con foco, opción seleccionada y el panel de calificar.

Opciones de la paleta (14):
`oklch(0.7 0.19 38)`, `oklch(0.7 0.17 20)`, `oklch(0.78 0.15 85)`, `oklch(0.78 0.16 125)`, `oklch(0.72 0.15 150)`, `oklch(0.72 0.12 180)`, `oklch(0.72 0.12 220)`, `oklch(0.65 0.15 255)`, `oklch(0.65 0.15 285)`, `oklch(0.7 0.15 310)`, `oklch(0.7 0.16 340)`, `oklch(0.64 0.19 5)`, `oklch(0.6 0.1 60)`, `#efebe4`.

Texto sobre el acento: siempre `#0f0e0d`.

### Color de portada
En el detalle de un disco, la nota grande y el nombre del artista toman un tono claro extraído de la portada (misma tonalidad, luminosidad ~0.76). Si la app no extrae colores, usar `accent`.

## Tipografía (Google Fonts)
| Rol | Fuente | Detalle |
|---|---|---|
| Display / títulos / notas | **Archivo** | `font-stretch` 62–80% (condensada), peso 700–900, interlineado 0.8–0.9, tracking −0.01em |
| Cuerpo / UI | **Archivo** | ancho normal, 400–600 |
| Etiquetas y datos | **IBM Plex Mono** 500 | MAYÚSCULAS, tracking 0.06–0.1em, 9.5–11px |
| Citas de reseñas | **Newsreader** itálica 400 | solo comentarios / reseñas |

> Archivo es variable en ancho: cargar `Archivo:wdth,wght@62..125,300..900`. En iOS/Android, si no hay soporte de eje `wdth`, usar **Archivo Condensed / Archivo ExtraCondensed** como archivos estáticos.

Escala (px, pantalla de 390 de ancho):
- Logo "VINILO": 900, stretch 62%, 128 (bienvenida) / 36 (header).
- Título de pantalla: 800, stretch 62%, 46–64.
- Nota principal: 700, stretch 62%, 56–64. Nota en listas: 28–36.
- Título de fila: 700, stretch 75%, 19–24.
- Cuerpo: 14–15, interlineado 1.4–1.45.
- Etiqueta mono: 10–10.5.
- Barra inferior: 13, activa 600 / inactiva 500 con `ink` al 55%.

## Espaciado y medidas
- Márgenes laterales: 20px (24 en bienvenida).
- Botón primario: alto 56, relleno horizontal 20, texto a la izquierda y "→" a la derecha. Fondo `ink` o `accent`.
- Botón secundario: alto 48–52, borde 1px `line-strong`.
- Barra inferior: alto 84, borde superior `line`, 3 ítems (Inicio, Buscar, Perfil).
- Separación entre portadas en cuadrícula: 2px.
- Portadas en carrusel del inicio: 136×136 (se ven 2,5 a la vez).
- Avatar en "Calificado por": 56 círculo, nota debajo, en una sola fila. Al tocar, abre el detalle de esa calificación.
- Headers de sección: fila con etiqueta mono a la izquierda y acción a la derecha, línea `line` arriba, relleno vertical 10.

## Escala de notas 1–10
- Siempre una retícula de 10 columnas iguales.
- Distribución de la comunidad: barras sobre esa misma retícula; columnas sin votos = línea de 2px `rgba(239,235,228,.2)`.
- Etiquetas de veredicto (1→10): Terrible, Muy malo, Malo, Flojo, Regular, Aceptable, Bueno, Muy bueno, Excelente, Obra maestra.
- Decimales con coma: `9,5`.

### Animación de "Calificar"
Para cada columna `k` con nota seleccionada `n`, `d = |k − n|`:
- alto = `max(30, 136 − d·20)` px
- tamaño de número = `max(11, 24 − d·3)` px
- opacidad = `1` si d=0, si no `max(0.16, 0.62 − (d−1)·0.11)`
- La seleccionada: fondo `accent`, número `#0f0e0d` peso 700; el resto fondo `accent` con esa opacidad, número `ink` 500.
- Transición de alto/opacidad/tamaño: ~220ms ease-out. Se puede tocar o arrastrar.

## Bottom sheets (Agregar a una lista / Nueva lista)
- Fondo `sheet`, borde superior 1px `line`, sin radio. Asa: 40×4 `rgba(239,235,228,.3)`.
- Inputs: sin caja; texto + línea inferior 1px `line-strong`. Con foco: línea 2px `accent` y etiqueta en `accent`. Contador mono a la derecha.
- Tipo (Lista / Ranking): dos cajas con borde 1px; la seleccionada con borde `accent`, título `accent` y check cuadrado de 14px.

## Web (enlaces compartidos)
- Ancho de contenido 1200, márgenes 48. Franja superior de 6px con el color de la portada o del acento.
- Cierre con "¿Todavía no tienes Vinilo?" y botón con borde "Muy pronto en el App Store".
- Pie: "Datos de discos y artistas: Spotify."

## Ícono de app
"V" en Archivo 900 condensada, color `ink`, sobre `#0f0e0d`, con una barra horizontal corta en `accent` debajo.
