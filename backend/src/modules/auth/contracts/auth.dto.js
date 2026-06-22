/**
 * Auth DTOs
 */

function toUserSummary(user) {
    if (!user) return null;
    return {
        id: String(user._id || user.id),
        first_name: user.firstName,
        last_name: user.lastName,
    };
}

function toUserPublic(user) {
    return {
        id: String(user._id || user.id),
        email: user.email,
        phone: user.phoneNumber,
        first_name: user.firstName,
        last_name: user.lastName,
        role: user.role || 'user',
        status: user.status || 'active',
        phone_verified: user.phone_verified || false,
        balance: user.balance || 0,
    };
}

function toUserDetail(user) {
    return {
        ...toUserPublic(user),
        accepted_terms_at: user.accepted_terms_at,
        terms_version: user.terms_version,
        last_login_at: user.last_login_at,
        password_changed_at: user.password_changed_at,
        created_at: user.created_at,
        updated_at: user.updated_at,
    };
}

function toTokenPairResponse(tokenPair, user, isNewUser = false) {
    return {
        type: 'success',
        message: isNewUser ? 'User registered via phone' : 'User logged in',
        is_new_user: isNewUser,
        user: user ? toUserPublic(user) : null,
        access_token: tokenPair.accessToken,
        refresh_token: tokenPair.refreshToken,
        expires_in: tokenPair.expiresIn,
        issued_at: tokenPair.issuedAt,
    };
}

function toSessionResponse(session) {
    return {
        id: String(session._id || session.id),
        ip: session.ip || '',
        user_agent: session.user_agent || '',
        created_at: session.created_at,
        expires_at: session.expires_at,
        revoked: session.revoked,
        revoke_reason: session.revoke_reason,
    };
}

module.exports = {
    toUserSummary, toUserPublic, toUserDetail,
    toTokenPairResponse, toSessionResponse,
};
