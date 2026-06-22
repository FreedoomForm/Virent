/**
 * Auth domain tests
 *
 * Per constitution §21: unit tests for domain rules
 */

const assert = require('assert');
const { User, TokenPair, OtpCode } = require('../domain/auth.entity.js');

let passed = 0, failed = 0;
function test(name, fn) {
    try { fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}

console.log('\n=== Auth Domain Tests ===\n');

test('User.fullName returns combined name', () => {
    const u = new User({ firstName: 'John', lastName: 'Doe' });
    assert.strictEqual(u.fullName(), 'John Doe');
});

test('User.fullName returns Unknown when empty', () => {
    const u = new User({});
    assert.strictEqual(u.fullName(), 'Unknown');
});

test('User.isActive checks status', () => {
    assert.strictEqual(new User({ status: 'active' }).isActive(), true);
    assert.strictEqual(new User({ status: 'blocked' }).isActive(), false);
    assert.strictEqual(new User({}).isActive(), true);  // default active
});

test('User role checks', () => {
    assert.strictEqual(new User({ role: 'admin' }).isAdmin(), true);
    assert.strictEqual(new User({ role: 'user' }).isAdmin(), false);
    assert.strictEqual(new User({ role: 'juicer' }).isJuicer(), true);
    assert.strictEqual(new User({ role: 'mechanic' }).isMechanic(), true);
});

test('User.hasAcceptedTerms', () => {
    assert.strictEqual(new User({ accepted_terms_at: new Date() }).hasAcceptedTerms(), true);
    assert.strictEqual(new User({}).hasAcceptedTerms(), false);
});

test('User.canLogin requires active status', () => {
    assert.strictEqual(new User({ status: 'active' }).canLogin(), true);
    assert.strictEqual(new User({ status: 'blocked' }).canLogin(), false);
});

test('TokenPair.isExpired', () => {
    const past = new TokenPair('a', 'b', 1);
    past.issuedAt = new Date(Date.now() - 2000);  // 2s ago, expires in 1s
    assert.strictEqual(past.isExpired(), true);

    const future = new TokenPair('a', 'b', 3600);
    assert.strictEqual(future.isExpired(), false);
});

test('TokenPair.toJSON has correct fields', () => {
    const tp = new TokenPair('access', 'refresh', 900);
    const j = tp.toJSON();
    assert.strictEqual(j.access_token, 'access');
    assert.strictEqual(j.refresh_token, 'refresh');
    assert.strictEqual(j.expires_in, 900);
    assert.ok(j.issued_at);
});

test('OtpCode.isExpired', () => {
    const expired = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() - 1000),
    });
    assert.strictEqual(expired.isExpired(), true);

    const valid = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() + 60000),
    });
    assert.strictEqual(valid.isExpired(), false);
});

test('OtpCode.isBlocked after 5 attempts', () => {
    const otp = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() + 60000),
    });
    assert.strictEqual(otp.isBlocked(), false);
    otp.attempts = 5;
    assert.strictEqual(otp.isBlocked(), true);
});

test('OtpCode.verify succeeds with correct code', () => {
    const otp = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() + 60000),
    });
    const result = otp.verify('123456');
    assert.strictEqual(result.ok, true);
    assert.strictEqual(otp.used, true);
});

test('OtpCode.verify fails with wrong code and increments attempts', () => {
    const otp = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() + 60000),
    });
    const result = otp.verify('999999');
    assert.strictEqual(result.ok, false);
    assert.strictEqual(otp.attempts, 1);
    assert.strictEqual(otp.used, false);  // not used yet
});

test('OtpCode.verify fails when already used', () => {
    const otp = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() + 60000),
    });
    otp.used = true;
    const result = otp.verify('123456');
    assert.strictEqual(result.ok, false);
    assert.match(result.error, /already used/i);
});

test('OtpCode.verify fails when expired', () => {
    const otp = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() - 1000),
    });
    const result = otp.verify('123456');
    assert.strictEqual(result.ok, false);
    assert.match(result.error, /expired/i);
});

test('OtpCode.verify fails when blocked', () => {
    const otp = new OtpCode({
        phone: '+998901234567', purpose: 'login', code: '123456',
        expiresAt: new Date(Date.now() + 60000),
    });
    otp.attempts = 5;
    const result = otp.verify('123456');
    assert.strictEqual(result.ok, false);
    assert.match(result.error, /too many/i);
});

console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
