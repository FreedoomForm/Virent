/** Geofencing routes — /v1/geofencing */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const geoModel = require("../models/geofencing.js");

// User: check a location (used by mobile app to show zone info)
router.post('/check',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => geoModel.checkLocation(res, req.body, req.path));

// User: get speed limit at current location
router.post('/speed-limit',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    async (req, res) => {
        const result = await geoModel.getSpeedLimit(req.body.coordinates);
        return res.status(200).json({ data: result });
    });

module.exports = router;
