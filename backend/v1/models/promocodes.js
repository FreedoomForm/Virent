/**
 * promocodes.js — promo codes & referral program
 *
 * Promo code types:
 *   - first_ride    — discount on first ride (flat amount or %)
 *   - any_ride      — discount on any ride
 *   - free_minutes  — N free minutes per ride
 *   - cashback      — % cashback after ride
 *   - referral_inviter — bonus to inviter after referee's first ride
 *   - referral_invitee — bonus to invitee after first ride
 *
 * Fields:
 *   code, type, value, max_uses, used_count,
 *   valid_from, valid_until, min_ride_cost, max_discount,
 *   per_user_limit, used_by: [{user_id, used_at, trip_id}],
 *   status (active/expired/disabled)
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const mongoURI = process.env.DBURI;

const promocodes = {
    /**
     * Admin: POST /promocodes — create new promo code
     */
    create: async function(res, body, path) {
        const code = (sanitize(body.code) || '').toUpperCase().trim();
        const type = sanitize(body.type);
        const value = parseFloat(sanitize(body.value));
        const maxUses = parseInt(sanitize(body.max_uses)) || 0; // 0 = unlimited
        const validFrom = sanitize(body.valid_from) ? new Date(sanitize(body.valid_from)) : new Date();
        const validUntil = sanitize(body.valid_until) ? new Date(sanitize(body.valid_until)) : null;
        const perUserLimit = parseInt(sanitize(body.per_user_limit)) || 1;
        const minRideCost = parseFloat(sanitize(body.min_ride_cost)) || 0;
        const maxDiscount = parseFloat(sanitize(body.max_discount)) || 0;

        if (!code || code.length < 3) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Code must be at least 3 characters" }});
        }
        if (!['first_ride','any_ride','free_minutes','cashback',
              'referral_inviter','referral_invitee'].includes(type)) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Invalid type. Must be one of: first_ride, any_ride, free_minutes, cashback, referral_inviter, referral_invitee" }});
        }
        if (isNaN(value) || value <= 0) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "value must be positive number" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("promocodes");
            const existing = await col.findOne({ code });
            if (existing) {
                return res.status(409).json({ errors: { status: 409, source: path,
                    title: "Code already exists" }});
            }
            const doc = {
                code, type, value, max_uses: maxUses, used_count: 0,
                valid_from: validFrom, valid_until: validUntil,
                per_user_limit: perUserLimit,
                min_ride_cost: minRideCost,
                max_discount: maxDiscount,
                used_by: [],
                status: 'active',
                created_at: new Date(),
            };
            const result = await col.insertOne(doc);
            return res.status(201).json({ data: { type: "success",
                message: "Promo code created", promo_id: result.insertedId, code }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: GET /promocodes — list all
     */
    listAll: async function(res, query, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};
        if (query.status) filter.status = sanitize(query.status);

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("promocodes");
            const items = await col.find(filter).sort({ created_at: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments(filter);
            return res.status(200).json({ data: { promocodes: items, total, limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: POST /promocodes/redeem — redeem code, returns discount info
     * Body: { code, ride_cost? }
     * Doesn't apply yet — just previews discount. Application happens at trip end.
     */
    redeem: async function(res, body, user, path) {
        const code = (sanitize(body.code) || '').toUpperCase().trim();
        const rideCost = parseFloat(sanitize(body.ride_cost)) || 0;

        if (!code) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "code required" }});
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("promocodes");

            const promo = await col.findOne({ code, status: 'active' });
            if (!promo) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Promo code not found or inactive" }});
            }
            const now = new Date();
            if (promo.valid_from && now < promo.valid_from) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "Promo not yet valid" }});
            }
            if (promo.valid_until && now > promo.valid_until) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "Promo expired" }});
            }
            if (promo.max_uses > 0 && promo.used_count >= promo.max_uses) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "Promo usage limit reached" }});
            }
            if (promo.min_ride_cost > 0 && rideCost < promo.min_ride_cost) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: `Min ride cost is ${promo.min_ride_cost}` }});
            }
            // Per-user limit check
            const userUses = (promo.used_by || [])
                .filter(u => u.user_id.toString() === user.id).length;
            if (userUses >= promo.per_user_limit) {
                return res.status(400).json({ errors: { status: 400, source: path,
                    title: "You've already used this promo" }});
            }

            // Calculate discount
            let discount = 0;
            let bonusMinutes = 0;
            let cashbackPercent = 0;
            if (promo.type === 'first_ride' || promo.type === 'any_ride') {
                if (promo.value <= 1) { // percentage
                    discount = Math.round(rideCost * promo.value * 100) / 100;
                } else { // flat
                    discount = Math.min(promo.value, rideCost);
                }
                if (promo.max_discount > 0 && discount > promo.max_discount) {
                    discount = promo.max_discount;
                }
            } else if (promo.type === 'free_minutes') {
                bonusMinutes = Math.floor(promo.value);
            } else if (promo.type === 'cashback') {
                cashbackPercent = promo.value <= 1 ? promo.value : promo.value / 100;
            }

            // Check if user has previous rides (for first_ride)
            if (promo.type === 'first_ride') {
                const tripsCol = db.collection("trips");
                const tripCount = await tripsCol.countDocuments({
                    user_id: new ObjectId(user.id),
                    status: 'ended'
                });
                if (tripCount > 0) {
                    return res.status(400).json({ errors: { status: 400, source: path,
                        title: "Promo valid for first ride only" }});
                }
            }

            return res.status(200).json({ data: {
                type: "success",
                promo_id: promo._id,
                code: promo.code,
                promo_type: promo.type,
                discount,
                bonus_minutes: bonusMinutes,
                cashback_percent: cashbackPercent,
                final_cost: Math.max(0, rideCost - discount),
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * User: GET /promocodes/referral — get my referral code
     * Auto-creates referral promo code on first request.
     */
    getMyReferral: async function(res, user, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("promocodes");
            const referralCode = `REF${String(user.id).slice(-6).toUpperCase()}`;
            let promo = await col.findOne({ code: referralCode });
            if (!promo) {
                await col.insertOne({
                    code: referralCode,
                    type: 'referral_invitee',
                    value: 5000, // 5000 UZS to invitee
                    max_uses: 0, // unlimited
                    used_count: 0,
                    valid_from: new Date(),
                    valid_until: null,
                    per_user_limit: 1,
                    min_ride_cost: 0,
                    max_discount: 0,
                    used_by: [],
                    status: 'active',
                    referrer: new ObjectId(user.id),
                    created_at: new Date(),
                });
                // Create matching inviter bonus
                await col.insertOne({
                    code: referralCode + '_INV',
                    type: 'referral_inviter',
                    value: 10000, // 10000 UZS to inviter
                    max_uses: 0,
                    used_count: 0,
                    valid_from: new Date(),
                    valid_until: null,
                    per_user_limit: 0, // unlimited per user (each referral counts)
                    min_ride_cost: 0,
                    max_discount: 0,
                    used_by: [],
                    status: 'active',
                    referrer: new ObjectId(user.id),
                    created_at: new Date(),
                });
            }
            return res.status(200).json({ data: {
                type: "success",
                referral_code: referralCode,
                invitee_bonus: 5000,
                inviter_bonus: 10000,
                share_text: `Используй мой код ${referralCode} и получи 5000 сум на первую поездку в SparkRentals!`,
            }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * Admin: DELETE /promocodes/:code — disable promo
     */
    disable: async function(res, code, path) {
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const result = await db.collection("promocodes").updateOne(
                { code: (code || '').toUpperCase() },
                { $set: { status: 'disabled', disabled_at: new Date() } });
            if (result.matchedCount === 0) {
                return res.status(404).json({ errors: { status: 404, source: path,
                    title: "Promo not found" }});
            }
            return res.status(200).json({ data: { type: "success",
                message: "Promo disabled" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = promocodes;
