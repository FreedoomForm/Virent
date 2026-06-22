/** Search routes — /v1/search */
const express = require('express');
const router = express.Router();
const authModel = require('../../v1/models/auth.js');
const searchService = require('./search.service.js');

router.get('/', (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => searchService.search(res, req.query, req.admin, req.path));

module.exports = router;
