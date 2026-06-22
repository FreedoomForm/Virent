/** Stats routes — /v1/stats (admin only) */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const stats = require("../models/stats.js");

router.get('/overview',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => stats.overview(res, req.query, req.path));

router.get('/revenue',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => stats.revenueTimeSeries(res, req.query, req.path));

router.get('/trips',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => stats.tripsTimeSeries(res, req.query, req.path));

router.get('/fleet',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => stats.fleetUtilization(res, req.path));

module.exports = router;
