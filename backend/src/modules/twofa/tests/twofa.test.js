const assert = require('assert');
const twofa = require('../twofa.service.js');
let passed = 0, failed = 0;
function test(name, fn) {
    try { fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}
console.log('\n=== 2FA TOTP Tests ===\n');
test('base32 encode produces valid string', () => {
    const encoded = twofa._base32Encode(Buffer.alloc(20, 0x42));
    assert.ok(encoded.length > 0);
    assert.match(encoded, /^[A-Z2-7]+$/);
});
test('generateTotp returns 6-digit code', () => {
    const secret = twofa._base32Encode(Buffer.alloc(20, 0x42));
    const code = twofa._generateTotp(secret, Date.now());
    assert.strictEqual(code.length, 6);
    assert.match(code, /^\d{6}$/);
});
test('same secret + same time = same code', () => {
    const secret = twofa._base32Encode(Buffer.alloc(20, 0x42));
    const time = Date.now();
    assert.strictEqual(twofa._generateTotp(secret, time), twofa._generateTotp(secret, time));
});
test('different secrets = different codes', () => {
    const s1 = twofa._base32Encode(Buffer.alloc(20, 0x42));
    const s2 = twofa._base32Encode(Buffer.alloc(20, 0x99));
    assert.notStrictEqual(twofa._generateTotp(s1, Date.now()), twofa._generateTotp(s2, Date.now()));
});
test('code changes after 30s step', () => {
    const secret = twofa._base32Encode(Buffer.alloc(20, 0x42));
    const now = Date.now();
    assert.notStrictEqual(twofa._generateTotp(secret, now), twofa._generateTotp(secret, now + 31000));
});
test('code is deterministic within same TOTP step', () => {
    const secret = twofa._base32Encode(Buffer.alloc(20, 0x42));
    const step = Math.floor(Date.now() / 30000) * 30000;
    assert.strictEqual(twofa._generateTotp(secret, step), twofa._generateTotp(secret, step + 15000));
});
console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
