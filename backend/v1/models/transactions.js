/**
 * transactions.js — payment & transaction history
 *
 * Transaction types:
 *   - topup_click       — balance top-up via Click
 *   - topup_payme       — balance top-up via Payme
 *   - topup_card        — balance top-up via direct card
 *   - trip_payment      — trip cost deduction
 *   - refund            — refund (admin or auto)
 *   - bonus             — referral bonus, promo bonus
 *   - penalty           — penalty (no-parking, damage)
 *
 * Providers:
 *   - internal          — internal balance transfer
 *   - click             — Click.uz
 *   - payme             — Payme.uz
 *   - card              — direct card acquiring
 */
const sanitize = require('mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const crypto = require('crypto');
const mongoURI = process.env.DBURI;

const transactions = {
    /**
     * GET /transactions?user_id&limit&offset&type&from&to
     * User-scoped if x-access-token; admin can query any user.
     */
    getTransactions: async function(res, query, user, isAdmin, path) {
        const limit = Math.min(parseInt(query.limit || '50'), 200);
        const offset = Math.max(parseInt(query.offset || '0'), 0);
        const filter = {};

        if (isAdmin && query.user_id && ObjectId.isValid(query.user_id)) {
            filter.user_id = new ObjectId(sanitize(query.user_id));
        } else {
            filter.user_id = new ObjectId(user.id);
        }
        if (query.type) filter.type = sanitize(query.type);
        if (query.from || query.to) {
            filter.created_at = {};
            if (query.from) filter.created_at.$gte = new Date(sanitize(query.from));
            if (query.to) filter.created_at.$lte = new Date(sanitize(query.to));
        }

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const col = db.collection("transactions");
            const items = await col.find(filter).sort({ created_at: -1 })
                .skip(offset).limit(limit).toArray();
            const total = await col.countDocuments(filter);
            const sumAggregate = await col.aggregate([
                { $match: filter },
                { $group: { _id: null, total: { $sum: "$amount" } } }
            ]).toArray();
            const sum = sumAggregate[0]?.total || 0;
            return res.status(200).json({ data: { transactions: items, total, sum,
                limit, offset }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * POST /transactions/topup/click — initiate Click payment
     * Body: { amount, return_url? }
     * Returns: Click payment URL/redirect
     */
    initClickTopup: async function(res, body, user, path) {
        const amount = parseFloat(sanitize(body.amount));
        if (!amount || amount < 1000) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Min topup is 1000 UZS" }});
        }
        const merchantId = process.env.CLICK_MERCHANT_ID;
        const serviceId = process.env.CLICK_SERVICE_ID;
        const secretKey = process.env.CLICK_SECRET_KEY;
        if (!merchantId || !secretKey) {
            return res.status(503).json({ errors: { status: 503, source: path,
                title: "Click not configured",
                detail: "Set CLICK_MERCHANT_ID and CLICK_SECRET_KEY env vars" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const txnCol = db.collection("transactions");
            const pendingTxn = {
                user_id: new ObjectId(user.id),
                type: 'topup_click',
                amount: amount,
                balance_after: null,
                method: 'external',
                provider: 'click',
                provider_txn_id: null,
                status: 'pending',
                description: `Click top-up ${amount} UZS`,
                created_at: new Date(),
                updated_at: new Date(),
            };
            const insertResult = await txnCol.insertOne(pendingTxn);
            // Click Merchant API: generate payment URL
            // Format: https://my.click.uz/services/pay?service_id=X&merchant_id=Y&amount=Z&transaction_param=TXN_ID
            const txnIdStr = String(insertResult.insertedId);
            const sign = crypto.createHash('md5')
                .update(`${txnIdStr}${amount}${secretKey}`).digest('hex');
            const clickUrl = `https://my.click.uz/services/pay?` +
                `service_id=${serviceId || merchantId}&merchant_id=${merchantId}` +
                `&amount=${amount}&transaction_param=${txnIdStr}&sign=${sign}`;
            return res.status(200).json({ data: { type: "success",
                transaction_id: insertResult.insertedId,
                payment_url: clickUrl,
                provider: "click" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * POST /transactions/topup/payme — initiate Payme payment
     */
    initPaymeTopup: async function(res, body, user, path) {
        const amount = parseFloat(sanitize(body.amount));
        if (!amount || amount < 1000) {
            return res.status(400).json({ errors: { status: 400, source: path,
                title: "Min topup is 1000 UZS" }});
        }
        const paymeMerchant = process.env.PAYME_MERCHANT_ID;
        const paymeKey = process.env.PAYME_KEY;
        if (!paymeMerchant) {
            return res.status(503).json({ errors: { status: 503, source: path,
                title: "Payme not configured" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const txnCol = db.collection("transactions");
            const pendingTxn = {
                user_id: new ObjectId(user.id),
                type: 'topup_payme',
                amount: amount,
                balance_after: null,
                method: 'external',
                provider: 'payme',
                provider_txn_id: null,
                status: 'pending',
                description: `Payme top-up ${amount} UZS`,
                created_at: new Date(),
                updated_at: new Date(),
            };
            const insertResult = await txnCol.insertOne(pendingTxn);
            const txnIdStr = String(insertResult.insertedId);
            // Payme checkout URL format
            const paymeUrl = `https://checkout.paycom.uz/${Buffer.from(
                `m=${paymeMerchant};ac.order_id=${txnIdStr};a=${Math.round(amount * 100)}`
            ).toString('base64')}`;
            return res.status(200).json({ data: { type: "success",
                transaction_id: insertResult.insertedId,
                payment_url: paymeUrl,
                provider: "payme" }});
        } catch (e) {
            return res.status(500).json({ errors: { status: 500, source: path,
                title: "Server error", detail: e.message }});
        } finally { await client.close(); }
    },

    /**
     * POST /webhooks/click — Click webhook (called by Click server)
     * Click Merchant API v2 signature: MD5(sign_string + secret_key)
     */
    clickWebhook: async function(res, body, path) {
        const signString = body.sign_string;
        const incomingSign = body.sign;
        const secretKey = process.env.CLICK_SECRET_KEY;
        if (!secretKey) {
            return res.status(503).json({ error: -32400, error_note: "Click not configured" });
        }
        const expectedSign = crypto.createHash('md5')
            .update(`${signString}${secretKey}`).digest('hex');
        if (incomingSign !== expectedSign) {
            return res.status(200).json({ error: -1, error_note: "Invalid sign" });
        }

        const action = body.merchant_prepare || body.merchant_confirm;
        const txnId = body.merchant_trans_id; // our txn _id

        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const txnCol = db.collection("transactions");
            const usersCol = db.collection("users");
            const txn = await txnCol.findOne({ _id: new ObjectId(txnId) });
            if (!txn) {
                return res.status(200).json({ error: -5, error_note: "Transaction not found" });
            }
            if (body.action === 'prepare') {
                // Pre-confirm: validate amount
                if (Math.abs(txn.amount - body.amount) > 1) {
                    return res.status(200).json({ error: -2, error_note: "Amount mismatch" });
                }
                await txnCol.updateOne({ _id: txn._id }, {
                    $set: { provider_txn_id: String(body.click_trans_id),
                            status: 'preparing', updated_at: new Date() }
                });
                return res.status(200).json({ click_trans_id: body.click_trans_id,
                    merchant_trans_id: txnId, error: 0, error_note: "Success" });
            }
            if (body.action === 'complete') {
                if (body.error < 0) {
                    await txnCol.updateOne({ _id: txn._id }, {
                        $set: { status: 'failed', error: body.error,
                                updated_at: new Date() }
                    });
                    return res.status(200).json({ error: body.error,
                        error_note: "Failed" });
                }
                // Success: credit user balance
                const userDoc = await usersCol.findOne({ _id: txn.user_id });
                const newBalance = (userDoc.balance || 0) + txn.amount;
                await usersCol.updateOne({ _id: userDoc._id }, {
                    $set: { balance: newBalance, updated_at: new Date() }
                });
                await txnCol.updateOne({ _id: txn._id }, {
                    $set: { status: 'completed', balance_after: newBalance,
                            completed_at: new Date(), updated_at: new Date() }
                });
                return res.status(200).json({ click_trans_id: body.click_trans_id,
                    merchant_trans_id: txnId, error: 0, error_note: "Success" });
            }
            return res.status(200).json({ error: -8, error_note: "Unknown action" });
        } catch (e) {
            console.error('clickWebhook error:', e);
            return res.status(200).json({ error: -5, error_note: e.message });
        } finally { await client.close(); }
    },

    /**
     * POST /webhooks/payme — Payme webhook
     */
    paymeWebhook: async function(res, body, path) {
        const method = body.method;
        const paymeKey = process.env.PAYME_KEY;
        if (!paymeKey) {
            return res.status(503).json({ error: { code: -32403,
                message: "Payme not configured" }});
        }
        const client = new MongoClient(mongoURI);
        try {
            await client.connect();
            const db = client.db("spark-rentals");
            const txnCol = db.collection("transactions");
            const usersCol = db.collection("users");

            if (method === 'CheckTransaction') {
                const txn = await txnCol.findOne({
                    _id: new ObjectId(body.params.id.replace('order_', ''))
                });
                if (!txn) return res.json({ error: { code: -31003,
                    message: "Transaction not found" }});
                return res.json({ result: { create_time: txn.created_at.getTime(),
                    perform_time: txn.completed_at?.getTime() || 0,
                    cancel_time: 0,
                    transaction: String(txn._id),
                    state: txn.status === 'completed' ? 2 : (txn.status === 'failed' ? -2 : 1),
                    reason: null }});
            }
            if (method === 'CreateTransaction') {
                const orderId = body.params.account.order_id;
                const amount = body.params.amount / 100; // Payme uses tiyin
                const txn = await txnCol.findOne({ _id: new ObjectId(orderId) });
                if (!txn) return res.json({ error: { code: -31003,
                    message: "Transaction not found" }});
                if (Math.abs(txn.amount - amount) > 1) {
                    return res.json({ error: { code: -31001,
                        message: "Amount mismatch" }});
                }
                await txnCol.updateOne({ _id: txn._id }, {
                    $set: { provider_txn_id: body.params.id,
                            status: 'preparing', updated_at: new Date() }
                });
                return res.json({ result: { create_time: Date.now(),
                    transaction: String(txn._id), state: 1 }});
            }
            if (method === 'PerformTransaction') {
                const txn = await txnCol.findOne({
                    _id: new ObjectId(body.params.transaction.replace('order_', ''))
                });
                if (!txn) return res.json({ error: { code: -31003 }});
                const userDoc = await usersCol.findOne({ _id: txn.user_id });
                const newBalance = (userDoc.balance || 0) + txn.amount;
                await usersCol.updateOne({ _id: userDoc._id },
                    { $set: { balance: newBalance, updated_at: new Date() }});
                await txnCol.updateOne({ _id: txn._id }, {
                    $set: { status: 'completed', balance_after: newBalance,
                            completed_at: new Date(), updated_at: new Date() }
                });
                return res.json({ result: { perform_time: Date.now(),
                    transaction: String(txn._id), state: 2 }});
            }
            if (method === 'CancelTransaction') {
                const txn = await txnCol.findOne({
                    _id: new ObjectId(body.params.transaction.replace('order_', ''))
                });
                if (!txn) return res.json({ error: { code: -31003 }});
                await txnCol.updateOne({ _id: txn._id }, {
                    $set: { status: 'cancelled', cancel_reason: body.params.reason,
                            updated_at: new Date() }
                });
                return res.json({ result: { cancel_time: Date.now(),
                    transaction: String(txn._id), state: -2 }});
            }
            return res.json({ error: { code: -32601, message: "Method not found" }});
        } catch (e) {
            return res.json({ error: { code: -32403, message: e.message }});
        } finally { await client.close(); }
    },
};

module.exports = transactions;
