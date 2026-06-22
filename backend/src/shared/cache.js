/**
 * cache.js — Simple in-process LRU cache with TTL
 *
 * Per constitution §15:
 *   - No cache without TTL
 *   - No cache without owner
 *   - Cache hit/miss logged
 *
 * Levels L0/L1 implemented here (request memoization + application memory).
 * L2 (Redis) is a separate module for production use.
 */

class LruCache {
    constructor(maxSize = 1000) {
        this.maxSize = maxSize;
        this.store = new Map(); // Map preserves insertion order
        this.hits = 0;
        this.misses = 0;
    }

    _key(namespace, key, version = 'v1') {
        return `${namespace}:${version}:${typeof key === 'string' ? key : JSON.stringify(key)}`;
    }

    get(namespace, key, version) {
        const k = this._key(namespace, key, version);
        const entry = this.store.get(k);
        if (!entry) {
            this.misses++;
            return null;
        }
        if (entry.expiresAt < Date.now()) {
            this.store.delete(k);
            this.misses++;
            return null;
        }
        // Move to end (LRU)
        this.store.delete(k);
        this.store.set(k, entry);
        this.hits++;
        return entry.value;
    }

    set(namespace, key, value, ttlSec = 60, version) {
        const k = this._key(namespace, key, version);
        if (this.store.size >= this.maxSize) {
            // Evict oldest
            const oldestKey = this.store.keys().next().value;
            this.store.delete(oldestKey);
        }
        this.store.set(k, {
            value,
            expiresAt: Date.now() + ttlSec * 1000,
            createdAt: Date.now(),
        });
    }

    invalidate(namespace, key, version) {
        if (key === undefined) {
            // Invalidate all keys in namespace
            const prefix = `${namespace}:`;
            for (const k of this.store.keys()) {
                if (k.startsWith(prefix)) this.store.delete(k);
            }
        } else {
            const k = this._key(namespace, key, version);
            this.store.delete(k);
        }
    }

    stats() {
        const total = this.hits + this.misses;
        return {
            size: this.store.size,
            maxSize: this.maxSize,
            hits: this.hits,
            misses: this.misses,
            hitRate: total > 0 ? this.hits / total : 0,
        };
    }

    clear() {
        this.store.clear();
        this.hits = 0;
        this.misses = 0;
    }
}

// Singleton cache for the whole app
const globalCache = new LruCache(2000);

/**
 * Helper: get-or-set pattern
 */
async function getOrSet(namespace, key, ttlSec, fetchFn, version) {
    const cached = globalCache.get(namespace, key, version);
    if (cached !== null) return cached;
    const fresh = await fetchFn();
    if (fresh !== null && fresh !== undefined) {
        globalCache.set(namespace, key, fresh, ttlSec, version);
    }
    return fresh;
}

module.exports = { LruCache, globalCache, getOrSet };
