const express = require('express');
const router = express.Router();
const authModel = require('../../../v1/models/auth.js');
const userService = require('../application/user.service.js');

// User updates own profile
router.put('/me', (req, res, next) => authModel.userCheckToken(req, res, next),
    async (req, res) => {
        try {
            const updated = await userService.updateProfile(req.user.id, req.body);
            res.status(200).json({ data: { type: 'success', user: updated }});
        } catch (e) {
            res.status(e.statusCode || 500).json({ errors: { status: e.statusCode || 500, detail: e.message }});
        }
    });

// Admin: block user
router.post('/:id/block', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const result = await userService.block(req.params.id, req.body.reason);
            res.status(200).json({ data: { type: 'success', user: result }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

// Admin: unblock user
router.post('/:id/unblock', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const result = await userService.unblock(req.params.id);
            res.status(200).json({ data: { type: 'success', user: result }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

// Admin: adjust balance
router.post('/:id/adjust-balance', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            const result = await userService.adjustBalance(req.params.id, req.body.amount, req.body.reason);
            res.status(200).json({ data: { type: 'success', ...result }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

// Admin: delete user (soft)
router.delete('/:id', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    async (req, res) => {
        try {
            await userService.delete(req.params.id);
            res.status(200).json({ data: { type: 'success', message: 'User deleted' }});
        } catch (e) { res.status(e.statusCode || 500).json({ errors: { detail: e.message }}); }
    });

module.exports = router;
