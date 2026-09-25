// Prueba local de la página web pública (functions/web.js) con un Firestore
// falso: arma cada tipo de página y comprueba el escapado, el idioma, los 404
// y que no salgan correos ni uids. No necesita Firebase ni desplegar nada.
//
//   node tool/web_test.js
const path = require("path");
const Module = require("module");
const FN = path.join(__dirname, "..", "functions");

const ts = (ms) => ({ toMillis: () => ms });
const data = {
  "lists/lista1": { name: "Para <b>llover</b>", description: "Discos grises", kind: "ranking", itemType: "albums", ownerUid: "u1",
    owner: { name: "Vale \"Ríos\"", color: 4284186600, avatarUrl: null },
    items: [{ id: "a1", name: "OK Computer", artist: "Radiohead", coverSmall: "https://i.scdn.co/image/x", year: 1997 },
            { id: "a2", name: "Kid A", artist: "Radiohead", coverSmall: "https://i.scdn.co/image/y", year: 2000 }] },
  "albums/a1": { id: "a1", name: "OK Computer", artist: "Radiohead", cover: "https://i.scdn.co/image/x", coverSmall: "https://i.scdn.co/image/x", year: 1997, type: "album", totalTracks: 12, ratingsCount: 2, ratingsSum: 19, hist: { "9": 1, "10": 1 }, artistIds: ["r1"] },
  "ratings/u1_a1": { uid: "u1", albumId: "a1", score: 10, note: "Perfecto <script>alert(1)</script>", album: { id: "a1", name: "OK Computer", artist: "Radiohead", coverSmall: "https://i.scdn.co/image/x" }, user: { name: "Vale", color: 4284186600 }, likedBy: ["u2"], repliesCount: 1, updatedAt: ts(2) },
  "ratings/u2_a1": { uid: "u2", albumId: "a1", score: 9, note: "", album: { id: "a1", name: "OK Computer" }, user: { name: "Santi", color: 4291058646 }, likedBy: [], updatedAt: ts(1) },
  "users/u1": { name: "Vale Ríos", username: "vale.rios", bio: "Rock y lluvia", color: 4284186600, ratingsCount: 1, ratingsSum: 10, followersCount: 3, followingCount: 1,
    bannerUrl: "https://x.test/b.jpg');background:red;('", favorites: [{ id: "a1", name: "OK Computer", coverSmall: "https://i.scdn.co/image/x" }], favoriteArtists: [{ id: "r1", name: "Radiohead", image: "https://i.scdn.co/image/r" }] },
  "usernames/vale.rios": { uid: "u1" },
  "ratings/u1_a1/replies/r1": { uid: "u2", user: { name: "Santi", username: "santimejia", color: 4291058646 }, text: "¡De acuerdo, @vale.rios!", createdAt: ts(3) },
};

function docSnap(p) {
  const d = data[p];
  return { exists: !!d, id: p.split("/").pop(), data: () => d, get: (k) => d?.[k], ref: ref(p) };
}
function ref(p) {
  return { get: async () => docSnap(p), collection: (c) => coll(`${p}/${c}`) };
}
function coll(p, filters = []) {
  const q = {
    doc: (id) => ref(`${p}/${id}`),
    where: (f, op, v) => coll(p, [...filters, [f, op, v]]),
    orderBy: () => q, limit: () => q,
    get: async () => {
      const docs = Object.keys(data)
        .filter((k) => k.startsWith(p + "/") && k.slice(p.length + 1).indexOf("/") < 0)
        .filter((k) => filters.every(([f, op, v]) => op === "==" ? data[k][f] === v : (data[k][f] || []).includes(v)))
        .map(docSnap);
      return { docs, size: docs.length };
    },
  };
  return q;
}
const fakeDb = { collection: (c) => coll(c) };

const origResolve = Module._resolveFilename;
Module._resolveFilename = function (req, ...rest) {
  if (req === "firebase-admin/firestore") return "fake-firestore";
  return origResolve.call(this, req, ...rest);
};
require.cache["fake-firestore"] = { id: "fake-firestore", filename: "fake-firestore", loaded: true, exports: { getFirestore: () => fakeDb } };

const { createWebHandler, pickLang } = require(path.join(FN, "web.js"));
const handler = createWebHandler({
  getAlbumDetail: async (id) => { const e = new Error("no"); e.status = 404; throw e; },
  getArtist: async (id) => ({ id, name: "Radiohead", image: "https://i.scdn.co/image/r", genres: ["art rock"] }),
});

async function run(p, lang = "es-CO,es;q=0.9") {
  let status = 0, body = "";
  const headers = {};
  const req = { path: p, method: "GET", query: {}, get: (h) => (h === "Accept-Language" ? lang : "") };
  const res = { set: (k, v) => { headers[k] = v; }, status: (s) => { status = s; return res; }, send: (b) => { body = b; } };
  await handler(req, res);
  return { status, body, headers };
}

(async () => {
  const checks = [];
  const ok = (name, cond) => { checks.push([name, !!cond]); };
  const list = await run("/l/lista1");
  ok("lista 200", list.status === 200);
  ok("lista escapa el nombre", list.body.includes("Para &lt;b&gt;llover&lt;/b&gt;") && !list.body.includes("<b>llover"));
  ok("lista og:title", list.body.includes('property="og:title" content="Para &lt;b&gt;llover&lt;/b&gt;"'));
  ok("ranking numerado", list.body.includes('class="num">1<') && list.body.includes('class="num">2<'));
  const album = await run("/d/a1");
  ok("disco 200 con promedio 9,5", album.status === 200 && album.body.includes(">9,5<"));
  ok("disco comentario escapado", album.body.includes("&lt;script&gt;") && !album.body.includes("<script>alert"));
  const albumEn = await run("/d/a1", "en-US,en;q=0.9");
  ok("inglés: 9.5 y RATING", albumEn.body.includes(">9.5<") && albumEn.body.includes("RATING") && albumEn.body.includes('lang="en"'));
  const rating = await run("/n/u1_a1");
  ok("nota 200 con respuesta", rating.status === 200 && rating.body.includes("¡De acuerdo, @vale.rios!") && rating.body.includes("Obra maestra"));
  ok("nota enlaza al perfil", rating.body.includes('href="/u/vale.rios"'));
  const artist = await run("/a/r1");
  ok("artista 200 con su disco", artist.status === 200 && artist.body.includes("OK Computer") && artist.body.includes("art rock"));
  const profile = await run("/u/vale.rios");
  ok("perfil 200 con bio", profile.status === 200 && profile.body.includes("Rock y lluvia") && profile.body.includes("@vale.rios"));
  ok("perfil banner sin inyección CSS", !profile.body.includes("background:red;('") && profile.body.includes("%27%29"));
  const byUid = await run("/u/u1");
  ok("perfil por uid", byUid.status === 200);
  ok("404 lista", (await run("/l/nada")).status === 404);
  ok("404 disco sin Spotify", (await run("/d/zzz")).status === 404);
  ok("404 ruta rara", (await run("/x/1")).status === 404);
  ok("404 id inválido", (await run("/l/..%2F..")).status === 404);
  ok("sin correos ni uids en la página", !profile.body.includes("u1\"") && !profile.body.includes("@vinilo"));
  ok("caché privada", list.headers["Cache-Control"] === "private, max-age=300");
  ok("pickLang", pickLang({ query: {}, get: () => "fr-FR,en;q=0.8,es;q=0.5" }) === "en" && pickLang({ query: { lang: "es" }, get: () => "en" }) === "es");
  for (const [name, pass] of checks) console.log(pass ? "ok  " : "FALLA", name);
  const passed = checks.every(([, p]) => p);
  console.log(passed ? "TODO BIEN" : "HAY FALLAS");
  if (!passed) process.exitCode = 1;
})().catch((e) => { console.error(e); process.exit(1); });
