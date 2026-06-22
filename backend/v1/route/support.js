/** Support routes — /v1/support */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const supportModel = require("../models/support.js");

// User endpoints
router.post('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => supportModel.create(res, req.body, req.user, req.path));

router.get('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => supportModel.listMine(res, req.query, req.user, req.path));

router.get('/:id',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => supportModel.getMine(res, req.params.id, req.user, req.path));

router.post('/:id/message',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => supportModel.addMessage(res, req.params.id, req.body, req.user, req.path));

// Admin endpoints
router.get('/admin/list',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => supportModel.listAll(res, req.query, req.path));

router.post('/admin/:id/reply',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => supportModel.adminReply(res, req.params.id, req.body, req.admin, req.path));

module.exports = router;
