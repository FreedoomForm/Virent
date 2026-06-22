/** Promocodes routes — /v1/promocodes */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const promoModel = require("../models/promocodes.js");

// User: redeem a promo code (preview discount)
router.post('/redeem',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => promoModel.redeem(res, req.body, req.user, req.path));

// User: get my referral code
router.get('/referral',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => promoModel.getMyReferral(res, req.user, req.path));

// Admin: list all promo codes
router.get('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => promoModel.listAll(res, req.query, req.path));

// Admin: create promo code
router.post('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => promoModel.create(res, req.body, req.path));

// Admin: disable promo code
router.delete('/:code',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => promoModel.disable(res, req.params.code, req.path));

module.exports = router;
