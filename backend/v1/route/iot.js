/** IoT routes — /v1/iot */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const iotModel = require("../models/iot.js");

// Scooter-to-server endpoints (use scooter_mac + secret instead of JWT)
router.post('/telemetry', (req, res) => iotModel.telemetry(res, req.body, req.path));
router.post('/event', (req, res) => iotModel.event(res, req.body, req.path));
router.get('/command', (req, res) => iotModel.pollCommand(res, req.query, req.path));

// Admin endpoints
router.post('/command/send',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => iotModel.sendCommand(res, req.body, req.path));

module.exports = router;
