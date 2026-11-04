import {Router} from 'express';
import db from '../../config/db.js';
import {requireRole} from '../../middleware/auth.js';
import {rankCoaches,specialties} from '../../services/coachRecommendations.js';
const router=Router();
router.get('/',requireRole('client'),async(req,res)=>{
  try{
    const userID=req.user.id;
    const [[client]]=await db.query(`SELECT u.interests,COALESCE(l.city,u.ville) AS city,l.latitude,l.longitude,l.updatedAt AS locationUpdatedAt
      FROM users u LEFT JOIN user_locations l ON l.userID=u.id WHERE u.id=?`,[userID]);
    const [history]=await db.query(`SELECT cp.specialties,cp.specialty FROM coachprofiles cp WHERE cp.userID IN
      (SELECT coachID FROM coach_favorites WHERE clientID=? UNION SELECT coachID FROM reservations WHERE clientID=? AND status='confirmed')`,[userID,userID]);
    const [rows]=await db.query(`SELECT u.id,u.firstName,u.lastName,u.avatarUrl,u.isPremium,u.isApproved,
      cp.bio,cp.instagramPage,cp.invitationCode,cp.totalInvitations,cp.earnedPoints,cp.tel,cp.price,cp.ville,
      cp.specialties,cp.specialty,cp.specialty AS speciality,cp.certifications,
      l.latitude,l.longitude,l.updatedAt AS locationUpdatedAt,
      COALESCE(rv.rating,0) AS rating,COALESCE(rv.reviewCount,0) AS reviewCount,
      COALESCE(pk.packageCount,0) AS packageCount,pk.minPrice,
      COALESCE(rs.completedSessions,0) AS completedSessions
      FROM users u JOIN coachprofiles cp ON cp.userID=u.id
      LEFT JOIN user_locations l ON l.userID=u.id
      LEFT JOIN (SELECT coachID,AVG(rating) AS rating,COUNT(*) AS reviewCount FROM coachreviews GROUP BY coachID) rv ON rv.coachID=u.id
      LEFT JOIN (SELECT coachID,COUNT(*) AS packageCount,MIN(price) AS minPrice FROM coach_packages WHERE isActive=1 GROUP BY coachID) pk ON pk.coachID=u.id
      LEFT JOIN (SELECT coachID,COUNT(*) AS completedSessions FROM reservations WHERE status='confirmed' AND reservedDate<CURDATE() GROUP BY coachID) rs ON rs.coachID=u.id
      WHERE u.role='coach' AND u.id NOT IN (SELECT blockedID FROM user_blocks WHERE blockerID=?)
      AND u.id NOT IN (SELECT blockerID FROM user_blocks WHERE blockedID=?)`,[userID,userID]);
    const interests=history.flatMap(c=>[...specialties(c.specialties),...specialties(c.specialty)]);
    const ranked=rankCoaches(rows,client||{},{interests,explicitInterests:specialties(client?.interests),selectedSpecialty:String(req.query.specialty||'')});
    const limit=Math.min(50,Math.max(1,Number(req.query.limit)||20));
    res.json(ranked.slice(0,limit));
  }catch(error){console.error('Recommendations failed:',error.message);res.status(500).json({error:'Could not load your recommendations.'});}
});
export default router;
