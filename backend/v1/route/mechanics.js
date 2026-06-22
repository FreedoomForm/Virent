/** Mechanics routes — /v1/mechanics */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const mechanicsModel = require("../models/mechanics.js");

function mechanicAuth(req, res, next) {
    authModel.userCheckToken(req, res, () => {
        if (req.user.role !== 'mechanic') {
            return res.status(403).json({ errors: { status: 403,
                source: req.path, title: "Mechanic access required" }});
        }
        next();
    });
}

// Admin: register mechanic
router.post('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => mechanicsModel.register(res, req.body, req.path));

// Admin: list maintenance requests
router.get('/requests',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => mechanicsModel.listRequests(res, req.query, req.path));

// Admin: create maintenance request
router.post('/requests',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => mechanicsModel.createRequest(res, req.body, req.path));

// Admin: assign mechanic to request
router.post('/requests/:id/assign',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => mechanicsModel.assignRequest(res, req.params.id, req.body, req.path));

// Admin: inventory
router.get('/inventory',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => mechanicsModel.getInventory(res, req.path));

router.post('/inventory/restock',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => mechanicsModel.restock(res, req.body, req.path));

// Mechanic endpoints
router.get('/me/requests',
    (req, res, next) => mechanicAuth(req, res, next),
    (req, res) => mechanicsModel.myRequests(res, req.user, req.query, req.path));

router.post('/requests/:id/start',
    (req, res, next) => mechanicAuth(req, res, next),
    (req, res) => mechanicsModel.startWork(res, req.params.id, req.user, req.path));

router.post('/requests/:id/complete',
    (req, res, next) => mechanicAuth(req, res, next),
    (req, res) => mechanicsModel.completeWork(res, req.params.id, req.body, req.user, req.path));

router.post('/requests/:id/escalate',
    (req, res, next) => mechanicAuth(req, res, next),
    (req, res) => mechanicsModel.escalate(res, req.params.id, req.body, req.user, req.path));

module.exports = router;
