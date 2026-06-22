/** Export routes — /v1/exports/* (admin only) */
const express = require('express');
const router = express.Router();
const authModel = require('../../v1/models/auth.js');
const exportService = require('./export.service.js');

router.get('/trips.csv', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => exportService.trips(res, req.query));
router.get('/transactions.csv', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => exportService.transactions(res, req.query));
router.get('/users.csv', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => exportService.users(res));
router.get('/scooters.csv', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => exportService.scooters(res));

module.exports = router;
