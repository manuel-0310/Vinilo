#!/usr/bin/env node
// Maneja Vinilo en el simulador a través de la extensión de Flutter Driver.
// Uso:
//   node tool/drive.mjs <ws-url> <comando> [args...]
// Comandos:
//   tap key:<valueKey> | text:<texto> | type:<Widget>
//   type <texto>                       (escribe en el campo con foco)
//   wait key:<valueKey>|text:<texto>   (espera a que exista)
//   scroll key:<k> <dx> <dy> [ms]      (arrastra sobre el widget)
//   into key:<k>                       (scrollIntoView)
//   gettext key:<k>
//   health
//   sleep <ms>
// Se pueden encadenar varios comandos separando con "--".
import process from 'node:process';

const [wsUrl, ...rest] = process.argv.slice(2);
if (!wsUrl) {
  console.error('Falta la URL ws:// del VM Service');
  process.exit(2);
}

function finder(spec) {
  const idx = spec.indexOf(':');
  const kind = spec.slice(0, idx);
  const value = spec.slice(idx + 1);
  switch (kind) {
    case 'key':
      return { finderType: 'ByValueKey', keyValueString: value, keyValueType: 'String' };
    case 'text':
      return { finderType: 'ByText', text: value };
    case 'type':
      return { finderType: 'ByType', type: value };
    case 'tooltip':
      return { finderType: 'ByTooltipMessage', text: value };
    default:
      throw new Error(`Finder desconocido: ${spec}`);
  }
}

const ws = new WebSocket(wsUrl);
let nextId = 1;
const pending = new Map();

ws.addEventListener('message', (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id !== undefined && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    if (msg.error) reject(new Error(JSON.stringify(msg.error)));
    else resolve(msg.result);
  }
});

function rpc(method, params = {}) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ jsonrpc: '2.0', id, method, params }));
  });
}

async function driverIsolate() {
  const vm = await rpc('getVM');
  for (const iso of vm.isolates) {
    const info = await rpc('getIsolate', { isolateId: iso.id });
    if ((info.extensionRPCs || []).includes('ext.flutter.driver')) return iso.id;
  }
  throw new Error('La app no tiene la extensión de Flutter Driver (usa -t test_driver/app.dart)');
}

async function driver(isolateId, command) {
  const params = { isolateId };
  for (const [k, v] of Object.entries(command)) params[k] = String(v);
  const res = await rpc('ext.flutter.driver', params);
  if (res.isError) throw new Error(`Driver: ${JSON.stringify(res.response)}`);
  return res.response;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function run() {
  const isolateId = await driverIsolate();
  // La app tiene animaciones infinitas (vinilo girando, shimmer); con
  // frameSync activo el driver esperaría para siempre a que "se calme".
  await driver(isolateId, { command: 'set_frame_sync', enabled: 'false' });
  const groups = rest.join('\u0000').split('\u0000--\u0000').map((g) => g.split('\u0000'));
  for (const [cmd, ...args] of groups) {
    switch (cmd) {
      case 'health':
        console.log(JSON.stringify(await driver(isolateId, { command: 'get_health' })));
        break;
      case 'tap':
        await driver(isolateId, { command: 'waitFor', ...finder(args[0]), timeout: 8000 });
        try {
          await driver(isolateId, { command: 'tap', ...finder(args[0]), timeout: Number(process.env.TAP_TIMEOUT || 4000) });
          console.log(`tap ${args[0]}`);
        } catch (e) {
          // El tap del driver se cuelga sobre algunos widgets (portadas con
          // Hero). Un arrastre de 1 px recorre el camino real de eventos y
          // el reconocedor lo trata como un toque.
          await driver(isolateId, {
            command: 'scroll', ...finder(args[0]), dx: 1, dy: 1, duration: 80000, frequency: 60,
          });
          console.log(`tap ${args[0]} (via micro-drag)`);
        }
        break;
      case 'type':
        await driver(isolateId, { command: 'enter_text', text: args.join(' ') });
        console.log(`type "${args.join(' ')}"`);
        break;
      case 'wait':
        await driver(isolateId, { command: 'waitFor', ...finder(args[0]), timeout: args[1] || 15000 });
        console.log(`found ${args[0]}`);
        break;
      case 'gone':
        await driver(isolateId, { command: 'waitForAbsent', ...finder(args[0]), timeout: args[1] || 15000 });
        console.log(`gone ${args[0]}`);
        break;
      case 'scroll':
        await driver(isolateId, {
          command: 'scroll',
          ...finder(args[0]),
          dx: args[1],
          dy: args[2],
          duration: (Number(args[3] || 400)) * 1000, // microsegundos
          frequency: 60,
        });
        console.log(`scroll ${args[0]} ${args[1]},${args[2]}`);
        break;
      case 'into':
        await driver(isolateId, { command: 'scrollIntoView', ...finder(args[0]), alignment: args[1] || 0.5 });
        console.log(`into ${args[0]}`);
        break;
      case 'gettext':
        console.log(JSON.stringify(await driver(isolateId, { command: 'get_text', ...finder(args[0]) })));
        break;
      case 'settle':
        await driver(isolateId, { command: 'waitForCondition', conditionName: 'NoTransientCallbacks', timeout: args[0] || 8000 });
        console.log('settled');
        break;
      case 'sleep':
        await sleep(Number(args[0] || 500));
        break;
      case 'home': {
        // Cierra rutas apiladas (o una hoja) hasta ver la barra de pestañas.
        for (let i = 0; i < 4; i++) {
          try {
            await driver(isolateId, { command: 'waitFor', ...finder('key:tab-0'), timeout: 1200 });
            break;
          } catch {
            try {
              await driver(isolateId, { command: 'tap', ...finder('key:back'), timeout: 1500 });
            } catch {
              // Sin botón de volver: probablemente una hoja modal. Toca fuera.
              await driver(isolateId, { command: 'tap', ...finder('type:ModalBarrier'), timeout: 1500 }).catch(() => {});
            }
            await sleep(700);
          }
        }
        await driver(isolateId, { command: 'tap', ...finder('key:tab-' + (args[0] || '0')), timeout: 3000 });
        console.log('home ' + (args[0] || '0'));
        break;
      }
      default:
        throw new Error(`Comando desconocido: ${cmd}`);
    }
  }
}

ws.addEventListener('open', () => {
  run()
    .then(() => { ws.close(); process.exit(0); })
    .catch((e) => { console.error(e.message); ws.close(); process.exit(1); });
});
ws.addEventListener('error', (e) => { console.error('ws error', e.message || e); process.exit(1); });
