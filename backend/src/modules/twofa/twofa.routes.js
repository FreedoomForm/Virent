const express = require('express');
const router = express.Router();
const authModel = require('../../v1/models/auth.js');
const twofa = require('./twofa.service.js');

router.post('/setup', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => twofa.setup(res, req.admin, req.path));
router.post('/verify', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => twofa.verify(res, req.body, req.admin, req.path));
router.post('/disable', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => twofa.disable(res, req.body, req.admin, req.path));
router.post('/verify-login', (req, res) => twofa.verifyLogin(res, req.body, req.path));

module.exports = router;
