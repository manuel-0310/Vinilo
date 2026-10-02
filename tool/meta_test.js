// Prueba local del país y los géneros de los artistas (functions/meta.js)
// con un Firestore y un MusicBrainz falsos. No necesita red ni desplegar.
//
//   node tool/meta_test.js
const path = require("path");
const assert = require("assert");
const { createMetaResolver, parseIds, metaFromArtist, artistFromUrlLookup, USER_AGENT } =
  require(path.join(__dirname, "..", "functions", "meta.js"));

let checks = 0;
async function check(name, fn) {
  await fn();
  checks++;
  console.log(`ok   ${name}`);
}

// Ids con forma de Spotify (22 letras y números).
const CERATI = "1QOmebWGB6FdFtW7Bo3F0W";
const SODA = "7An4yvF7hDYDolN4m5zKBp";
const NADIE = "0000000000000000000000";
const OTRO = "1111111111111111111111";

function fakeDb(initial = {}) {
  const store = { ...initial };
  return {
    store,
    collection: (c) => ({
      doc: (id) => ({
        get: async () => ({ exists: `${c}/${id}` in store, data: () => store[`${c}/${id}`] }),
        set: async (d) => { store[`${c}/${id}`] = { ...d }; },
      }),
    }),
  };
}

// MusicBrainz falso: Cerati (AR) y Soda Stereo (sin país propio, con el
// área), y nada para el resto.
const mb = {
  [`/url?resource=${encodeURIComponent(`https://open.spotify.com/artist/${CERATI}`)}&inc=artist-rels`]: {
    relations: [{ type: "free streaming", artist: { id: "mb-cerati", name: "Gustavo Cerati" } }],
  },
  "/artist/mb-cerati?inc=genres": {
    country: "AR",
    genres: [
      { name: "Rock", count: 2 },
      { name: "art rock", count: 5 },
      { name: "pop rock", count: 1 },
    ],
  },
  [`/url?resource=${encodeURIComponent(`https://open.spotify.com/artist/${SODA}`)}&inc=artist-rels`]: {
    relations: [{ type: "free streaming", artist: { id: "mb-soda" } }],
  },
  "/artist/mb-soda?inc=genres": { country: null, area: { "iso-3166-1-codes": ["AR"] }, genres: [] },
};

function fakeFetch(log, { status } = {}) {
  return async (url, options) => {
    log.push({ url, ua: options?.headers?.["User-Agent"] });
    if (status) return { status, ok: false, json: async () => ({}) };
    const key = url.replace("https://musicbrainz.org/ws/2", "").replace(/[&?]fmt=json$/, "");
    if (!(key in mb)) return { status: 404, ok: false, json: async () => ({}) };
    return { status: 200, ok: true, json: async () => mb[key] };
  };
}

function resolver(db, log, extra = {}) {
  let clock = 1_000_000;
  const sleeps = [];
  const resolve = createMetaResolver({
    getFirestore: () => db,
    fetch: fakeFetch(log, extra.fetch),
    sleep: async (ms) => { sleeps.push(ms); clock += ms; },
    now: () => clock,
    ...extra.options,
  });
  return { resolve, sleeps };
}

(async () => {
  await check("ids: solo con forma de Spotify, sin repetir y hasta 10", () => {
    assert.deepStrictEqual(parseIds(`${CERATI}, ${CERATI},hola,${SODA}`), [CERATI, SODA]);
    assert.deepStrictEqual(parseIds(""), []);
    const many = Array.from({ length: 14 }, (_, i) => String(i).padStart(22, "a"));
    assert.strictEqual(parseIds(many.join(",")).length, 10);
  });

  await check("país y géneros: de más a menos votos, en minúsculas; el área si no hay país", () => {
    assert.deepStrictEqual(metaFromArtist(mb["/artist/mb-cerati?inc=genres"]), {
      country: "AR",
      genres: ["art rock", "rock", "pop rock"],
    });
    assert.deepStrictEqual(metaFromArtist(mb["/artist/mb-soda?inc=genres"]), { country: "AR", genres: [] });
    assert.strictEqual(metaFromArtist({ country: "XW" }).country, null);
    assert.strictEqual(artistFromUrlLookup({ relations: [] }), null);
  });

  await check("busca, guarda y devuelve; lo que no existe queda como missing", async () => {
    const db = fakeDb();
    const log = [];
    const { resolve, sleeps } = resolver(db, log);
    const out = await resolve([CERATI, SODA, NADIE]);
    assert.deepStrictEqual(out.meta[CERATI], { country: "AR", genres: ["art rock", "rock", "pop rock"] });
    assert.deepStrictEqual(out.meta[SODA], { country: "AR", genres: [] });
    assert.deepStrictEqual(out.meta[NADIE], { country: null, genres: [] });
    assert.deepStrictEqual(out.pending, []);
    assert.strictEqual(db.store[`artistMeta/${CERATI}`].mbid, "mb-cerati");
    assert.strictEqual(db.store[`artistMeta/${CERATI}`].source, "musicbrainz");
    assert.strictEqual(db.store[`artistMeta/${NADIE}`].missing, true);
    // Cada petición con User-Agent y separada por más de un segundo.
    assert.ok(log.every((c) => c.ua === USER_AGENT));
    assert.ok(log.every((c) => c.url.endsWith("fmt=json")));
    assert.strictEqual(sleeps.length, log.length - 1);
    assert.ok(sleeps.every((ms) => ms >= 1000));
  });

  await check("lo ya guardado no vuelve a preguntar", async () => {
    const db = fakeDb({ [`artistMeta/${CERATI}`]: { country: "AR", genres: ["rock"] } });
    const log = [];
    const { resolve } = resolver(db, log);
    const out = await resolve([CERATI]);
    assert.deepStrictEqual(out.meta[CERATI], { country: "AR", genres: ["rock"] });
    assert.strictEqual(log.length, 0);
  });

  await check("resuelve pocos por llamada y deja el resto en pending", async () => {
    const db = fakeDb();
    const log = [];
    const { resolve } = resolver(db, log, { options: { maxResolve: 1 } });
    const out = await resolve([CERATI, SODA, NADIE]);
    assert.deepStrictEqual(Object.keys(out.meta), [CERATI]);
    assert.deepStrictEqual(out.pending, [SODA, NADIE]);
  });

  await check("si MusicBrainz pide calma (503), para y no guarda nada", async () => {
    const db = fakeDb();
    const log = [];
    const { resolve } = resolver(db, log, { fetch: { status: 503 } });
    const out = await resolve([CERATI, OTRO]);
    assert.deepStrictEqual(out.meta, {});
    assert.deepStrictEqual(out.pending, [CERATI, OTRO]);
    assert.strictEqual(log.length, 1);
    assert.strictEqual(Object.keys(db.store).length, 0);
  });

  console.log(`\n${checks} comprobaciones`);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
