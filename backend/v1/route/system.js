/** System routes — /v1/system (admin only) */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const system = require("../models/system.js");

router.get('/info',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => system.info(res, req.path));

module.exports = router;
