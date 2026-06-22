/** SMS routes — mounted at /v1/sms */
const express = require('express');
const router = express.Router();
const sms = require("../models/sms.js");

router.post('/send-code',
    (req, res, next) => req.app.locals.otpLimiter(req, res, next),
    async (req, res) => {
        const phone = req.body.phone;
        const purpose = req.body.purpose || 'login';
        const result = await sms.sendOtp(phone, purpose);
        if (!result.ok) {
            return res.status(400).json({ errors: { status: 400,
                source: "/sms/send-code", title: "Failed", detail: result.error }});
        }
        return res.status(200).json({ data: { type: "success",
            phone: result.phone, expires_at: result.expires_at,
            ...(result.dev_code ? { dev_code: result.dev_code } : {}) }});
    });

router.post('/verify-code', async (req, res) => {
    const phone = req.body.phone;
    const code = req.body.code;
    const purpose = req.body.purpose || 'login';
    const result = await sms.verifyOtp(phone, code, purpose);
    if (!result.ok) {
        return res.status(401).json({ errors: { status: 401,
            source: "/sms/verify-code", title: "Verification failed",
            detail: result.error }});
    }
    return res.status(200).json({ data: { type: "success",
        phone: result.phone, message: "Verified" }});
});

module.exports = router;
