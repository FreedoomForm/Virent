/**
 * User domain entity
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
        this.created_at = props.created_at;
        this.updated_at = props.updated_at;
    }

    fullName() { return `${this.firstName} ${this.lastName}`.trim() || 'Unknown'; }
    isActive() { return this.status === 'active'; }
    isAdmin() { return this.role === 'admin'; }
    canLogin() { return this.isActive(); }
}

module.exports = { User, USER_ROLES, USER_STATUSES };
