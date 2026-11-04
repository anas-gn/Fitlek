export const CAMPAIGN_SCHEMA = [
 `CREATE TABLE IF NOT EXISTS app_campaigns (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,adminID BIGINT UNSIGNED NOT NULL,title VARCHAR(90) NOT NULL,body VARCHAR(500) NOT NULL DEFAULT '',imageUrl VARCHAR(600) NOT NULL DEFAULT '',destination VARCHAR(500) NOT NULL DEFAULT '',buttonLabel VARCHAR(40) NOT NULL DEFAULT '',audience VARCHAR(10) NOT NULL,pushEnabled TINYINT NOT NULL DEFAULT 1,popupEnabled TINYINT NOT NULL DEFAULT 0,bannerEnabled TINYINT NOT NULL DEFAULT 0,bannerID INT NULL,status VARCHAR(10) NOT NULL DEFAULT 'draft',startsAt DATETIME NOT NULL,expiresAt DATETIME NULL,dispatchedAt DATETIME NULL,createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,INDEX(status,startsAt))`,
 `CREATE TABLE IF NOT EXISTS app_campaign_receipts (campaignID BIGINT UNSIGNED NOT NULL,userID BIGINT UNSIGNED NOT NULL,seenAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(campaignID,userID))`
];
export async function ensureCampaignSchema(db){for(const sql of CAMPAIGN_SCHEMA)await db.query(sql);}
export function validateCampaign(input){
 const title=String(input.title||'').trim(),body=String(input.body||'').trim(),imageUrl=String(input.imageUrl||'').trim(),destination=String(input.destination||'').trim(),buttonLabel=String(input.buttonLabel||'').trim();
 if(!title||title.length>90||body.length>500||buttonLabel.length>40)throw Error('Titre obligatoire (90 caractères maximum), texte 500 et bouton 40 maximum.');
 const url=v=>{try{const u=new URL(v);return ['https:','http:'].includes(u.protocol)&&!u.username&&!u.password}catch{return false}};
 if(imageUrl.length>600||(imageUrl&&!url(imageUrl)))throw Error('URL d’image HTTP/HTTPS invalide.');
 const paths=['/explore','/coaches','/sessions','/profile','/messages','/notifications','/scan'];
 if(destination.length>500||(destination&&!paths.includes(destination)&&!/^\/(coaches|sessions)\/[1-9][0-9]*$/.test(destination)&&!url(destination)&&!/^(mailto:[^\s@]+@[^\s@]+|tel:\+?[0-9 ()-]+|sms:\+?[0-9 ()-]+)$/i.test(destination)))throw Error('Destination invalide.');
 if(!['all','client','coach'].includes(input.audience))throw Error('Audience invalide.');
 if(input.audience!=='client'&&(['/explore','/coaches','/scan'].includes(destination)||destination.startsWith('/coaches/')))throw Error('Cette destination est réservée aux clients. Choisissez l’audience Clients.');
 for(const key of ['pushEnabled','popupEnabled','bannerEnabled'])if(typeof input[key]!=='boolean')throw Error('Canal de diffusion invalide.');
 if(!input.pushEnabled&&!input.popupEnabled&&!input.bannerEnabled)throw Error('Choisissez au moins un canal de diffusion.');
 if(input.bannerEnabled&&input.audience==='coach')throw Error('La bannière d’accueil est réservée aux clients.');
 const date=v=>{const d=new Date(v);if(!Number.isFinite(d.getTime()))throw Error('Date invalide.');return d.toISOString().slice(0,19).replace('T',' ')};
 const startsAt=date(input.startsAt||new Date()),expiresAt=input.expiresAt?date(input.expiresAt):null;
 if(expiresAt&&expiresAt<=startsAt)throw Error('La fin doit être après le début.');
 return {title,body,imageUrl,destination,buttonLabel,audience:input.audience,pushEnabled:input.pushEnabled,popupEnabled:input.popupEnabled,bannerEnabled:input.bannerEnabled,startsAt,expiresAt};
}
export async function dispatchCampaigns(db){
 await db.query("UPDATE actualites a JOIN app_campaigns c ON c.bannerID=a.id SET a.isPublished=0 WHERE c.status<>'active' OR (c.expiresAt IS NOT NULL AND c.expiresAt<=UTC_TIMESTAMP())");
 const [due]=await db.query("SELECT id FROM app_campaigns WHERE status='active' AND dispatchedAt IS NULL AND startsAt<=UTC_TIMESTAMP() AND (expiresAt IS NULL OR expiresAt>UTC_TIMESTAMP()) ORDER BY id LIMIT 20");
 for(const {id} of due){const tx=await db.getConnection();try{await tx.beginTransaction();
  const [[c]]=await tx.query("SELECT * FROM app_campaigns WHERE id=? AND status='active' AND dispatchedAt IS NULL AND startsAt<=UTC_TIMESTAMP() AND (expiresAt IS NULL OR expiresAt>UTC_TIMESTAMP()) FOR UPDATE",[id]);
  if(!c){await tx.rollback();continue;}
  if(c.pushEnabled||c.popupEnabled)await tx.query(`INSERT IGNORE INTO notifications (recipientUserID,type,title,body,relatedEntityID,actorName,uniqueKey,pushDelivered)
    SELECT u.id,'app_campaign',?, ?,?,'Sirvya',CONCAT('app_campaign:',?,':',u.id),? FROM users u WHERE u.role IN ('client','coach') AND (?='all' OR u.role=?)`,[c.title,c.body.slice(0,255),id,id,c.pushEnabled?0:1,c.audience,c.audience]);
  if(c.bannerEnabled){const [r]=await tx.query('INSERT INTO actualites (adminID,title,content,imageUrl,link,buttonLabel,isPublished,publishedAt) VALUES (?,?,?,?,?,?,1,UTC_TIMESTAMP())',[c.adminID,c.title,c.body,c.imageUrl,c.destination,c.buttonLabel]);await tx.query('UPDATE app_campaigns SET bannerID=? WHERE id=?',[r.insertId,id]);}
  await tx.query('UPDATE app_campaigns SET dispatchedAt=UTC_TIMESTAMP() WHERE id=?',[id]);await tx.commit();
 }catch(e){await tx.rollback();throw e;}finally{tx.release();}}
}

export async function claimCampaignPopup(db,campaignID,user){
 const [result]=await db.query(`INSERT IGNORE INTO app_campaign_receipts (campaignID,userID)
   SELECT c.id,? FROM app_campaigns c WHERE c.id=? AND c.status='active' AND c.startsAt<=UTC_TIMESTAMP()
   AND (c.expiresAt IS NULL OR c.expiresAt>UTC_TIMESTAMP()) AND (c.audience='all' OR c.audience=?) AND c.popupEnabled=1`,[user.id,campaignID,user.role]);
 return result.affectedRows>0;
}
