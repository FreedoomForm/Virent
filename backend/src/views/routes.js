/**
 * Views routes — /v1/views/*
 *
 * Per constitution §1.4 + §6: View API (BFF) for complex screens.
 * One endpoint aggregates all data for a screen via request tree.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../shared/auth-middleware.js');
const { getDashboard } = require('./dashboard.view.js');
const { getTripDetail } = require('./trip-detail.view.js');

// Admin views
router.get('/dashboard', authMiddleware.requireAdmin, getDashboard);

// User/Admin views
router.get('/trip-detail/:tripId',
    authMiddleware.requireUser, getTripDetail);

module.exports = router;
