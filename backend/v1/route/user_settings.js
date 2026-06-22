/** User settings routes — /v1/user-settings */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const settings = require("../models/user_settings.js");

router.get('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => settings.get(res, req.user, req.path));

router.put('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => settings.update(res, req.body, req.user, req.path));

module.exports = router;
