import assert from 'node:assert/strict';
import crypto from 'node:crypto';

const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

const tokenA = crypto.randomBytes(32).toString('hex');
const tokenB = crypto.randomBytes(32).toString('hex');
const userA = {
  email: 'driver@example.com',
  passwordResetTokenHash: hashToken(tokenA),
  passwordResetExpiresAt: new Date(Date.now() + 15 * 60 * 1000),
};
const userB = {
  email: 'other@example.com',
  passwordResetTokenHash: hashToken(tokenB),
  passwordResetExpiresAt: new Date(Date.now() + 15 * 60 * 1000),
};

const canReset = ({ user, email, token, now = new Date() }) =>
  user.email === email &&
  user.passwordResetTokenHash === hashToken(token) &&
  user.passwordResetExpiresAt > now;

assert.equal(canReset({ user: userA, email: userA.email, token: tokenA }), true);
assert.equal(canReset({ user: userA, email: userA.email, token: 'wrong' }), false);
assert.equal(
  canReset({
    user: { ...userA, passwordResetExpiresAt: new Date(Date.now() - 1000) },
    email: userA.email,
    token: tokenA,
  }),
  false,
);
assert.equal(canReset({ user: userA, email: userB.email, token: tokenA }), false);
assert.equal(canReset({ user: userA, email: userA.email, token: tokenB }), false);

userA.passwordResetTokenHash = null;
userA.passwordResetExpiresAt = null;
assert.equal(canReset({ user: userA, email: userA.email, token: tokenA }), false);

console.log('Password reset security checks passed');
