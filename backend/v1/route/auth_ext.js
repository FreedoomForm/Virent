/**
 * auth_ext routes — extended authentication
 * Mounted at /v1/auth/...
 *
 * Endpoints:
 *   POST /auth/phone/send-code         — send SMS OTP (rate-limited)
 *   POST /auth/phone/login             — login/register with phone+OTP
 *   POST /auth/refresh                  — refresh access token
 *   POST /auth/logout                   — revoke refresh token
 *   POST /auth/forgot-password          — request SMS reset code
 *   POST /auth/reset-password           — reset password with code+new password
 *   POST /auth/change-password          — change password (logged in)
 *   POST /auth/accept-terms             — accept T&C
 */
const express = require('express');
const router = express.Router();
const authExt = require("../models/auth_ext.js");
const sms = require("../models/sms.js");
const authModel = require("../models/auth.js");

// Helper to get IP from request
function getIp(req) {
    return req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket.remoteAddress;
}

// Apply OTP rate limiter to code-sending endpoints
router.post('/phone/send-code',
    (req, res, next) => req.app.locals.otpLimiter(req, res, next),
    async (req, res) => {
        const phone = req.body.phone;
        const purpose = req.body.purpose || 'login';
        const result = await sms.sendOtp(phone, purpose);
        if (!result.ok) {
            return res.status(400).json({ errors: { status: 400,
                source: "/auth/phone/send-code",
                title: "Failed to send code", detail: result.error }});
        }
        return res.status(200).json({ data: {
            type: "success", message: "Code sent via SMS",
            phone: result.phone, expires_at: result.expires_at,
            // In dev mode, the actual code is returned for testing
            ...(result.dev_code ? { dev_code: result.dev_code } : {}),
        }});
    });

// Apply auth rate limiter to login attempts
router.post('/phone/login',
    (req, res, next) => req.app.locals.authLimiter(req, res, next),
    (req, res) => authExt.phoneLoginOrRegister(res, req.body, getIp(req), "/auth/phone/login"));

router.post('/refresh',
    (req, res) => authExt.refreshAccessToken(res, req.body, "/auth/refresh"));

router.post('/logout',
    (req, res, next) => {
        // Optional: require user token, but logout should work even with expired access
        next();
    },
    (req, res) => authExt.logout(res, req.body, "/auth/logout"));

router.post('/forgot-password',
    (req, res, next) => req.app.locals.otpLimiter(req, res, next),
    (req, res) => authExt.forgotPassword(res, req.body, "/auth/forgot-password"));

router.post('/reset-password',
    (req, res, next) => req.app.locals.authLimiter(req, res, next),
    (req, res) => authExt.resetPassword(res, req.body, "/auth/reset-password"));

// Change password requires user JWT
router.post('/change-password',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => authExt.changePassword(res, req.body, req.user, "/auth/change-password"));

router.post('/accept-terms',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => authExt.acceptTerms(res, req.body, req.user, "/auth/accept-terms"));

router.post('/logout-all',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => authExt.logoutAll(res, req.user, "/auth/logout-all"));

router.get('/sessions',
    (req, res, next) => authModel.userCheckToken(req, res, next),
    (req, res) => authExt.listSessions(res, req.user, "/auth/sessions"));

module.exports = router;
