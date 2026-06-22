/**
 * permissions.js — centralized authorization policies
 *
 * Per constitution §19.1: separate AuthN (who are you?) from AuthZ (what can you do?)
 * Per constitution §19.2: permissions centralized, not scattered in controllers
 */

const { ForbiddenError } = require('./errors.js');

const ROLES = {
    USER: 'user',
    ADMIN: 'admin',
    JUICER: 'juicer',
    MECHANIC: 'mechanic',
    SUPPORT: 'support',
};

const POLICIES = {
    // User can access their own data
    'user.readOwn': (user, resource) => user && resource && String(user.id) === String(resource.user_id || resource._id),
    'user.updateOwn': (user, resource) => user && resource && String(user.id) === String(resource.user_id || resource._id),

    // Trip ownership
    'trip.readOwn': (user, trip) => user && trip && String(user.id) === String(trip.user_id),
    'trip.cancelOwn': (user, trip) => user && trip && String(user.id) === String(trip.user_id),
    'trip.endOwn': (user, trip) => user && trip && String(user.id) === String(trip.user_id),

    // Admin powers
    'admin.any': (user) => user && user.role === ROLES.ADMIN,
    'admin.refundTrip': (user) => user && user.role === ROLES.ADMIN,
    'admin.createPromo': (user) => user && user.role === ROLES.ADMIN,
    'admin.createScooter': (user) => user && user.role === ROLES.ADMIN,
    'admin.deleteScooter': (user) => user && user.role === ROLES.ADMIN,
    'admin.broadcast': (user) => user && user.role === ROLES.ADMIN,

    // Juicer powers
    'juicer.claimTask': (user) => user && user.role === ROLES.JUICER,
    'juicer.ownTask': (user, task) => user && task && String(user.id) === String(task.juicer_id),

    // Mechanic powers
    'mechanic.ownRequest': (user, req) => user && req && String(user.id) === String(req.mechanic_id),
};

/**
 * Check policy. Throws ForbiddenError if denied.
 */
function can(user, policyName, resource = null) {
    const policy = POLICIES[policyName];
    if (!policy) {
        throw new Error(`Unknown policy: ${policyName}`);
    }
    if (!policy(user, resource)) {
        throw new ForbiddenError(policyName, `You don't have permission: ${policyName}`);
    }
    return true;
}

/**
 * Soft check — returns boolean
 */
function canDo(user, policyName, resource = null) {
    const policy = POLICIES[policyName];
    if (!policy) return false;
    return policy(user, resource);
}

module.exports = { ROLES, POLICIES, can, canDo };
