/**
 * Vinilo — proxy de Spotify.
 *
 * Guarda el Client ID y el Client Secret como secretos de Secret Manager,
 * pide el token con el flujo client-credentials y expone una API pequeña y
 * normalizada para la app. Requiere un ID token de Firebase Auth (la app usa
 * Auth anónimo) para que la cuota de Spotify no la consuma cualquiera.
 *
 * Rutas (todas GET):
 *   /search?q=texto&offset=0        → { items: [Album], total, nextOffset }
 *   /album/:id                      → AlbumDetail (con tracks)
 *   /artist/:id                     → Artist (nombre, foto, géneros)
 *   /artist/:id/albums?offset=0     → { items: [Album], total, nextOffset }
 *   /new?offset=0                   → { items: [Album] } álbumes del año en curso
 *   /artists/search?q=texto&offset=0 → { items: [Artist], total, nextOffset }
 *   /                               → { ok: true }
 *
 * Nota: en modo desarrollo Spotify limita cada página a 10 elementos y
 * bloquea /browse/new-releases y /albums?ids=, por eso no se usan.
 *
 * Vinilo — cuenta (función `account`, sin secretos).
 *
 *   POST /delete   → { ok: true, deleted: {...} } borra la cuenta de quien
 *                    manda el token (exige haber escrito la contraseña hace
 *                    menos de 5 minutos) y todo lo suyo con el Admin SDK:
 *                    también los hilos de sus notas y sus respuestas en
 *                    notas ajenas.
 *   GET  /         → { ok: true }
 *
 * Vinilo — página web pública (función `web`, en web.js): lo que se comparte
 * desde la app (/l/, /d/, /n/, /a/, /u/), servido por Firebase Hosting en
 * https://red-social-c786b.web.app.
 */

const { onRequest } = require("firebase-functions/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { createWebHandler } = require("./web");

initializeApp();

const SPOTIFY_CLIENT_ID = defineSecret("SPOTIFY_CLIENT_ID");
const SPOTIFY_CLIENT_SECRET = defineSecret("SPOTIFY_CLIENT_SECRET");

const SPOTIFY_API = "https://api.spotify.com/v1";
const PAGE_SIZE = 10; // Tope de Spotify para apps en modo desarrollo.
const MAX_OFFSET = 50;

class HttpError extends Error {
  constructor(status, message, extra) {
    super(message);
    this.status = status;
    this.extra = extra;
  }
}

// ---------------------------------------------------------------------------
// Token de Spotify (client credentials) con caché en memoria por instancia.
// ---------------------------------------------------------------------------

let tokenCache = { value: null, expiresAt: 0 };

async function getAccessToken(force = false) {
  if (!force && tokenCache.value && Date.now() < tokenCache.expiresAt - 60_000) {
    return tokenCache.value;
  }
  const credentials = Buffer.from(
    `${SPOTIFY_CLIENT_ID.value()}:${SPOTIFY_CLIENT_SECRET.value()}`,
  ).toString("base64");
  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) {
    logger.error("Spotify token request failed", { status: res.status });
    throw new HttpError(502, "No se pudo obtener el token de Spotify");
  }
  const json = await res.json();
  tokenCache = {
    value: json.access_token,
    expiresAt: Date.now() + Number(json.expires_in || 3600) * 1000,
  };
  return tokenCache.value;
}

async function spotifyGet(path, params = {}, retry = true) {
  const token = await getAccessToken();
  const url = new URL(`${SPOTIFY_API}${path}`);
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && value !== "") {
      url.searchParams.set(key, String(value));
    }
  }
  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (res.status === 401 && retry) {
    await getAccessToken(true);
    return spotifyGet(path, params, false);
  }
  if (res.status === 429) {
    const retryAfter = Number(res.headers.get("retry-after") || 5);
    throw new HttpError(429, "Spotify está limitando las peticiones", { retryAfter });
  }
  if (res.status === 404) {
    throw new HttpError(404, "No encontrado en Spotify");
  }
  if (!res.ok) {
    const body = await res.text();
    logger.warn("Spotify error", { status: res.status, path, body: body.slice(0, 300) });
    throw new HttpError(502, `Spotify respondió ${res.status}`);
  }
  return res.json();
}

// ---------------------------------------------------------------------------
// Normalización: la app solo recibe lo que necesita.
// ---------------------------------------------------------------------------

function pickImage(images, minWidth) {
  if (!Array.isArray(images) || images.length === 0) return null;
  const sorted = [...images]
    .filter((img) => img && img.url)
    .sort((a, b) => (a.width || 0) - (b.width || 0));
  const fit = sorted.find((img) => (img.width || 0) >= minWidth);
  return (fit || sorted[sorted.length - 1]).url;
}

function normalizeAlbum(album) {
  const artists = (album.artists || []).map((a) => ({ id: a.id, name: a.name }));
  const releaseDate = album.release_date || null;
  return {
    id: album.id,
    name: album.name,
    artist: artists.map((a) => a.name).join(", "),
    artists,
    year: releaseDate ? Number(releaseDate.slice(0, 4)) : null,
    releaseDate,
    type: album.album_type || null,
    totalTracks: album.total_tracks ?? null,
    cover: pickImage(album.images, 640),
    coverSmall: pickImage(album.images, 300),
    coverThumb: pickImage(album.images, 64),
    spotifyUrl: album.external_urls?.spotify || null,
  };
}

function normalizeArtist(artist) {
  return {
    id: artist.id,
    name: artist.name,
    image: pickImage(artist.images, 300),
    imageSmall: pickImage(artist.images, 64),
    genres: artist.genres || [],
    spotifyUrl: artist.external_urls?.spotify || null,
  };
}

function normalizeTrack(track) {
  return {
    id: track.id,
    name: track.name,
    number: track.track_number,
    disc: track.disc_number || 1,
    durationMs: track.duration_ms || 0,
    explicit: Boolean(track.explicit),
    artists: (track.artists || []).map((a) => a.name).join(", "),
  };
}

async function fetchAllTracks(albumId, first) {
  const tracks = (first?.items || []).map(normalizeTrack);
  const total = first?.total ?? tracks.length;
  let offset = tracks.length;
  let guard = 0;
  while (tracks.length < total && guard < 6) {
    const page = await spotifyGet(`/albums/${albumId}/tracks`, {
      limit: PAGE_SIZE,
      offset,
    });
    const items = (page.items || []).map(normalizeTrack);
    if (items.length === 0) break;
    tracks.push(...items);
    offset += items.length;
    guard += 1;
  }
  return tracks;
}

async function normalizeAlbumDetail(album) {
  return {
    ...normalizeAlbum(album),
    label: album.label || null,
    popularity: album.popularity ?? null,
    genres: album.genres || [],
    copyright: album.copyrights?.[0]?.text || null,
    tracks: await fetchAllTracks(album.id, album.tracks),
  };
}

// Caché pequeña de detalles de álbum por instancia (1 hora).
const albumCache = new Map();
const ALBUM_TTL_MS = 60 * 60 * 1000;

async function getAlbumDetail(id) {
  const cached = albumCache.get(id);
  if (cached && cached.expiresAt > Date.now()) return cached.value;
  const raw = await spotifyGet(`/albums/${id}`);
  const value = await normalizeAlbumDetail(raw);
  if (albumCache.size > 400) albumCache.delete(albumCache.keys().next().value);
  albumCache.set(id, { value, expiresAt: Date.now() + ALBUM_TTL_MS });
  return value;
}

function clampOffset(raw) {
  const n = Number.parseInt(raw, 10);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.min(n - (n % PAGE_SIZE), MAX_OFFSET);
}

function pageResult(paging, offset) {
  const items = (paging?.items || []).filter(Boolean).map(normalizeAlbum);
  const total = paging?.total ?? items.length;
  const hasMore = Boolean(paging?.next) && offset + PAGE_SIZE < MAX_OFFSET + PAGE_SIZE;
  return { items, total, nextOffset: hasMore ? offset + PAGE_SIZE : null };
}

/** Ficha de un artista (nombre, foto y géneros). */
async function getArtist(id) {
  return normalizeArtist(await spotifyGet(`/artists/${id}`));
}

// ---------------------------------------------------------------------------
// Auth: la app manda el ID token del usuario anónimo de Firebase.
// ---------------------------------------------------------------------------

async function requireUser(req) {
  const header = req.get("Authorization") || "";
  const match = header.match(/^Bearer (.+)$/);
  if (!match) throw new HttpError(401, "Falta el token de Firebase");
  try {
    return await getAuth().verifyIdToken(match[1]);
  } catch (err) {
    logger.warn("ID token inválido", { message: err.message });
    throw new HttpError(401, "Token de Firebase inválido");
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

async function route(req) {
  const path = req.path.replace(/\/+$/, "") || "/";

  if (path === "/") return { ok: true, service: "vinilo-spotify" };

  await requireUser(req);

  if (path === "/search") {
    const q = String(req.query.q || "").trim();
    if (q.length < 1) throw new HttpError(400, "Falta q");
    const offset = clampOffset(req.query.offset);
    const data = await spotifyGet("/search", {
      q: q.slice(0, 120),
      type: "album",
      limit: PAGE_SIZE,
      offset,
    });
    return pageResult(data.albums, offset);
  }

  if (path === "/artists/search") {
    const q = String(req.query.q || "").trim();
    if (q.length < 1) throw new HttpError(400, "Falta q");
    const offset = clampOffset(req.query.offset);
    const data = await spotifyGet("/search", {
      q: q.slice(0, 120),
      type: "artist",
      limit: PAGE_SIZE,
      offset,
    });
    const paging = data.artists;
    const items = (paging?.items || []).filter(Boolean).map(normalizeArtist);
    const hasMore = Boolean(paging?.next) && offset + PAGE_SIZE < MAX_OFFSET + PAGE_SIZE;
    return { items, total: paging?.total ?? items.length, nextOffset: hasMore ? offset + PAGE_SIZE : null };
  }

  const albumMatch = path.match(/^\/album\/([A-Za-z0-9]+)$/);
  if (albumMatch) return getAlbumDetail(albumMatch[1]);

  const artistDetailMatch = path.match(/^\/artist\/([A-Za-z0-9]+)$/);
  if (artistDetailMatch) return getArtist(artistDetailMatch[1]);

  const artistMatch = path.match(/^\/artist\/([A-Za-z0-9]+)\/albums$/);
  if (artistMatch) {
    const offset = clampOffset(req.query.offset);
    const data = await spotifyGet(`/artists/${artistMatch[1]}/albums`, {
      include_groups: req.query.groups || "album",
      limit: PAGE_SIZE,
      offset,
    });
    return pageResult(data, offset);
  }

  if (path === "/new") {
    const year = new Date().getFullYear();
    const offset = clampOffset(req.query.offset);
    const data = await spotifyGet("/search", {
      q: `year:${year}`,
      type: "album",
      limit: PAGE_SIZE,
      offset,
    });
    const page = pageResult(data.albums, offset);
    page.items = page.items.filter((a) => a.type === "album");
    return page;
  }

  throw new HttpError(404, "Ruta desconocida");
}

exports.spotify = onRequest(
  {
    region: "us-central1",
    secrets: [SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET],
    cors: true,
    maxInstances: 5,
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({ error: "Solo GET" });
      return;
    }
    try {
      const body = await route(req);
      res.set("Cache-Control", "private, max-age=120");
      res.status(200).json(body);
    } catch (err) {
      const status = err instanceof HttpError ? err.status : 500;
      if (status === 500) logger.error("Unhandled", err);
      if (err.extra?.retryAfter) res.set("Retry-After", String(err.extra.retryAfter));
      res.status(status).json({ error: err.message || "Error interno" });
    }
  },
);

// ---------------------------------------------------------------------------
// Borrar la cuenta
// ---------------------------------------------------------------------------
//
// Todo con el Admin SDK (no pasa por las reglas) y en un orden que se puede
// repetir: cada paso es idempotente y la cuenta de Auth se borra al final.
// Si algo falla a mitad, la persona sigue pudiendo entrar y vuelve a pedir el
// borrado, que retoma donde quedó en lugar de dejar datos a medias.

const RECENT_LOGIN_SECONDS = 5 * 60;
const BATCH_LIMIT = 400;

/** Aplica `op(batch, doc)` a cada documento, en lotes de 400. */
async function inBatches(db, docs, op) {
  for (let i = 0; i < docs.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    for (const doc of docs.slice(i, i + BATCH_LIMIT)) op(batch, doc);
    await batch.commit();
  }
  return docs.length;
}

/**
 * Borra una nota y la descuenta del disco (cuenta, suma e histograma) en la
 * misma transacción, igual que `RatingsRepo.remove` en la app.
 */
function removeRating(db, ref) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const score = Number(snap.get("score")) || 0;
    const albumId = snap.get("albumId");
    const albumRef = albumId ? db.collection("albums").doc(albumId) : null;
    const album = albumRef ? await tx.get(albumRef) : null;
    if (album && album.exists) {
      const hist = { ...(album.get("hist") || {}) };
      const key = String(score);
      hist[key] = Math.max(0, (Number(hist[key]) || 1) - 1);
      tx.update(albumRef, {
        ratingsCount: Math.max(0, (Number(album.get("ratingsCount")) || 1) - 1),
        ratingsSum: Math.max(0, Number(album.get("ratingsSum") ?? score) - score),
        hist,
      });
    }
    tx.delete(ref);
    return true;
  });
}

/**
 * Borra una respuesta (`ratings/{id}/replies/{replyId}`) y baja en uno el
 * contador `repliesCount` de su nota, en la misma transacción.
 */
function removeReply(db, ref) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const ratingRef = ref.parent.parent;
    const rating = await tx.get(ratingRef);
    if (rating.exists) {
      tx.update(ratingRef, {
        repliesCount: Math.max(0, (Number(rating.get("repliesCount")) || 1) - 1),
      });
    }
    tx.delete(ref);
    return true;
  });
}

/**
 * Borra un seguimiento y baja en uno el contador de la otra persona
 * (`followersCount` de a quién seguía o `followingCount` de quien la seguía).
 */
function removeFollow(db, ref, otherUid, counter) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const otherRef = db.collection("users").doc(otherUid);
    const other = await tx.get(otherRef);
    if (other.exists) {
      tx.update(otherRef, {
        [counter]: Math.max(0, (Number(other.get(counter)) || 0) - 1),
      });
    }
    tx.delete(ref);
    return true;
  });
}

async function deleteAccountData(uid) {
  const db = getFirestore();
  const deleted = {};

  // 1. Sus notas con su hilo de respuestas (las de todas las personas),
  //    ajustando promedios e histogramas de cada disco.
  const ratings = await db.collection("ratings").where("uid", "==", uid).get();
  let ratingsRemoved = 0;
  for (const doc of ratings.docs) {
    await db.recursiveDelete(doc.ref.collection("replies"));
    if (await removeRating(db, doc.ref)) ratingsRemoved++;
  }
  deleted.ratings = ratingsRemoved;

  // 1b. Sus respuestas en notas de otras personas, bajando el contador de
  //     cada hilo (índice de grupo de colecciones sobre `replies.uid`).
  const replies = await db.collectionGroup("replies").where("uid", "==", uid).get();
  let repliesRemoved = 0;
  for (const doc of replies.docs) {
    if (await removeReply(db, doc.ref)) repliesRemoved++;
  }
  deleted.replies = repliesRemoved;

  // 2. Sus "me gusta" en notas de otras personas.
  const liked = await db.collection("ratings").where("likedBy", "array-contains", uid).get();
  deleted.ratingLikes = await inBatches(db, liked.docs, (b, d) =>
    b.update(d.ref, { likedBy: FieldValue.arrayRemove(uid) }));

  // 3. Sus listas, y sus "me gusta" y guardadas en listas de otras personas.
  const lists = await db.collection("lists").where("ownerUid", "==", uid).get();
  // Primero las portadas (Storage lists/{id}/…), luego los documentos.
  const listsBucket = getStorage().bucket();
  for (const doc of lists.docs) {
    await listsBucket.deleteFiles({ prefix: `lists/${doc.id}/` });
  }
  deleted.lists = await inBatches(db, lists.docs, (b, d) => b.delete(d.ref));
  const likedLists = await db.collection("lists").where("likedBy", "array-contains", uid).get();
  deleted.listLikes = await inBatches(db, likedLists.docs, (b, d) =>
    b.update(d.ref, { likedBy: FieldValue.arrayRemove(uid) }));
  const savedLists = await db.collection("lists").where("savedBy", "array-contains", uid).get();
  deleted.listSaves = await inBatches(db, savedLists.docs, (b, d) =>
    b.update(d.ref, { savedBy: FieldValue.arrayRemove(uid) }));

  // 4. Seguimientos en los dos sentidos, con los contadores de los demás.
  const following = await db.collection("follows").where("follower", "==", uid).get();
  let followsRemoved = 0;
  for (const doc of following.docs) {
    if (await removeFollow(db, doc.ref, doc.get("followed"), "followersCount")) followsRemoved++;
  }
  const followers = await db.collection("follows").where("followed", "==", uid).get();
  for (const doc of followers.docs) {
    if (await removeFollow(db, doc.ref, doc.get("follower"), "followingCount")) followsRemoved++;
  }
  deleted.follows = followsRemoved;

  // 5. Notificaciones: las suyas y las que provocó en otras personas.
  const toMe = await db.collection("notifications").where("to", "==", uid).get();
  const fromMe = await db.collection("notifications").where("from", "==", uid).get();
  deleted.notifications =
    (await inBatches(db, toMe.docs, (b, d) => b.delete(d.ref))) +
    (await inBatches(db, fromMe.docs, (b, d) => b.delete(d.ref)));

  // 6. Avatar y banner en Storage.
  const bucket = getStorage().bucket();
  await Promise.all([
    bucket.file(`avatars/${uid}.jpg`).delete({ ignoreNotFound: true }),
    bucket.file(`banners/${uid}.jpg`).delete({ ignoreNotFound: true }),
  ]);

  // 7. El @usuario reservado y el perfil, juntos.
  const userRef = db.collection("users").doc(uid);
  const usernames = await db.collection("usernames").where("uid", "==", uid).get();
  const batch = db.batch();
  for (const doc of usernames.docs) batch.delete(doc.ref);
  batch.delete(userRef);
  await batch.commit();
  deleted.usernames = usernames.size;

  // 8. La cuenta de Auth, al final.
  try {
    await getAuth().deleteUser(uid);
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
  }
  return deleted;
}

exports.account = onRequest(
  {
    region: "us-central1",
    cors: true,
    maxInstances: 3,
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  async (req, res) => {
    try {
      const path = req.path.replace(/\/+$/, "") || "/";
      if (path === "/") {
        res.status(200).json({ ok: true, service: "vinilo-account" });
        return;
      }
      if (path !== "/delete") throw new HttpError(404, "Ruta desconocida");
      if (req.method !== "POST") throw new HttpError(405, "Solo POST");
      const user = await requireUser(req);
      // Firebase pide un inicio de sesión reciente para borrar una cuenta; la
      // app vuelve a pedir la contraseña justo antes de llamar.
      const age = Math.floor(Date.now() / 1000) - Number(user.auth_time || 0);
      if (age > RECENT_LOGIN_SECONDS) {
        throw new HttpError(401, "Vuelve a escribir tu contraseña para borrar la cuenta.", {
          code: "requires-recent-login",
        });
      }
      logger.info("Borrando cuenta", { uid: user.uid });
      const deleted = await deleteAccountData(user.uid);
      logger.info("Cuenta borrada", { uid: user.uid, deleted });
      res.status(200).json({ ok: true, deleted });
    } catch (err) {
      const status = err instanceof HttpError ? err.status : 500;
      if (status === 500) logger.error("No se pudo borrar la cuenta", err);
      res.status(status).json({
        error: err.message || "Error interno",
        ...(err.extra?.code ? { code: err.extra.code } : {}),
      });
    }
  },
);

// ---------------------------------------------------------------------------
// Página web pública (lo que se comparte desde la app), ver web.js
// ---------------------------------------------------------------------------

exports.web = onRequest(
  {
    region: "us-central1",
    secrets: [SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET],
    maxInstances: 10,
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  createWebHandler({ getAlbumDetail, getArtist }),
);
