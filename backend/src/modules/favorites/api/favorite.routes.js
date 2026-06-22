const express = require('express');
const router = express.Router();
const authModel = require('../../../v1/models/auth.js');
const favService = require('../favorite.service.js');
router.get('/', (req, res, next) => authModel.userCheckToken(req, res, next), async (req, res) => {
    const favs = await favService.list(req.user.id);
    res.status(200).json({ data: { favorites: favs }});
});
router.post('/', (req, res, next) => authModel.userCheckToken(req, res, next), async (req, res) => {
    try { const fav = await favService.add(req.user.id, req.body);
        res.status(201).json({ data: { type: 'success', favorite: fav }});
    } catch (e) { res.status(400).json({ errors: { detail: e.message }}); }
});
router.delete('/:id', (req, res, next) => authModel.userCheckToken(req, res, next), async (req, res) => {
    const ok = await favService.remove(req.user.id, req.params.id);
    res.status(ok ? 200 : 404).json({ data: { type: ok ? 'success' : 'not_found' }});
});
module.exports = router;
