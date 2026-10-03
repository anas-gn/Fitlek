import coachSignIn from './routes/pahae/coachSignIn.js';
import coachSignUp from './routes/pahae/coachSignUp.js';
import coachDashboard from './routes/pahae/coachDashboard.js';
import coachCalendar from './routes/pahae/coachCalendar.js';
import coachConversations from './routes/pahae/coachConversations.js';
import coachChat from './routes/pahae/coachChat.js';
import coachClients from './routes/pahae/coachClients.js';
import coachInviteClients from './routes/pahae/coachInviteClients.js';
import coachInvitations from './routes/pahae/coachInvitations.js';
import coachNotifications from './routes/pahae/coachNotifications.js';
import coachProfile from './routes/pahae/coachProfile.js';
import coachAvatarRouter from './routes/pahae/coachAvatar.js';
import coachEditProfile from './routes/pahae/coachEditProfile.js';
import managerSignIn from './routes/pahae/managerSignIn.js';
import managerDashboard from './routes/pahae/managerDashboard.js';
import managerClients from './routes/pahae/managerClients.js';
import managerCreateClient from './routes/pahae/managerCreateClient.js';
import managerEditClient from './routes/pahae/managerEditClient.js';
import managerCoaches from './routes/pahae/managerCoaches.js';
import managerCreateCoach from './routes/pahae/managerCreateCoach.js';
import managerEditCoach from './routes/pahae/managerEditCoach.js';
import managerAdmins from './routes/pahae/managerAdmins.js';
import managerCreateAdmin from './routes/pahae/managerCreateAdmin.js';
import managerEditAdmin from './routes/pahae/managerEditAdmin.js';
import managerAdvisors from './routes/pahae/managerAdvisors.js';
import managerBans from './routes/pahae/managerBans.js';
import managerPendingCoaches from './routes/pahae/managerPendingCoaches.js';
import managerReservations from './routes/pahae/managerReservations.js';
import managerProfile from './routes/pahae/managerProfile.js';

import authRoutes from './routes/anas/auth.js';
import clientRoutes from './routes/anas/client.js';
import coachRoutes from './routes/anas/coach.js';
import advisorProfilesRoutes from './routes/anas/advisorProfiles.js';
import reservationsRoutes from './routes/anas/reservations.js';
import coachAvailabilityRoutes from './routes/anas/coachAvailability.js';
import conversationsRoutes from './routes/anas/conversations.js';
import messagesRoutes from './routes/anas/messages.js';
import invitationsRoutes from './routes/anas/invitations.js';
import coachClientsRoutes from './routes/anas/coachClients.js';
import bansRoutes from './routes/anas/bans.js';
import reviewsRoutes from './routes/anas/reviews.js';
import weightHistoryRoutes from './routes/anas/weightHistory.js';
import uploadRoutes from './routes/anas/upload.js';
import appVersionRoutes from './routes/anas/appVersion.js';
import ugcRoutes from './routes/anas/ugc.js';
import categoryRoutes from './routes/anas/categories.js';
import favoriteRoutes from './routes/anas/favorites.js';
import premiumRoutes from './routes/anas/premium.js';
import premiumWorkoutRoutes from './routes/anas/premiumWorkouts.js';
import premiumCoachRoutes from './routes/anas/premiumCoach.js';
import db from './config/db.js';
import { ensureGoogleAuthSchema } from './config/googleAuthSchema.js';
import { ensureAppCompatibilitySchema } from './config/appCompatibilitySchema.js';
import { ensureWorkoutSchema } from './config/workoutSchema.js';
import { createWorkoutRouter } from './routes/anas/workout.js';
import { createAndSendNotification } from './services/pushNotificationService.js';

import express from 'express';
import notificationsRoutes from './routes/anas/notifications.js';
import {startWorkoutReminders} from './services/workoutReminders.js';
import {startWorkoutMediaCleanup} from './services/workoutMediaCleanup.js';
import path from 'path';
import cors from 'cors';
import dotenv from 'dotenv';
import { initFirebase } from './config/firebase.js';
import { requireAuth } from './middleware/auth.js';
import {
  ensureReferralSchema,
  ensureClientInvitationSchema,
  ensureNotificationSchema,
  ensureCoachProfileColumns,
  ensureTermsAcceptedColumn,
  ensureOTPSchema,
  ensureFcmTokenColumn,
  ensureAppVersionSchema,
  ensureDeletedAccountsSchema,
  ensureUgcComplianceSchema,
  ensureCoachImagesSchema,
} from './config/ensureSchema.js';
import { startMediaCleanupJob } from './cron/mediaCleanup.js';
dotenv.config();
initFirebase();
startMediaCleanupJob();

// Auth routes must not accept requests against a partially migrated schema.
await ensureGoogleAuthSchema(db);
await ensureAppCompatibilitySchema(db);

let resolveWorkoutSchema;
let rejectWorkoutSchema;
const workoutReady = new Promise((resolve, reject) => {
  resolveWorkoutSchema = resolve;
  rejectWorkoutSchema = reject;
});
workoutReady.catch(() => {});

// Run schema ensures sequentially — Clever Cloud allows only ~5 MySQL
// connections; parallel ensure* calls race the pool and cause ECONNRESET.
(async () => {
  try {
    await ensureReferralSchema();
  } catch (e) {
    console.error('❌ Referral schema ensure failed:', e.message);
  }
  try {
    await ensureClientInvitationSchema();
  } catch (e) {
    console.error('❌ Client invitation schema ensure failed:', e.message);
  }
  try {
    await ensureNotificationSchema();
  } catch (e) {
    console.error('❌ Notification schema ensure failed:', e.message);
  }
  try {
    await ensureCoachProfileColumns();
  } catch (e) {
    console.error('❌ Coach profile columns ensure failed:', e.message);
  }
  try {
    await ensureTermsAcceptedColumn();
  } catch (e) {
    console.error('❌ Terms accepted column ensure failed:', e.message);
  }
  try {
    await ensureOTPSchema();
  } catch (e) {
    console.error('❌ OTP schema ensure failed:', e.message);
  }
  try {
    await ensureFcmTokenColumn();
  } catch (e) {
    console.error('❌ FCM token column ensure failed:', e.message);
  }
  try {
    await ensureAppVersionSchema();
  } catch (e) {
    console.error('❌ App version schema ensure failed:', e.message);
  }
  try {
    await ensureDeletedAccountsSchema();
  } catch (e) {
    console.error('❌ Deleted accounts schema ensure failed:', e.message);
  }
  try {
    await ensureUgcComplianceSchema();
  } catch (e) {
    console.error('❌ UGC compliance schema ensure failed:', e.message);
  }
  try {
    await ensureCoachImagesSchema();
  } catch (e) {
    console.error('❌ Coach images schema ensure failed:', e.message);
  }
  try {
    await ensureWorkoutSchema(db);
    resolveWorkoutSchema();
  } catch (e) {
    console.error('Workout schema ensure failed:', e.message);
    rejectWorkoutSchema(e);
  }
})();



const app = express();

app.use(cors({
  origin: '*', 
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Large workout transfers are authenticated before parsing; other APIs retain
// their existing request-size limit.
app.use(['/api/workout/history/import-preview','/api/workout/history/import'],requireAuth,express.json({limit:'10mb'}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files for uploaded images
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// Root health check endpoints
app.get('/', (req, res) => {
  res.send('✅ Sirvya API Backend Server is Running');
});

app.get('/api', (req, res) => {
  res.json({ ok: true, message: 'Sirvya API Server is Running' });
});

app.use('/api/coach', coachAvatarRouter);
app.use('/api/coach/auth',          coachSignIn);
app.use('/api/coach/register',      coachSignUp);
app.use('/api/coach/dashboard',     coachDashboard);
app.use('/api/coach/calendar',      coachCalendar);
app.use('/api/coach/conversations', coachConversations);
app.use('/api/coach/chat',          coachChat);
app.use('/api/coach/clients',       coachClients);
app.use('/api/coach/invite',        coachInviteClients);
app.use('/api/coach/invitations',   coachInvitations);
app.use('/api/coach/notifications', coachNotifications);
app.use('/api/coach/profile',       coachProfile);
app.use('/api/coach/profile/edit',  coachEditProfile);

app.use('/api/manager/auth',             managerSignIn);
app.use('/api/manager/dashboard',        managerDashboard);
app.use('/api/manager/clients',          managerClients);
app.use('/api/manager/clients/create',   managerCreateClient);
app.use('/api/manager/clients/edit',     managerEditClient);
app.use('/api/manager/coaches',          managerCoaches);
app.use('/api/manager/coaches/create',   managerCreateCoach);
app.use('/api/manager/coaches/edit',     managerEditCoach);
app.use('/api/manager/admins',           managerAdmins);
app.use('/api/manager/admins/create',    managerCreateAdmin);
app.use('/api/manager/admins/edit',      managerEditAdmin);
app.use('/api/manager/advisors',         managerAdvisors);
app.use('/api/manager/bans',             managerBans);
app.use('/api/manager/pending-coaches',  managerPendingCoaches);
app.use('/api/manager/reservations',     managerReservations);
app.use('/api/manager/profile',          managerProfile);

app.use('/api/auth',          authRoutes);
app.use('/api/clients',       requireAuth, clientRoutes);
app.use('/api/coaches',       requireAuth, coachRoutes);
app.use('/api/advisors',      requireAuth, advisorProfilesRoutes);
app.use('/api/reservations',  requireAuth, reservationsRoutes);
app.use('/api/availability',  requireAuth, coachAvailabilityRoutes);
app.use('/api/conversations', requireAuth, conversationsRoutes);
app.use('/api/messages',      requireAuth, messagesRoutes);
app.use('/api/invitations',   requireAuth, invitationsRoutes);
app.use('/api/coach-clients', requireAuth, coachClientsRoutes);
app.use('/api/bans',          requireAuth, bansRoutes);
app.use('/api/reviews',       requireAuth, reviewsRoutes);
app.use('/api/weight-history', requireAuth, weightHistoryRoutes);
app.use('/api/upload',        requireAuth, uploadRoutes);
app.use('/api/app-version',   appVersionRoutes);
app.use('/api/ugc',           requireAuth, ugcRoutes);
app.use('/api/categories',    requireAuth, categoryRoutes);
app.use('/api/favorites',     requireAuth, favoriteRoutes);
app.use('/api/premium',       requireAuth, premiumRoutes);
app.use('/api/premium/workouts', requireAuth, premiumWorkoutRoutes);
app.use('/api/coach/premium', requireAuth, premiumCoachRoutes);
app.use('/api/workout', createWorkoutRouter(db, {ready: workoutReady, notify: createAndSendNotification}));
app.use('/api/notifications',notificationsRoutes);
startWorkoutReminders(db,createAndSendNotification,workoutReady);
startWorkoutMediaCleanup(db,workoutReady);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`✅ Fitlek API running on port ${PORT}`));

export default app;
