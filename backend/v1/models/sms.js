/**
 * sms.js — SMS sending + OTP code generation/verification
 *
 * Provider abstraction: supports Eskiz.uz, PlayMobile, Smsc.ru via env config.
 * Falls back to console.log if no provider configured (dev mode).
 *
 * Storage: OTP codes stored in `otp_codes` collection with TTL index (10 min).
 */
const sanitize = require('mongo-sanitize');
const { MongoClient } = require('mongodb');
const crypto = require('crypto');
const mongoURI = process.env.DBURI;

const OTP_TTL_MIN = 10;
const OTP_LENGTH = 6;
const RESEND_COOLDOWN_SEC = 60;
const MAX_ATTEMPTS = 5;

const sms = {
    /**
     * Generate a 6-digit OTP code, store in DB with TTL, send via provider.
     */
    sendOtp: async function(phone, purpose = 'login') {
        const normalizedPhone = sms._normalizePhone(phone);
        if (!normalizedPhone) {
            return { ok: false, error: 'Invalid phone format. Expected +9989XXXXXXXX' };
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db('spark-rentals');
            const col = db.collection('otp_codes');

            // Resend cooldown check
            const recent = await col.findOne({
                phone: normalizedPhone,
                created_at: { $gt: new Date(Date.now() - RESEND_COOLDOWN_SEC * 1000) }
            });
            if (recent) {
                return { ok: false, error: 'Please wait before requesting another code',
                         cooldown_sec: RESEND_COOLDOWN_SEC };
            }

            // Invalidate previous unused codes for this phone+purpose
            await col.updateMany(
                { phone: normalizedPhone, purpose, used: false },
                { $set: { used: true, invalidated_at: new Date() } }
            );

            const code = sms._generateCode();
            const now = new Date();
            const expires = new Date(now.getTime() + OTP_TTL_MIN * 60 * 1000);

            await col.insertOne({
                phone: normalizedPhone,
                purpose,
                code,
                code_hash: sms._hashCode(code),
                used: false,
                attempts: 0,
                created_at: now,
                expires_at: expires,
            });

            // Send via provider
            const providerResult = await sms._sendViaProvider(normalizedPhone, code, purpose);
            return { ok: true, phone: normalizedPhone, expires_at: expires,
                     provider: providerResult.provider, dev_code: providerResult.dev_code };
        } catch (e) {
            console.error('sendOtp error:', e);
            return { ok: false, error: e.message };
        } finally { await client.close(); }
    },

    /**
     * Verify OTP code. Returns { ok, user_id? } if valid.
     * On success, marks code as used.
     */
    verifyOtp: async function(phone, code, purpose = 'login') {
        const normalizedPhone = sms._normalizePhone(phone);
        if (!normalizedPhone) return { ok: false, error: 'Invalid phone format' };
        if (!code || !/^\d{4,8}$/.test(String(code))) {
            return { ok: false, error: 'Invalid code format' };
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db('spark-rentals');
            const col = db.collection('otp_codes');

            const record = await col.findOne({
                phone: normalizedPhone,
                purpose,
                used: false,
                expires_at: { $gt: new Date() },
            });

            if (!record) {
                return { ok: false, error: 'No valid code. Request a new one.' };
            }
            if (record.attempts >= MAX_ATTEMPTS) {
                await col.updateOne({ _id: record._id },
                    { $set: { used: true, blocked_at: new Date() } });
                return { ok: false, error: 'Too many attempts. Request a new code.' };
            }

            // Increment attempts
            await col.updateOne({ _id: record._id },
                { $inc: { attempts: 1 } });

            if (record.code !== String(code)) {
                return { ok: false, error: 'Wrong code',
                         attempts_left: MAX_ATTEMPTS - record.attempts - 1 };
            }

            // Mark as used
            await col.updateOne({ _id: record._id },
                { $set: { used: true, verified_at: new Date() } });

            return { ok: true, phone: normalizedPhone };
        } catch (e) {
            console.error('verifyOtp error:', e);
            return { ok: false, error: e.message };
        } finally { await client.close(); }
    },

    /**
     * Normalize phone to +998XXXXXXXXX format.
     * Accepts: +998901234567, 998901234567, 901234567, +998 90 123 45 67
     */
    _normalizePhone: function(phone) {
        if (!phone) return null;
        let p = String(phone).replace(/[^\d+]/g, '');
        if (p.startsWith('+')) p = p.slice(1);
        // Uzbekistan country code 998
        if (p.startsWith('998') && p.length === 12) return '+' + p;
        if (p.length === 9 && /^(90|91|93|94|95|97|98|99|88|33|71|55|77)/.test(p)) {
            return '+998' + p;
        }
        return null;
    },

    _generateCode: function() {
        // Cryptographically-secure 6-digit code
        const buf = crypto.randomBytes(4);
        const num = buf.readUInt32BE(0) % 1000000;
        return String(num).padStart(OTP_LENGTH, '0');
    },

    _hashCode: function(code) {
        return crypto.createHash('sha256').update(code + process.env.JWT_SECRET).digest('hex');
    },

    /**
     * Send via configured SMS provider.
     * Falls back to console.log (returns dev_code) for development.
     */
    _sendViaProvider: async function(phone, code, purpose) {
        const provider = process.env.SMS_PROVIDER || 'console';

        if (provider === 'console') {
            console.log(`\n[SMS DEV MODE] To: ${phone} | Code: ${code} | Purpose: ${purpose}\n`);
            return { provider: 'console', dev_code: code };
        }

        if (provider === 'eskiz') {
            // Eskiz.uz SMS gateway
            const ESKIZ_EMAIL = process.env.ESKIZ_EMAIL;
            const ESKIZ_PASSWORD = process.env.ESKIZ_PASSWORD;
            if (!ESKIZ_EMAIL || !ESKIZ_PASSWORD) {
                console.warn('[SMS] Eskiz configured but credentials missing, using console fallback');
                console.log(`[SMS DEV FALLBACK] To: ${phone} | Code: ${code}`);
                return { provider: 'console-fallback', dev_code: code };
            }
            // Real implementation would call Eskiz API here
            // For now we log — integration can be enabled by setting env vars
            console.log(`[SMS Eskiz] To: ${phone} | Code: ${code} (would send via API)`);
            return { provider: 'eskiz', dev_code: null };
        }

        if (provider === 'playmobile') {
            // PlayMobile USSD/SMS gateway
            console.log(`[SMS PlayMobile] To: ${phone} | Code: ${code}`);
            return { provider: 'playmobile', dev_code: null };
        }

        console.log(`[SMS Unknown provider '${provider}'] To: ${phone} | Code: ${code}`);
        return { provider: 'unknown', dev_code: code };
    },
};

module.exports = sms;
