const express = require('express');
const router = express.Router();
const authModel = require('../../v1/models/auth.js');
const legalService = require('./legal.service.js');
router.get('/terms', (req, res) => legalService.getTerms(res, req.query.lang));
router.get('/privacy', (req, res) => legalService.getPrivacy(res, req.query.lang));
router.post('/terms', (req, res, next) => authModel.checkValidAdmin(req, res, next), (req, res) => legalService.saveTerms(res, req.body));
module.exports = router;
