/**
 * Validation helpers tests
 *
 * Per constitution §21: unit tests for shared utilities
 * Run: node src/shared/tests/validation.test.js
 */

const assert = require('assert');
const { isEmail, isPhone, isInt, isFloat, isObjectId, validate } = require('../validation.js');
const { ValidationError } = require('../errors.js');

let passed = 0, failed = 0;
function test(name, fn) {
    try { fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}

console.log('\n=== Validation Tests ===\n');

test('isEmail accepts valid emails', () => {
    assert.strictEqual(isEmail('user@example.com'), true);
    assert.strictEqual(isEmail('test.user+tag@sub.domain.org'), true);
});

test('isEmail rejects invalid emails', () => {
    assert.strictEqual(isEmail('not-an-email'), false);
    assert.strictEqual(isEmail('missing@domain'), false);
    assert.strictEqual(isEmail(''), false);
    assert.strictEqual(isEmail(null), false);
    assert.strictEqual(isEmail(123), false);
});

test('isEmail rejects too long', () => {
    const long = 'a'.repeat(255) + '@example.com';
    assert.strictEqual(isEmail(long), false);
});

test('isPhone accepts +998 format', () => {
    assert.strictEqual(isPhone('+998901234567'), true);
    assert.strictEqual(isPhone('+99890 123 45 67'), true);
});

test('isPhone accepts 9-digit local', () => {
    assert.strictEqual(isPhone('901234567'), true);
});

test('isPhone accepts 12-digit international', () => {
    assert.strictEqual(isPhone('998901234567'), true);
});

test('isPhone rejects invalid', () => {
    assert.strictEqual(isPhone('123'), false);
    assert.strictEqual(isPhone(''), false);
    assert.strictEqual(isPhone(null), false);
});

test('isInt accepts integers', () => {
    assert.strictEqual(isInt(5), true);
    assert.strictEqual(isInt('5'), true);
    assert.strictEqual(isInt(0), true);
    assert.strictEqual(isInt(-10), true);
});

test('isInt rejects floats and strings', () => {
    assert.strictEqual(isInt(5.5), false);
    assert.strictEqual(isInt('5.5'), false);
    assert.strictEqual(isInt('abc'), false);
    assert.strictEqual(isInt(null), false);
});

test('isInt respects min/max', () => {
    assert.strictEqual(isInt(5, 1, 10), true);
    assert.strictEqual(isInt(0, 1, 10), false);
    assert.strictEqual(isInt(15, 1, 10), false);
});

test('isFloat accepts numbers', () => {
    assert.strictEqual(isFloat(3.14), true);
    assert.strictEqual(isFloat('3.14'), true);
    assert.strictEqual(isFloat(-1.5), true);
});

test('isFloat rejects NaN/Infinity', () => {
    assert.strictEqual(isFloat(NaN), false);
    assert.strictEqual(isFloat(Infinity), false);
});

test('isObjectId accepts 24-char hex', () => {
    assert.strictEqual(isObjectId('6a32a090f1daffb517b20da6'), true);
    assert.strictEqual(isObjectId('ABCDEF1234567890ABCDEF12'), true);
});

test('isObjectId rejects wrong length/format', () => {
    assert.strictEqual(isObjectId('short'), false);
    assert.strictEqual(isObjectId('6a32a090f1daffb517b20d'), false);
    assert.strictEqual(isObjectId('6a32a090f1daffb517b20da!'), false);
});

test('validate: required field missing throws', () => {
    assert.throws(() => validate({}, { name: { type: 'string', required: true } }), ValidationError);
});

test('validate: optional field missing OK', () => {
    const out = validate({}, { name: { type: 'string' } });
    assert.deepStrictEqual(out, {});
});

test('validate: applies default', () => {
    const out = validate({}, { role: { type: 'string', default: 'user' } });
    assert.strictEqual(out.role, 'user');
});

test('validate: coerces int', () => {
    const out = validate({ age: '25' }, { age: { type: 'int' } });
    assert.strictEqual(out.age, 25);
    assert.strictEqual(typeof out.age, 'number');
});

test('validate: rejects invalid type', () => {
    assert.throws(() =>
        validate({ email: 'not-email' }, { email: { type: 'email', required: true } }),
        ValidationError
    );
});

test('validate: in enum', () => {
    const out = validate({ status: 'active' }, {
        status: { type: 'in', values: ['active', 'inactive'] }
    });
    assert.strictEqual(out.status, 'active');

    assert.throws(() =>
        validate({ status: 'invalid' }, {
            status: { type: 'in', values: ['active', 'inactive'] }
        }),
        ValidationError
    );
});

test('validate: multiple fields', () => {
    const out = validate({
        email: 'test@example.com', age: 25, name: 'Alex',
    }, {
        email: { type: 'email', required: true },
        age: { type: 'int', min: 18 },
        name: { type: 'nonEmptyString', required: true },
    });
    assert.strictEqual(out.email, 'test@example.com');
    assert.strictEqual(out.age, 25);
    assert.strictEqual(out.name, 'Alex');
});

console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
