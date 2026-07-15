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

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { ensureReferralSchema, ensureNotificationSchema, ensureCoachProfileColumns } from './config/ensureSchema.js';
dotenv.config();

// Run schema ensures sequentially — Clever Cloud allows only ~5 MySQL
// connections; parallel ensure* calls race the pool and cause ECONNRESET.
(async () => {
  try {
    await ensureReferralSchema();
  } catch (e) {
    console.error('❌ Referral schema ensure failed:', e.message);
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
})();

const app = express();

app.use(cors({
  origin: '*', 
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
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
app.use('/api/clients',       clientRoutes);
app.use('/api/coaches',       coachRoutes);
app.use('/api/advisors',      advisorProfilesRoutes);
app.use('/api/reservations',  reservationsRoutes);
app.use('/api/availability',  coachAvailabilityRoutes);
app.use('/api/conversations', conversationsRoutes);
app.use('/api/messages',      messagesRoutes);
app.use('/api/invitations',   invitationsRoutes);
app.use('/api/coach-clients', coachClientsRoutes);
app.use('/api/bans',          bansRoutes);
app.use('/api/reviews',       reviewsRoutes);
app.use('/api/weight-history', weightHistoryRoutes);
app.use('/api/upload',        uploadRoutes);

app.listen(3000, () => console.log('✅ Fitlek API running on port 3000'));

export default app;