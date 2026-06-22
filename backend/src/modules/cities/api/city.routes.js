const express = require('express');
const router = express.Router();
const authModel = require('../../../v1/models/auth.js');
const cityService = require('../application/city.service.js');

// Admin: add zone to city
router.post('/:id/zones', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const zone = await cityService.addZone(req.params.id, req.body);
            res.status(201).json({ data: { type: 'success', zone }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

// Admin: remove zone
router.delete('/:id/zones/:zoneId', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const city = await cityService.removeZone(req.params.id, req.params.zoneId);
            res.status(200).json({ data: { type: 'success', city }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

// Admin: update zone
router.put('/:id/zones/:zoneId', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const zone = await cityService.updateZone(req.params.id, req.params.zoneId, req.body);
            res.status(200).json({ data: { type: 'success', zone }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

// Admin: update rates
router.put('/:id/rates', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const city = await cityService.updateRates(req.params.id, req.body);
            res.status(200).json({ data: { type: 'success', city }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

module.exports = router;
