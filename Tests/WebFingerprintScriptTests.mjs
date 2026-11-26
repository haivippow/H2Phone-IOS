import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const testsDir = path.dirname(fileURLToPath(import.meta.url));
const sourcePath = path.join(testsDir, '..', 'Tweak', 'H2WebFingerprint.m');
const objectiveC = fs.readFileSync(sourcePath, 'utf8');
const builder = objectiveC.match(/NSString \*source\s*=([\s\S]*?);\s*NSDictionary \*payload/);
assert.ok(builder, 'H2WebFingerprintScript template must be discoverable');

const literals = [...builder[1].matchAll(/@"((?:\\.|[^"\\])*)"/g)];
assert.ok(literals.length > 0, 'script template must contain Objective-C string literals');
const template = literals.map((match) => JSON.parse(`"${match[1]}"`)).join('');

function buildScript(userAgent, profile, seed) {
  const payload = JSON.stringify({ userAgent, profile, seed: seed & 0xff })
    .replaceAll('\u2028', '\\u2028').replaceAll('\u2029', '\\u2029');
  return template.replaceAll('__H2_PAYLOAD__', payload);
}

function contextWithNavigator() {
  function Navigator() {}
  Object.defineProperties(Navigator.prototype, {
    userAgent: { configurable: true, enumerable: true, get: () => 'original' },
    appVersion: { configurable: true, enumerable: true, get: () => 'original' },
    language: { configurable: true, enumerable: true, get: () => 'en-US' },
    languages: { configurable: true, enumerable: true, get: () => ['en-US'] },
    platform: { configurable: true, enumerable: true, get: () => 'original' },
    vendor: { configurable: true, enumerable: true, get: () => 'original' },
    hardwareConcurrency: { configurable: true, enumerable: true, get: () => 2 },
    maxTouchPoints: { configurable: true, enumerable: true, get: () => 1 },
  });
  const navigator = new Navigator();
  function Screen() {}
  Object.defineProperties(Screen.prototype, {
    width: { configurable: true, get: () => 1 }, height: { configurable: true, get: () => 1 },
    availWidth: { configurable: true, get: () => 1 }, availHeight: { configurable: true, get: () => 1 },
    colorDepth: { configurable: true, get: () => 24 }, pixelDepth: { configurable: true, get: () => 24 },
  });
  const screen = new Screen();
  function WebGLRenderingContext() {}
  WebGLRenderingContext.prototype.getParameter = function (parameter) { return `original:${parameter}`; };
  const window = { screen };
  Object.defineProperty(window, 'devicePixelRatio', { configurable: true, get: () => 1 });
  return vm.createContext({ window, Screen, screen, Navigator, navigator, WebGLRenderingContext, Date, Intl });
}

const profile = { screenWidth: 430, screenHeight: 932, screenScale: 3, cores: 6, maxTouchPoints: 5, webglVendor: 'Apple Inc.', webglRenderer: 'Apple GPU' };
const specialUA = `Mozilla/'quote'\\slash\u2028line\u2029end __SEED__ __UA_JSON__ __PROFILE_JSON__ __H2_PAYLOAD__`;
const firstContext = contextWithNavigator();
vm.runInContext(buildScript(specialUA, profile, 511), firstContext);
assert.equal(firstContext.navigator.userAgent, specialUA, 'special-character UA must round-trip');
assert.equal(firstContext.window.__h2changerFingerprint.seed, 255, 'seed must be masked to one byte');
assert.deepEqual([...firstContext.navigator.languages], ['vi-VN', 'en-US']);

const replacementUA = 'replacement/2.0';
vm.runInContext(buildScript(replacementUA, profile, 258), firstContext);
assert.equal(firstContext.navigator.userAgent, replacementUA, 'existing state must update its UA');
assert.equal(firstContext.window.__h2changerFingerprint.seed, 2, 'existing state must update its seed');
assert.equal(firstContext.screen.width, 430, 'screen width must come from profile');
assert.equal(firstContext.screen.height, 932, 'screen height must come from profile');
assert.equal(firstContext.window.devicePixelRatio, 3, 'DPR must come from profile');
assert.equal(firstContext.navigator.hardwareConcurrency, 6, 'CPU count must come from profile');
assert.equal(firstContext.navigator.maxTouchPoints, 5, 'touch count must come from profile');
const gl = new firstContext.WebGLRenderingContext();
assert.equal(gl.getParameter(37445), 'Apple Inc.', 'WebGL vendor must come from profile');
assert.equal(gl.getParameter(37446), 'Apple GPU', 'WebGL renderer must come from profile');

const browserProfileBlock = objectiveC.match(/H2BrowserProfile\([^)]*\)\s*\{([\s\S]*?)\n\}/);
assert.ok(browserProfileBlock, 'browser profile allowlist must exist');
for (const sensitiveKey of ['uuid', 'idfa', 'imei', 'imei2']) {
  assert.equal(browserProfileBlock[1].includes(`@"${sensitiveKey}"`), false, `${sensitiveKey} must not enter browser payload`);
}

console.log('Web fingerprint script tests passed: 17 assertions.');
