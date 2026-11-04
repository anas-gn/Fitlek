import {Router} from 'express';
import db from '../../config/db.js';
const router = Router();
router.get('/:code', async (req,res) => {
 const code = String(req.params.code).trim().toUpperCase();
 if (!/^[A-Z0-9-]{4,64}$/.test(code)) return res.status(400).send('Invalid invitation code');
 try {
  const [[coach]] = await db.query(`SELECT cp.userID, u.firstName, u.lastName FROM coachprofiles cp JOIN users u ON u.id=cp.userID
    WHERE cp.invitationCode=? AND u.role='coach' LIMIT 1`,[code]);
  if (!coach) return res.status(404).send('Invitation not found');
  const inviter = `${coach.firstName || ''} ${coach.lastName || ''}`.trim() || 'A SIRVYA coach';
  const safeName = inviter.replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  const appLink = `sirvya://invite?code=${encodeURIComponent(code)}`;
  res.set('Cache-Control','no-store');
  res.set('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'");
  res.send(`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>${safeName} invites you to SIRVYA</title>
    <meta name="description" content="Join SIRVYA through a personal invitation. Find your coach or grow your coaching business.">
    <meta property="og:title" content="${safeName} invites you to SIRVYA">
    <meta property="og:description" content="Your next chapter starts here. Join as a client or coach with your personal invitation code.">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://sirvya.com/invite/${code}"><style>body{background:#091b18;color:#f3f1e7;font-family:system-ui;display:grid;place-items:center;min-height:90vh;margin:20px}main{max-width:380px;text-align:center}a{display:block;background:#f3f1e7;color:#073d37;padding:16px;border-radius:16px;text-decoration:none;font-weight:700}code{font-size:24px;letter-spacing:2px}p{line-height:1.6;color:#a7bbb6}</style>
    <main><p style="letter-spacing:4px;font-weight:800">SIRVYA</p><h1>Your next chapter starts here</h1><p><strong>${safeName}</strong> has invited you to join SIRVYA. Find your coach or grow your coaching business.</p><p>Use your personal invitation code when signing up:</p><h2><code>${code}</code></h2>
    <a href="${appLink}">Open SIRVYA and sign up</a><p>If the app isn't installed, install SIRVYA and enter this code during signup. Already have an account? The link won't create another one.</p></main></html>`);
 } catch (_) {res.status(503).send('Please try again later');}
});
export default router;
