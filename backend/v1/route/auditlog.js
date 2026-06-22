/** Audit log routes — /v1/audit-log (admin only) */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const auditlog = require("../models/auditlog.js");

router.get('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => auditlog.query(res, req.query, req.path));

module.exports = router;
