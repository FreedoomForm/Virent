/**
 * auth.js — extended auth model
 *
 * Adds on top of original auth.js:
 *   - refresh tokens (30-day) + access tokens (15-min)
 *   - phone + SMS OTP login/register
 *   - forgot password via SMS
 *   - password reset
 *   - terms acceptance tracking
 *
 * Token storage: refresh tokens stored in `refresh_tokens` collection
 * with user_id, hashed token, expires_at, user_agent, ip.
 */
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require("mongodb");
const mongoURI = process.env.DBURI;
const api_token = process.env.API_TOKEN;
const jwtSecret = process.env.JWT_SECRET;
const refreshSecret = process.env.JWT_REFRESH_SECRET || (jwtSecret + '_refresh_v1');

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL_DAYS = 30;
const PASSWORD_RESET_TTL_MIN = 15;

const authExt = {
    /**
     * Login with phone + SMS OTP. If user doesn't exist, register automatically
     * (passwordless flow).
     */
    phoneLoginOrRegister: async function(res, body, ip, path) {
        const phone = sanitize(body.phone);
        const code = sanitize(body.code);

        if (!phone || !code) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Phone and code required" }});
        }

        const sms = require('./sms.js');
        const verifyResult = await sms.verifyOtp(phone, code, 'login');
        if (!verifyResult.ok) {
            return res.status(401).json({ errors: { status: 401, source: path,
                title: "OTP verification failed", detail: verifyResult.error }});
        }

        const normalizedPhone = verifyResult.phone;
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const usersCol = db.collection("users");

            let user = await usersCol.findOne({ phoneNumber: normalizedPhone });
            let isNewUser = false;
            if (!user) {
                // Auto-register
                isNewUser = true;
                const insertResult = await usersCol.insertOne({
                    googleId: null,
                    firstName: '',
                    lastName: '',
                    phoneNumber: normalizedPhone,
                    email: null,
                    password: null,
                    balance: 0,
                    history: [],
                    phone_verified: true,
                    phone_verified_at: new Date(),
                    accepted_terms_at: new Date(),
                    terms_version: '1.0',
                    role: 'user',
                    status: 'active',
                    created_at: new Date(),
                    updated_at: new Date(),
                });
                user = await usersCol.findOne({ _id: insertResult.insertedId });
            } else {
                await usersCol.updateOne({ _id: user._id }, {
                    $set: { phone_verified: true, phone_verified_at: new Date(),
                            last_login_at: new Date(), updated_at: new Date() }
                });
            }

            // Generate access + refresh tokens
            const accessToken = authExt._signAccessToken(user);
            const refreshToken = await authExt._issueRefreshToken(user._id, ip);

            return res.status(200).json({
                data: {
                    type: "success",
                    message: isNewUser ? "User registered via phone" : "User logged in",
                    is_new_user: isNewUser,
                    user: { id: user._id, phone: normalizedPhone,
                            email: user.email, firstName: user.firstName,
                            lastName: user.lastName, balance: user.balance || 0 },
                    access_token: accessToken,
                    refresh_token: refreshToken,
                    expires_in: 900, // 15 min
                }
            });
        } catch (e) {
            console.error('phoneLoginOrRegister error:', e);
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Refresh access token using a valid refresh token.
     */
    refreshAccessToken: async function(res, body, path) {
        const refreshToken = sanitize(body.refresh_token);
        if (!refreshToken) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "refresh_token required" }});
        }

        // Verify signature
        let payload;
        try {
            payload = jwt.verify(refreshToken, refreshSecret);
        } catch (e) {
            return res.status(401).json({ errors: { status: 401, source: path,
                title: "Invalid or expired refresh token" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const refreshCol = db.collection("refresh_tokens");
            const tokenHash = authExt._hashToken(refreshToken);
            const stored = await refreshCol.findOne({
                user_id: new ObjectId(payload.sub),
                token_hash: tokenHash,
                revoked: false,
                expires_at: { $gt: new Date() },
            });
            if (!stored) {
                return res.status(401).json({ errors: { status: 401, source: path,
                    title: "Refresh token not recognized" }});
            }

            const usersCol = db.collection("users");
            const user = await usersCol.findOne({ _id: stored.user_id });
            if (!user || user.status === 'blocked') {
                return res.status(403).json({ errors: { status: 403, source: path,
                    title: "User not allowed" }});
            }

            const newAccessToken = authExt._signAccessToken(user);
            // Rotate refresh token (revoke old, issue new) — best practice
            await refreshCol.updateOne({ _id: stored._id },
                { $set: { revoked: true, revoked_at: new Date(),
                          revoke_reason: 'rotated' } });
            const newRefreshToken = await authExt._issueRefreshToken(user._id, stored.ip || '');

            return res.status(200).json({
                data: {
                    type: "success",
                    access_token: newAccessToken,
                    refresh_token: newRefreshToken,
                    expires_in: 900,
                }
            });
        } catch (e) {
            console.error('refreshAccessToken error:', e);
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Logout: revoke refresh token (access token stays valid until expiry).
     */
    logout: async function(res, body, path) {
        const refreshToken = sanitize(body.refresh_token);
        if (!refreshToken) {
            return res.status(200).json({ data: { message: "Nothing to revoke" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const refreshCol = db.collection("refresh_tokens");
            const tokenHash = authExt._hashToken(refreshToken);
            await refreshCol.updateOne({ token_hash: tokenHash },
                { $set: { revoked: true, revoked_at: new Date(),
                          revoke_reason: 'user_logout' } });
            return res.status(200).json({ data: { type: "success",
                message: "Logged out" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Logout from ALL devices — revoke all refresh tokens for this user.
     */
    logoutAll: async function(res, user, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const result = await db.collection("refresh_tokens").updateMany(
                { user_id: new ObjectId(user.id), revoked: false },
                { $set: { revoked: true, revoked_at: new Date(),
                          revoke_reason: 'logout_all' } });
            return res.status(200).json({ data: { type: "success",
                message: `Logged out from ${result.modifiedCount} device(s)` }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Get list of active sessions (devices).
     */
    listSessions: async function(res, user, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const sessions = await db.collection("refresh_tokens").find({
                user_id: new ObjectId(user.id), revoked: false,
                expires_at: { $gt: new Date() }
            }).project({ token_hash: 0 }).toArray();
            return res.status(200).json({ data: { sessions,
                count: sessions.length }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Forgot password — send OTP via SMS to user's phone.
     */
    forgotPassword: async function(res, body, path) {
        const phone = sanitize(body.phone);
        if (!phone) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "phone required" }});
        }
        const sms = require('./sms.js');
        const normalized = sms._normalizePhone(phone);
        if (!normalized) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid phone format" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const usersCol = db.collection("users");
            const user = await usersCol.findOne({ phoneNumber: normalized });
            if (!user) {
                // For privacy we don't reveal whether phone exists
                return res.status(200).json({ data: { type: "success",
                    message: "If the phone exists, a code was sent" }});
            }
        } finally { await client.close(); }

        const result = await sms.sendOtp(normalized, 'password_reset');
        if (!result.ok) {
            return res.status(429).json({ errors: { status: 429, source: path,
                title: result.error }});
        }
        return res.status(200).json({ data: { type: "success",
            message: "Reset code sent via SMS",
            expires_at: result.expires_at }});
    },

    /**
     * Reset password using SMS code + new password.
     */
    resetPassword: async function(res, body, path) {
        const phone = sanitize(body.phone);
        const code = sanitize(body.code);
        const newPassword = sanitize(body.new_password);

        if (!phone || !code || !newPassword) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "phone, code, new_password required" }});
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Password too short (min 6 chars)" }});
        }

        const sms = require('./sms.js');
        const verify = await sms.verifyOtp(phone, code, 'password_reset');
        if (!verify.ok) {
            return res.status(401).json({ errors: { status: 401, source: path,
                title: "Code verification failed", detail: verify.error }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const usersCol = db.collection("users");
            const user = await usersCol.findOne({ phoneNumber: verify.phone });
            if (!user) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "User not found" }});
            }
            const hash = await bcrypt.hash(newPassword, 10);
            await usersCol.updateOne({ _id: user._id }, {
                $set: { password: hash, password_changed_at: new Date(),
                        updated_at: new Date() }
            });
            // Revoke all refresh tokens
            await db.collection("refresh_tokens").updateMany(
                { user_id: user._id, revoked: false },
                { $set: { revoked: true, revoked_at: new Date(),
                          revoke_reason: 'password_reset' } });

            return res.status(200).json({ data: { type: "success",
                message: "Password updated" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Change password (when logged in, with current password).
     */
    changePassword: async function(res, body, user, path) {
        const currentPassword = sanitize(body.current_password);
        const newPassword = sanitize(body.new_password);

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "current_password and new_password required" }});
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Password too short (min 6 chars)" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const usersCol = db.collection("users");
            const userDoc = await usersCol.findOne({ _id: new ObjectId(user.id) });
            if (!userDoc || !userDoc.password) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "No password set for this account. Use SMS reset." }});
            }
            const match = await bcrypt.compare(currentPassword, userDoc.password);
            if (!match) {
                return res.status(401).json({ errors: { status: 401, source: path,
                    title: "Current password incorrect" }});
            }
            const hash = await bcrypt.hash(newPassword, 10);
            await usersCol.updateOne({ _id: userDoc._id }, {
                $set: { password: hash, password_changed_at: new Date(),
                        updated_at: new Date() }
            });
            return res.status(200).json({ data: { type: "success",
                message: "Password changed" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Accept terms & conditions (versioned).
     */
    acceptTerms: async function(res, body, user, path) {
        const version = sanitize(body.version) || '1.0';
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            await db.collection("users").updateOne(
                { _id: new ObjectId(user.id) },
                { $set: { accepted_terms_at: new Date(),
                          terms_version: version,
                          updated_at: new Date() } });
            return res.status(200).json({ data: { type: "success",
                message: "Terms accepted", version }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    // ---------- helpers ----------

    _signAccessToken: function(user) {
        return jwt.sign({
            id: String(user._id),
            email: user.email,
            phone: user.phoneNumber,
            role: user.role || 'user',
            type: 'access',
        }, jwtSecret, { expiresIn: ACCESS_TOKEN_TTL });
    },

    _issueRefreshToken: async function(userId, ip) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("refresh_tokens");
            const token = crypto.randomBytes(48).toString('base64url');
            const tokenHash = authExt._hashToken(token);
            const expiresAt = new Date(Date.now() + REFRESH_TOKEN_TTL_DAYS * 86400 * 1000);
            await col.insertOne({
                user_id: new ObjectId(userId),
                token_hash: tokenHash,
                revoked: false,
                ip: ip || '',
                created_at: new Date(),
                expires_at: expiresAt,
            });
            return token;
        } finally { await client.close(); }
    },

    _hashToken: function(token) {
        return crypto.createHash('sha256').update(token).digest('hex');
    },
};

module.exports = authExt;
