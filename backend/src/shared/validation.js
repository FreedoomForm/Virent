/**
 * validation.js — input validation helpers
 *
 * Per constitution §19: input validation is mandatory security baseline.
 * Uses simple predicate functions — no heavy dependency.
 */

const { ValidationError } = require('./errors.js');

function isString(v, max = 1000) {
    return typeof v === 'string' && v.length > 0 && v.length <= max;
}

function isNonEmptyString(v, max = 1000) {
    return typeof v === 'string' && v.trim().length > 0 && v.length <= max;
}

function isEmail(v) {
    return typeof v === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) && v.length <= 254;
}

function isPhone(v) {
    // +998901234567, 998901234567, 901234567
    if (typeof v !== 'string') return false;
    const cleaned = v.replace(/[^\d+]/g, '');
    if (cleaned.startsWith('+')) {
        return /^\+\d{9,15}$/.test(cleaned);
    }
    return /^\d{9,15}$/.test(cleaned);
}

function isInt(v, min = -Infinity, max = Infinity) {
    if (typeof v === 'number') return Number.isInteger(v) && v >= min && v <= max;
    if (typeof v === 'string') {
        // Strict integer string — no decimals, no scientific notation
        if (!/^-?\d+$/.test(v.trim())) return false;
        const n = parseInt(v, 10);
        return !isNaN(n) && Number.isInteger(n) && n >= min && n <= max;
    }
    return false;
}

function isFloat(v, min = -Infinity, max = Infinity) {
    const n = typeof v === 'string' ? parseFloat(v) : v;
    return typeof n === 'number' && !isNaN(n) && isFinite(n) && n >= min && n <= max;
}

function isObjectId(v) {
    return typeof v === 'string' && /^[0-9a-fA-F]{24}$/.test(v);
}

function isIsoDate(v) {
    if (typeof v !== 'string') return false;
    const d = new Date(v);
    return !isNaN(d.getTime()) && v.includes('T');
}

function isIn(v, allowed) {
    return allowed.includes(v);
}

/**
 * Validate object against schema. Throws ValidationError on first failure.
 *
 * Schema format:
 * {
 *   email: { type: 'email', required: true },
 *   age: { type: 'int', min: 18, max: 120, required: true },
 *   role: { type: 'in', values: ['admin','user'], default: 'user' },
 * }
 */
function validate(input, schema) {
    const out = {};
    for (const [field, rule] of Object.entries(schema)) {
        let v = input[field];
        if (v === undefined || v === null) {
            if (rule.default !== undefined) {
                out[field] = rule.default;
                continue;
            }
            if (rule.required) {
                throw new ValidationError(field, 'is required');
            }
            continue;
        }
        let ok = true;
        switch (rule.type) {
            case 'string': ok = isString(v, rule.max || 1000); break;
            case 'nonEmptyString': ok = isNonEmptyString(v, rule.max || 1000); break;
            case 'email': ok = isEmail(v); break;
            case 'phone': ok = isPhone(v); break;
            case 'int': ok = isInt(v, rule.min ?? -Infinity, rule.max ?? Infinity); break;
            case 'float': ok = isFloat(v, rule.min ?? -Infinity, rule.max ?? Infinity); break;
            case 'objectId': ok = isObjectId(v); break;
            case 'isoDate': ok = isIsoDate(v); break;
            case 'in': ok = isIn(v, rule.values); break;
            case 'boolean': ok = typeof v === 'boolean'; break;
            case 'object': ok = typeof v === 'object' && v !== null && !Array.isArray(v); break;
            case 'array': ok = Array.isArray(v); break;
            default: ok = true; // unknown type — allow
        }
        if (!ok) {
            throw new ValidationError(field, `has invalid value: ${JSON.stringify(v).slice(0, 100)}`);
        }
        // Coercion
        if (rule.type === 'int') out[field] = parseInt(v, 10);
        else if (rule.type === 'float') out[field] = parseFloat(v);
        else if (rule.type === 'boolean' && typeof v === 'string') {
            out[field] = v === 'true' || v === '1';
        } else out[field] = v;
    }
    return out;
}

module.exports = {
    isString, isNonEmptyString, isEmail, isPhone, isInt, isFloat,
    isObjectId, isIsoDate, isIn, validate,
};
