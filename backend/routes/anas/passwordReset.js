import express from 'express';
import crypto from 'node:crypto';
import bcrypt from 'bcrypt';
import {requestLimit} from '../../middleware/requestLimit.js';

const normalize = value => typeof value === 'string' ? value.trim().toLowerCase() : '';
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
const codeDigest = (id, code) => crypto.createHmac('sha256', process.env.JWT_SECRET).update(`${id}:${code}`).digest('hex');
const invalid = res => res.status(400).json({error: 'Invalid or expired verification. Please request a new code.'});

export function createPasswordResetRouter(db, {sendCode} = {}) {
  const router = express.Router();
  router.use(['/forgot-password','/reset-password','/send-forgot-otp','/verify-forgot-otp','/reset-password-otp'], requestLimit({limit: 30, windowMs: 15 * 60000}));
  const transaction = async fn => {
    const conn = await db.getConnection();
    try { await conn.beginTransaction(); const value = await fn(conn); await conn.commit(); return value; }
    catch (error) { await conn.rollback(); throw error; }
    finally { conn.release(); }
  };
  const run = fn => async (req, res) => {
    try { await fn(req, res); }
    catch (error) {
      console.error('Password reset failed:', error.code || 'delivery_or_database_error');
      res.status(503).json({error: 'Password reset is temporarily unavailable. Try again shortly.'});
    }
  };
  // Retire the unused link endpoints, including all previously disclosed tokens.
  for (const path of ['/forgot-password', '/reset-password']) {
    router.post(path, (_req, res) => res.status(410).json({error: 'Use the email verification code password reset flow.'}));
  }
  router.post('/send-forgot-otp', run(async (req, res) => {
    const email = normalize(req.body?.email);
    if (!email || email.length > 255 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return invalid(res);
    const challenge = await transaction(async conn => {
      const [[user]] = await conn.query('SELECT id FROM users WHERE LOWER(email)=? FOR UPDATE', [email]);
      if (!user) return null;
      const [[recent]] = await conn.query('SELECT id FROM password_reset_challenges WHERE userID=? AND createdAt>DATE_SUB(NOW(),INTERVAL 1 MINUTE) LIMIT 1', [user.id]);
      if (recent) return null;
      const [[count]] = await conn.query('SELECT COUNT(*) AS n FROM password_reset_challenges WHERE userID=? AND createdAt>DATE_SUB(NOW(),INTERVAL 1 HOUR)', [user.id]);
      if (count.n >= 5) return null;
      const id = crypto.randomUUID(), otp = String(crypto.randomInt(100000, 1000000));
      await conn.query('UPDATE password_reset_challenges SET consumedAt=NOW() WHERE userID=? AND consumedAt IS NULL', [user.id]);
      await conn.query('INSERT INTO password_reset_challenges(id,userID,email,codeHash,expiresAt) VALUES(?,?,?,?,DATE_ADD(NOW(),INTERVAL 10 MINUTE))', [id,user.id,email,codeDigest(id,otp)]);
      return {id, otp};
    });
    if (challenge) {
      try { await sendCode({to: email, otp: challenge.otp, type: 'forgot_password'}); }
      catch (error) { await db.query('UPDATE password_reset_challenges SET consumedAt=NOW() WHERE id=?', [challenge.id]); throw error; }
    }
    res.json({message: 'If an account exists, a verification code has been sent.'});
  }));
  router.post('/verify-forgot-otp', run(async (req, res) => {
    const email = normalize(req.body?.email), otp = String(req.body?.otp ?? '').trim();
    if (!email || !/^\d{6}$/.test(otp)) return invalid(res);
    const capability = await transaction(async conn => {
      const [[row]] = await conn.query(`SELECT *, expiresAt>NOW() AS valid FROM password_reset_challenges
        WHERE email=? ORDER BY createdAt DESC,id DESC LIMIT 1 FOR UPDATE`, [email]);
      if (!row || !row.valid || row.consumedAt || row.verifiedAt || row.attempts >= 5) return null;
      await conn.query('UPDATE password_reset_challenges SET attempts=attempts+1 WHERE id=?', [row.id]);
      if (!crypto.timingSafeEqual(Buffer.from(row.codeHash,'hex'),Buffer.from(codeDigest(row.id,otp),'hex'))) return null;
      const token = crypto.randomBytes(32).toString('hex');
      await conn.query('UPDATE password_reset_challenges SET verifiedAt=NOW(),capabilityHash=?,capabilityExpiresAt=DATE_ADD(NOW(),INTERVAL 10 MINUTE) WHERE id=?', [digest(token),row.id]);
      return token;
    });
    if (!capability) return invalid(res);
    res.set('Cache-Control', 'no-store').json({verified: true, resetToken: capability});
  }));
  router.post('/reset-password-otp', run(async (req, res) => {
    const email = normalize(req.body?.email), token = req.body?.resetToken, password = req.body?.newPassword;
    if (!email || typeof token !== 'string' || !/^[a-f0-9]{64}$/.test(token)) return invalid(res);
    if (typeof password !== 'string' || password.length < 8 || Buffer.byteLength(password,'utf8') > 72) {
      return res.status(400).json({error: 'Use at least 8 characters and at most 72 UTF-8 bytes.'});
    }
    const done = await transaction(async conn => {
      // Lock the account first, matching send-code lock order and ensuring a
      // resend cannot invalidate the proof halfway through a password update.
      const [[user]] = await conn.query('SELECT id FROM users WHERE LOWER(email)=? FOR UPDATE',[email]);
      if (!user) return false;
      const [[row]] = await conn.query(`SELECT id FROM password_reset_challenges WHERE userID=? AND email=?
        AND capabilityHash=? AND verifiedAt IS NOT NULL AND capabilityExpiresAt>NOW() AND consumedAt IS NULL FOR UPDATE`,[user.id,email,digest(token)]);
      if (!row) return false;
      const hash = await bcrypt.hash(password,12);
      await conn.query('UPDATE users SET passwordHash=?,tokenVersion=tokenVersion+1 WHERE id=?',[hash,user.id]);
      await conn.query('UPDATE password_reset_challenges SET consumedAt=NOW(),capabilityHash=NULL WHERE userID=? AND consumedAt IS NULL',[user.id]);
      await conn.query('UPDATE authtokens SET revokedAt=NOW() WHERE userID=? AND revokedAt IS NULL',[user.id]);
      return true;
    });
    if (!done) return invalid(res);
    res.json({message: 'Password updated successfully. Sign in again.'});
  }));
  return router;
}
