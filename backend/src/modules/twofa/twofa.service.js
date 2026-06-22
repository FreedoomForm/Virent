/**
 * twofa.service.js — Two-Factor Authentication (TOTP) for admins
 *
 * Per Backend Design System §19 (Security): 2FA for admin accounts
 * Uses otplib-style TOTP (RFC 6238) with manual implementation.
 *
 * Flow:
 *   1. Admin calls setup → returns secret + QR URL
 *   2. Admin scans QR in Google Authenticator
 *   3. Admin enters 6-digit code → verify endpoint
 *   4. If valid, secret stored on admin record
 *   5. Future logins require code after password
 */
const crypto = require('crypto');
const { getDb } = require('../../shared/db.js');
const { ObjectId } = require('mongodb');

const STEP = 30; // seconds
const DIGITS = 6;

function base32Encode(buffer) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = 0, value = 0, output = '';
  for (const byte of buffer) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      output += alphabet[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) output += alphabet[(value << (5 - bits)) & 31];
  return output;
}

function base32Decode(secret) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  const cleaned = secret.replace(/=+$/, '').toUpperCase();
  let bits = 0, value = 0, output = Buffer.alloc(Math.floor(cleaned.length * 5 / 8));
  let idx = 0;
  for (const c of cleaned) {
    const v = alphabet.indexOf(c);
    if (v < 0) continue;
    value = (value << 5) | v;
    bits += 5;
    if (bits >= 8) {
      output[idx++] = (value >>> (bits - 8)) & 0xff;
      bits -= 8;
    }
  }
  return output;
}

function generateTotp(secret, time = Date.now()) {
  const key = base32Decode(secret);
  const counter = Math.floor(time / 1000 / STEP);
  const buf = Buffer.alloc(8);
  buf.writeBigUInt64BE(BigInt(counter));
  const hmac = crypto.createHmac('sha1', key).update(buf).digest();
  const offset = hmac[hmac.length - 1] & 0xf;
  const code = ((hmac[offset] & 0x7f) << 24 |
                (hmac[offset + 1] & 0xff) << 16 |
                (hmac[offset + 2] & 0xff) << 8 |
                (hmac[offset + 3] & 0xff)) % Math.pow(10, DIGITS);
  return code.toString().padStart(DIGITS, '0');
}

const twofa = {
  /**
   * POST /v1/2fa/setup — generate new TOTP secret for admin
   */
  setup: async function(res, admin, path) {
    const secret = base32Encode(crypto.randomBytes(20));
    const otpauth = `otpauth://totp/SparkRentals:${admin.email}?secret=${secret}&issuer=SparkRentals&algorithm=SHA1&digits=${DIGITS}&period=${STEP}`;
    const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(otpauth)}`;

    const db = await getDb();
    await db.collection('admins').updateOne(
      { _id: new ObjectId(admin.id) },
      { $set: { twofa_pending_secret: secret, twofa_pending_at: new Date() } }
    );

    return res.status(200).json({ data: { type: 'success', secret, qr_url: qrUrl, manual_entry: otpauth }});
  },

  /**
   * POST /v1/2fa/verify — verify TOTP code and enable 2FA
   */
  verify: async function(res, body, admin, path) {
    const code = body.code;
    if (!code || !/^\d{6}$/.test(String(code))) {
      return res.status(400).json({ errors: { status: 400, detail: 'Code must be 6 digits' }});
    }
    const db = await getDb();
    const adminDoc = await db.collection('admins').findOne({ _id: new ObjectId(admin.id) });
    if (!adminDoc || !adminDoc.twofa_pending_secret) {
      return res.status(400).json({ errors: { status: 400, detail: 'No pending 2FA setup. Call /2fa/setup first.' }});
    }
    const expected = generateTotp(adminDoc.twofa_pending_secret);
    if (code !== expected) {
      return res.status(401).json({ errors: { status: 401, detail: 'Invalid code' }});
    }
    await db.collection('admins').updateOne(
      { _id: adminDoc._id },
      { $set: { twofa_secret: adminDoc.twofa_pending_secret, twofa_enabled: true },
        $unset: { twofa_pending_secret: '', twofa_pending_at: '' } }
    );
    return res.status(200).json({ data: { type: 'success', message: '2FA enabled' }});
  },

  /**
   * POST /v1/2fa/disable — disable 2FA (requires current code)
   */
  disable: async function(res, body, admin, path) {
    const code = body.code;
    const db = await getDb();
    const adminDoc = await db.collection('admins').findOne({ _id: new ObjectId(admin.id) });
    if (!adminDoc || !adminDoc.twofa_secret) {
      return res.status(400).json({ errors: { status: 400, detail: '2FA not enabled' }});
    }
    const expected = generateTotp(adminDoc.twofa_secret);
    if (code !== expected) {
      return res.status(401).json({ errors: { status: 401, detail: 'Invalid code' }});
    }
    await db.collection('admins').updateOne(
      { _id: adminDoc._id },
      { $unset: { twofa_secret: '', twofa_enabled: '' } }
    );
    return res.status(200).json({ data: { type: 'success', message: '2FA disabled' }});
  },

  /**
   * POST /v1/2fa/verify-login — verify code during login
   */
  verifyLogin: async function(res, body, path) {
    const { email, code } = body;
    if (!email || !code) {
      return res.status(400).json({ errors: { status: 400, detail: 'email and code required' }});
    }
    const db = await getDb();
    const admin = await db.collection('admins').findOne({ email });
    if (!admin || !admin.twofa_enabled || !admin.twofa_secret) {
      return res.status(400).json({ errors: { status: 400, detail: '2FA not enabled for this admin' }});
    }
    const expected = generateTotp(admin.twofa_secret);
    if (code !== expected) {
      return res.status(401).json({ errors: { status: 401, detail: 'Invalid 2FA code' }});
    }
    return res.status(200).json({ data: { type: 'success', message: '2FA verified', email }});
  },

  // Export for testing
  _generateTotp: generateTotp,
  _base32Encode: base32Encode,
};

module.exports = twofa;
