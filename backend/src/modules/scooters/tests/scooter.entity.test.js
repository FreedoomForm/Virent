/**
 * Scooter domain entity tests
 */

const assert = require('assert');
const { Scooter, SCOOTER_STATUSES, SCOOTER_TRANSITIONS } = require('../domain/scooter.entity.js');

let passed = 0, failed = 0;
function test(name, fn) {
    try { fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}

console.log('\n=== Scooter Entity Tests ===\n');

test('Scooter defaults to available status', () => {
    const s = new Scooter({});
    assert.strictEqual(s.status, 'available');
});

test('Scooter.canTransitionTo respects state machine', () => {
    const available = new Scooter({ status: 'available' });
    assert.strictEqual(available.canTransitionTo('reserved'), true);
    assert.strictEqual(available.canTransitionTo('maintenance'), true);
    assert.strictEqual(available.canTransitionTo('in_use'), false);  // must go through reserved
    assert.strictEqual(available.canTransitionTo('retired'), true);

    const reserved = new Scooter({ status: 'reserved' });
    assert.strictEqual(reserved.canTransitionTo('available'), true);
    assert.strictEqual(reserved.canTransitionTo('in_use'), true);
    assert.strictEqual(reserved.canTransitionTo('maintenance'), false);

    const inUse = new Scooter({ status: 'in_use' });
    assert.strictEqual(inUse.canTransitionTo('available'), true);
    assert.strictEqual(inUse.canTransitionTo('charging_needed'), true);
    assert.strictEqual(inUse.canTransitionTo('reserved'), false);

    const maintenance = new Scooter({ status: 'maintenance' });
    assert.strictEqual(maintenance.canTransitionTo('available'), true);
    assert.strictEqual(maintenance.canTransitionTo('retired'), true);
    assert.strictEqual(maintenance.canTransitionTo('in_use'), false);

    const retired = new Scooter({ status: 'retired' });
    assert.strictEqual(retired.canTransitionTo('available'), false);
    assert.strictEqual(retired.canTransitionTo('maintenance'), false);
});

test('Scooter.isAvailable', () => {
    assert.strictEqual(new Scooter({ status: 'available' }).isAvailable(), true);
    assert.strictEqual(new Scooter({ status: 'in_use' }).isAvailable(), false);
});

test('Scooter.isUsable — available/reserved/in_use', () => {
    assert.strictEqual(new Scooter({ status: 'available' }).isUsable(), true);
    assert.strictEqual(new Scooter({ status: 'reserved' }).isUsable(), true);
    assert.strictEqual(new Scooter({ status: 'in_use' }).isUsable(), true);
    assert.strictEqual(new Scooter({ status: 'maintenance' }).isUsable(), false);
    assert.strictEqual(new Scooter({ status: 'retired' }).isUsable(), false);
});

test('Scooter.needsCharging — battery < 20 and not charging', () => {
    assert.strictEqual(new Scooter({ battery: 15, status: 'available' }).needsCharging(), true);
    assert.strictEqual(new Scooter({ battery: 25, status: 'available' }).needsCharging(), false);
    assert.strictEqual(new Scooter({ battery: 15, status: 'charging' }).needsCharging(), false);
    assert.strictEqual(new Scooter({ battery: 0, status: 'available' }).needsCharging(), true);
});

test('Scooter.needsMaintenance', () => {
    assert.strictEqual(new Scooter({ status: 'maintenance' }).needsMaintenance(), true);
    assert.strictEqual(new Scooter({ status: 'available' }).needsMaintenance(), false);
});

test('Scooter.isRetired', () => {
    assert.strictEqual(new Scooter({ status: 'retired' }).isRetired(), true);
    assert.strictEqual(new Scooter({ status: 'available' }).isRetired(), false);
});

test('Scooter has default values', () => {
    const s = new Scooter({});
    assert.strictEqual(s.total_distance_km, 0);
    assert.strictEqual(s.total_rides, 0);
    assert.strictEqual(s.battery_health_percent, 100);
    assert.strictEqual(s.battery_cycles, 0);
    assert.strictEqual(s.max_speed_kmh, 25);
    assert.strictEqual(s.battery_capacity_wh, 280);
    assert.deepStrictEqual(s.log, []);
});

test('SCOOTER_STATUSES contains all expected statuses', () => {
    assert.ok(SCOOTER_STATUSES.includes('available'));
    assert.ok(SCOOTER_STATUSES.includes('reserved'));
    assert.ok(SCOOTER_STATUSES.includes('in_use'));
    assert.ok(SCOOTER_STATUSES.includes('charging_needed'));
    assert.ok(SCOOTER_STATUSES.includes('charging'));
    assert.ok(SCOOTER_STATUSES.includes('maintenance'));
    assert.ok(SCOOTER_STATUSES.includes('retired'));
    assert.strictEqual(SCOOTER_STATUSES.length, 7);
});

test('SCOOTER_TRANSITIONS has entries for all statuses', () => {
    for (const status of SCOOTER_STATUSES) {
        assert.ok(SCOOTER_TRANSITIONS[status], `Missing transitions for ${status}`);
    }
});

test('SCOOTER_TRANSITIONS retired is terminal (empty)', () => {
    assert.deepStrictEqual(SCOOTER_TRANSITIONS.retired, []);
});

console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
