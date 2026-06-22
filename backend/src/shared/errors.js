/**
 * errors.js — Centralized error system
 *
 * Every error has:
 *   - stable machine code (UPPER_SNAKE_CASE)
 *   - human-readable message
 *   - HTTP status mapping
 *   - optional safe details (no PII)
 *
 * Usage:
 *   throw new AppError('TRIP_NOT_FOUND', { tripId: '...' });
 *   throw new ValidationError('email', 'Invalid email format');
 *   throw new AuthError('TOKEN_EXPIRED');
 */

class AppError extends Error {
    constructor(code, message, options = {}) {
        super(message || code);
        this.name = 'AppError';
        this.code = code;
        this.statusCode = options.statusCode || 500;
        this.details = options.details || {};
        this.isOperational = options.isOperational !== false;
        Error.captureStackTrace(this, this.constructor);
    }

    toJSON() {
        return {
            error: {
                code: this.code,
                message: this.message,
                details: this.details,
            },
        };
    }
}

class ValidationError extends AppError {
    constructor(field, message, details = {}) {
        super('VALIDATION_FAILED', `Field "${field}": ${message}`, {
            statusCode: 400,
            details: { field, ...details },
        });
        this.name = 'ValidationError';
        this.field = field;
    }
}

class AuthError extends AppError {
    constructor(code, message, details = {}) {
        super(code, message, { statusCode: 401, details });
        this.name = 'AuthError';
    }
}

class ForbiddenError extends AppError {
    constructor(code = 'PERMISSION_DENIED', message = 'Permission denied', details = {}) {
        super(code, message, { statusCode: 403, details });
        this.name = 'ForbiddenError';
    }
}

class NotFoundError extends AppError {
    constructor(resource, id, details = {}) {
        // Convert resource to snake_case code, e.g. 'active_trip' → 'ACTIVE_TRIP_NOT_FOUND'
        const code = `${resource.toUpperCase()}_NOT_FOUND`;
        super(code,
            `${resource} not found${id ? `: ${id}` : ''}`,
            { statusCode: 404, details: { resource, id, ...details } });
        this.name = 'NotFoundError';
    }
}

class ConflictError extends AppError {
    constructor(code, message, details = {}) {
        super(code, message, { statusCode: 409, details });
        this.name = 'ConflictError';
    }
}

class RateLimitError extends AppError {
    constructor(code = 'RATE_LIMIT_EXCEEDED', message = 'Too many requests', details = {}) {
        super(code, message, { statusCode: 429, details });
        this.name = 'RateLimitError';
    }
}

// Stable error code catalog (per constitution §8.3 + §16)
const ERROR_CODES = {
    // Validation
    VALIDATION_FAILED: 400,
    INVALID_INPUT: 400,
    MISSING_FIELD: 400,

    // Auth
    UNAUTHORIZED: 401,
    TOKEN_EXPIRED: 401,
    TOKEN_INVALID: 401,
    INVALID_CREDENTIALS: 401,
    OTP_INVALID: 401,
    OTP_EXPIRED: 401,

    // Forbidden
    PERMISSION_DENIED: 403,
    NOT_ADMIN: 403,
    NOT_OWNER: 403,
    NOT_JUICER: 403,
    NOT_MECHANIC: 403,

    // Not found
    USER_NOT_FOUND: 404,
    SCOOTER_NOT_FOUND: 404,
    TRIP_NOT_FOUND: 404,
    CITY_NOT_FOUND: 404,
    TICKET_NOT_FOUND: 404,
    TRANSACTION_NOT_FOUND: 404,

    // Conflict
    SCOOTER_NOT_AVAILABLE: 409,
    SCOOTER_ALREADY_RESERVED: 409,
    USER_ALREADY_EXISTS: 409,
    DUPLICATE_PROMO_CODE: 409,
    ACTIVE_TRIP_EXISTS: 409,

    // Business rules
    INSUFFICIENT_BALANCE: 422,
    TRIP_NOT_ACTIVE: 422,
    RESERVATION_EXPIRED: 410,
    LOW_BATTERY: 422,

    // Rate limit
    RATE_LIMIT_EXCEEDED: 429,
    TOO_MANY_OTP_REQUESTS: 429,

    // Server
    INTERNAL_ERROR: 500,
    PROVIDER_NOT_CONFIGURED: 503,
};

function toErrorResponse(err, requestId) {
    if (err instanceof AppError) {
        return {
            error: {
                code: err.code,
                message: err.message,
                details: err.details,
                requestId,
            },
        };
    }
    // Unknown error — don't leak internals
    return {
        error: {
            code: 'INTERNAL_ERROR',
            message: 'An error occurred',
            details: process.env.NODE_ENV === 'production' ? {} : { original: err.message },
            requestId,
        },
    };
}

module.exports = {
    AppError,
    ValidationError,
    AuthError,
    ForbiddenError,
    NotFoundError,
    ConflictError,
    RateLimitError,
    ERROR_CODES,
    toErrorResponse,
};
