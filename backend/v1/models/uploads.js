/**
 * uploads.js — photo upload (proof of parking, breakdown photos, etc.)
 *
 * Stores files on local disk under UPLOAD_DIR.
 * For production: replace with S3/MinIO upload.
 *
 * Each upload:
 *   - Validates file type (JPEG, PNG, WebP)
 *   - Validates size (max 5 MB)
 *   - Generates unique filename
 *   - Saves to disk
 *   - Returns public URL
 *
 * Files stored under /home/z/my-project/uploads/{yyyy}/{mm}/
 */
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const UPLOAD_DIR = process.env.UPLOAD_DIR || '/home/z/my-project/uploads';
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const PUBLIC_BASE = process.env.PUBLIC_BASE_URL || 'http://localhost:8393';

const uploads = {
    /**
     * POST /uploads — multipart/form-data with field "file"
     * Returns: { url, filename, size }
     */
    uploadFile: async function(res, file, user, purpose, path_) {
        if (!file) {
            return res.status(400).json({ errors: { status: 400, source: path_,
                title: "No file uploaded. Use multipart/form-data with field 'file'." }});
        }
        if (!ALLOWED_TYPES.includes(file.mimetype)) {
            return res.status(400).json({ errors: { status: 400, source: path_,
                title: `Type not allowed. Allowed: ${ALLOWED_TYPES.join(', ')}` }});
        }
        if (file.size > MAX_FILE_SIZE) {
            return res.status(400).json({ errors: { status: 400, source: path_,
                title: `File too large. Max: ${MAX_FILE_SIZE / 1024 / 1024} MB` }});
        }

        const now = new Date();
        const yyyy = now.getFullYear();
        const mm = String(now.getMonth() + 1).padStart(2, '0');
        const dir = path.join(UPLOAD_DIR, String(yyyy), mm);
        fs.mkdirSync(dir, { recursive: true });

        const ext = file.mimetype.split('/')[1];
        const filename = `${crypto.randomBytes(12).toString('hex')}.${ext}`;
        const fullPath = path.join(dir, filename);
        fs.writeFileSync(fullPath, file.buffer);

        const publicUrl = `${PUBLIC_BASE}/uploads/${yyyy}/${mm}/${filename}`;

        // Log to DB
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            await db.collection("uploads").insertOne({
                user_id: user?.id ? new ObjectId(user.id) : null,
                filename,
                original_name: file.originalname,
                mime_type: file.mimetype,
                size: file.size,
                path: fullPath,
                public_url: publicUrl,
                purpose: purpose || 'general',
                created_at: now,
            });
        } catch (e) {
            console.error('[uploads] DB log failed:', e.message);
            // Don't fail the upload — file is saved on disk
        } finally { await client.close(); }

        return res.status(201).json({ data: { type: "success",
            url: publicUrl, filename, size: file.size,
            mime_type: file.mimetype }});
    },

    /**
     * Admin: GET /uploads?user_id&purpose&limit&offset
     */
    listUploads: async function(res, query, path_) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};
        if (query.user_id && ObjectId.isValid(query.user_id))
            filter.user_id = new ObjectId(sanitize(query.user_id));
        if (query.purpose) filter.purpose = sanitize(query.purpose);

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const items = await db.collection("uploads").find(filter)
                .sort({ created_at: -1 }).skip(offset).limit(limit).toArray();
            const total = await db.collection("uploads").countDocuments(filter);
            return res.status(200).json({ data: { uploads: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path_,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = uploads;
module.exports.UPLOAD_DIR = UPLOAD_DIR;
module.exports.MAX_FILE_SIZE = MAX_FILE_SIZE;
module.exports.ALLOWED_TYPES = ALLOWED_TYPES;
