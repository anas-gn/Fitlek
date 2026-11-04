export const CLIENT_REFERRAL_SCHEMA = `CREATE TABLE IF NOT EXISTS clientreferrals (
 id INT AUTO_INCREMENT PRIMARY KEY,
 inviterCoachID BIGINT UNSIGNED NOT NULL,
 invitedClientID BIGINT UNSIGNED NOT NULL,
 invitationCode VARCHAR(64) NOT NULL,
 createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uniq_referred_client (invitedClientID),
 KEY idx_clientref_inviter (inviterCoachID),
 FOREIGN KEY (inviterCoachID) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY (invitedClientID) REFERENCES users(id) ON DELETE CASCADE
);`;
// Called inside the signup transaction, only after creating a new client.
// UNIQUE(invitedClientID) prevents repeated attribution across login providers.
export async function recordClientReferral(conn, inviterCoachID, clientID, code) {
 if (!inviterCoachID) return;
 if (Number(inviterCoachID) === Number(clientID)) throw new Error('You cannot invite yourself.');
 await conn.query('INSERT INTO clientreferrals (inviterCoachID, invitedClientID, invitationCode) VALUES (?,?,?)',
   [inviterCoachID, clientID, code]);
 await conn.query('INSERT INTO invitations (coachID, invitedUserID, status, pointsEarned, clickedAt) VALUES (?, ?, "pending", 0, NOW())',
   [inviterCoachID, clientID]);
 await conn.query('UPDATE coachprofiles SET totalInvitations = totalInvitations + 1 WHERE userID = ?', [inviterCoachID]);
}

// Notifications are emitted after commit; a delivery failure must not undo signup.
export async function notifyReferralSignup(db, clientID, role) {
 try {
  const table = role === 'client' ? 'clientreferrals' : 'coachreferrals';
  const field = role === 'client' ? 'invitedClientID' : 'invitedCoachID';
  const [[referral]] = await db.query(`SELECT inviterCoachID FROM ${table} WHERE ${field}=?`,[clientID]);
  if (!referral) return;
  const {invalidate} = await import('./realtime.js');
  invalidate('invitations');
  const {createAndSendNotification} = await import('./pushNotificationService.js');
  await createAndSendNotification({recipientUserID:referral.inviterCoachID,type:'referral_signup',
    title:'Your invitation brought someone to SIRVYA',
    body: role === 'client' ? 'A new client joined with your code. Accept their connection in Clients to earn 20 points.' : 'A new coach joined with your code. You earned 40 points.',
    relatedEntityID:clientID,uniqueKey:`referral_signup:${clientID}`});
 } catch (error) {console.error('Referral notification unavailable:',error.code || 'delivery error');}
}
