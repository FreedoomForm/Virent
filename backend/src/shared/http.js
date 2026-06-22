/**
 * http.js — HTTP helpers: pagination, response formatters, requestId
 *
 * Per constitution §8: responses follow { data, meta } structure.
 * Lists have pagination in meta: { limit, nextCursor, hasMore }.
 */

const crypto = require('crypto');

/**
 * Generate unique request ID — used for log correlation and response meta
 */
function generateRequestId() {
    return 'req_' + crypto.randomBytes(8).toString('hex');
}

/**
 * Parse pagination params from query string.
 * Returns { limit, cursor, sort } with safe defaults.
 *
 * Per constitution §5.5: list endpoints always have limit, sort, filters
 * Per constitution §13.4: cursor pagination by default (we accept offset for backward compat)
 */
function parsePagination(query, options = {}) {
    const defaultLimit = options.defaultLimit || 25;
    const maxLimit = options.maxLimit || 100;

    const limit = Math.min(Math.max(parseInt(query.limit) || defaultLimit, 1), maxLimit);
    const offset = Math.max(parseInt(query.offset) || 0, 0);
    const cursor = query.cursor || null;

    // Sort: "-createdAt" or "createdAt" or "createdAt,-updatedAt"
    let sort = {};
    if (query.sort) {
        const parts = String(query.sort).split(',').map(s => s.trim()).filter(Boolean);
        for (const part of parts) {
            if (part.startsWith('-')) {
                sort[part.slice(1)] = -1;
            } else {
                sort[part] = 1;
            }
        }
    } else if (options.defaultSort) {
        sort = options.defaultSort;
    } else {
        sort = { created_at: -1 };
    }

    return { limit, offset, cursor, sort };
}

/**
 * Build list response — per constitution §8.2
 * {
 *   data: [...],
 *   meta: {
 *     requestId, page: { limit, offset, total, hasMore }
 *   }
 * }
 */
function listResponse(items, meta) {
    return {
        data: items,
        meta: {
            requestId: meta.requestId,
            page: {
                limit: meta.limit,
                offset: meta.offset,
                total: meta.total,
                hasMore: meta.offset + items.length < meta.total,
                nextOffset: meta.offset + items.length < meta.total
                    ? meta.offset + items.length : null,
            },
        },
    };
}

/**
 * Build single-item response — per constitution §8.1
 * { data: {...}, meta: { requestId } }
 */
function itemResponse(item, requestId) {
    return { data: item, meta: { requestId } };
}

/**
 * Build error response — per constitution §8.3
 * { error: { code, message, details, requestId } }
 */
function errorResponse(code, message, details, requestId) {
    return {
        error: {
            code,
            message,
            details: details || {},
            requestId,
        },
    };
}

module.exports = {
    generateRequestId,
    parsePagination,
    listResponse,
    itemResponse,
    errorResponse,
};
