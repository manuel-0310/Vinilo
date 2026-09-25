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
 *
 * El HTML se arma en el servidor con el Admin SDK y solo lleva lo que se
 * comparte (nunca correos ni uids), con etiquetas Open Graph para que
 * WhatsApp o iMessage muestren la tarjeta. Idioma según Accept-Language
 * (o ?lang=es|en). Todo texto que viene de las personas pasa por `esc`.
 */

const { getFirestore } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const SITE = "https://red-social-c786b.web.app";
// URL de la app en el App Store; mientras esté vacía, la página dice
// "Muy pronto en el App Store". Se configura en functions/.env.
const APP_STORE_URL = process.env.APP_STORE_URL || "";
const DEFAULT_ACCENT = "#E8A04B";

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
    ratingLabel: "CALIFICACIÓN",
    ratings: (n) => plural(n, "1 calificación", `${n} calificaciones`),
    noRatings: "Nadie lo ha calificado todavía en Vinilo.",
    comments: "Comentarios",
    replies: "Respuestas",
    tracks: (n) => plural(n, "1 canción", `${n} canciones`),
    albums: (n) => plural(n, "1 disco", `${n} discos`),
    list: "Lista",
    ranking: "Ranking",
    by: (name) => `de ${name}`,
    likes: (n) => plural(n, "1 me gusta", `${n} me gusta`),
    replyCount: (n) => plural(n, "1 respuesta", `${n} respuestas`),
    rated: "calificó",
    community: "Promedio de la comunidad",
    followers: (n) => plural(n, "seguidor", "seguidores"),
    following: (n) => plural(n, "seguido", "seguidos"),
    ratingsWord: (n) => plural(n, "nota", "notas"),
    averageWord: "promedio",
    favorites: "Discos favoritos",
    favoriteArtists: "Artistas favoritos",
    recent: "Últimas notas",
    lists: "Listas",
    ratedInVinilo: "Calificados en Vinilo",
    notRatedYet: "Todavía nadie ha calificado sus discos en Vinilo.",
    more: (n) => `y ${n} más`,
    notFoundTitle: "No encontramos esto",
    notFoundBody: "Puede que lo hayan borrado o que el enlace esté incompleto.",
    home: "Ir al inicio",
    credits: "Datos de discos y artistas: Spotify.",
    scoreLabels: ["Insufrible", "Malo", "Flojo", "Meh", "Regular", "Está bien", "Bueno", "Muy bueno", "Excelente", "Obra maestra"],
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
    ratingLabel: "RATING",
    ratings: (n) => plural(n, "1 rating", `${n} ratings`),
    noRatings: "No one has rated it on Vinilo yet.",
    comments: "Comments",
    replies: "Replies",
    tracks: (n) => plural(n, "1 song", `${n} songs`),
    albums: (n) => plural(n, "1 album", `${n} albums`),
    list: "List",
    ranking: "Ranking",
    by: (name) => `by ${name}`,
    likes: (n) => plural(n, "1 like", `${n} likes`),
    replyCount: (n) => plural(n, "1 reply", `${n} replies`),
    rated: "rated",
    community: "Community average",
    followers: (n) => plural(n, "follower", "followers"),
    following: () => "following",
    ratingsWord: (n) => plural(n, "rating", "ratings"),
    averageWord: "average",
    favorites: "Favorite albums",
    favoriteArtists: "Favorite artists",
    recent: "Latest ratings",
    lists: "Lists",
    ratedInVinilo: "Rated on Vinilo",
    notRatedYet: "No one has rated their albums on Vinilo yet.",
    more: (n) => `and ${n} more`,
    notFoundTitle: "We couldn't find this",
    notFoundBody: "It may have been deleted, or the link is incomplete.",
    home: "Go home",
    credits: "Album and artist data: Spotify.",
    scoreLabels: ["Unbearable", "Bad", "Weak", "Meh", "So-so", "Decent", "Good", "Very good", "Excellent", "Masterpiece"],
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
// Color: el mismo énfasis y la misma escala de notas que la app (tema oscuro).
// ---------------------------------------------------------------------------

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const lerp = (a, b, t) => a + (b - a) * t;

function argbToHex(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return DEFAULT_ACCENT;
  return `#${(n & 0xffffff).toString(16).padStart(6, "0")}`;
}

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function hexToHsl(hex) {
  const [r, g, b] = hexToRgb(hex).map((v) => v / 255);
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) * 60;
  else if (max === g) h = ((b - r) / d + 2) * 60;
  else h = ((r - g) / d + 4) * 60;
  return [h, s, l];
}

function hslToHex(h, s, l) {
  const k = (n) => (n + h / 30) % 12;
  const a = s * Math.min(l, 1 - l);
  const f = (n) => l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
  return `#${[f(0), f(8), f(4)]
    .map((v) => Math.round(v * 255).toString(16).padStart(2, "0"))
    .join("")}`;
}

/** `accentFor(seed, Brightness.dark)` de score.dart. */
function accentFor(hex) {
  const [h, s, l] = hexToHsl(hex);
  return hslToHex(h, clamp(s, 0.45, 0.9), clamp(l, 0.58, 0.72));
}

/** `Score.color` sobre fondo oscuro: baja apagada, alta intensa. */
function scoreColor(score, accent) {
  const t = (clamp(Number(score) || 1, 1, 10) - 1) / 9;
  const [h, s, l] = hexToHsl(accent);
  return hslToHex(h, clamp(lerp(0.2, s, t), 0, 1), clamp(lerp(l - 0.15, l + 0.13, t), 0.08, 0.9));
}

function luminance(hex) {
  const [r, g, b] = hexToRgb(hex).map((v) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** Tinta o papel, lo que más contraste con el énfasis (`onAccentFor`). */
function onAccentFor(accent) {
  const ratio = (a, b) => {
    const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
    return (hi + 0.05) / (lo + 0.05);
  };
  return ratio(accent, "#1B1408") >= ratio(accent, "#FBF8F2") ? "#1B1408" : "#FBF8F2";
}

function formatAverage(value, t) {
  return value.toFixed(1).replace(".", t.decimal);
}

// ---------------------------------------------------------------------------
// Piezas
// ---------------------------------------------------------------------------

function avatar(person, size = 34) {
  const color = argbToHex(person.color);
  const url = safeUrl(person.avatarUrl);
  const initial = (String(person.name || "?").trim()[0] || "?").toUpperCase();
  return url
    ? html`<img class="avatar" src="${url}" alt="" width="${size}" height="${size}" style="--size:${size}px">`
    : html`<span class="avatar" style="--size:${size}px;--c:${color}">${initial}</span>`;
}

function histogram(hist, accent) {
  const counts = Array.from({ length: 10 }, (_, i) => Number(hist?.[String(i + 1)]) || 0);
  const max = Math.max(1, ...counts);
  return html`<div class="hist" aria-hidden="true">${counts.map((n, i) => html`<span style="height:${Math.max(4, Math.round((n / max) * 100))}%;--c:${scoreColor(i + 1, accent)}"></span>`)}</div>`;
}

/** Bloque "CALIFICACIÓN 8,4 /10 · N calificaciones" con histograma. */
function communityBlock(stats, t, accent) {
  if (!stats || !stats.count) return html`<p class="muted center">${t.noRatings}</p>`;
  const average = stats.sum / stats.count;
  return html`<div class="card score-card">
    <div>
      <p class="label">${t.ratingLabel}</p>
      <p><span class="big" style="color:${scoreColor(average, accent)}">${formatAverage(average, t)}</span><span class="out">/10</span></p>
      <p class="muted small">${t.ratings(stats.count)}</p>
    </div>
    ${histogram(stats.hist, accent)}
  </div>`;
}

function commentCard(entry, t, accent) {
  return html`<article class="card comment">
    <div class="row">
      ${avatar(entry.user)}
      <p class="grow"><strong>${entry.user.name}</strong></p>
      <span class="numeral" style="color:${scoreColor(entry.score, accent)}">${entry.score}</span>
    </div>
    <p class="quote">${entry.note}</p>
    ${entry.likes ? html`<p class="muted small">${t.likes(entry.likes)}</p>` : ""}
  </article>`;
}

function albumMeta(album, t) {
  return [
    t.types[album.type] || null,
    album.year || null,
    album.totalTracks ? t.tracks(album.totalTracks) : null,
  ].filter(Boolean).join(" · ");
}

function page({ t, lang, title, description, image, path, accent = DEFAULT_ACCENT, glowSrc, body }) {
  const onAccent = onAccentFor(accent);
  const url = `${SITE}${path}`;
  const cta = APP_STORE_URL
    ? html`<a class="btn" href="${APP_STORE_URL}">${t.ctaDownload}</a>`
    : html`<span class="btn soon">${t.ctaSoon}</span>`;
  return `<!doctype html>${render(html`<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${title} · Vinilo</title>
<meta name="description" content="${description}">
<meta name="robots" content="noindex">
<meta name="theme-color" content="#0F0E0C">
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
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Manrope:wght@400..800&display=swap" rel="stylesheet">
<style>${new Raw(CSS)}</style>
</head>
<body style="--accent:${accent};--on-accent:${onAccent};--glow:${accent}">
<div class="glow"></div>
<div class="page">
  <header class="top"><a class="brand" href="/">Vinilo</a><span class="muted small">${t.tagline}</span></header>
  <main>${body}</main>
  <aside class="cta">
    <div class="vinyl small-vinyl" aria-hidden="true"></div>
    <h3>${t.ctaTitle}</h3>
    <p class="muted">${t.ctaBody}</p>
    ${cta}
  </aside>
  <footer>${t.credits}</footer>
</div>
${glowSrc ? html`<img hidden data-glow-src="${safeUrl(glowSrc)}" alt=""><script>${new Raw(GLOW_SCRIPT)}</script>` : ""}
</body>
</html>`)}`;
}

function notFoundPage(t, lang, path) {
  return page({
    t,
    lang,
    title: t.notFoundTitle,
    description: t.tagline,
    path,
    body: html`<section class="hero">
      <div class="vinyl" aria-hidden="true"></div>
      <h1 class="title">${t.notFoundTitle}</h1>
      <p class="muted">${t.notFoundBody}</p>
      <p><a class="link" href="/">${t.home}</a></p>
    </section>`,
  });
}

// ---------------------------------------------------------------------------
// Datos
// ---------------------------------------------------------------------------

const ID = /^[A-Za-z0-9_-]{1,128}$/;
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

// ---------------------------------------------------------------------------
// Páginas
// ---------------------------------------------------------------------------

async function listPage(db, id, t, lang) {
  const snap = await db.collection("lists").doc(id).get();
  if (!snap.exists) return null;
  const d = snap.data();
  const owner = d.owner || {};
  const accent = accentFor(argbToHex(owner.color));
  const items = Array.isArray(d.items) ? d.items : [];
  const ranking = d.kind === "ranking";
  const tracks = d.itemType === "tracks";
  const count = tracks ? t.tracks(items.length) : t.albums(items.length);
  const covers = items.map((i) => safeUrl(i.coverSmall || i.cover)).filter(Boolean);
  const cover = safeUrl(d.coverUrl) || covers[0] || "";
  const shown = items.slice(0, 100);
  const art = safeUrl(d.coverUrl)
    ? html`<img class="cover" src="${safeUrl(d.coverUrl)}" alt="">`
    : html`<div class="cover mosaic">${[0, 1, 2, 3].map((i) => (covers[i] ? html`<img src="${covers[i]}" alt="">` : html`<span></span>`))}</div>`;
  return page({
    t,
    lang,
    title: d.name || t.list,
    description: ranking ? t.descRanking(owner.name || "", count) : t.descList(owner.name || "", count),
    image: cover,
    path: `/l/${id}`,
    accent,
    glowSrc: cover,
    body: html`<section class="hero">
      ${art}
      <p class="label spaced">${ranking ? t.ranking : t.list} · ${count}</p>
      <h1 class="title">${d.name}</h1>
      ${d.description ? html`<p class="desc">${d.description}</p>` : ""}
      <p class="owner">${avatar(owner, 26)}<span>${t.by(owner.name || "")}</span></p>
    </section>
    <section class="section">
      ${shown.map((item, i) => html`<div class="item">
        ${ranking ? html`<span class="num">${i + 1}</span>` : ""}
        <img src="${safeUrl(item.coverSmall || item.cover)}" alt="" loading="lazy">
        <div class="grow">
          <p class="item-title">${item.name}</p>
          <p class="muted small">${tracks && item.albumName ? `${item.artist} · ${item.albumName}` : [item.artist, item.year].filter(Boolean).join(" · ")}</p>
        </div>
      </div>`)}
      ${items.length > shown.length ? html`<p class="muted center small">${t.more(items.length - shown.length)}</p>` : ""}
    </section>`,
  });
}

async function albumPage(db, id, t, lang, deps) {
  const snap = await db.collection("albums").doc(id).get();
  let album = snap.exists ? snap.data() : null;
  const stats = statsFrom(album);
  if (!album) {
    try {
      album = await deps.getAlbumDetail(id);
    } catch (err) {
      if (err.status === 400 || err.status === 404) return null;
      throw err;
    }
  }
  const comments = stats && stats.count ? await topComments(db, id) : [];
  const accent = DEFAULT_ACCENT;
  const cover = safeUrl(album.cover || album.coverSmall);
  const average = stats && stats.count ? formatAverage(stats.sum / stats.count, t) : null;
  return page({
    t,
    lang,
    title: album.name,
    description: t.descAlbum(album.artist || "", average, stats ? t.ratings(stats.count) : ""),
    image: cover,
    path: `/d/${id}`,
    accent,
    glowSrc: safeUrl(album.coverSmall || album.cover),
    body: html`<section class="hero">
      ${cover ? html`<img class="cover" src="${cover}" alt="">` : html`<div class="cover"></div>`}
      <h1 class="title">${album.name}</h1>
      <p class="subtitle">${album.artist}</p>
      <p class="meta">${albumMeta(album, t)}</p>
    </section>
    <section class="section">${communityBlock(stats, t, accent)}</section>
    ${comments.length ? html`<section class="section">
      <h2>${t.comments}</h2>
      ${comments.map((c) => commentCard(c, t, accent))}
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
  const accent = accentFor(argbToHex(entry.user.color));
  const stats = statsFrom(albumSnap?.exists ? albumSnap.data() : null);
  const cover = safeUrl(album.cover || album.coverSmall);
  const replies = repliesSnap.docs.map((r) => r.data());
  const who = username && USERNAME.test(username)
    ? html`<a href="/u/${username}"><strong>${entry.user.name}</strong></a>`
    : html`<strong>${entry.user.name}</strong>`;
  return page({
    t,
    lang,
    title: t.titleRating(entry.user.name || "", entry.score, album.name || ""),
    description: entry.note || `${album.name || ""} · ${album.artist || ""}`,
    image: cover,
    path: `/n/${id}`,
    accent,
    glowSrc: safeUrl(album.coverSmall || album.cover),
    body: html`<section class="hero">
      <p class="owner">${avatar(entry.user, 30)}<span>${who} ${t.rated}</span></p>
      ${cover ? html`<a href="/d/${album.id}"><img class="cover" src="${cover}" alt=""></a>` : ""}
      <h1 class="title">${album.name}</h1>
      <p class="subtitle">${album.artist}</p>
      <p class="rating-line"><span class="huge" style="color:${scoreColor(entry.score, accent)}">${entry.score}</span><span class="out">/10</span></p>
      <p class="label" style="color:${scoreColor(entry.score, accent)}">${t.scoreLabels[entry.score - 1] || ""}</p>
      ${entry.note ? html`<p class="quote big-quote">“${entry.note}”</p>` : ""}
      <p class="muted small">${[entry.likes ? t.likes(entry.likes) : null, entry.replies ? t.replyCount(entry.replies) : null].filter(Boolean).join(" · ")}</p>
    </section>
    ${replies.length ? html`<section class="section">
      <h2>${t.replies}</h2>
      ${replies.map((r) => html`<div class="reply row top-align">
        ${avatar(r.user || {}, 30)}
        <div class="grow">
          <p><strong>${r.user?.name || ""}</strong>${r.user?.username ? html` <span class="muted small">@${r.user.username}</span>` : ""}</p>
          <p class="reply-text">${r.text}</p>
        </div>
      </div>`)}
    </section>` : ""}
    ${stats && stats.count ? html`<section class="section">
      <p class="label spaced">${t.community}</p>
      ${communityBlock(stats, t, DEFAULT_ACCENT)}
    </section>` : ""}`,
  });
}

async function artistPage(db, id, t, lang, deps) {
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
  const accent = DEFAULT_ACCENT;
  const image = safeUrl(artist.image);
  return page({
    t,
    lang,
    title: artist.name,
    description: t.descArtist(t.albums(albums.length)),
    image,
    path: `/a/${id}`,
    accent,
    glowSrc: safeUrl(artist.imageSmall || artist.image),
    body: html`<section class="hero">
      ${image ? html`<img class="cover round" src="${image}" alt="">` : html`<div class="cover round"></div>`}
      <h1 class="title">${artist.name}</h1>
      ${artist.genres?.length ? html`<p class="meta">${artist.genres.slice(0, 3).join(" · ")}</p>` : ""}
    </section>
    <section class="section">${count ? communityBlock({ count, sum, hist }, t, accent) : html`<p class="muted center">${t.notRatedYet}</p>`}</section>
    ${albums.length ? html`<section class="section">
      <h2>${t.ratedInVinilo}</h2>
      ${albums.map((a) => html`<a class="item" href="/d/${a.id}">
        <img src="${safeUrl(a.coverSmall || a.cover)}" alt="" loading="lazy">
        <div class="grow">
          <p class="item-title">${a.name}</p>
          <p class="muted small">${[a.year, t.ratings(a.stats.count)].filter(Boolean).join(" · ")}</p>
        </div>
        <span class="numeral" style="color:${scoreColor(a.stats.sum / a.stats.count, accent)}">${formatAverage(a.stats.sum / a.stats.count, t)}</span>
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
  const accent = accentFor(argbToHex(d.color));
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
  const average = ratingsCount ? formatAverage((Number(d.ratingsSum) || 0) / ratingsCount, t) : null;
  const banner = safeUrl(d.bannerUrl);
  const username = USERNAME.test(d.username || "") ? d.username : null;
  const stat = (n, word) => html`<span><strong>${n}</strong> ${word}</span>`;
  return page({
    t,
    lang,
    title: username ? `${d.name} (@${username})` : d.name,
    description: d.bio || t.descProfile(d.name || ""),
    image: safeUrl(d.avatarUrl) || banner,
    path: `/u/${username || handle}`,
    accent,
    body: html`${banner ? html`<div class="banner" style="background-image:url('${cssUrl(banner)}')"></div>` : ""}
    <section class="profile">
      ${avatar({ name: d.name, color: d.color, avatarUrl: d.avatarUrl }, 88)}
      <h1 class="title">${d.name}</h1>
      ${username ? html`<p class="muted">@${username}</p>` : ""}
      ${d.bio ? html`<p class="desc">${d.bio}</p>` : ""}
      <p class="stats">
        ${stat(ratingsCount, t.ratingsWord(ratingsCount))}
        ${average ? stat(average, t.averageWord) : ""}
        ${stat(Number(d.followersCount) || 0, t.followers(Number(d.followersCount) || 0))}
        ${stat(Number(d.followingCount) || 0, t.following(Number(d.followingCount) || 0))}
      </p>
    </section>
    ${favorites.length ? html`<section class="section">
      <h2>${t.favorites}</h2>
      <div class="grid3">${favorites.map((a) => html`<a href="/d/${a.id}"><img class="tile" src="${safeUrl(a.coverSmall || a.cover)}" alt="${a.name}" loading="lazy"></a>`)}</div>
    </section>` : ""}
    ${artists.length ? html`<section class="section">
      <h2>${t.favoriteArtists}</h2>
      <div class="grid3">${artists.map((a) => html`<a class="artist" href="/a/${a.id}"><img class="tile round" src="${safeUrl(a.image || a.imageSmall)}" alt="" loading="lazy"><span class="small">${a.name}</span></a>`)}</div>
    </section>` : ""}
    ${recent.length ? html`<section class="section">
      <h2>${t.recent}</h2>
      <div class="grid3">${recent.map((e) => html`<a class="recent" href="/n/${e.id}">
        <img class="tile" src="${safeUrl(e.album.coverSmall || e.album.cover)}" alt="${e.album.name || ""}" loading="lazy">
        <span class="badge" style="color:${scoreColor(e.score, accent)}">${e.score}</span>
      </a>`)}</div>
    </section>` : ""}
    ${lists.length ? html`<section class="section">
      <h2>${t.lists}</h2>
      ${lists.map((l) => {
        const items = Array.isArray(l.items) ? l.items : [];
        const cover = safeUrl(l.coverUrl) || safeUrl(items[0]?.coverSmall || items[0]?.cover);
        const count = l.itemType === "tracks" ? t.tracks(items.length) : t.albums(items.length);
        return html`<a class="item" href="/l/${l.id}">
          <img src="${cover}" alt="" loading="lazy">
          <div class="grow">
            <p class="item-title">${l.name}</p>
            <p class="muted small">${l.kind === "ranking" ? t.ranking : t.list} · ${count}</p>
          </div>
        </a>`;
      })}
    </section>` : ""}`,
  });
}

// ---------------------------------------------------------------------------
// Estilo y resplandor
// ---------------------------------------------------------------------------

const CSS = `
:root{--bg:#0F0E0C;--surface:#181613;--surface2:#211E1A;--surface3:#2B2722;--line:rgba(255,255,255,.086);--text:#F4EFE6;--text2:#A9A296;--text3:#6F695F;--serif:'Instrument Serif',Georgia,serif;--sans:'Manrope',system-ui,-apple-system,sans-serif}
*{box-sizing:border-box;margin:0;padding:0}
html{-webkit-text-size-adjust:100%}
body{background:var(--bg);color:var(--text);font-family:var(--sans);font-size:15px;line-height:1.45;min-height:100vh;overflow-x:hidden;position:relative}
a{color:inherit;text-decoration:none}
img{display:block}
.glow{position:absolute;inset:0 0 auto 0;height:560px;background:radial-gradient(70% 60% at 50% 0%,color-mix(in srgb,var(--glow) 34%,transparent),transparent 72%);pointer-events:none;transition:background 1s ease}
.page{position:relative;max-width:560px;margin:0 auto;padding:max(14px,env(safe-area-inset-top)) 16px max(28px,env(safe-area-inset-bottom))}
.top{display:flex;align-items:baseline;justify-content:space-between;gap:12px;padding:6px 0 18px}
.brand{font-family:var(--serif);font-style:italic;font-size:28px;letter-spacing:-.5px}
.muted{color:var(--text2)}
.small{font-size:12.5px}
.center{text-align:center}
.grow{flex:1;min-width:0}
.label{font-size:11px;font-weight:700;letter-spacing:1.4px;color:var(--text3);text-transform:uppercase}
.label.spaced{margin:22px 0 10px}
.hero{text-align:center;padding-top:10px}
.cover{width:min(70vw,300px);aspect-ratio:1;margin:0 auto;border-radius:18px;object-fit:cover;background:var(--surface2);box-shadow:0 26px 60px -20px color-mix(in srgb,var(--glow) 55%,#000)}
.cover.round{border-radius:50%;width:min(52vw,220px)}
.mosaic{display:grid;grid-template-columns:1fr 1fr;overflow:hidden}
.mosaic img,.mosaic span{width:100%;height:100%;object-fit:cover;background:var(--surface3)}
.title{font-family:var(--serif);font-weight:400;font-size:38px;line-height:1.04;letter-spacing:-.5px;margin-top:22px;overflow-wrap:anywhere}
.subtitle{color:var(--accent);font-weight:600;font-size:16px;margin-top:8px}
.meta{color:var(--text3);font-size:13px;margin-top:6px}
.desc{color:var(--text2);margin:12px auto 0;max-width:440px;white-space:pre-line}
.owner{display:inline-flex;align-items:center;gap:8px;margin:14px 0 18px;color:var(--text2);font-size:14px}
.owner strong{color:var(--text)}
.section{margin-top:32px}
.section h2{font-family:var(--serif);font-weight:400;font-size:27px;letter-spacing:-.3px;margin-bottom:12px}
.card{background:color-mix(in srgb,var(--surface) 72%,transparent);border:1px solid var(--line);border-radius:22px;padding:16px 18px}
.score-card{display:flex;align-items:center;gap:22px}
.big{font-family:var(--serif);font-size:56px;line-height:.95}
.huge{font-family:var(--serif);font-size:88px;line-height:.9}
.out{color:var(--text3);font-size:14px;margin-left:6px}
.rating-line{margin-top:18px}
.hist{flex:1;display:flex;align-items:flex-end;gap:4px;height:70px}
.hist span{flex:1;border-radius:3px;background:var(--c)}
.comment{margin-bottom:10px}
.row{display:flex;align-items:center;gap:12px}
.top-align{align-items:flex-start}
.numeral{font-family:var(--serif);font-size:32px;line-height:1}
.quote{font-family:var(--serif);font-style:italic;font-size:19px;line-height:1.22;margin:10px 0 6px;overflow-wrap:anywhere}
.big-quote{font-size:23px;margin:18px auto 10px;max-width:460px}
.avatar{width:var(--size);height:var(--size);border-radius:50%;object-fit:cover;flex:none;display:inline-grid;place-items:center;font-weight:800;font-size:calc(var(--size)*.42);color:#1B1408;background:var(--c)}
.item{display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid var(--line)}
.item img{width:50px;height:50px;border-radius:9px;object-fit:cover;background:var(--surface2);flex:none}
.item-title{font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.num{font-family:var(--serif);font-size:26px;width:30px;text-align:center;color:var(--text3);flex:none}
.reply{padding:10px 0;border-bottom:1px solid var(--line)}
.reply-text{margin-top:2px;overflow-wrap:anywhere;white-space:pre-line}
.banner{height:150px;margin:0 -16px -44px;background-size:cover;background-position:center;-webkit-mask-image:linear-gradient(#000 45%,transparent);mask-image:linear-gradient(#000 45%,transparent)}
.profile{text-align:center;position:relative}
.profile .avatar{margin:0 auto;box-shadow:0 0 0 3px var(--bg),0 0 0 5px var(--accent)}
.profile .title{margin-top:16px}
.stats{display:flex;flex-wrap:wrap;justify-content:center;gap:6px 16px;margin-top:14px;color:var(--text2);font-size:13.5px}
.stats strong{color:var(--text)}
.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
.tile{width:100%;aspect-ratio:1;border-radius:12px;object-fit:cover;background:var(--surface2)}
.tile.round{border-radius:50%}
.artist{text-align:center}
.artist span{display:block;margin-top:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.recent{position:relative}
.badge{position:absolute;right:6px;bottom:6px;font-family:var(--serif);font-size:22px;line-height:1;padding:3px 8px 4px;border-radius:10px;background:rgba(15,14,12,.78)}
.link{color:var(--accent);font-weight:700;display:inline-block;margin-top:14px}
.cta{margin-top:42px;text-align:center;padding:26px 22px 24px;border-radius:26px;background:var(--surface);border:1px solid var(--line)}
.cta h3{font-family:var(--serif);font-weight:400;font-size:29px;letter-spacing:-.3px;margin-top:12px}
.cta p{margin:8px auto 0;max-width:380px}
.btn{display:inline-block;margin-top:18px;padding:14px 22px;border-radius:999px;background:var(--accent);color:var(--on-accent);font-weight:800}
.btn.soon{background:var(--surface3);color:var(--text2)}
.vinyl{width:120px;height:120px;border-radius:50%;margin:0 auto;background:conic-gradient(from 40deg,transparent 0 8%,rgba(255,255,255,.07) 13%,transparent 20% 58%,rgba(255,255,255,.05) 63%,transparent 70%),radial-gradient(circle,var(--bg) 0 3%,var(--accent) 3.5% 17%,#0b0a09 17.5% 19%,transparent 19.5%),repeating-radial-gradient(circle,#1b1916 0 2px,#0c0b0a 2px 4px);box-shadow:0 18px 44px -18px #000;animation:spin 9s linear infinite}
.small-vinyl{width:64px;height:64px}
@keyframes spin{to{transform:rotate(360deg)}}
@media (prefers-reduced-motion:reduce){.vinyl{animation:none}}
footer{margin-top:26px;text-align:center;color:var(--text3);font-size:11.5px}
`;

// Tiñe el resplandor con el color de la portada (como PaletteService en la
// app). Si la imagen no deja leerse (CORS), queda el color de énfasis.
const GLOW_SCRIPT = `(function(){var el=document.querySelector('[data-glow-src]');if(!el)return;var img=new Image();img.crossOrigin='anonymous';img.onload=function(){try{var c=document.createElement('canvas');c.width=c.height=12;var x=c.getContext('2d');x.drawImage(img,0,0,12,12);var d=x.getImageData(0,0,12,12).data,r=0,g=0,b=0,n=0;for(var i=0;i<d.length;i+=4){var w=Math.max(d[i],d[i+1],d[i+2])-Math.min(d[i],d[i+1],d[i+2])+8;r+=d[i]*w;g+=d[i+1]*w;b+=d[i+2]*w;n+=w;}document.body.style.setProperty('--glow','rgb('+Math.round(r/n)+','+Math.round(g/n)+','+Math.round(b/n)+')');}catch(e){}};img.src=el.getAttribute('data-glow-src');})();`;

// ---------------------------------------------------------------------------
// Manejador
// ---------------------------------------------------------------------------

function send(res, status, body) {
  // Solo caché del navegador: la página cambia con el idioma de quien la abre.
  res.set("Cache-Control", "private, max-age=300");
  res.set("Content-Type", "text/html; charset=utf-8");
  res.status(status).send(body);
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
    const match = path.match(/^\/([ldnau])\/([^/]+)$/);
    try {
      if (!match) {
        send(res, 404, notFoundPage(t, lang, path));
        return;
      }
      let id;
      try {
        id = decodeURIComponent(match[2]);
      } catch (_) {
        send(res, 404, notFoundPage(t, lang, path));
        return;
      }
      const body = await routes[match[1]](getFirestore(), id, t, lang);
      if (!body) {
        send(res, 404, notFoundPage(t, lang, path));
        return;
      }
      send(res, 200, body);
    } catch (err) {
      logger.error("No se pudo armar la página", { path, message: err.message });
      send(res, 500, notFoundPage(t, lang, path));
    }
  };
}

module.exports = { createWebHandler, pickLang, esc, accentFor, scoreColor, onAccentFor };
