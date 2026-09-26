/**
 * Vinilo — página web pública (función `web`, detrás de Firebase Hosting).
 *
 * Lo que se comparte desde la app abre aquí, para quien no tiene la app:
 *   /l/{listId}     lista o ranking
 *   /d/{albumId}    disco: promedio de la comunidad, histograma y comentarios
 *   /n/{ratingId}   una nota ({uid}_{albumId}): disco, nota, comentario y
 *                   sus respuestas
 *   /a/{artistId}   artista con sus discos calificados en Vinilo
 *   /u/{usuario}    perfil (también acepta el uid)
 *   /portadas       JSON con las portadas de la bienvenida de la app (las 8
 *                   más calificadas), que la app pide antes de tener cuenta
 *
 * El HTML se arma en el servidor con el Admin SDK y solo lleva lo que se
 * comparte (nunca correos ni uids), con etiquetas Open Graph para que
 * WhatsApp o iMessage muestren la tarjeta. Idioma según Accept-Language
 * (o ?lang=es|en). Todo texto que viene de las personas pasa por `esc`.
 *
 * El diseño es el del prototipo ("Web · disco compartido", "Web · artista
 * compartido", "Web · enlace roto"): ancho de 1200 con márgenes de 48, una
 * franja de 6 px del color de la portada, Archivo condensada, IBM Plex Mono
 * e itálica Newsreader. Por debajo de 820 px todo se apila.
 */

const { getFirestore } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const SITE = "https://red-social-c786b.web.app";
// URL de la app en el App Store; mientras esté vacía, la página dice
// "Muy pronto en el App Store". Se configura en functions/.env.
const APP_STORE_URL = process.env.APP_STORE_URL || "";
/** Bermellón, `oklch(0.7 0.19 38)`: el énfasis por defecto de la app. */
const DEFAULT_ACCENT = "#fd6a3a";

/** Los 14 colores de énfasis de la app (`VColors.accentPalette`). */
const ACCENT_PALETTE = [
  "#fd6a3a", "#f66b71", "#e3ae28", "#a0c849", "#53be70", "#2fbda7", "#2fb5d8",
  "#4990e8", "#877fe6", "#bb82e3", "#de73bd", "#e44d7d", "#ac713e", "#efebe4",
];

// ---------------------------------------------------------------------------
// Textos
// ---------------------------------------------------------------------------

const plural = (n, one, many) => (n === 1 ? one : many);

const STRINGS = {
  es: {
    tagline: "Califica tus discos del 1 al 10",
    ctaTitle: "¿Todavía no tienes Vinilo?",
    ctaBody:
      "Califica tus discos del 1 al 10, lleva el diario de lo que escuchas y mira qué califican tus amigos.",
    ctaSoon: "Muy pronto en el App Store",
    ctaDownload: "Descargar en el App Store",
    ratings: (n) => plural(n, "1 calificación", `${n} calificaciones`),
    noRatingsShort: "Sin notas todavía",
    comments: "Comentarios",
    replies: "Respuestas",
    tracks: (n) => plural(n, "1 canción", `${n} canciones`),
    albums: (n) => plural(n, "1 disco", `${n} discos`),
    songsHead: "Canciones",
    albumsHead: "Discos",
    list: "Lista",
    ranking: "Ranking",
    likes: (n) => plural(n, "1 me gusta", `${n} me gusta`),
    replyCount: (n) => plural(n, "1 respuesta", `${n} respuestas`),
    rated: "calificó",
    community: "Promedio de la comunidad",
    statAlbums: (n) => plural(n, "Disco", "Discos"),
    statAverage: "Promedio",
    followers: (n) => plural(n, "Seguidor", "Seguidores"),
    following: (n) => plural(n, "Seguido", "Seguidos"),
    favorites: "Discos favoritos",
    favoriteArtists: "Artistas favoritos",
    recent: "Últimas notas",
    lists: "Listas",
    artistRated: (n) => plural(n, "Artista · 1 disco calificado", `Artista · ${n} discos calificados`),
    ratedInVinilo: "Calificados en Vinilo",
    notRatedYet: "Todavía nadie ha calificado sus discos en Vinilo.",
    more: (n) => `y ${n} más`,
    error404: "Error 404 · lado C",
    notFoundTitle: "No encontramos esto",
    notFoundBody: "Puede que lo hayan borrado o que el enlace esté incompleto.",
    home: "Ir al inicio",
    credits: "Datos de discos y artistas: Spotify.",
    scoreLabels: ["Terrible", "Muy malo", "Malo", "Flojo", "Regular", "Aceptable", "Bueno", "Muy bueno", "Excelente", "Obra maestra"],
    types: { album: "Álbum", single: "Sencillo", compilation: "Recopilación", ep: "EP" },
    decimal: ",",
    descList: (owner, n) => `Una lista de ${owner} en Vinilo · ${n}`,
    descRanking: (owner, n) => `Un ranking de ${owner} en Vinilo · ${n}`,
    descAlbum: (artist, avg, n) =>
      avg ? `${artist} · ${avg}/10 en Vinilo (${n})` : `${artist} · en Vinilo`,
    titleRating: (name, score, album) => `${name} le dio ${score}/10 a ${album}`,
    descArtist: (n) => `Sus discos calificados por la comunidad de Vinilo · ${n}`,
    descProfile: (name) => `El diario de discos de ${name} en Vinilo`,
  },
  en: {
    tagline: "Rate your albums from 1 to 10",
    ctaTitle: "Don't have Vinilo yet?",
    ctaBody:
      "Rate your albums from 1 to 10, keep a diary of what you listen to and see what your friends are rating.",
    ctaSoon: "Coming soon to the App Store",
    ctaDownload: "Download on the App Store",
    ratings: (n) => plural(n, "1 rating", `${n} ratings`),
    noRatingsShort: "No ratings yet",
    comments: "Comments",
    replies: "Replies",
    tracks: (n) => plural(n, "1 song", `${n} songs`),
    albums: (n) => plural(n, "1 album", `${n} albums`),
    songsHead: "Songs",
    albumsHead: "Albums",
    list: "List",
    ranking: "Ranking",
    likes: (n) => plural(n, "1 like", `${n} likes`),
    replyCount: (n) => plural(n, "1 reply", `${n} replies`),
    rated: "rated",
    community: "Community average",
    statAlbums: (n) => plural(n, "Album", "Albums"),
    statAverage: "Average",
    followers: (n) => plural(n, "Follower", "Followers"),
    following: () => "Following",
    favorites: "Favorite albums",
    favoriteArtists: "Favorite artists",
    recent: "Latest ratings",
    lists: "Lists",
    artistRated: (n) => plural(n, "Artist · 1 album rated", `Artist · ${n} albums rated`),
    ratedInVinilo: "Rated on Vinilo",
    notRatedYet: "No one has rated their albums on Vinilo yet.",
    more: (n) => `and ${n} more`,
    error404: "Error 404 · side C",
    notFoundTitle: "We couldn't find this",
    notFoundBody: "It may have been deleted, or the link is incomplete.",
    home: "Go home",
    credits: "Album and artist data: Spotify.",
    scoreLabels: ["Terrible", "Very bad", "Bad", "Weak", "So-so", "Decent", "Good", "Very good", "Excellent", "Masterpiece"],
    types: { album: "Album", single: "Single", compilation: "Compilation", ep: "EP" },
    decimal: ".",
    descList: (owner, n) => `A list by ${owner} on Vinilo · ${n}`,
    descRanking: (owner, n) => `A ranking by ${owner} on Vinilo · ${n}`,
    descAlbum: (artist, avg, n) =>
      avg ? `${artist} · ${avg}/10 on Vinilo (${n})` : `${artist} · on Vinilo`,
    titleRating: (name, score, album) => `${name} gave ${album} a ${score}/10`,
    descArtist: (n) => `Their albums as rated by the Vinilo community · ${n}`,
    descProfile: (name) => `${name}'s album diary on Vinilo`,
  },
};

/** El idioma: ?lang=, o el primero entre es/en de Accept-Language; si no, es. */
function pickLang(req) {
  const forced = String(req.query.lang || "");
  if (forced === "es" || forced === "en") return forced;
  const header = String(req.get("Accept-Language") || "").toLowerCase();
  for (const part of header.split(",")) {
    const code = part.trim().slice(0, 2);
    if (code === "es" || code === "en") return code;
  }
  return "es";
}

// ---------------------------------------------------------------------------
// HTML seguro: todo se escapa salvo lo que ya armó `html`.
// ---------------------------------------------------------------------------

class Raw {
  constructor(value) {
    this.value = value;
  }
}

function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (ch) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;",
  })[ch]);
}

function render(value) {
  if (value == null || value === false) return "";
  if (value instanceof Raw) return value.value;
  if (Array.isArray(value)) return value.map(render).join("");
  return esc(value);
}

function html(strings, ...values) {
  let out = strings[0];
  values.forEach((value, i) => {
    out += render(value) + strings[i + 1];
  });
  return new Raw(out);
}

/** Solo URLs https (portadas de Spotify, fotos de Storage). */
function safeUrl(url) {
  return typeof url === "string" && url.startsWith("https://") ? url : "";
}

/** Una URL para `url('…')` de CSS: sin comillas, paréntesis ni espacios. */
function cssUrl(url) {
  return safeUrl(url).replace(/['"()\\\s]/g, (ch) => `%${ch.charCodeAt(0).toString(16).padStart(2, "0")}`);
}

// ---------------------------------------------------------------------------
// Color: el énfasis de la persona (el más parecido de la paleta, como
// `VColors.nearest`) y el fondo de su avatar sin foto (`personTone`).
// ---------------------------------------------------------------------------

function argbToHex(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return DEFAULT_ACCENT;
  return `#${(n & 0xffffff).toString(16).padStart(6, "0")}`;
}

function oklab(hex) {
  const n = parseInt(hex.slice(1), 16);
  const lin = (v) => {
    const c = v / 255;
    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  };
  const r = lin((n >> 16) & 255);
  const g = lin((n >> 8) & 255);
  const b = lin(n & 255);
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}

/** El color de la paleta más parecido (distancia en OKLab). */
function nearestAccent(hex) {
  const [l, a, b] = oklab(hex);
  let best = DEFAULT_ACCENT;
  let bestD = Infinity;
  for (const c of ACCENT_PALETTE) {
    const [l2, a2, b2] = oklab(c);
    const d = (l - l2) ** 2 + (a - a2) ** 2 + (b - b2) ** 2;
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return best;
}

/** `personTone`: la misma tonalidad, apagada (L 0,44, croma hasta 0,12). */
function personTone(hex) {
  const [, a, b] = oklab(hex);
  const c = Math.min(Math.hypot(a, b), 0.12);
  let h = (Math.atan2(b, a) * 180) / Math.PI;
  if (h < 0) h += 360;
  return `oklch(0.44 ${c.toFixed(3)} ${h.toFixed(1)})`;
}

function formatAverage(value, t) {
  return value.toFixed(1).replace(".", t.decimal);
}

// ---------------------------------------------------------------------------
// Piezas
// ---------------------------------------------------------------------------

/** Avatar redondo: la foto o la inicial sobre su color apagado. */
function avatar(person, size = 28) {
  const url = safeUrl(person.avatarUrl);
  const initial = (String(person.name || "?").trim()[0] || "?").toUpperCase();
  return url
    ? html`<img class="avatar" src="${url}" alt="" width="${size}" height="${size}" style="--size:${size}px">`
    : html`<span class="avatar" style="--size:${size}px;--c:${personTone(argbToHex(person.color))}">${initial}</span>`;
}

/**
 * La distribución de notas en una retícula de 10: la más votada llega a
 * `height − 4` y las demás van proporcionales (y más transparentes); sin
 * votos, una raya de 2 px. Debajo, los números del 1 al 10.
 */
function histogram(hist, height = 70) {
  const counts = Array.from({ length: 10 }, (_, i) => Number(hist?.[String(i + 1)]) || 0);
  const max = Math.max(...counts);
  return html`<div class="hist" style="height:${height}px" aria-hidden="true">${counts.map((n) => (n === 0 || max === 0
    ? html`<span class="none"></span>`
    : html`<span class="${n === max ? "" : "low"}" style="height:${Math.max(2, Math.round(((height - 4) * n) / max))}px"></span>`))}</div>
  <div class="nums" aria-hidden="true">${counts.map((_, i) => html`<span>${i + 1}</span>`)}</div>`;
}

/** "8,3 /10" con cuántas notas, y el histograma. */
function communityBlock(stats, t, height = 70) {
  if (!stats || !stats.count) {
    return html`<div class="score-row"><span class="big dim">—</span><span class="mono">${t.noRatingsShort}</span></div>`;
  }
  return html`<div class="score-row">
      <span class="big">${formatAverage(stats.sum / stats.count, t)}<span class="out"> /10</span></span>
      <span class="mono">${t.ratings(stats.count)}</span>
    </div>
    ${histogram(stats.hist, height)}`;
}

/** Un comentario: la nota en 64, el nombre y la cita en Newsreader. */
function commentRow(entry) {
  return html`<article class="comment">
    <span class="num-big">${entry.score}</span>
    <p class="name">${entry.user.name}</p>
    <p class="quote">“${entry.note}”</p>
  </article>`;
}

function blockHead(label, count) {
  return html`<div class="block-head mono"><span>${label}</span>${count == null ? "" : html`<span>${count}</span>`}</div>`;
}

function albumMeta(album, t) {
  return [
    t.types[album.type] || null,
    album.year || null,
    album.totalTracks ? t.tracks(album.totalTracks) : null,
  ].filter(Boolean).join(" · ");
}

function ctaButton(t) {
  return APP_STORE_URL
    ? html`<a class="btn-line" href="${APP_STORE_URL}">${t.ctaDownload}</a>`
    : html`<span class="btn-line">${t.ctaSoon}</span>`;
}

/**
 * La página: franja de color, encabezado ("VINILO" y el lema), el cuerpo,
 * "¿Todavía no tienes Vinilo?" y el pie. `toneSrc` es la imagen de la que
 * el navegador saca el color de la franja y el tono (`--tone`); sin ella,
 * el énfasis.
 */
function page({ t, lang, title, description, image, path, accent = DEFAULT_ACCENT, toneSrc, body, stripe = true, cta = true, footerLine = false }) {
  const url = `${SITE}${path}`;
  return `<!doctype html>${render(html`<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${title} · Vinilo</title>
<meta name="description" content="${description}">
<meta name="robots" content="noindex">
<meta name="theme-color" content="#0f0e0d">
<meta property="og:site_name" content="Vinilo">
<meta property="og:type" content="website">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${description}">
<meta property="og:url" content="${url}">
${safeUrl(image) ? html`<meta property="og:image" content="${safeUrl(image)}">` : ""}
<meta name="twitter:card" content="summary">
<link rel="canonical" href="${url}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="${new Raw(FONTS)}" rel="stylesheet">
<style>${new Raw(CSS)}</style>
</head>
<body style="--accent:${accent};--tone:${accent};--stripe:${accent}"${safeUrl(toneSrc) ? html` data-tone-src="${safeUrl(toneSrc)}"` : ""}>
<div class="page">
  ${stripe ? html`<div class="stripe"></div>` : ""}
  <header class="top"><a class="brand" href="/">Vinilo</a><span class="mono">${t.tagline}</span></header>
  <main>${body}</main>
  ${cta ? html`<aside class="cta">
    <div><h3>${t.ctaTitle}</h3><p>${t.ctaBody}</p></div>
    ${ctaButton(t)}
  </aside>` : ""}
  <footer class="mono${footerLine ? " line" : ""}">${t.credits}</footer>
</div>
${safeUrl(toneSrc) ? html`<script>${new Raw(TONE_SCRIPT)}</script>` : ""}
</body>
</html>`)}`;
}

/** Colores planos de las portadas del 404 si no hay portadas reales. */
const FALLBACK_COVERS = ["oklch(0.62 0.21 38)", "oklch(0.42 0.14 255)", "oklch(0.52 0.13 150)"];

/** "Error 404 · lado C": el título grande y "Ir al inicio"; al lado, tres
 * portadas y la invitación. */
function notFoundPage(t, lang, path, covers = []) {
  return page({
    t,
    lang,
    title: t.notFoundTitle,
    description: t.tagline,
    path,
    stripe: false,
    cta: false,
    footerLine: true,
    body: html`<section class="nf">
      <div>
        <p class="mono accent">${t.error404}</p>
        <h1 class="title nf-title">${t.notFoundTitle}</h1>
        <p class="desc">${t.notFoundBody}</p>
        <a class="btn-ink" href="/">${t.home} <span>→</span></a>
      </div>
      <aside class="nf-side">
        <div class="grid3 tight">${[0, 1, 2].map((i) => (safeUrl(covers[i])
          ? html`<img class="art" src="${safeUrl(covers[i])}" alt="" loading="lazy">`
          : html`<span class="art" style="background:${FALLBACK_COVERS[i]}"></span>`))}</div>
        <h3>${t.ctaTitle}</h3>
        <p>${t.ctaBody}</p>
        ${ctaButton(t)}
      </aside>
    </section>`,
  });
}

// ---------------------------------------------------------------------------
// Datos
// ---------------------------------------------------------------------------

const ID = /^[A-Za-z0-9_-]{1,128}$/;
/** Los ids de Spotify: 22 letras y números. Con otra forma, ni se pregunta. */
const SPOTIFY_ID = /^[A-Za-z0-9]{22}$/;
const USERNAME = /^[a-z0-9._]{3,20}$/;

function statsFrom(d) {
  if (!d) return null;
  return { count: Number(d.ratingsCount) || 0, sum: Number(d.ratingsSum) || 0, hist: d.hist || {} };
}

function entryFrom(doc) {
  const d = doc.data() || {};
  return {
    id: doc.id,
    uid: d.uid,
    score: Number(d.score) || 0,
    note: String(d.note || ""),
    album: d.album || {},
    user: d.user || {},
    likes: Array.isArray(d.likedBy) ? d.likedBy.length : 0,
    replies: Number(d.repliesCount) || 0,
    updatedAt: d.updatedAt?.toMillis?.() || 0,
  };
}

/** Los comentarios de un disco: con texto, más "me gusta" primero. */
async function topComments(db, albumId, limit = 6) {
  const snap = await db.collection("ratings").where("albumId", "==", albumId).limit(80).get();
  return snap.docs
    .map(entryFrom)
    .filter((e) => e.note.trim())
    .sort((a, b) => b.likes - a.likes || b.updatedAt - a.updatedAt)
    .slice(0, limit);
}

/** El nombre enlazado a su perfil si se sabe su @usuario. */
function personLink(name, username) {
  return username && USERNAME.test(username)
    ? html`<a href="/u/${username}"><strong>${name}</strong></a>`
    : html`<strong>${name}</strong>`;
}

// ---------------------------------------------------------------------------
// Páginas
// ---------------------------------------------------------------------------

async function listPage(db, id, t, lang) {
  const snap = await db.collection("lists").doc(id).get();
  if (!snap.exists) return null;
  const d = snap.data();
  const owner = d.owner || {};
  const accent = nearestAccent(argbToHex(owner.color));
  const items = Array.isArray(d.items) ? d.items : [];
  const ranking = d.kind === "ranking";
  const tracks = d.itemType === "tracks";
  const count = tracks ? t.tracks(items.length) : t.albums(items.length);
  const first = items[0] || {};
  const cover = safeUrl(d.coverUrl) || safeUrl(first.cover || first.coverSmall);
  const toneSrc = safeUrl(d.coverUrl) || safeUrl(first.coverSmall || first.cover);
  const shown = items.slice(0, 100);
  const username = USERNAME.test(owner.username || "") ? owner.username : null;
  const likes = Array.isArray(d.likedBy) ? d.likedBy.length : 0;
  return page({
    t,
    lang,
    title: d.name || t.list,
    description: ranking ? t.descRanking(owner.name || "", count) : t.descList(owner.name || "", count),
    image: cover,
    path: `/l/${id}`,
    accent,
    toneSrc,
    body: html`<section class="hero">
      ${cover ? html`<img class="art" src="${cover}" alt="">` : html`<div class="art"></div>`}
      <div class="col">
        <p class="mono">${ranking ? t.ranking : t.list} · ${count}</p>
        <h1 class="title">${d.name}</h1>
        ${d.description ? html`<p class="desc">${d.description}</p>` : ""}
        <p class="owner">${avatar(owner, 28)}${personLink(owner.name || "", username)}${username ? html`<span class="mono">@${username}</span>` : ""}</p>
        ${likes ? html`<p class="mono foot">${t.likes(likes)}</p>` : ""}
      </div>
    </section>
    <section class="block">
      ${blockHead(tracks ? t.songsHead : t.albumsHead, items.length)}
      ${shown.map((item, i) => {
        const meta = tracks && item.durationMs
          ? `${Math.floor(item.durationMs / 60000)}:${String(Math.floor((item.durationMs % 60000) / 1000)).padStart(2, "0")}`
          : item.year || "";
        const place = i + 1;
        return ranking
          ? html`<div class="rank${place === 1 ? " first" : ""}">
            <span data-rank="${place <= 3 ? place : "n"}" class="num">${place}</span>
            <div class="grow"><p class="rank-title">${item.name}</p><p class="sub">${item.artist}</p></div>
            <span class="mono">${meta}</span>
          </div>`
          : html`<div class="item">
            <img src="${safeUrl(item.coverSmall || item.cover)}" alt="" loading="lazy">
            <div class="grow"><p class="item-title">${item.name}</p><p class="sub">${item.artist}</p></div>
            <span class="mono">${meta}</span>
          </div>`;
      })}
      ${items.length > shown.length ? html`<p class="mono more">${t.more(items.length - shown.length)}</p>` : ""}
    </section>`,
  });
}

async function albumPage(db, id, t, lang, deps) {
  const snap = await db.collection("albums").doc(id).get();
  let album = snap.exists ? snap.data() : null;
  const stats = statsFrom(album);
  if (!album) {
    if (!SPOTIFY_ID.test(id)) return null;
    try {
      album = await deps.getAlbumDetail(id);
    } catch (err) {
      if (err.status === 400 || err.status === 404) return null;
      throw err;
    }
  }
  const comments = stats && stats.count ? await topComments(db, id) : [];
  const cover = safeUrl(album.cover || album.coverSmall);
  const average = stats && stats.count ? formatAverage(stats.sum / stats.count, t) : null;
  const artistId = Array.isArray(album.artistIds) ? album.artistIds[0] : null;
  const artist = album.artist || "";
  return page({
    t,
    lang,
    title: album.name,
    description: t.descAlbum(artist, average, stats ? t.ratings(stats.count) : ""),
    image: cover,
    path: `/d/${id}`,
    toneSrc: safeUrl(album.coverSmall || album.cover),
    body: html`<section class="hero">
      ${cover ? html`<img class="art" src="${cover}" alt="">` : html`<div class="art"></div>`}
      <div class="col">
        <p class="mono">${albumMeta(album, t)}</p>
        <h1 class="title">${album.name}</h1>
        ${artistId && ID.test(artistId) ? html`<a class="byline" href="/a/${artistId}">${artist}</a>` : html`<p class="byline">${artist}</p>`}
        <div class="score">${communityBlock(stats, t)}</div>
      </div>
    </section>
    ${comments.length ? html`<section class="block">
      ${blockHead(t.comments, comments.length)}
      ${comments.map(commentRow)}
    </section>` : ""}`,
  });
}

async function ratingPage(db, id, t, lang) {
  const snap = await db.collection("ratings").doc(id).get();
  if (!snap.exists) return null;
  const entry = entryFrom(snap);
  const album = entry.album || {};
  const [profileSnap, albumSnap, repliesSnap] = await Promise.all([
    entry.uid ? db.collection("users").doc(entry.uid).get() : null,
    album.id ? db.collection("albums").doc(album.id).get() : null,
    snap.ref.collection("replies").orderBy("createdAt").limit(20).get(),
  ]);
  const username = profileSnap?.exists ? profileSnap.get("username") : null;
  const accent = nearestAccent(argbToHex(entry.user.color));
  const stats = statsFrom(albumSnap?.exists ? albumSnap.data() : null);
  const cover = safeUrl(album.cover || album.coverSmall);
  const replies = repliesSnap.docs.map((r) => r.data());
  const facts = [entry.likes ? t.likes(entry.likes) : null, entry.replies ? t.replyCount(entry.replies) : null].filter(Boolean);
  return page({
    t,
    lang,
    title: t.titleRating(entry.user.name || "", entry.score, album.name || ""),
    description: entry.note || `${album.name || ""} · ${album.artist || ""}`,
    image: cover,
    path: `/n/${id}`,
    accent,
    toneSrc: safeUrl(album.coverSmall || album.cover),
    body: html`<section class="hero">
      ${cover && album.id && ID.test(album.id) ? html`<a href="/d/${album.id}"><img class="art" src="${cover}" alt=""></a>` : html`<div class="art"></div>`}
      <div class="col">
        <p class="owner">${avatar(entry.user, 28)}${personLink(entry.user.name || "", username)}<span class="dim">${t.rated}</span></p>
        <h1 class="title">${album.name}</h1>
        <p class="byline">${album.artist}</p>
        <div class="score">
          <div class="score-row">
            <span class="big">${entry.score}<span class="out"> /10</span></span>
            <span class="mono tone">${t.scoreLabels[entry.score - 1] || ""}</span>
          </div>
          ${entry.note ? html`<p class="quote big-quote">“${entry.note}”</p>` : ""}
          ${facts.length ? html`<p class="mono foot">${facts.join(" · ")}</p>` : ""}
        </div>
      </div>
    </section>
    ${replies.length ? html`<section class="block">
      ${blockHead(t.replies, replies.length)}
      ${replies.map((r) => html`<div class="reply">
        <p class="name">${r.user?.name || ""}${r.user?.username ? html` <span class="mono">@${r.user.username}</span>` : ""}</p>
        <p class="reply-text">${r.text}</p>
      </div>`)}
    </section>` : ""}
    ${stats && stats.count ? html`<section class="block">
      ${blockHead(t.community, null)}
      <div class="community">${communityBlock(stats, t)}</div>
    </section>` : ""}`,
  });
}

async function artistPage(db, id, t, lang, deps) {
  if (!SPOTIFY_ID.test(id)) return null;
  let artist;
  try {
    artist = await deps.getArtist(id);
  } catch (err) {
    if (err.status === 400 || err.status === 404) return null;
    throw err;
  }
  const snap = await db.collection("albums").where("artistIds", "array-contains", id).get();
  const albums = snap.docs
    .map((doc) => ({ ...doc.data(), stats: statsFrom(doc.data()) }))
    .filter((a) => a.stats.count > 0)
    .sort((a, b) => b.stats.sum / b.stats.count - a.stats.sum / a.stats.count);
  const count = albums.reduce((n, a) => n + a.stats.count, 0);
  const sum = albums.reduce((n, a) => n + a.stats.sum, 0);
  const hist = {};
  for (const a of albums) {
    for (let i = 1; i <= 10; i++) hist[i] = (hist[i] || 0) + (Number(a.stats.hist?.[String(i)]) || 0);
  }
  const image = safeUrl(artist.image);
  return page({
    t,
    lang,
    title: artist.name,
    description: t.descArtist(t.albums(albums.length)),
    image,
    path: `/a/${id}`,
    body: html`<section class="hero round">
      ${image ? html`<img class="art circle" src="${image}" alt="">` : html`<div class="art circle"></div>`}
      <div class="col">
        <p class="mono">${t.artistRated(albums.length)}</p>
        <h1 class="title xl">${artist.name}</h1>
        <div class="score split">
          ${count
            ? html`<div><span class="big">${formatAverage(sum / count, t)}<span class="out"> /10</span></span><p class="mono gap">${t.ratings(count)}</p></div>
              <div>${histogram(hist, 80)}</div>`
            : html`<p class="desc">${t.notRatedYet}</p>`}
        </div>
      </div>
    </section>
    ${albums.length ? html`<section class="block">
      ${blockHead(t.ratedInVinilo, albums.length)}
      ${albums.map((a) => html`<a class="row" href="/d/${a.id}">
        <img src="${safeUrl(a.coverSmall || a.cover)}" alt="" loading="lazy">
        <div class="grow">
          <p class="row-title">${a.name}</p>
          <p class="mono">${[a.year, t.ratings(a.stats.count)].filter(Boolean).join(" · ")}</p>
        </div>
        <span class="row-score">${formatAverage(a.stats.sum / a.stats.count, t)}</span>
      </a>`)}
    </section>` : ""}`,
  });
}

async function profilePage(db, handle, t, lang) {
  let uid = null;
  if (USERNAME.test(handle)) {
    const reserved = await db.collection("usernames").doc(handle).get();
    if (reserved.exists) uid = reserved.get("uid");
  }
  if (!uid && ID.test(handle)) uid = handle;
  if (!uid) return null;
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return null;
  const d = snap.data();
  const accent = nearestAccent(argbToHex(d.color));
  const [recentSnap, listsSnap] = await Promise.all([
    db.collection("ratings").where("uid", "==", uid).orderBy("updatedAt", "desc").limit(9).get()
      .catch(() => db.collection("ratings").where("uid", "==", uid).limit(9).get()),
    db.collection("lists").where("ownerUid", "==", uid).limit(30).get(),
  ]);
  const recent = recentSnap.docs.map(entryFrom);
  const lists = listsSnap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((a, b) => (b.updatedAt?.toMillis?.() || 0) - (a.updatedAt?.toMillis?.() || 0))
    .slice(0, 6);
  const favorites = (Array.isArray(d.favorites) ? d.favorites : []).slice(0, 3);
  const artists = (Array.isArray(d.favoriteArtists) ? d.favoriteArtists : []).slice(0, 3);
  const ratingsCount = Number(d.ratingsCount) || 0;
  const average = ratingsCount ? formatAverage((Number(d.ratingsSum) || 0) / ratingsCount, t) : "—";
  const followers = Number(d.followersCount) || 0;
  const following = Number(d.followingCount) || 0;
  const banner = safeUrl(d.bannerUrl);
  const photo = safeUrl(d.avatarUrl);
  const username = USERNAME.test(d.username || "") ? d.username : null;
  const initial = (String(d.name || "?").trim()[0] || "?").toUpperCase();
  const stat = (value, label) => html`<div><p class="stat">${value}</p><p class="mono">${label}</p></div>`;
  return page({
    t,
    lang,
    title: username ? `${d.name} (@${username})` : d.name,
    description: d.bio || t.descProfile(d.name || ""),
    image: photo || banner,
    path: `/u/${username || handle}`,
    accent,
    body: html`${banner ? html`<div class="banner" style="background-image:url('${cssUrl(banner)}')"></div>` : ""}
    <section class="hero round">
      ${photo
        ? html`<img class="art circle" src="${photo}" alt="">`
        : html`<div class="art circle initial" style="background:${personTone(argbToHex(d.color))}">${initial}</div>`}
      <div class="col">
        ${username ? html`<p class="mono">@${username}</p>` : ""}
        <h1 class="title xl">${d.name}</h1>
        ${d.bio ? html`<p class="desc">${d.bio}</p>` : ""}
        <div class="stats">
          ${stat(ratingsCount, t.statAlbums(ratingsCount))}
          ${stat(average, t.statAverage)}
          ${stat(followers, t.followers(followers))}
          ${stat(following, t.following(following))}
        </div>
      </div>
    </section>
    ${favorites.length ? html`<section class="block">
      ${blockHead(t.favorites, null)}
      <div class="grid3 tight fav">${favorites.map((a) => html`<a href="/d/${a.id}"><img class="art" src="${safeUrl(a.cover || a.coverSmall)}" alt="${a.name}" loading="lazy"></a>`)}</div>
    </section>` : ""}
    ${artists.length ? html`<section class="block">
      ${blockHead(t.favoriteArtists, null)}
      <div class="grid3 fav">${artists.map((a) => html`<a class="artist" href="/a/${a.id}"><img class="art circle" src="${safeUrl(a.image || a.imageSmall)}" alt="" loading="lazy"><span class="name">${a.name}</span></a>`)}</div>
    </section>` : ""}
    ${recent.length ? html`<section class="block">
      ${blockHead(t.recent, recent.length)}
      ${recent.map((e) => html`<a class="row" href="/n/${e.id}">
        <img src="${safeUrl(e.album.coverSmall || e.album.cover)}" alt="" loading="lazy">
        <div class="grow">
          <p class="row-title">${e.album.name || ""}</p>
          <p class="mono">${e.album.artist || ""}</p>
        </div>
        <span class="row-score">${e.score}</span>
      </a>`)}
    </section>` : ""}
    ${lists.length ? html`<section class="block">
      ${blockHead(t.lists, lists.length)}
      ${lists.map((l) => {
        const items = Array.isArray(l.items) ? l.items : [];
        const cover = safeUrl(l.coverUrl) || safeUrl(items[0]?.coverSmall || items[0]?.cover);
        const count = l.itemType === "tracks" ? t.tracks(items.length) : t.albums(items.length);
        return html`<a class="row" href="/l/${l.id}">
          ${cover ? html`<img src="${cover}" alt="" loading="lazy">` : html`<span class="ph"></span>`}
          <div class="grow">
            <p class="row-title">${l.name}</p>
            <p class="mono">${l.kind === "ranking" ? t.ranking : t.list} · ${count}</p>
          </div>
          <span class="arrow">→</span>
        </a>`;
      })}
    </section>` : ""}`,
  });
}

// ---------------------------------------------------------------------------
// Estilo y color de portada
// ---------------------------------------------------------------------------

const FONTS = "https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,300..900&family=IBM+Plex+Mono:wght@400;500&family=Newsreader:ital,opsz,wght@1,6..72,400&display=swap";

const CSS = `
:root{--bg:#0f0e0d;--surface:#2a2826;--ink:#efebe4;--ink2:rgba(239,235,228,.62);--ink3:rgba(239,235,228,.58);--ink4:rgba(239,235,228,.5);--line:rgba(239,235,228,.14);--line-soft:rgba(239,235,228,.08);--line-strong:rgba(239,235,228,.28);--sans:'Archivo',system-ui,-apple-system,sans-serif;--mono:'IBM Plex Mono',ui-monospace,Menlo,monospace;--serif:'Newsreader',Georgia,serif}
*{box-sizing:border-box;margin:0;padding:0}
html{-webkit-text-size-adjust:100%}
body{background:var(--bg);color:var(--ink);font-family:var(--sans);font-size:15px;line-height:1.45;-webkit-font-smoothing:antialiased;overflow-x:hidden}
a{color:inherit;text-decoration:none}
img{display:block}
.page{max-width:1200px;margin:0 auto;min-height:100vh;display:flex;flex-direction:column}
main{flex:1}
.stripe{height:6px;background:var(--stripe)}
.top{display:flex;justify-content:space-between;align-items:center;gap:16px;padding:22px 48px;border-bottom:1px solid var(--line)}
.brand{font-stretch:62%;font-weight:900;font-size:32px;line-height:1;text-transform:uppercase}
.mono{font-family:var(--mono);font-weight:500;font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--ink3)}
.mono.accent{color:var(--accent)}
.mono.tone{color:var(--tone)}
.mono.gap{margin-top:10px}
.mono.foot{margin-top:14px}
.dim{color:var(--ink3)}
.hero{display:grid;grid-template-columns:520px minmax(0,1fr);gap:56px;padding:48px}
.hero.round{grid-template-columns:400px minmax(0,1fr);gap:64px;padding:56px 48px;align-items:center}
.art{display:block;width:100%;aspect-ratio:1;object-fit:cover;background:var(--surface)}
.art.circle{border-radius:50%}
.art.initial{display:flex;align-items:center;justify-content:center;font-weight:600;font-size:140px;color:var(--ink)}
.col{display:flex;flex-direction:column;min-width:0}
.title{font-stretch:62%;font-weight:800;font-size:120px;line-height:.84;letter-spacing:-.015em;margin-top:14px;overflow-wrap:anywhere}
.title.xl{font-size:128px}
.byline{display:block;font-weight:500;font-size:22px;color:var(--tone);margin-top:12px}
a.byline:hover{text-decoration:underline;text-underline-offset:4px}
.desc{font-size:19px;color:var(--ink2);margin-top:20px;white-space:pre-line;overflow-wrap:anywhere}
.owner{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-top:18px;font-size:15px}
.owner .mono{margin-left:4px}
.avatar{width:var(--size);height:var(--size);border-radius:50%;object-fit:cover;flex:none;display:inline-flex;align-items:center;justify-content:center;font-weight:600;font-size:calc(var(--size)*.42);color:var(--ink);background:var(--c)}
.score{margin-top:auto;border-top:1px solid var(--line);padding-top:14px}
.score.split{margin-top:36px;display:grid;grid-template-columns:auto minmax(0,1fr);gap:40px;align-items:end}
.score-row{display:flex;justify-content:space-between;align-items:flex-end;gap:24px}
.big{font-stretch:62%;font-weight:700;font-size:112px;line-height:.8;color:var(--tone)}
.big.dim{color:rgba(239,235,228,.28)}
.out{font-stretch:100%;font-weight:500;font-size:18px;color:var(--ink4)}
.hist{display:grid;grid-template-columns:repeat(10,1fr);align-items:end;margin-top:18px;border-bottom:1px solid var(--line)}
.score.split .hist{margin-top:0}
.hist span{margin:0 3px;background:var(--tone)}
.hist span.low{opacity:.6}
.hist span.none{height:2px;background:rgba(239,235,228,.2)}
.nums{display:grid;grid-template-columns:repeat(10,1fr);margin-top:8px;font:500 11px var(--mono);color:var(--ink4);text-align:center}
.block{padding:0 48px}
.block+.block{margin-top:24px}
.block-head{display:flex;justify-content:space-between;padding:12px 0;border-top:1px solid var(--line)}
.comment{display:grid;grid-template-columns:120px 200px minmax(0,1fr);gap:24px;align-items:baseline;padding:22px 0;border-top:1px solid var(--line-soft)}
.num-big{font-stretch:62%;font-weight:700;font-size:64px;line-height:.8;color:var(--tone)}
.name{font-weight:600;font-size:16px}
.name .mono{margin-left:6px}
.quote{font-family:var(--serif);font-style:italic;font-size:28px;line-height:1.2;overflow-wrap:anywhere}
.big-quote{font-size:34px;margin-top:22px}
.reply{display:grid;grid-template-columns:200px minmax(0,1fr);gap:24px;align-items:baseline;padding:18px 0;border-top:1px solid var(--line-soft)}
.reply-text{font-size:19px;white-space:pre-line;overflow-wrap:anywhere}
.community{padding:8px 0 4px;max-width:640px}
.item,.rank{display:grid;grid-template-columns:64px minmax(0,1fr) auto;gap:20px;align-items:center;padding:14px 0;border-top:1px solid var(--line-soft)}
.item img{width:64px;height:64px;object-fit:cover;background:var(--surface)}
.item-title{font-weight:600;font-size:19px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sub{font-size:15px;color:var(--ink3);margin-top:2px}
.rank{grid-template-columns:120px minmax(0,1fr) auto}
.num{font-stretch:62%;font-weight:700;font-size:44px;line-height:.8;color:var(--ink4)}
.num[data-rank="1"]{font-weight:800;font-size:96px;color:var(--tone)}
.num[data-rank="2"],.num[data-rank="3"]{font-size:64px;color:var(--tone)}
.rank-title{font-weight:600;font-size:19px;overflow-wrap:anywhere}
.rank.first .rank-title{font-stretch:75%;font-weight:700;font-size:36px;line-height:1}
.more{padding:14px 0}
.row{display:grid;grid-template-columns:88px minmax(0,1fr) auto;gap:24px;align-items:center;padding:16px 0;border-top:1px solid var(--line-soft)}
.row img,.row .ph{width:88px;height:88px;object-fit:cover;background:var(--surface)}
.row-title{font-stretch:75%;font-weight:700;font-size:32px;line-height:1;overflow-wrap:anywhere}
.row .mono{margin-top:8px}
.row-score{font-stretch:62%;font-weight:700;font-size:72px;line-height:.8;color:var(--accent)}
.arrow{font-size:22px;color:var(--ink4)}
a.row:hover .row-title,a.item:hover .item-title{text-decoration:underline;text-underline-offset:4px}
.banner{height:260px;background-size:cover;background-position:center}
.stats{display:grid;grid-template-columns:repeat(4,1fr);margin-top:32px;border-top:1px solid var(--line);border-bottom:1px solid var(--line)}
.stats>div{padding:12px 0 12px 14px;border-left:1px solid var(--line)}
.stats>div:first-child{padding-left:0;border-left:0}
.stat{font-stretch:65%;font-weight:700;font-size:44px;line-height:1}
.stats .mono{margin-top:6px;font-size:10px}
.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;padding:12px 0 8px}
.grid3.tight{gap:2px}
.fav{max-width:720px}
.artist{text-align:center}
.artist .name{display:block;margin-top:12px}
.cta{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:32px;align-items:center;margin:40px 48px 0;padding:32px 0;border-top:1px solid var(--line-strong)}
.cta h3,.nf-side h3{font-stretch:70%;font-weight:700;font-size:40px;line-height:1}
.cta p{font-size:16px;color:var(--ink2);margin-top:8px}
.btn-line{display:inline-flex;align-items:center;height:56px;padding:0 24px;border:1px solid var(--line-strong);font-weight:500;font-size:15px;color:rgba(239,235,228,.75);white-space:nowrap}
a.btn-line:hover{border-color:var(--ink);color:var(--ink)}
.btn-ink{display:inline-flex;gap:10px;align-items:center;height:52px;padding:0 22px;margin-top:28px;background:var(--ink);color:var(--bg);font-weight:600;font-size:15px}
.btn-ink:hover{background:var(--accent)}
footer{padding:20px 48px 28px}
footer.line{padding:18px 48px;border-top:1px solid var(--line)}
.nf{display:grid;grid-template-columns:minmax(0,1fr) 380px;gap:56px;padding:48px;min-height:560px}
.nf-title{font-size:132px;margin-top:16px}
.nf-side{border-left:1px solid var(--line);padding-left:32px;display:flex;flex-direction:column;justify-content:flex-end}
.nf-side .grid3{margin-bottom:24px;padding:0}
.nf-side h3{font-size:32px}
.nf-side p{font-size:15px;line-height:1.45;color:var(--ink2);margin-top:10px}
.nf-side .btn-line{height:52px;margin-top:20px;padding:0 18px}
@media (max-width:819px){
.top{padding:16px 20px}
.brand{font-size:26px}
.top .mono{font-size:9.5px;text-align:right}
.hero,.hero.round{grid-template-columns:minmax(0,1fr);gap:24px;padding:20px 20px 32px}
.hero.round .art{max-width:280px}
.title{font-size:clamp(52px,16vw,96px)}
.title.xl{font-size:clamp(56px,17vw,104px)}
.byline{font-size:19px}
.desc{font-size:16px;margin-top:14px}
.score{margin-top:28px}
.score.split{grid-template-columns:minmax(0,1fr);gap:20px;margin-top:28px}
.big{font-size:84px}
.block{padding:0 20px}
.comment{grid-template-columns:64px minmax(0,1fr);gap:6px 16px;padding:18px 0}
.comment .num-big{grid-row:span 2;font-size:48px}
.quote{font-size:21px}
.big-quote{font-size:24px}
.reply{grid-template-columns:minmax(0,1fr);gap:4px}
.reply-text{font-size:16px}
.item,.rank{gap:14px}
.item{grid-template-columns:48px minmax(0,1fr) auto}
.item img{width:48px;height:48px}
.item-title,.rank-title{font-size:16px}
.rank{grid-template-columns:56px minmax(0,1fr) auto}
.num{font-size:28px}
.num[data-rank="1"]{font-size:60px}
.num[data-rank="2"],.num[data-rank="3"]{font-size:40px}
.rank.first .rank-title{font-size:24px}
.row{grid-template-columns:64px minmax(0,1fr) auto;gap:14px}
.row img,.row .ph{width:64px;height:64px}
.row-title{font-size:22px}
.row-score{font-size:44px}
.banner{height:160px}
.stats{margin-top:24px}
.stat{font-size:28px}
.stats .mono{font-size:9px}
.grid3{gap:12px}
.cta{grid-template-columns:minmax(0,1fr);gap:20px;margin:32px 20px 0;padding:28px 0}
.cta h3{font-size:32px}
footer,footer.line{padding:20px}
.nf{grid-template-columns:minmax(0,1fr);gap:40px;padding:28px 20px;min-height:0}
.nf-title{font-size:clamp(60px,18vw,110px)}
.nf-side{border-left:0;padding-left:0;border-top:1px solid var(--line);padding-top:28px}
}
`;

// El color de la portada, como la app: el dominante (24 tonalidades más un
// grupo para los grises, con más peso a lo saturado) va a la franja, y su
// tono claro (la misma tonalidad con luminosidad 0,76–0,86, `coverTone`) a
// la nota, el artista y el histograma. Si la imagen no deja leerse (CORS),
// queda el énfasis.
const TONE_SCRIPT = `(function(){var src=document.body.getAttribute('data-tone-src');if(!src)return;var img=new Image();img.crossOrigin='anonymous';img.onload=function(){try{var S=48,cv=document.createElement('canvas');cv.width=cv.height=S;var x=cv.getContext('2d');x.drawImage(img,0,0,S,S);var d=x.getImageData(0,0,S,S).data,B=25,w=[],R=[],G=[],Bl=[];for(var k=0;k<B;k++){w[k]=0;R[k]=0;G[k]=0;Bl[k]=0;}for(var i=0;i<d.length;i+=4){var r=d[i]/255,g=d[i+1]/255,b=d[i+2]/255,mx=Math.max(r,g,b),mn=Math.min(r,g,b),l=(mx+mn)/2,s=mx===mn?0:(l>.5?(mx-mn)/(2-mx-mn):(mx-mn)/(mx+mn));if(l<.08||l>.94)continue;var h=0;if(mx!==mn){if(mx===r)h=((g-b)/(mx-mn)+(g<b?6:0))*60;else if(mx===g)h=((b-r)/(mx-mn)+2)*60;else h=((r-g)/(mx-mn)+4)*60;}var gray=s<.12,wt=.12+(gray?0:s*(1-Math.abs(l-.5))),k2=gray?24:Math.floor(h/360*24)%24;w[k2]+=wt;R[k2]+=d[i]*wt;G[k2]+=d[i+1]*wt;Bl[k2]+=d[i+2]*wt;}var best=-1,bw=0;for(k=0;k<B;k++)if(w[k]>bw){bw=w[k];best=k;}if(best<0)return;var cr=R[best]/bw,cg=G[best]/bw,cb=Bl[best]/bw;function lin(v){v/=255;return v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4);}var lr=lin(cr),lg=lin(cg),lb=lin(cb),L1=Math.cbrt(.4122214708*lr+.5363325363*lg+.0514459929*lb),M1=Math.cbrt(.2119034982*lr+.6806995451*lg+.1073969566*lb),S1=Math.cbrt(.0883024619*lr+.2817188376*lg+.6299787005*lb),L=.2104542553*L1+.793617785*M1-.0040720468*S1,A=1.9779984951*L1-2.428592205*M1+.4505937099*S1,Bb=.0259040371*L1+.7827717662*M1-.808675766*S1,C=Math.sqrt(A*A+Bb*Bb),H=Math.atan2(Bb,A)*180/Math.PI;if(H<0)H+=360;var tl=Math.min(.86,Math.max(.76,L)),tc=C<.02?C*2:Math.min(.15,.6*C+.05);var st=document.body.style;st.setProperty('--stripe','rgb('+Math.round(cr)+','+Math.round(cg)+','+Math.round(cb)+')');st.setProperty('--tone','oklch('+tl.toFixed(3)+' '+tc.toFixed(3)+' '+H.toFixed(1)+')');}catch(e){}};img.src=src;})();`;

// ---------------------------------------------------------------------------
// Manejador
// ---------------------------------------------------------------------------

/**
 * Las 8 portadas más calificadas, para la rejilla de la bienvenida de la
 * app (y las tres del 404). Son datos públicos (la misma portada de
 * Spotify); se salta los discos sin portada o sin notas.
 */
async function welcomeCovers(db) {
  const snap = await db.collection("albums").orderBy("ratingsCount", "desc").limit(24).get();
  const covers = [];
  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const url = safeUrl(d.coverSmall || d.cover);
    if (url && (d.ratingsCount || 0) > 0 && !covers.includes(url)) covers.push(url);
    if (covers.length === 8) break;
  }
  return covers;
}

function sendCovers(res, status, covers) {
  // Igual para todo el mundo y cambia poco: una hora de caché.
  res.set("Cache-Control", "public, max-age=3600");
  res.set("Content-Type", "application/json; charset=utf-8");
  res.set("Access-Control-Allow-Origin", "*");
  res.status(status).send(JSON.stringify({ covers }));
}

function send(res, status, body) {
  // Solo caché del navegador: la página cambia con el idioma de quien la abre.
  res.set("Cache-Control", "private, max-age=300");
  res.set("Content-Type", "text/html; charset=utf-8");
  res.status(status).send(body);
}

/** El 404 con tres portadas reales (o los colores planos si fallan). */
async function sendNotFound(res, status, t, lang, path) {
  let covers = [];
  try {
    covers = (await welcomeCovers(getFirestore())).slice(0, 3);
  } catch (_) {
    covers = [];
  }
  send(res, status, notFoundPage(t, lang, path, covers));
}

/**
 * `deps` trae lo de Spotify desde index.js (`getAlbumDetail`, `getArtist`),
 * para discos y artistas que todavía no están en Firestore.
 */
function createWebHandler(deps) {
  const routes = {
    l: (db, id, t, lang) => (ID.test(id) ? listPage(db, id, t, lang) : null),
    d: (db, id, t, lang) => (ID.test(id) ? albumPage(db, id, t, lang, deps) : null),
    n: (db, id, t, lang) => (ID.test(id) ? ratingPage(db, id, t, lang) : null),
    a: (db, id, t, lang) => (ID.test(id) ? artistPage(db, id, t, lang, deps) : null),
    u: (db, id, t, lang) => profilePage(db, id.toLowerCase(), t, lang),
  };
  return async (req, res) => {
    const lang = pickLang(req);
    const t = STRINGS[lang];
    const path = req.path.replace(/\/+$/, "");
    if (req.method !== "GET" && req.method !== "HEAD") {
      res.status(405).send("");
      return;
    }
    if (path === "/portadas") {
      try {
        sendCovers(res, 200, await welcomeCovers(getFirestore()));
      } catch (err) {
        logger.error("No se pudieron leer las portadas", { message: err.message });
        sendCovers(res, 500, []);
      }
      return;
    }
    const match = path.match(/^\/([ldnau])\/([^/]+)$/);
    try {
      if (!match) {
        await sendNotFound(res, 404, t, lang, path);
        return;
      }
      let id;
      try {
        id = decodeURIComponent(match[2]);
      } catch (_) {
        await sendNotFound(res, 404, t, lang, path);
        return;
      }
      const body = await routes[match[1]](getFirestore(), id, t, lang);
      if (!body) {
        await sendNotFound(res, 404, t, lang, path);
        return;
      }
      send(res, 200, body);
    } catch (err) {
      logger.error("No se pudo armar la página", { path, message: err.message });
      await sendNotFound(res, 500, t, lang, path);
    }
  };
}

module.exports = { createWebHandler, pickLang, esc, nearestAccent, personTone };
