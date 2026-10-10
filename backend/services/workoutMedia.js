import multer from 'multer';
import sharp from 'sharp';
import jwt from 'jsonwebtoken';
import {createHash,randomUUID} from 'node:crypto';
import {mkdir,writeFile,unlink} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {fail,integer} from './workoutDomain.js';

const directory=fileURLToPath(new URL('../storage/workout/',import.meta.url));
const secret=()=>createHash('sha256').update(`${process.env.JWT_SECRET}:sirvya-workout-media`).digest('hex');
const upload=multer({storage:multer.memoryStorage(),limits:{fileSize:30*1024*1024,files:1,fields:0}}).single('file');

export function validMP4(buffer){
  let offset=0;const boxes=new Set();
  while(offset+8<=buffer.length){
    let size=buffer.readUInt32BE(offset);const type=buffer.toString('ascii',offset+4,offset+8);let header=8;
    if(size===1){if(offset+16>buffer.length)return false;const large=buffer.readBigUInt64BE(offset+8);if(large>BigInt(buffer.length))return false;size=Number(large);header=16;}
    if(size===0)size=buffer.length-offset;
    if(size<header||offset+size>buffer.length)return false;
    if(offset===0&&(type!=='ftyp'||size<16))return false;
    boxes.add(type);offset+=size;
  }
  return offset===buffer.length&&boxes.has('ftyp')&&boxes.has('moov')&&boxes.has('mdat');
}

export function installWorkoutMedia(router,db,{run,sessionAccess,visibleExercise},beforeAuthentication=false){
  const access=async(user,id)=>{
    const [[media]]=await db.query('SELECT * FROM workout_media WHERE id=?',[integer(id)]);
    if(!media)fail('media_not_found',404);
    if(media.sessionID)await sessionAccess(db,user,media.sessionID);
    else await visibleExercise(db,user,media.exerciseID);
    return media;
  };
  // Restricted download capability. Its signing key cannot authenticate API calls.
  if(beforeAuthentication){
    router.get('/media/:id/content',run(async(req,res)=>{
      let claim;try{claim=jwt.verify(req.query.ticket,secret(),{algorithms:['HS256'],audience:'workout-media'});}catch{fail('authentication_expired',401);}
      if(claim.mediaID!==integer(req.params.id))fail('media_not_found',404);
      const [[user]]=await db.query(`SELECT id,role,tokenVersion,
        EXISTS(SELECT 1 FROM bans WHERE userID=users.id AND isActive=1 AND (banType='permanent' OR expiresAt>NOW())) AS banned
        FROM users WHERE id=?`,[claim.userID]);
      if(!user||user.banned||!['client','coach'].includes(user.role)||Number(user.tokenVersion)!==Number(claim.tokenVersion??0))fail('authentication_expired',401);
      const media=await access(user,req.params.id);
      if(!/^[a-f0-9-]+\.(webp|mp4)$/.test(media.filename))fail('media_not_found',404);
      res.set({'Content-Type':media.mimeType,'X-Content-Type-Options':'nosniff','Cache-Control':'private, no-store'});
      res.sendFile(path.join(directory,media.filename),error=>{if(error&&!res.headersSent)res.status(404).end();});
    }));return;
  }
  router.get('/media/:id/ticket',run(async(req,res)=>{
    const media=await access(req.user,req.params.id);
    res.set('Cache-Control','no-store').json({ticket:jwt.sign({mediaID:Number(media.id),userID:Number(req.user.id),tokenVersion:req.user.tokenVersion??0},secret(),{algorithm:'HS256',audience:'workout-media',expiresIn:'15m'})});
  }));
  for(const kind of ['sessions','exercises']){
    const column=kind==='sessions'?'sessionID':'exerciseID';
    const target=async(req,writing=false)=>{
      if(kind==='sessions'){
        const s=await sessionAccess(db,req.user,req.params.id);
        if(writing&&(req.user.role!=='client'||Number(s.clientID)!==Number(req.user.id)||s.status==='cancelled'))fail('unauthorized_client',403);
        return s;
      }
      const e=await visibleExercise(db,req.user,req.params.id);
      if(writing&&Number(e.ownerID)!==Number(req.user.id))fail('unauthorized_client',403);
      return e;
    };
    router.get(`/${kind}/:id/media`,run(async(req,res)=>{
      const owner=await target(req);
      const [rows]=await db.query(`SELECT id,mimeType,createdAt FROM workout_media WHERE ${column}=? ORDER BY id`,[owner.id]);
      res.json({data:rows,canUpload:kind==='sessions'?req.user.role==='client'&&Number(owner.clientID)===Number(req.user.id):Number(owner.ownerID)===Number(req.user.id)});
    }));
    router.post(`/${kind}/:id/media`,run(async(req,res)=>{
      const owner=await target(req,true);
      await new Promise((resolve,reject)=>upload(req,res,error=>error?reject(Object.assign(error,{code:'invalid_media',status:400})):resolve()));
      const file=req.file;if(!file)fail('invalid_media');
      let bytes,extension,mimeType;
      const isMP4=validMP4(file.buffer);
      if(isMP4){bytes=file.buffer;extension='mp4';mimeType='video/mp4';}
      else {
        if(file.size>8*1024*1024)fail('invalid_media');
        try{
          const image=sharp(file.buffer,{limitInputPixels:40000000}),info=await image.metadata();
          if(!['jpeg','png','webp','heif'].includes(info.format))fail('invalid_media');
          bytes=await image.rotate().resize({width:1600,height:1600,fit:'inside',withoutEnlargement:true}).webp({quality:85}).toBuffer();
        }catch{fail('invalid_media');}extension='webp';mimeType='image/webp';
      }
      const filename=`${randomUUID()}.${extension}`;await mkdir(directory,{recursive:true});
      const conn=await db.getConnection();let stored=false;
      try{
        await conn.beginTransaction();
        await conn.query('SELECT id FROM users WHERE id=? FOR UPDATE',[req.user.id]);
        const [[count]]=await conn.query(`SELECT COUNT(*) AS total FROM workout_media WHERE ${column}=?`,[owner.id]);
        if(Number(count.total)>=10)fail('too_many_media');
        await writeFile(path.join(directory,filename),bytes,{flag:'wx'});stored=true;
        const [r]=await conn.query(`INSERT INTO workout_media (ownerID,${column},filename,mimeType) VALUES (?,?,?,?)`,[req.user.id,owner.id,filename,mimeType]);
        await conn.commit();res.status(201).json({id:r.insertId});
      }catch(error){await conn.rollback();if(stored)await unlink(path.join(directory,filename)).catch(()=>{});throw error;}
      finally{conn.release();}
    }));
  }
  router.delete('/media/:id',run(async(req,res)=>{
    const media=await access(req.user,req.params.id);
    if(Number(media.ownerID)!==Number(req.user.id))fail('unauthorized_client',403);
    await db.query('DELETE FROM workout_media WHERE id=? AND ownerID=?',[media.id,req.user.id]);
    await unlink(path.join(directory,media.filename)).catch(()=>{});
    res.json({deleted:true});
  }));
}
