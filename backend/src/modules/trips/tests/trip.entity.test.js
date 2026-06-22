/**
 * Trip entity tests
 *
 * Per constitution §21: unit tests for domain rules, policies, mappers
 * Run: node src/modules/trips/tests/trip.entity.test.js
 */

const assert = require('assert');
const { Trip, Coordinates, TRIP_TRANSITIONS } = require('../domain/trip.entity.js');

let passed = 0, failed = 0;

function test(name, fn) {
    try { fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}

console.log('\n=== Trip Entity Tests ===\n');

test('Coordinates parses string values', () => {
    const c = new Coordinates('65.7850', '38.8600');
    assert.strictEqual(c.longitude, 65.7850);
    assert.strictEqual(c.latitude, 38.8600);
});

test('Coordinates rejects invalid values', () => {
    assert.throws(() => new Coordinates('not-a-number', '38.8600'), /Invalid/);
    assert.throws(() => new Coordinates(200, 38.86), /Invalid/);  // lng > 180
    assert.throws(() => new Coordinates(65.78, 95), /Invalid/);   // lat > 90
});

test('Coordinates.toJSON returns string format', () => {
    const c = new Coordinates(65.785, 38.86);
    const j = c.toJSON();
    assert.strictEqual(typeof j.longitude, 'string');
    assert.strictEqual(typeof j.latitude, 'string');
});

test('Trip.canTransitionTo respects state machine', () => {
    const reserved = new Trip({ status: 'reserved' });
    assert.strictEqual(reserved.canTransitionTo('active'), true);
    assert.strictEqual(reserved.canTransitionTo('ended'), false);
    assert.strictEqual(reserved.canTransitionTo('cancelled'), true);

    const active = new Trip({ status: 'active' });
    assert.strictEqual(active.canTransitionTo('ended'), true);
    assert.strictEqual(active.canTransitionTo('cancelled'), true);
    assert.strictEqual(active.canTransitionTo('reserved'), false);

    const ended = new Trip({ status: 'ended' });
    assert.strictEqual(ended.canTransitionTo('active'), false);
    assert.strictEqual(ended.canTransitionTo('cancelled'), false);
});

test('Trip.isActive/isReserved/isEnded', () => {
    assert.strictEqual(new Trip({ status: 'active' }).isActive(), true);
    assert.strictEqual(new Trip({ status: 'reserved' }).isReserved(), true);
    assert.strictEqual(new Trip({ status: 'ended' }).isEnded(), true);
    assert.strictEqual(new Trip({ status: 'cancelled' }).isEnded(), true);
    assert.strictEqual(new Trip({ status: 'expired' }).isEnded(), true);
    assert.strictEqual(new Trip({ status: 'active' }).isEnded(), false);
});

test('Trip.isReservationExpired', () => {
    const past = new Date(Date.now() - 1000);
    const future = new Date(Date.now() + 600000);

    const expired = new Trip({ status: 'reserved', reservation_expires: past });
    const notExpired = new Trip({ status: 'reserved', reservation_expires: future });
    const active = new Trip({ status: 'active', reservation_expires: past });

    assert.strictEqual(expired.isReservationExpired(), true);
    assert.strictEqual(notExpired.isReservationExpired(), false);
    assert.strictEqual(active.isReservationExpired(), false);  // active, not reserved
});

test('Trip.calculateCost: base + time only (street zone)', () => {
    const city = {
        fixedRate: 100, timeRate: 10,
        parkingZoneRate: 20, bonusParkingZoneRate: 30,
        noParkingZoneRate: 50,
    };
    const result = Trip.calculateCost({ durationMin: 5, city, endZoneType: 'street' });
    // base=100, time=5*10=50, discount=0, fee=50 (street = no_parking fee)
    assert.strictEqual(result.total, 200);
    assert.strictEqual(result.base, 100);
    assert.strictEqual(result.time, 50);
    assert.strictEqual(result.discount, 0);
    assert.strictEqual(result.fee, 50);
});

test('Trip.calculateCost: parking zone discount', () => {
    const city = {
        fixedRate: 100, timeRate: 10,
        parkingZoneRate: 20, bonusParkingZoneRate: 30,
        noParkingZoneRate: 50,
    };
    const result = Trip.calculateCost({ durationMin: 5, city, endZoneType: 'parking' });
    // base=100, time=50, discount=20 (parking), fee=0
    assert.strictEqual(result.total, 130);
    assert.strictEqual(result.discount, 20);
    assert.strictEqual(result.fee, 0);
});

test('Trip.calculateCost: bonus zone bigger discount', () => {
    const city = {
        fixedRate: 100, timeRate: 10,
        parkingZoneRate: 20, bonusParkingZoneRate: 30,
        noParkingZoneRate: 50,
    };
    const result = Trip.calculateCost({ durationMin: 5, city, endZoneType: 'bonus_parking' });
    // base=100, time=50, discount=30 (bonus), fee=0
    assert.strictEqual(result.total, 120);
    assert.strictEqual(result.discount, 30);
});

test('Trip.calculateCost: no-parking zone adds fee', () => {
    const city = {
        fixedRate: 100, timeRate: 10,
        parkingZoneRate: 20, bonusParkingZoneRate: 30,
        noParkingZoneRate: 50,
    };
    const result = Trip.calculateCost({ durationMin: 5, city, endZoneType: 'no_parking' });
    // base=100, time=50, discount=0, fee=50 (no_parking)
    assert.strictEqual(result.total, 200);
    assert.strictEqual(result.fee, 50);
});

test('Trip.calculateCost: minimum 1 minute', () => {
    const city = { fixedRate: 100, timeRate: 10 };
    const result = Trip.calculateCost({ durationMin: 0, city, endZoneType: 'parking' });
    // base=100, time=10 (1min minimum), discount=0 (city has no parkingZoneRate)
    assert.strictEqual(result.time, 10);
});

test('Trip.calculateCost: never negative', () => {
    const city = { fixedRate: 0, timeRate: 0, parkingZoneRate: 1000 };  // huge discount
    const result = Trip.calculateCost({ durationMin: 1, city, endZoneType: 'parking' });
    assert.ok(result.total >= 0, `Expected >= 0, got ${result.total}`);
});

test('Trip.calculateCost: includes breakdown with city_rates', () => {
    const city = { fixedRate: 100, timeRate: 10, parkingZoneRate: 20 };
    const result = Trip.calculateCost({ durationMin: 5, city, endZoneType: 'parking' });
    assert.ok(result.breakdown.city_rates);
    assert.strictEqual(result.breakdown.city_rates.fixedRate, 100);
    assert.strictEqual(result.breakdown.city_rates.timeRate, 10);
});

console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
