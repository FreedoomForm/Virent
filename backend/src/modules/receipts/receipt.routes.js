const express = require('express');
const router = express.Router();
const authModel = require('../../v1/models/auth.js');
const receiptService = require('./receipt.service.js');

router.get('/', (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => receiptService.listReceipts(res, req.user, req.query, req.path));

router.get('/:tripId', (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => receiptService.getReceipt(res, req.params.tripId, req.user, req.path));

module.exports = router;
