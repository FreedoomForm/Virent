# Security Policy

## ⚠️ Critical: Token Safety

**NEVER commit GitHub tokens, API keys, or passwords to git.**

If a token has been exposed (in chat, screenshot, log, or commit):
1. **Revoke immediately** at https://github.com/settings/tokens
2. Create a new token
3. Audit repo access logs for unauthorized activity
4. Force-push to remove from git history if committed

## How to Handle Tokens Safely

### ❌ NEVER do this:
```bash
# Token in URL
git remote add origin https://github.com/user/repo-ghp_xxx.git

# Token in code
const TOKEN = 'ghp_REDACTED';

# Token in chat
"Push to https://github.com/user/repo-ghp_xxx"
```

### ✅ DO this:
```bash
# Token in environment variable
export GH_TOKEN=ghp_xxx
git push origin main

# Or use GitHub CLI
gh auth login
gh repo push

# Or git credential helper
git config --global credential.helper store
# (saves to ~/.git-credentials with 600 perms)
```

## What to do if a token is compromised

1. **Revoke NOW**: https://github.com/settings/tokens → Delete
2. **Create new token**: https://github.com/settings/tokens/new
3. **Check audit log**: https://github.com/settings/security-log
4. **Check repo access**: https://github.com/settings/repositories
5. **Check OAuth apps**: https://github.com/settings/applications
6. **Enable 2FA**: https://github.com/settings/security

## Token Scopes

Minimal scopes for this project:
- `repo` (for push to private repos)
- `workflow` (for GitHub Actions)

Don't grant:
- `delete_repo` (unless really needed)
- `admin:org` (unless managing org)
- `user` (unless needed)

## Reporting Security Issues

If you find a security vulnerability:
1. DO NOT open a public issue
2. Email: security@sparkrentals.uz (or DM maintainer)
3. Include: description, reproduction steps, affected versions
4. Wait for response before public disclosure

## Security Headers (in nginx)

The included nginx config sets:
- `Strict-Transport-Security` (HSTS)
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`

## Backend Security

- Helmet middleware (security headers)
- Rate limiting (4 separate limiters)
- Input validation on all endpoints
- MongoDB sanitize (NoSQL injection protection)
- bcrypt password hashing
- JWT with rotation (access 15min + refresh 30d)
- Audit log for all admin actions
- Sensitive data auto-redacted in logs
