/** Uploads routes — /v1/uploads */
const express = require('express');
const router = express.Router();
const authModel = require("../models/auth.js");
const uploadsModel = require("../models/uploads.js");

// User: upload file (multipart/form-data with field "file")
router.post('/',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res, next) => req.app.locals.upload.single('file')(req, res, next),
    (req, res) => uploadsModel.uploadFile(res, req.file, req.user, req.body.purpose, req.path));

// Admin: list uploads
router.get('/',
    (req, res, next) => authModel.checkValidAdmin(req, res, next),
    (req, res) => uploadsModel.listUploads(res, req.query, req.path));

module.exports = router;
