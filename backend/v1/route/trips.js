/**
 * Trips routes — /v1/trips
 */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const tripsModel = require("../models/trips.js");

// All trip routes require authentication (user or admin depending on route)
// authModel.checkAPIKey runs globally via v1/index.js

// User-scoped endpoints (require user JWT)
router.post('/reserve',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => tripsModel.reserveScooter(res, req.body, req.user, req.path));

router.post('/start',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => tripsModel.startTrip(res, req.body, req.user, req.path));

router.post('/end',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => tripsModel.endTrip(res, req.body, req.user, req.path));

router.post('/cancel',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => tripsModel.cancelTrip(res, req.body, req.user, req.path));

router.get('/active',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => tripsModel.getActiveTrip(res, req.user, req.path));

router.get('/history',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => tripsModel.getTripHistory(res, req.query, req.user, req.path));

// Admin endpoints
router.get('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => tripsModel.getAllTrips(res, req.query, req.path));

router.post('/refund',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => tripsModel.refundTrip(res, req.body, req.path));

module.exports = router;
