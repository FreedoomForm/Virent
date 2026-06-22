/** Discovery routes — /v1/discovery */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const discovery = require("../models/discovery.js");

// User endpoints
router.get('/nearest',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => discovery.nearest(res, req.query, req.path));

router.get('/available',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => discovery.availableInCity(res, req.query, req.path));

router.get('/qr/:code',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => discovery.resolveQr(res, req.params.code, req.path));

module.exports = router;
