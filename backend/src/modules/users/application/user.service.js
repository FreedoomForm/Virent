/**
 * User service — profile update, block/unblock, balance operations
 * Per constitution: admin can block users, users can update own profile
 */
const { getDb } = require('../../../shared/db.js');
const { ObjectId } = require('mongodb');
const { NotFoundError, ForbiddenError, ValidationError } = require('../../../shared/errors.js');

const userService = {
  /**
   * PUT /users/:id — update user profile (own profile only)
   */
  updateProfile: async function(userId, updates) {
    const allowed = ['firstName', 'lastName', 'email', 'phoneNumber'];
    const clean = {};
    for (const k of allowed) {
      if (updates[k] !== undefined) clean[k] = updates[k];
    }
    if (Object.keys(clean).length === 0) {
      throw new ValidationError('updates', 'No valid fields to update');
    }
    clean.updated_at = new Date();
    const db = await getDb();
    const result = await db.collection('users').findOneAndUpdate(
      { _id: new ObjectId(userId) },
      { $set: clean },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('user', userId);
    return result;
  },

  /**
   * POST /users/:id/block — admin blocks user
   */
  block: async function(userId, reason = 'admin_action') {
    const db = await getDb();
    const result = await db.collection('users').findOneAndUpdate(
      { _id: new ObjectId(userId) },
      { $set: { status: 'blocked', blocked_reason: reason, blocked_at: new Date(), updated_at: new Date() } },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('user', userId);
    // Revoke all refresh tokens
    await db.collection('refresh_tokens').updateMany(
      { user_id: new ObjectId(userId), revoked: false },
      { $set: { revoked: true, revoked_at: new Date(), revoke_reason: 'user_blocked' } }
    );
    return result;
  },

  /**
   * POST /users/:id/unblock — admin unblocks user
   */
  unblock: async function(userId) {
    const db = await getDb();
    const result = await db.collection('users').findOneAndUpdate(
      { _id: new ObjectId(userId) },
      { $set: { status: 'active', updated_at: new Date() },
        $unset: { blocked_reason: '', blocked_at: '' } },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('user', userId);
    return result;
  },

  /**
   * POST /users/:id/adjust-balance — admin adjusts user balance
   */
  adjustBalance: async function(userId, amount, reason) {
    if (!amount || isNaN(parseFloat(amount))) {
      throw new ValidationError('amount', 'must be a number');
    }
    const db = await getDb();
    const user = await db.collection('users').findOne({ _id: new ObjectId(userId) });
    if (!user) throw new NotFoundError('user', userId);
    const newBalance = (user.balance || 0) + parseFloat(amount);
    await db.collection('users').updateOne(
      { _id: user._id },
      { $set: { balance: newBalance, updated_at: new Date() } }
    );
    // Record transaction
    await db.collection('transactions').insertOne({
      user_id: user._id,
      type: amount > 0 ? 'bonus' : 'penalty',
      amount: parseFloat(amount),
      balance_after: newBalance,
      method: 'balance',
      provider: 'internal',
      status: 'completed',
      description: `Admin adjustment: ${reason || 'no reason'}`,
      created_at: new Date(),
      updated_at: new Date(),
    });
    return { balance: newBalance };
  },

  /**
   * DELETE /users/:id — admin deletes user (soft delete)
   */
  delete: async function(userId) {
    const db = await getDb();
    const result = await db.collection('users').findOneAndUpdate(
      { _id: new ObjectId(userId) },
      { $set: { status: 'deleted', deleted_at: new Date(), updated_at: new Date() } },
      { returnDocument: 'after' }
    );
    if (!result) throw new NotFoundError('user', userId);
    // Revoke all sessions
    await db.collection('refresh_tokens').updateMany(
      { user_id: new ObjectId(userId), revoked: false },
      { $set: { revoked: true, revoked_at: new Date(), revoke_reason: 'user_deleted' } }
    );
    return result;
  },
};

module.exports = userService;
