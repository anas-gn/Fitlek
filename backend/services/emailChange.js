import crypto from 'node:crypto';
import {Router} from 'express';

export const EMAIL_CHANGE_SCHEMA = `CREATE TABLE IF NOT EXISTS email_change_requests (
  userID BIGINT UNSIGNED PRIMARY KEY, oldEmail VARCHAR(255) NOT NULL, newEmail VARCHAR(255) NOT NULL,
  oldHash CHAR(64) NOT NULL, newHash CHAR(64) NULL, oldVerified TINYINT NOT NULL DEFAULT 0,
  attempts INT NOT NULL DEFAULT 0, expiresAt DATETIME NOT NULL, sentAt DATETIME NOT NULL,
  FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
)`;
const hash = (userID, email, code) => crypto.createHash('sha256').update(`${userID}:${email}:${code}`).digest('hex');
const code = () => String(crypto.randomInt(100000,1000000));
const fail = (message,status=400) => Object.assign(new Error(message),{status});

export function emailChangeRouter(db,sendEmail) {
  const router=Router();
  function handler(action) {return async(req,res)=>{
    const tx=await db.getConnection();
    try {
      await tx.beginTransaction();
      const [[user]]=await tx.query('SELECT id,email FROM users WHERE id=? FOR UPDATE',[req.user.id]);
      if(!user) throw fail('Account not found.',404);
      const [[request]]=await tx.query('SELECT *,expiresAt<=NOW() AS expired,TIMESTAMPDIFF(SECOND,sentAt,NOW()) AS elapsed FROM email_change_requests WHERE userID=? FOR UPDATE',[user.id]);
      if(action==='start') {
        const email=String(req.body.newEmail || '').trim().toLowerCase();
        if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>254) throw fail('Enter a valid new email address.');
        if(email===user.email.toLowerCase()) throw fail('Choose a different email address.');
        if(request && request.elapsed<60) throw fail('Wait 60 seconds before requesting another code.',429);
        const [existing]=await tx.query('SELECT id FROM users WHERE LOWER(email)=? AND id<>?',[email,user.id]);
        if(existing.length) throw fail('This email is already associated with an account.',409);
        const otp=code();
        await sendEmail({to:user.email,otp,type:'change_email_old'});
        await tx.query(`INSERT INTO email_change_requests (userID,oldEmail,newEmail,oldHash,expiresAt,sentAt)
          VALUES (?,?,?,?,DATE_ADD(NOW(),INTERVAL 10 MINUTE),NOW())
          ON DUPLICATE KEY UPDATE oldEmail=VALUES(oldEmail),newEmail=VALUES(newEmail),oldHash=VALUES(oldHash),
          newHash=NULL,oldVerified=0,attempts=0,expiresAt=VALUES(expiresAt),sentAt=NOW()`,[user.id,user.email,email,hash(user.id,user.email,otp)]);
        await tx.commit();return res.json({message:'Code sent to your current email.',newEmail:email});
      }
      if(!request || request.expired || request.oldEmail!==user.email) throw fail('This request expired. Start the email change again.');
      if(request.attempts>=5) throw fail('Too many incorrect codes. Start again after the resend waiting period.',429);
      if(action==='resend') {
        if(request.elapsed<60) throw fail('Wait 60 seconds before requesting another code.',429);
        const otp=code();const email=request.oldVerified?request.newEmail:request.oldEmail;
        await sendEmail({to:email,otp,type:request.oldVerified?'change_email_new':'change_email_old'});
        await tx.query(`UPDATE email_change_requests SET ${request.oldVerified?'newHash':'oldHash'}=?,attempts=0,expiresAt=DATE_ADD(NOW(),INTERVAL 10 MINUTE),sentAt=NOW() WHERE userID=?`,[hash(user.id,email,otp),user.id]);
        await tx.commit();return res.json({message:'New code sent.'});
      }
      if(action==='confirm' && !request.oldVerified) throw fail('Verify your current email first.');
      if(action==='verify-old' && request.oldVerified) throw fail('Your current email is already verified. Enter the code sent to your new email.');
      const supplied=String(req.body.otp || '').trim();
      const email=action==='verify-old'?request.oldEmail:request.newEmail;
      const expected=action==='verify-old'?request.oldHash:request.newHash;
      if(!/^\d{6}$/.test(supplied) || !expected || hash(user.id,email,supplied)!==expected) {
        await tx.query('UPDATE email_change_requests SET attempts=attempts+1 WHERE userID=?',[user.id]);
        await tx.commit();return res.status(400).json({error:'Incorrect verification code.'});
      }
      if(action==='verify-old') {
        const otp=code();
        await sendEmail({to:request.newEmail,otp,type:'change_email_new'});
        await tx.query('UPDATE email_change_requests SET oldVerified=1,newHash=?,attempts=0,expiresAt=DATE_ADD(NOW(),INTERVAL 10 MINUTE),sentAt=NOW() WHERE userID=?',[hash(user.id,request.newEmail,otp),user.id]);
        await tx.commit();return res.json({message:'Current email verified. Code sent to your new email.',newEmail:request.newEmail});
      }
      const [existing]=await tx.query('SELECT id FROM users WHERE LOWER(email)=? AND id<>?',[request.newEmail,user.id]);
      if(existing.length) throw fail('This email is already associated with an account.',409);
      await tx.query('UPDATE users SET email=? WHERE id=?',[request.newEmail,user.id]);
      await tx.query('DELETE FROM email_change_requests WHERE userID=?',[user.id]);
      await tx.commit();res.json({message:'Email updated successfully.',email:request.newEmail});
    } catch(error) {
      await tx.rollback();
      res.status(error.code==='ER_DUP_ENTRY'?409:error.status || 500).json({error:error.status?error.message:error.code==='ER_DUP_ENTRY'?'This email is already associated with an account.':'Could not complete the email change. Please try again.'});
    } finally {tx.release();}
  };}
  for(const action of ['start','verify-old','confirm','resend']) router.post(`/${action}`,handler(action));
  return router;
}
