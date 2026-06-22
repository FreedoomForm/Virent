/**
 * Trip controller contract tests
 * Per constitution §21: contract tests for request/response schema
 */
const assert = require('assert');
let passed = 0, failed = 0;
function test(name, fn) {
    try { fn(); passed++; console.log(`  ✓ ${name}`); }
    catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`); }
}
console.log('\n=== Trip Controller Contract Tests ===\n');

test('trip DTO toListItem has required fields', () => {
    const { toListItem } = require('../contracts/trip.dto.js');
    const dto = toListItem({ _id: 'abc123', status: 'ended', duration_min: 5, cost: 100, user_id: 'u1', scooter_id: 's1', start_time: new Date(), end_time: new Date(), end_zone_type: 'parking' });
    assert.ok(dto.id);
    assert.ok(dto.status);
    assert.ok(dto.duration_min !== undefined);
    assert.ok(dto.cost !== undefined);
    assert.ok(dto.scooter_id);
    assert.ok(dto.user_id);
});

test('trip DTO toDetail has all fields', () => {
    const { toDetail } = require('../contracts/trip.dto.js');
    const dto = toDetail({ _id: 'abc', user_id: 'u', scooter_id: 's', city_id: 'c', status: 'ended', start_time: new Date(), end_time: new Date(), reservation_time: new Date(), reservation_expires: new Date(), start_coordinates: {}, end_coordinates: {}, start_battery: 90, end_battery: 85, cost: 100, cost_breakdown: {}, created_at: new Date(), updated_at: new Date() });
    assert.strictEqual(dto.id, 'abc');
    assert.strictEqual(dto.status, 'ended');
    assert.ok(dto.start_time);
    assert.ok(dto.end_time);
    assert.ok(dto.cost_breakdown);
    assert.ok(dto.created_at);
});

test('trip DTO toSummary is minimal', () => {
    const { toSummary } = require('../contracts/trip.dto.js');
    const dto = toSummary({ _id: 'abc', status: 'ended', cost: 100, start_time: new Date() });
    assert.strictEqual(Object.keys(dto).length, 4); // id, status, cost, start_time
});

test('trip entity calculateCost returns all fields', () => {
    const { Trip } = require('../domain/trip.entity.js');
    const result = Trip.calculateCost({ durationMin: 5, city: { fixedRate: 100, timeRate: 10 }, endZoneType: 'parking' });
    assert.ok('base' in result);
    assert.ok('time' in result);
    assert.ok('discount' in result);
    assert.ok('fee' in result);
    assert.ok('total' in result);
    assert.ok('breakdown' in result);
    assert.ok('breakdown' in result && 'city_rates' in result.breakdown);
});

test('HTTP response format: list response has data array + meta.page', () => {
    const { listResponse } = require('../../../shared/http.js');
    const resp = listResponse([{id:1}], { requestId: 'req_1', limit: 25, offset: 0, total: 1 });
    assert.ok(Array.isArray(resp.data));
    assert.ok(resp.meta.page);
    assert.strictEqual(resp.meta.page.limit, 25);
    assert.strictEqual(resp.meta.page.total, 1);
});

test('HTTP response format: item response has data + meta.requestId', () => {
    const { itemResponse } = require('../../../shared/http.js');
    const resp = itemResponse({id:1}, 'req_123');
    assert.ok(resp.data);
    assert.strictEqual(resp.meta.requestId, 'req_123');
});

test('HTTP response format: error response has error.code + message + requestId', () => {
    const { errorResponse } = require('../../../shared/http.js');
    const resp = errorResponse('NOT_FOUND', 'Resource not found', { id: '123' }, 'req_456');
    assert.ok(resp.error);
    assert.strictEqual(resp.error.code, 'NOT_FOUND');
    assert.strictEqual(resp.error.message, 'Resource not found');
    assert.strictEqual(resp.error.requestId, 'req_456');
});

test('pagination parses sort direction', () => {
    const { parsePagination } = require('../../../shared/http.js');
    const p = parsePagination({ sort: '-createdAt,name', limit: '10' });
    assert.strictEqual(p.sort.createdAt, -1);
    assert.strictEqual(p.sort.name, 1);
    assert.strictEqual(p.limit, 10);
});

test('pagination enforces max limit', () => {
    const { parsePagination } = require('../../../shared/http.js');
    const p = parsePagination({ limit: '500' });
    assert.ok(p.limit <= 100);
});

console.log(`\n=== ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
