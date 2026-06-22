/**
 * User DTOs
 */
function toSummary(user) {
    if (!user) return null;
    return {
        id: String(user._id || user.id),
        first_name: user.firstName,
        last_name: user.lastName,
    };
}

function toListItem(user) {
    return {
        id: String(user._id || user.id),
        email: user.email,
        phone: user.phoneNumber,
        first_name: user.firstName,
        last_name: user.lastName,
        role: user.role || 'user',
        status: user.status || 'active',
        balance: user.balance || 0,
        phone_verified: user.phone_verified || false,
        created_at: user.created_at,
        last_login_at: user.last_login_at,
    };
}

function toDetail(user) {
    return {
        id: String(user._id || user.id),
        email: user.email,
        phone: user.phoneNumber,
        first_name: user.firstName,
        last_name: user.lastName,
        balance: user.balance || 0,
        role: user.role || 'user',
        status: user.status || 'active',
        phone_verified: user.phone_verified || false,
        phone_verified_at: user.phone_verified_at,
        accepted_terms_at: user.accepted_terms_at,
        terms_version: user.terms_version,
        last_login_at: user.last_login_at,
        created_at: user.created_at,
    };
}

function toPublicProfile(user) {
    // Safe to expose to other users (no email/phone unless owner)
    return {
        id: String(user._id || user.id),
        first_name: user.firstName,
        last_name: user.lastName,
    };
}

module.exports = { toSummary, toListItem, toDetail, toPublicProfile };
