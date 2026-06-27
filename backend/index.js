import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';

import coachSignIn from './routes/pahae/coachSignIn.js';
import coachSignUp from './routes/pahae/coachSignUp.js';
import coachDashboard from './routes/pahae/coachDashboard.js';
import coachCalendar from './routes/pahae/coachCalendar.js';
import coachConversations from './routes/pahae/coachConversations.js';
import coachChat from './routes/pahae/coachChat.js';
import coachClients from './routes/pahae/coachClients.js';
import coachInviteClients from './routes/pahae/coachInviteClients.js';
import coachInvitations from './routes/pahae/coachInvitations.js';
import coachProfile from './routes/pahae/coachProfile.js';
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

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/coach/auth',          coachSignIn);
app.use('/api/coach/register',      coachSignUp);
app.use('/api/coach/dashboard',     coachDashboard);
app.use('/api/coach/calendar',      coachCalendar);
app.use('/api/coach/conversations', coachConversations);
app.use('/api/coach/chat',          coachChat);
app.use('/api/coach/clients',       coachClients);
app.use('/api/coach/invite',        coachInviteClients);
app.use('/api/coach/invitations',   coachInvitations);
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log('______________________');
});
