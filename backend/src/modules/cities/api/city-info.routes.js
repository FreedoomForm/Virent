const express = require('express');
const router = express.Router();
const cityInfo = require('../application/city-info.service.js');
router.get('/', (req, res) => cityInfo.list(res));
router.get('/:id', (req, res) => cityInfo.detail(res, req.params.id));
module.exports = router;
