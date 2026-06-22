/** Notifications routes — /v1/notifications */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const notifModel = require("../models/notifications.js");

// User endpoints
router.post('/device',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => notifModel.registerDevice(res, req.body, req.user, req.path));

router.delete('/device',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => notifModel.unregisterDevice(res, req.body, req.user, req.path));

router.get('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => notifModel.listMine(res, req.query, req.user, req.path));

router.post('/:id/read',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => notifModel.markRead(res, req.params.id, req.user, req.path));

// Admin: broadcast
router.post('/broadcast',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => notifModel.broadcast(res, req.body, req.path));

module.exports = router;
