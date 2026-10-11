import {Router} from 'express';
import jwt from 'jsonwebtoken';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {publicOrigin} from '../config/runtime.js';

const secret=()=>createHash('sha256').update(`${process.env.JWT_SECRET}:sirvya-chat-media`).digest('hex');
const failure=(status,message)=>{throw Object.assign(new Error(message),{status});};
const validFilename=/^chat_(img|aud)_[a-zA-Z0-9_-]+\.(webp|m4a|aac|mp3|wav|ogg|webm|mp4)$/;

export async function ensureChatMediaSchema(db){
  await db.query(`CREATE TABLE IF NOT EXISTS chat_uploads (
    filename VARCHAR(200) NOT NULL PRIMARY KEY, ownerID BIGINT UNSIGNED NOT NULL,
    createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_chat_upload_owner(ownerID),
    FOREIGN KEY(ownerID) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB`);
}

export function chatFilename(url){
  try{
    const parsed=new URL(url);
    const filename=decodeURIComponent(parsed.pathname.slice('/uploads/chat_media/'.length));
    return ['http:','https:'].includes(parsed.protocol)&&parsed.pathname.startsWith('/uploads/chat_media/')&&validFilename.test(filename)?filename:null;
  }catch{return null;}
}

export function signedChatMedia(req,url){
  const filename=chatFilename(url);if(!filename)return url;
  const ticket=jwt.sign({filename,userID:Number(req.user.id),tokenVersion:Number(req.user.tokenVersion??0)},secret(),{algorithm:'HS256',audience:'chat-media',expiresIn:'15m'});
  return `${publicOrigin(req)}/uploads/chat_media/${filename}?ticket=${encodeURIComponent(ticket)}`;
}

async function canRead(db,userID,filename){
  const [[row]]=await db.query(`SELECT (
    EXISTS(SELECT 1 FROM chat_uploads WHERE filename=? AND ownerID=?) OR
    EXISTS(SELECT 1 FROM messages m JOIN conversations c ON c.id=m.conversationID
      WHERE m.mediaExpired=0 AND (c.clientID=? OR c.coachID=?)
      AND SUBSTRING_INDEX(SUBSTRING_INDEX(m.mediaUrl,'?',1),'/',-1)=?)
    ) AS allowed`,[filename,userID,userID,userID,filename]);
  return Boolean(row?.allowed);
}

export async function validateChatAttachment(db,userID,url){
  if(url==null||url==='')return null;
  if(typeof url!=='string'||url.length>2048)failure(400,'Invalid chat attachment');
  const filename=chatFilename(url);
  if(!filename)failure(400,'Invalid chat attachment');
  if(!await canRead(db,userID,filename))failure(403,'Chat attachment access denied');
  // Store the stable local path, never the temporary capability or a foreign host.
  return filename;
}

export function createChatMediaRouter(db,directory){
  const router=Router();
  router.get('/:filename',async(req,res)=>{
    try{
      const filename=req.params.filename;if(!validFilename.test(filename))failure(404,'Media not found');
      let claim;
      try{claim=jwt.verify(req.query.ticket,secret(),{algorithms:['HS256'],audience:'chat-media'});}catch{failure(401,'Authentication required');}
      if(claim.filename!==filename)failure(404,'Media not found');
      const [[user]]=await db.query(`SELECT id,tokenVersion,
        EXISTS(SELECT 1 FROM bans WHERE userID=users.id AND isActive=1 AND (banType='permanent' OR expiresAt>NOW())) AS banned
        FROM users WHERE id=?`,[claim.userID]);
      if(!user||user.banned||Number(user.tokenVersion)!==Number(claim.tokenVersion??0))failure(401,'Authentication expired');
      if(!await canRead(db,user.id,filename))failure(403,'Media access denied');
      res.set({'X-Content-Type-Options':'nosniff','Cache-Control':'private, no-store'});
      res.sendFile(path.resolve(directory,filename),error=>{if(error&&!res.headersSent)res.status(404).json({error:'Media not found'});});
    }catch(error){res.status(error.status??503).json({error:error.status?error.message:'Media unavailable'});}
  });
  // No request may fall through to the public /uploads static mount.
  router.use((_req,res)=>res.status(404).json({error:'Media not found'}));
  return router;
}
