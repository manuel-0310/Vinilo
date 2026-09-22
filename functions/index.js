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
 *   /artist/:id/albums?offset=0     → { items: [Album], total, nextOffset }
 *   /new?offset=0                   → { items: [Album] } álbumes del año en curso
 *   /artists/search?q=texto&offset=0 → { items: [Artist], total, nextOffset }
 *   /                               → { ok: true }
 *
 * Nota: en modo desarrollo Spotify limita cada página a 10 elementos y
 * bloquea /browse/new-releases y /albums?ids=, por eso no se usan.
 */

const { onRequest } = require("firebase-functions/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

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
