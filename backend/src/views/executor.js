/**
 * views/executor.js — Request Tree executor
 *
 * Per constitution §6.2: backend executes request tree by:
 *   1. Accept request
 *   2. Check auth
 *   3. Check permissions
 *   4. Read sections param
 *   5. Build dependency tree
 *   6. Remove unwanted branches
 *   7. Check cache
 *   8. Group identical requests
 *   9. Execute independent nodes in parallel
 *  10. Limit concurrency
 *  11. Assemble response
 *  12. Write metrics/logs
 *
 * Each node has: id, useCase (function), priority (B0/B1/B2/B3),
 *                dependsOn (array of node ids), cache (ttlSec), required (bool).
 */

const logger = require('../shared/logger.js');
const { globalCache } = require('../shared/cache.js');

/**
 * Execute a request tree.
 *
 * @param tree: { sections: { main: { nodes: [...] }, tasks: { nodes: [...] } } }
 * @param requestedSections: ['main', 'tasks', 'stats'] — undefined = all required
 * @param context: { user, requestId, params, ... } — passed to each useCase
 *
 * @returns { data: { section: { nodeId: result } }, meta: { sections: { name: { ms, cache, error } } } }
 */
async function executeTree(tree, requestedSections, context) {
    const startTotal = Date.now();
    const result = { data: {} };
    const meta = { sections: {}, partial: false };

    // Filter sections
    const allSections = Object.keys(tree.sections);
    const sectionsToRun = requestedSections && requestedSections.length
        ? requestedSections.filter(s => allSections.includes(s))
        : allSections.filter(s => tree.sections[s].required !== false);

    if (requestedSections && sectionsToRun.length < requestedSections.length) {
        meta.partial = true;
    }

    // Shared state ACROSS sections — allows cross-section dependencies
    const sharedResults = {};
    const sharedExecuted = new Set();

    // Execute each section (sections can depend on previous sections' nodes)
    for (const sectionName of sectionsToRun) {
        const section = tree.sections[sectionName];
        const startSection = Date.now();
        try {
            const sectionResult = await executeSection(section, context, sharedResults, sharedExecuted);
            result.data[sectionName] = sectionResult.data;
            meta.sections[sectionName] = {
                ms: Date.now() - startSection,
                cache: sectionResult.cacheStatus,
                error: null,
            };
        } catch (err) {
            if (section.required !== false) {
                throw err;
            }
            meta.sections[sectionName] = {
                ms: Date.now() - startSection,
                cache: 'ERROR',
                error: err.message,
            };
            meta.partial = true;
        }
    }

    meta.totalMs = Date.now() - startTotal;
    return { data: result.data, meta };
}

async function executeSection(section, context, sharedResults = {}, sharedExecuted = new Set()) {
    const nodes = section.nodes;
    const cacheNs = section.cacheNamespace || 'view';
    const cacheVer = section.cacheVersion || 'v1';
    const cacheTtl = section.cacheTtlSec || 0;

    // Try section-level cache
    if (cacheTtl > 0) {
        const cacheKey = JSON.stringify({
            section: cacheNs, context: serializeContext(context, section.cacheContextKeys || []),
        });
        const cached = globalCache.get('view_section', cacheKey, cacheVer);
        if (cached) {
            // Mark all nodes in this section as executed for downstream sections
            for (const node of nodes) {
                sharedExecuted.add(node.id);
                sharedResults[node.id] = cached[node.id];
            }
            return { data: cached, cacheStatus: 'HIT' };
        }
    }

    const results = {};
    const remaining = [...nodes];

    let iterations = 0;
    while (remaining.length > 0 && iterations < 50) {
        iterations++;
        const readyNow = remaining.filter(n =>
            !n.dependsOn || n.dependsOn.every(d => sharedExecuted.has(d))
        );
        if (readyNow.length === 0) {
            throw new Error(`Cyclic or unresolvable dependency in section nodes: ${remaining.map(n => n.id).join(', ')}`);
        }
        await Promise.all(readyNow.map(async (node) => {
            const nodeContext = { ...context, deps: pickKeys(sharedResults, node.dependsOn || []) };
            if (node.cache && node.cache.ttlSec > 0) {
                const cacheKey = JSON.stringify({ node: node.id, ctx: serializeContext(nodeContext, node.cache.contextKeys || []) });
                let val = globalCache.get('view_node', cacheKey, cacheVer);
                if (val === null) {
                    val = await node.useCase(nodeContext);
                    globalCache.set('view_node', cacheKey, val, node.cache.ttlSec, cacheVer);
                }
                results[node.id] = val;
                sharedResults[node.id] = val;
            } else {
                const val = await node.useCase(nodeContext);
                results[node.id] = val;
                sharedResults[node.id] = val;
            }
            sharedExecuted.add(node.id);
        }));
        for (const n of readyNow) {
            const idx = remaining.indexOf(n);
            if (idx >= 0) remaining.splice(idx, 1);
        }
    }

    if (cacheTtl > 0) {
        const cacheKey = JSON.stringify({
            section: cacheNs, context: serializeContext(context, section.cacheContextKeys || []),
        });
        globalCache.set('view_section', cacheKey, results, cacheTtl, cacheVer);
    }

    return { data: results, cacheStatus: 'MISS' };
}

function pickKeys(obj, keys) {
    const out = {};
    for (const k of keys) {
        if (obj[k] !== undefined) out[k] = obj[k];
    }
    return out;
}

function serializeContext(ctx, keys) {
    if (!keys || !keys.length) return null;
    const out = {};
    for (const k of keys) {
        const v = ctx[k];
        if (v !== undefined) {
            // Only serializable primitives
            if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') {
                out[k] = v;
            } else if (v && v.id) {
                out[k] = String(v.id);
            }
        }
    }
    return out;
}

module.exports = { executeTree };
