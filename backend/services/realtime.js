import jwt from 'jsonwebtoken';

let io;
export function setRealtimeServer(server) { io = server; }
export function authenticateSocket(socket, next) {
  try {
    const user = jwt.verify(socket.handshake.auth?.token, process.env.JWT_SECRET);
    if (!user.id || !['client','coach'].includes(user.role)) throw new Error('Unauthorized');
    socket.data.user = user;
    next();
  } catch { next(new Error('Unauthorized')); }
}
export async function canAccessConversation(db, conversationID, userID) {
  if (!/^[1-9]\d*$/.test(String(conversationID))) return false;
  const [[row]] = await db.query('SELECT id FROM conversations WHERE id=? AND (coachID=? OR clientID=?)', [conversationID,userID,userID]);
  return !!row;
}
export function emitUser(userID, event, payload) { io?.to(`user_${userID}`).emit(event, payload); }
export function emitMessage(message, conversation) {
  io?.to(`user_${conversation.coachID}`).to(`user_${conversation.clientID}`).emit('new_message', message);
}
export function invalidate(domain) { io?.emit('data_changed', {domain}); }
export function realtimeWrites(req, res, next) {
  if (!['POST','PUT','PATCH','DELETE'].includes(req.method)) return next();
  res.on('finish', () => {
    if (res.statusCode < 200 || res.statusCode >= 300) return;
    const parts = req.originalUrl.split('?')[0].split('/').filter(Boolean);
    const domain = parts[1] === 'coach' ? parts[2] : parts[1];
    // No names, coordinates, message contents or record IDs go to unrelated accounts.
    if (domain && !['auth','register','upload','messages','chat','chat-actions','chat-media','campaigns'].includes(domain)) invalidate(domain);
  });
  next();
}
