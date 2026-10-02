/**
 * Vinilo — país y géneros de los artistas (`artistMeta/{spotifyId}`), para
 * "Géneros" y "De dónde vienen" en las estadísticas del perfil. Spotify en
 * modo desarrollo no los manda (llega `genres` vacío y no hay país), así que
 * se buscan en MusicBrainz por el enlace de Spotify del artista:
 *
 *   1. /ws/2/url?resource=https://open.spotify.com/artist/{id}&inc=artist-rels
 *      → el artista de MusicBrainz enlazado a ese id de Spotify.
 *   2. /ws/2/artist/{mbid}?inc=genres → su país y sus géneros (con votos).
 *
 * Lo encontrado se guarda en `artistMeta/{id}` (`country`, `genres` de más
 * a menos votado, `mbid`); lo que no se encuentra también (`missing: true`)
 * para no volver a preguntar. La app solo pide los que no están.
 *
 * MusicBrainz pide como mucho una petición por segundo y un User-Agent que
 * diga quién pregunta: por eso cada llamada resuelve pocos artistas
 * (`maxResolve`) y deja el resto en `pending`, que la app vuelve a pedir.
 */

const MB_API = "https://musicbrainz.org/ws/2";
const USER_AGENT = "Vinilo/1.0 (https://red-social-c786b.web.app)";
const SPOTIFY_ID = /^[A-Za-z0-9]{22}$/;
const MAX_IDS = 10;
const MAX_GENRES = 5;

/** Los ids de `?ids=a,b,c`: con forma de id de Spotify, sin repetir, hasta 10. */
function parseIds(raw) {
  const out = [];
  for (const part of String(raw || "").split(",")) {
    const id = part.trim();
    if (SPOTIFY_ID.test(id) && !out.includes(id)) out.push(id);
    if (out.length >= MAX_IDS) break;
  }
  return out;
}

/** País (ISO de dos letras) y géneros (de más a menos votos) de un artista de MusicBrainz. */
function metaFromArtist(artist) {
  const area = artist?.area?.["iso-3166-1-codes"]?.[0] || null;
  const raw = typeof artist?.country === "string" && artist.country.length === 2 ? artist.country : area;
  // "XW" (mundo) y "XE" (Europa) no son países.
  const country = raw && !/^X[A-Z]$/.test(raw) ? raw.toUpperCase() : null;
  const genres = (Array.isArray(artist?.genres) ? artist.genres : [])
    .filter((g) => g && typeof g.name === "string" && g.name.trim())
    .sort((a, b) => (b.count || 0) - (a.count || 0))
    .slice(0, MAX_GENRES)
    .map((g) => g.name.trim().toLowerCase());
  return { country, genres };
}

/** El primer artista enlazado a la URL de Spotify (respuesta de /ws/2/url). */
function artistFromUrlLookup(body) {
  for (const rel of body?.relations || []) {
    if (rel?.artist?.id) return rel.artist;
  }
  return null;
}

/**
 * `getFirestore`, `fetch`, `sleep` y `now` se inyectan para poder probarlo
 * sin red (tool/meta_test.js).
 */
function createMetaResolver({
  getFirestore,
  fetch,
  sleep = (ms) => new Promise((r) => setTimeout(r, ms)),
  now = () => Date.now(),
  spacingMs = 1100,
  maxResolve = 4,
  budgetMs = 20_000,
  logError = () => {},
}) {
  let lastCall = 0;

  /** GET a MusicBrainz respetando una petición por segundo. null si no existe. */
  async function mbGet(path) {
    const wait = lastCall + spacingMs - now();
    if (wait > 0) await sleep(wait);
    lastCall = now();
    const res = await fetch(`${MB_API}${path}${path.includes("?") ? "&" : "?"}fmt=json`, {
      headers: { "User-Agent": USER_AGENT, Accept: "application/json" },
    });
    if (res.status === 404) return null;
    if (!res.ok) {
      const err = new Error(`MusicBrainz ${res.status}`);
      err.status = res.status;
      throw err;
    }
    return res.json();
  }

  async function lookup(spotifyId) {
    const resource = encodeURIComponent(`https://open.spotify.com/artist/${spotifyId}`);
    const link = await mbGet(`/url?resource=${resource}&inc=artist-rels`);
    const found = artistFromUrlLookup(link);
    if (!found) return { country: null, genres: [], mbid: null, missing: true };
    const artist = await mbGet(`/artist/${found.id}?inc=genres`);
    if (!artist) return { country: null, genres: [], mbid: found.id, missing: true };
    return { ...metaFromArtist(artist), mbid: found.id, missing: false };
  }

  /**
   * Devuelve `{ meta: { id: { country, genres } }, pending: [ids] }`: lo que
   * ya estaba guardado, lo que se resolvió ahora (y se guardó) y lo que
   * quedó para la próxima (por tiempo, por el tope o porque MusicBrainz no
   * respondió).
   */
  return async function resolveArtistMeta(ids) {
    const db = getFirestore();
    const col = db.collection("artistMeta");
    const meta = {};
    const unknown = [];
    const snaps = await Promise.all(ids.map((id) => col.doc(id).get()));
    snaps.forEach((snap, i) => {
      if (snap.exists) {
        const d = snap.data() || {};
        meta[ids[i]] = { country: d.country || null, genres: Array.isArray(d.genres) ? d.genres : [] };
      } else {
        unknown.push(ids[i]);
      }
    });

    const started = now();
    const pending = [];
    let resolved = 0;
    let stopped = false;
    for (const id of unknown) {
      if (stopped || resolved >= maxResolve || now() - started > budgetMs) {
        pending.push(id);
        continue;
      }
      try {
        const found = await lookup(id);
        await col.doc(id).set({ ...found, source: "musicbrainz", updatedAt: new Date(now()) });
        meta[id] = { country: found.country, genres: found.genres };
        resolved++;
      } catch (err) {
        // Un 503 es MusicBrainz pidiendo calma: se para y sigue otro día.
        logError("artistMeta", err);
        pending.push(id);
        if (err.status === 503 || err.status === 429) stopped = true;
      }
    }
    return { meta, pending };
  };
}

module.exports = { createMetaResolver, parseIds, metaFromArtist, artistFromUrlLookup, USER_AGENT };
