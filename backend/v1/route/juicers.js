/** Juicers routes — /v1/juicers */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const juicersModel = require("../models/juicers.js");

// Custom middleware: juicer auth (separate from admin/user)
// For simplicity, juicers authenticate with their phone + SMS code,
// then use a JWT with role='juicer'. We use userCheckToken + role check.
function juicerAuth(req, res, next) {
    authModel.userCheckToken(req, res, () => {
        if (req.user.role !== 'juicer') {
            return res.status(403).json({ errors: { status: 403,
                source: req.path, title: "Juicer access required" }});
        }
        next();
    });
}

// Admin endpoints
router.post('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => juicersModel.register(res, req.body, req.path));

router.get('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => juicersModel.list(res, req.query, req.path));

// Juicer endpoints
router.get('/me/earnings',
    (req, res, next) => juicerAuth(req, res, next),
    (req, res) => juicersModel.myEarnings(res, req.user, req.path));

router.get('/tasks/available',
    (req, res, next) => juicerAuth(req, res, next),
    (req, res) => juicersModel.availableTasks(res, req.user, req.path));

router.post('/tasks/claim',
    (req, res, next) => juicerAuth(req, res, next),
    (req, res) => juicersModel.claimTask(res, req.body, req.user, req.path));

router.post('/tasks/:id/pickup',
    (req, res, next) => juicerAuth(req, res, next),
    (req, res) => juicersModel.markPickedUp(res, req.params.id, req.user, req.path));

router.post('/tasks/:id/charge',
    (req, res, next) => juicerAuth(req, res, next),
    (req, res) => juicersModel.markCharged(res, req.params.id, req.user, req.path));

router.post('/tasks/:id/return',
    (req, res, next) => juicerAuth(req, res, next),
    (req, res) => juicersModel.markReturned(res, req.params.id, req.body, req.user, req.path));

module.exports = router;
