/**
 * auth-middleware.js — bridge between legacy v1 auth and new modular architecture
 *
 * The legacy auth.js (v1/models/auth.js) still handles JWT verification.
 * This middleware wraps it with cleaner semantics:
 *   requireUser    — must be authenticated as a user
 *   requireAdmin   — must be authenticated as an admin
 *   requireJuicer  — must be authenticated as a juicer
 *   requireMechanic — must be authenticated as a mechanic
 *   optional       — may or may not be authenticated
 */

const authModel = require('../../v1/models/auth.js');
const { AuthError, ForbiddenError } = require('./errors.js');

function wrap(checkFn) {
    return (req, res, next) => {
        // Check API key first
        authModel.checkAPIKey(req, res, (err) => {
            if (err) return next(err);
            checkFn(req, res, next);
        });
    };
}

const requireUser = wrap((req, res, next) => {
    authModel.userCheckToken(req, res, (err) => {
        if (err) return next(err);
        if (!req.user || !req.user.id) {
            return next(new AuthError('UNAUTHORIZED', 'Authentication required'));
        }
        next();
    });
});

const requireAdmin = wrap((req, res, next) => {
    authModel.checkValidAdmin(req, res, (err) => {
        if (err) return next(err);
        if (!req.admin || !req.admin.email) {
            return next(new AuthError('NOT_ADMIN', 'Admin access required'));
        }
        next();
    });
});

const requireJuicer = wrap((req, res, next) => {
    authModel.userCheckToken(req, res, (err) => {
        if (err) return next(err);
        if (!req.user || req.user.role !== 'juicer') {
            return next(new ForbiddenError('NOT_JUICER', 'Juicer access required'));
        }
        next();
    });
});

const requireMechanic = wrap((req, res, next) => {
    authModel.userCheckToken(req, res, (err) => {
        if (err) return next(err);
        if (!req.user || req.user.role !== 'mechanic') {
            return next(new ForbiddenError('NOT_MECHANIC', 'Mechanic access required'));
        }
        next();
    });
});

const optional = wrap((req, res, next) => {
    const token = req.headers['x-access-token'];
    if (!token) return next();
    authModel.userCheckToken(req, res, () => next());
});

module.exports = { requireUser, requireAdmin, requireJuicer, requireMechanic, optional };
