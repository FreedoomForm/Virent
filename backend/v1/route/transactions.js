/** Transactions routes — mounted at /v1/transactions */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const txModel = require("../models/transactions.js");

// User: list my transactions
router.get('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => txModel.getTransactions(res, req.query, req.user, false, req.path));

// Admin: list any user's transactions
router.get('/admin',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => txModel.getTransactions(res, req.query, req.user, true, req.path));

// Initiate top-up
router.post('/topup/click',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => txModel.initClickTopup(res, req.body, req.user, req.path));

router.post('/topup/payme',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => txModel.initPaymeTopup(res, req.body, req.user, req.path));

// Webhooks (called by Click/Payme servers)
router.post('/webhooks/click', (req, res) => txModel.clickWebhook(res, req.body, req.path));
router.post('/webhooks/payme', (req, res) => txModel.paymeWebhook(res, req.body, req.path));

module.exports = router;
