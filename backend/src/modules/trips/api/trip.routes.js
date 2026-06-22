/**
 * Trips routes — /v1/trips
 *
 * Per constitution §5: API paths use nouns, kebab-case actions via :action
 * Per constitution §5.5: list endpoints always have pagination
 */
const express = require('express');
const router = express.Router();
const controller = require('./trip.controller.js');
const authMiddleware = require('../../../shared/auth-middleware.js');

// User endpoints (require user JWT)
router.post('/reserve', authMiddleware.requireUser, controller.reserve);
router.post('/start',   authMiddleware.requireUser, controller.start);
router.post('/end',     authMiddleware.requireUser, controller.end);
router.post('/cancel',  authMiddleware.requireUser, controller.cancel);
router.get('/active',   authMiddleware.requireUser, controller.getActive);
router.get('/history',  authMiddleware.requireUser, controller.getHistory);
// Fare estimator (public — no auth required for estimation)
router.get("/estimate", async (req, res) => {
    const fareEstimator = require("../application/fare-estimator.js");
    return fareEstimator.estimate(res, req.query, req.path);
});

// Admin endpoints
router.get('/',         authMiddleware.requireAdmin, controller.listAll);
router.post('/refund',  authMiddleware.requireAdmin, controller.refund);

module.exports = router;
