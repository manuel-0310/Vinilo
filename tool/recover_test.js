// Prueba local de recuperar la contraseña (functions/recover.js) con un
// Firestore, un Auth y un correo falsos. No necesita Firebase ni desplegar.
//
//   node tool/recover_test.js
const path = require("path");
const assert = require("assert");
const { createRecoverHandler, codeMail, normalizeEmail, strongEnough, sha256 } =
  require(path.join(__dirname, "..", "functions", "recover.js"));

const store = {};
function ref(p) {
  return {
    get: async () => ({ exists: p in store, data: () => store[p], get: (k) => store[p]?.[k] }),
    set: async (d) => { store[p] = { ...d }; },
    update: async (d) => { store[p] = { ...store[p], ...d }; },
    delete: async () => { delete store[p]; },
  };
}
const fakeDb = { collection: (c) => ({ doc: (id) => ref(`${c}/${id}`) }) };
store["users/u1"] = { name: "Manuel" };

const users = { "manuel@correo.com": { uid: "u1" } };
const calls = [];
const fakeAuth = {
  getUserByEmail: async (email) => {
    if (users[email]) return users[email];
    const e = new Error("nope"); e.code = "auth/user-not-found"; throw e;
  },
  updateUser: async (uid, data) => { calls.push(["updateUser", uid, data.password]); },
  revokeRefreshTokens: async (uid) => { calls.push(["revoke", uid]); },
};

let clock = 1_000_000;
const mails = [];
let mailOn = true;
let nextCode = 482193;
const handler = createRecoverHandler({
  getAuth: () => fakeAuth,
  getFirestore: () => fakeDb,
  mailConfigured: () => mailOn,
  sendMail: async (m) => { mails.push(m); },
  now: () => clock,
  randomInt: () => nextCode,
  randomHex: (n) => "ab".repeat(n),
  logError: () => {},
});

async function call(route, body, method = "POST") {
  const res = { statusCode: 0, headers: {}, body: null,
    status(c) { this.statusCode = c; return this; },
    set(k, v) { this.headers[k] = v; return this; },
    json(b) { this.body = b; return this; } };
  await handler({ path: route, method, body }, res);
  return res;
}

let passed = 0;
async function check(name, fn) {
  try { await fn(); passed++; console.log("✓", name); }
  catch (e) { console.error("✗", name, "\n ", e.message); process.exitCode = 1; }
}

(async () => {
  await check("salud: dice si el correo está configurado", async () => {
    const r = await call("/", null, "GET");
    assert.equal(r.statusCode, 200);
    assert.equal(r.body.mail, true);
  });

  await check("correo inválido", async () => {
    const r = await call("/start", { email: "no-es-correo" });
    assert.equal(r.statusCode, 400);
    assert.equal(r.body.code, "invalid-email");
  });

  await check("start manda el código (en español) y guarda solo su hash", async () => {
    const r = await call("/start", { email: " Manuel@Correo.com ", lang: "es" });
    assert.equal(r.statusCode, 200);
    assert.deepEqual(r.body, { ok: true, resendIn: 45, expiresIn: 600 });
    assert.equal(mails.length, 1);
    assert.equal(mails[0].to, "manuel@correo.com");
    assert.match(mails[0].subject, /482193/);
    assert.match(mails[0].text, /Vence en 10 minutos/);
    const doc = store[`passwordResets/${sha256("manuel@correo.com")}`];
    assert.ok(doc);
    assert.ok(!JSON.stringify(doc).includes("482193"), "el código no se guarda en claro");
  });

  await check("no se puede pedir otro antes de 45 s", async () => {
    clock += 10_000;
    const r = await call("/start", { email: "manuel@correo.com" });
    assert.equal(r.statusCode, 429);
    assert.equal(r.body.code, "throttled");
    assert.equal(r.body.retryAfter, 35);
  });

  await check("un correo sin cuenta responde igual y no manda nada", async () => {
    const r = await call("/start", { email: "nadie@correo.com" });
    assert.equal(r.statusCode, 200);
    assert.equal(mails.length, 1);
    // Y al verificar dice "código incorrecto", como con una cuenta de verdad.
    const v = await call("/verify", { email: "nadie@correo.com", code: "482193" });
    assert.equal(v.body.code, "wrong-code");
  });

  await check("código incorrecto: quedan 2 y luego 1 intentos", async () => {
    let r = await call("/verify", { email: "manuel@correo.com", code: "111111" });
    assert.equal(r.statusCode, 400);
    assert.deepEqual(r.body, { code: "wrong-code", left: 2 });
    r = await call("/verify", { email: "manuel@correo.com", code: "12" });
    assert.deepEqual(r.body, { code: "wrong-code", left: 1 });
  });

  await check("el código bueno da un ticket", async () => {
    const r = await call("/verify", { email: "manuel@correo.com", code: "482193" });
    assert.equal(r.statusCode, 200);
    assert.equal(r.body.ticket, "ab".repeat(24));
    // El código ya no sirve una segunda vez.
    const again = await call("/verify", { email: "manuel@correo.com", code: "482193" });
    assert.equal(again.body.code, "expired");
  });

  await check("la contraseña nueva necesita 8 caracteres y un número", async () => {
    const r = await call("/finish", { email: "manuel@correo.com", ticket: "ab".repeat(24), password: "corta" });
    assert.equal(r.body.code, "weak-password");
    const r2 = await call("/finish", { email: "manuel@correo.com", ticket: "ab".repeat(24), password: "sinnumeros" });
    assert.equal(r2.body.code, "weak-password");
  });

  await check("un ticket que no es el bueno no sirve", async () => {
    const r = await call("/finish", { email: "manuel@correo.com", ticket: "cd".repeat(24), password: "nueva1234" });
    assert.equal(r.body.code, "expired");
  });

  await check("finish cambia la contraseña, cierra las sesiones y devuelve el nombre", async () => {
    const r = await call("/finish", { email: "manuel@correo.com", ticket: "ab".repeat(24), password: "nueva1234" });
    assert.equal(r.statusCode, 200);
    assert.deepEqual(r.body, { ok: true, name: "Manuel" });
    assert.deepEqual(calls, [["updateUser", "u1", "nueva1234"], ["revoke", "u1"]]);
    assert.equal(store[`passwordResets/${sha256("manuel@correo.com")}`], undefined);
  });

  await check("tres intentos fallidos gastan el código", async () => {
    clock += 60_000;
    nextCode = 7;
    await call("/start", { email: "manuel@correo.com", lang: "en" });
    assert.match(mails.at(-1).subject, /Your Vinilo code: 000007/);
    await call("/verify", { email: "manuel@correo.com", code: "000001" });
    await call("/verify", { email: "manuel@correo.com", code: "000002" });
    const r = await call("/verify", { email: "manuel@correo.com", code: "000003" });
    assert.equal(r.body.code, "too-many-attempts");
    const late = await call("/verify", { email: "manuel@correo.com", code: "000007" });
    assert.notEqual(late.statusCode, 200);
  });

  await check("el código vence a los 10 minutos", async () => {
    clock += 60_000;
    await call("/start", { email: "manuel@correo.com" });
    clock += 10 * 60_000 + 1;
    const r = await call("/verify", { email: "manuel@correo.com", code: "000007" });
    assert.equal(r.body.code, "expired");
  });

  await check("hasta 5 códigos por hora", async () => {
    for (let i = 0; i < 3; i++) {
      clock += 46_000;
      const ok = await call("/start", { email: "manuel@correo.com" });
      assert.equal(ok.statusCode, 200, `envío ${i}`);
    }
    clock += 46_000;
    const r = await call("/start", { email: "manuel@correo.com" });
    assert.equal(r.statusCode, 429);
  });

  await check("sin correo configurado responde 503 y la app usa el enlace de Firebase", async () => {
    mailOn = false;
    const r = await call("/start", { email: "otra@correo.com" });
    assert.equal(r.statusCode, 503);
    assert.equal(r.body.code, "mail-not-configured");
    mailOn = true;
  });

  await check("rutas y métodos", async () => {
    assert.equal((await call("/start", {}, "GET")).statusCode, 405);
    assert.equal((await call("/otra", {})).statusCode, 404);
  });

  await check("ayudantes", async () => {
    assert.equal(normalizeEmail("  A@B.co "), "a@b.co");
    assert.equal(normalizeEmail("sin-arroba"), null);
    assert.equal(strongEnough("abcdefg1"), true);
    assert.equal(strongEnough("abcdefgh"), false);
    assert.match(codeMail("123456", "es").html, /123456/);
  });

  console.log(`\n${passed} comprobaciones`);
})();
