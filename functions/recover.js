/**
 * Vinilo — recuperar la contraseña con un código de 6 dígitos (función
 * `recover`). Firebase Auth solo manda enlaces, así que el código lo genera
 * y lo manda esta función por correo (SMTP), y es ella la que cambia la
 * contraseña con el Admin SDK.
 *
 * Rutas (POST con JSON, sin sesión):
 *   /start  { email, lang }            → { ok, resendIn, expiresIn }
 *            Siempre responde lo mismo, exista o no la cuenta (no se puede
 *            averiguar qué correos tienen cuenta). Un código cada 45 s y
 *            hasta 5 por hora por correo.
 *   /verify { email, code }            → { ok, ticket } o
 *            { code: "wrong-code", left } / "too-many-attempts" / "expired"
 *            Tres intentos; el código vence a los 10 minutos.
 *   /finish { email, ticket, password } → { ok, name }
 *            Cambia la contraseña, cierra las demás sesiones
 *            (`revokeRefreshTokens`) y borra el código.
 *   GET /   → { ok, mail } (si el correo está configurado)
 *
 * Los códigos viven en `passwordResets/{sha256(correo)}`, con el código y
 * el ticket guardados como hash; las reglas no dejan que la app los lea.
 */

const crypto = require("node:crypto");

const CODE_TTL_MS = 10 * 60 * 1000;
const RESEND_MS = 45 * 1000;
const MAX_SENDS_PER_HOUR = 5;
const MAX_ATTEMPTS = 3;
const HOUR_MS = 60 * 60 * 1000;

class RecoverError extends Error {
  constructor(status, code, extra = {}) {
    super(code);
    this.status = status;
    this.code = code;
    this.extra = extra;
  }
}

const sha256 = (text) => crypto.createHash("sha256").update(text).digest("hex");

/** Compara dos hash hex sin dar pistas por el tiempo que tarda. */
function sameHash(a, b) {
  if (typeof a !== "string" || typeof b !== "string" || a.length !== b.length) return false;
  return crypto.timingSafeEqual(Buffer.from(a, "hex"), Buffer.from(b, "hex"));
}

function normalizeEmail(raw) {
  const email = String(raw || "").trim().toLowerCase();
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) && email.length <= 254 ? email : null;
}

/** La contraseña nueva: 8 o más caracteres y al menos un número. */
function strongEnough(password) {
  return typeof password === "string" && password.length >= 8 && password.length <= 128 && /\d/.test(password);
}

/** El correo con el código, en español o en inglés. */
function codeMail(code, lang) {
  const en = lang === "en";
  const subject = en ? `Your Vinilo code: ${code}` : `Tu código de Vinilo: ${code}`;
  const lines = en
    ? [
        `Your code to reset your Vinilo password is ${code}.`,
        "It expires in 10 minutes.",
        "If you didn't ask for it, you can ignore this email: your password stays the same.",
      ]
    : [
        `Tu código para recuperar la contraseña de Vinilo es ${code}.`,
        "Vence en 10 minutos.",
        "Si no lo pediste, ignora este correo: tu contraseña sigue igual.",
      ];
  const html = `<div style="font-family:Helvetica,Arial,sans-serif;background:#0f0e0d;color:#efebe4;padding:32px">
<div style="font:600 12px monospace;letter-spacing:.08em;color:rgba(239,235,228,.6)">VINILO</div>
<p style="font-size:15px;line-height:1.45;margin:18px 0 6px">${lines[0].replace(code, "")}</p>
<div style="font:800 44px Helvetica,Arial,sans-serif;letter-spacing:.2em;margin:6px 0 14px">${code}</div>
<p style="font-size:14px;line-height:1.45;color:rgba(239,235,228,.62);margin:0">${lines[1]} ${lines[2]}</p>
</div>`;
  return { subject, text: lines.join("\n"), html };
}

/**
 * Arma el manejador. Todo lo de afuera llega por `deps` para poder probarlo
 * sin Firebase: `getAuth`, `getFirestore`, `sendMail(msg)`,
 * `mailConfigured()`, y opcionalmente `now()`, `randomInt(max)` y
 * `randomHex(bytes)`.
 */
function createRecoverHandler(deps) {
  const now = deps.now || (() => Date.now());
  const randomInt = deps.randomInt || ((max) => crypto.randomInt(0, max));
  const randomHex = deps.randomHex || ((bytes) => crypto.randomBytes(bytes).toString("hex"));
  const docFor = (email) => deps.getFirestore().collection("passwordResets").doc(sha256(email));

  async function start(body) {
    const email = normalizeEmail(body.email);
    if (!email) throw new RecoverError(400, "invalid-email");
    if (!deps.mailConfigured()) throw new RecoverError(503, "mail-not-configured");
    const ref = docFor(email);
    const snap = await ref.get();
    const t = now();
    const prev = snap.exists ? snap.data() : null;
    if (prev && t - Number(prev.lastSentAt || 0) < RESEND_MS) {
      const retryAfter = Math.ceil((RESEND_MS - (t - Number(prev.lastSentAt))) / 1000);
      throw new RecoverError(429, "throttled", { retryAfter });
    }
    const sends = (prev?.sends || []).filter((s) => t - Number(s) < HOUR_MS);
    if (sends.length >= MAX_SENDS_PER_HOUR) {
      const retryAfter = Math.ceil((HOUR_MS - (t - Math.min(...sends))) / 1000);
      throw new RecoverError(429, "throttled", { retryAfter });
    }
    let user = null;
    try {
      user = await deps.getAuth().getUserByEmail(email);
    } catch (err) {
      if (err?.code !== "auth/user-not-found") throw err;
    }
    // Sin cuenta se responde igual y se guarda un código que nadie recibe:
    // `verify` contesta "código incorrecto" como con una cuenta de verdad,
    // así no se puede averiguar qué correos tienen cuenta.
    const code = String(randomInt(1000000)).padStart(6, "0");
    const salt = randomHex(16);
    await ref.set({
      uid: user ? user.uid : null,
      codeHash: sha256(salt + (user ? code : randomHex(16))),
      salt,
      attempts: 0,
      expiresAt: t + CODE_TTL_MS,
      lastSentAt: t,
      sends: [...sends, t],
      ticketHash: null,
      ticketExpiresAt: null,
    });
    if (user) {
      await deps.sendMail({ to: email, ...codeMail(code, body.lang === "en" ? "en" : "es") });
    }
    return { ok: true, resendIn: RESEND_MS / 1000, expiresIn: CODE_TTL_MS / 1000 };
  }

  async function verify(body) {
    const email = normalizeEmail(body.email);
    if (!email) throw new RecoverError(400, "invalid-email");
    const ref = docFor(email);
    const snap = await ref.get();
    const d = snap.exists ? snap.data() : null;
    const t = now();
    if (!d || !d.codeHash || t > Number(d.expiresAt || 0)) {
      if (d) await ref.update({ codeHash: null });
      throw new RecoverError(400, "expired");
    }
    const attempts = Number(d.attempts || 0);
    if (attempts >= MAX_ATTEMPTS) throw new RecoverError(400, "too-many-attempts");
    const code = String(body.code || "");
    const right = /^\d{6}$/.test(code) && sameHash(sha256(d.salt + code), d.codeHash);
    if (!right) {
      const used = attempts + 1;
      if (used >= MAX_ATTEMPTS) {
        // Sin intentos: el código ya no sirve (hay que pedir otro).
        await ref.update({ attempts: used, codeHash: null });
        throw new RecoverError(400, "too-many-attempts");
      }
      await ref.update({ attempts: used });
      throw new RecoverError(400, "wrong-code", { left: MAX_ATTEMPTS - used });
    }
    const ticket = randomHex(24);
    await ref.update({
      codeHash: null,
      ticketHash: sha256(ticket),
      ticketExpiresAt: t + CODE_TTL_MS,
    });
    return { ok: true, ticket };
  }

  async function finish(body) {
    const email = normalizeEmail(body.email);
    if (!email) throw new RecoverError(400, "invalid-email");
    const ref = docFor(email);
    const snap = await ref.get();
    const d = snap.exists ? snap.data() : null;
    const t = now();
    const ticket = String(body.ticket || "");
    if (!d || !d.uid || !d.ticketHash || t > Number(d.ticketExpiresAt || 0) || !sameHash(sha256(ticket), d.ticketHash)) {
      throw new RecoverError(400, "expired");
    }
    if (!strongEnough(body.password)) throw new RecoverError(400, "weak-password");
    const auth = deps.getAuth();
    await auth.updateUser(d.uid, { password: body.password });
    // Las demás sesiones (otros teléfonos) se cierran por seguridad.
    await auth.revokeRefreshTokens(d.uid);
    await ref.delete();
    let name = null;
    try {
      const profile = await deps.getFirestore().collection("users").doc(d.uid).get();
      name = profile.exists ? profile.get("name") || null : null;
    } catch (_) {
      // Sin nombre, la app dice "Todo listo".
    }
    return { ok: true, name };
  }

  return async (req, res) => {
    try {
      const path = (req.path || "/").replace(/\/+$/, "") || "/";
      if (path === "/") {
        res.status(200).json({ ok: true, service: "vinilo-recover", mail: deps.mailConfigured() });
        return;
      }
      if (req.method !== "POST") throw new RecoverError(405, "method-not-allowed");
      const body = typeof req.body === "object" && req.body ? req.body : {};
      const route = { "/start": start, "/verify": verify, "/finish": finish }[path];
      if (!route) throw new RecoverError(404, "not-found");
      res.status(200).json(await route(body));
    } catch (err) {
      if (err instanceof RecoverError) {
        if (err.extra.retryAfter) res.set("Retry-After", String(err.extra.retryAfter));
        res.status(err.status).json({ code: err.code, ...err.extra });
        return;
      }
      (deps.logError || console.error)("recover", err);
      res.status(500).json({ code: "server" });
    }
  };
}

module.exports = { createRecoverHandler, codeMail, normalizeEmail, strongEnough, sha256 };
