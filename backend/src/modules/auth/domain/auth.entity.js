/**
 * Auth domain entity
 *
 * Per constitution §12 Domain layer: business rules only
 */

const USER_ROLES = ['user', 'admin', 'juicer', 'mechanic', 'support'];
const USER_STATUSES = ['active', 'blocked', 'deleted'];

class User {
    constructor(props) {
        this.id = props._id || props.id;
        this.email = props.email;
        this.phoneNumber = props.phoneNumber;
        this.firstName = props.firstName;
        this.lastName = props.lastName;
        this.balance = props.balance || 0;
        this.role = props.role || 'user';
        this.status = props.status || 'active';
        this.phone_verified = props.phone_verified || false;
        this.accepted_terms_at = props.accepted_terms_at;
        this.terms_version = props.terms_version;
        this.last_login_at = props.last_login_at;
        this.password_changed_at = props.password_changed_at;
        this.created_at = props.created_at;
        this.updated_at = props.updated_at;
    }

    fullName() { return `${this.firstName || ''} ${this.lastName || ''}`.trim() || 'Unknown'; }
    isActive() { return this.status === 'active'; }
    isAdmin() { return this.role === 'admin'; }
    isJuicer() { return this.role === 'juicer'; }
    isMechanic() { return this.role === 'mechanic'; }
    canLogin() { return this.isActive(); }
    hasAcceptedTerms() { return !!this.accepted_terms_at; }

    /**
     * Check if user can perform action
     */
    can(action, resource = null) {
        const { POLICIES } = require('../../../shared/permissions.js');
        const policy = POLICIES[action];
        if (!policy) return false;
        return policy(this, resource);
    }
}

/**
 * Token pair value object
 */
class TokenPair {
    constructor(accessToken, refreshToken, expiresIn = 900) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
        this.issuedAt = new Date();
    }

    isExpired() {
        return new Date() > new Date(this.issuedAt.getTime() + this.expiresIn * 1000);
    }

    toJSON() {
        return {
            access_token: this.accessToken,
            refresh_token: this.refreshToken,
            expires_in: this.expiresIn,
            issued_at: this.issuedAt,
        };
    }
}

/**
 * OTP code value object — represents a one-time password
 */
class OtpCode {
    constructor({ phone, purpose, code, expiresAt }) {
        this.phone = phone;
        this.purpose = purpose;
        this.code = code;
        this.expiresAt = expiresAt;
        this.attempts = 0;
        this.used = false;
    }

    isExpired(now = new Date()) {
        return new Date(this.expiresAt) < now;
    }

    isBlocked(maxAttempts = 5) {
        return this.attempts >= maxAttempts;
    }

    verify(inputCode) {
        if (this.used) return { ok: false, error: 'Code already used' };
        if (this.isExpired()) return { ok: false, error: 'Code expired' };
        if (this.isBlocked()) return { ok: false, error: 'Too many attempts' };
        if (this.code !== String(inputCode)) {
            this.attempts++;
            return { ok: false, error: 'Wrong code', attempts_left: 5 - this.attempts };
        }
        this.used = true;
        return { ok: true };
    }
}

module.exports = { User, TokenPair, OtpCode, USER_ROLES, USER_STATUSES };
