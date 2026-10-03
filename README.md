# SIRVYA 🏋️‍♂️

**SIRVYA Workout** est intégré nativement à l’application Flutter existante,
avec l’authentification, les utilisateurs, les relations Coach/Client et MySQL
de SIRVYA. Voir [le guide Workout](docs/SIRVYA_WORKOUT.md),
[la matrice de fonctionnalités](docs/WORKOUT_PARITY.md) et
[les licences](docs/THIRD_PARTY_WORKOUT.md).

Plateforme complète de coaching sportif pour le marché marocain, composée d'une application mobile **Flutter**, d'un portail web **Next.js** pour les advisors (salles de sport / gérants), et d'une API backend **Node.js / Express** avec base de données **MySQL**.

---

## 📱 Aperçu du projet

SIRVYA connecte des **clients** avec des **coachs** sportifs, tout en donnant aux **advisors** (salles partenaires) et aux **admins** des outils de gestion complets.

**Rôles supportés :**
- `client` — réserve des séances, discute avec son coach, suit son profil
- `coach` — gère son profil, ses disponibilités, ses clients et ses réservations
- `advisor` — gère les coachs rattachés à sa salle, consulte les réservations et statistiques
- `manager` — supervision opérationnelle
- `admin` — gestion globale des utilisateurs, approbations et bannissements

**Marché cible :** Maroc — devise **MAD**, interface entièrement en **français**.

---



## 🏗️ Architecture technique

```
SIRVYA/
├── backend/              # API Node.js / Express
│   ├── config/db.js      # Pool mysql2 (promise)
│   ├── middleware/auth.js
│   └── routes/
├── mobile/                # Application Flutter (clients, coachs, advisors)
└── web/                   # Portail advisor Next.js
```

### Backend

- **Auth :** `middleware/auth.js` exporte `{ authenticate, authorize(...roles) }`
- **Base de données :** pool `mysql2` en mode promesse ; les écritures Workout utilisent une connexion dédiée et des transactions natives.


**Routes principales :**

| Fichier | Endpoints |
|---|---|
| `auth.js` | `/register`, `/login`, `/refresh`, `/logout`, `/forgot-password`, `/reset-password` |
| `client.js` | `/clients/me`, `/clients/:id`, `/clients` |
| `coach.js` | `/coaches`, `/coaches/:id`, `/coaches/me/profile`, `/coaches/me/stats` |
| `advisorProfiles.js` | `/advisors/me`, `/advisors`, `/advisors/:advisorId/coaches`, `/advisors/coaches/:coachId/assign\|unassign` |
| `adminProfiles.js` | `/admin/users`, `/users/:id/approve\|revoke\|premium`, `/admin/stats` |
| `reservations.js` | CRUD réservations + `/confirm`, `/cancel`, `/reject`, `/details`, `/price` |
| `coachAvailability.js` | `/:coachID`, `POST`, `DELETE /:id` |
| `conversations.js` | liste + création (get-or-create) |
| `messages.js` | `/:convID` (GET paginé, POST) |
| `invitations.js` | `/me`, `/use` (+20 points) |
| `coachClients.js` | `/me`, `POST`, `DELETE /:clientID` |
| `bans.js` | CRUD bannissements + `/:id/lift` |

### Base de données (MySQL)

Tables principales : `users`, `coachProfiles`, `advisorProfiles`, `reservations`, `coachAvailabilityBlocks`, `conversations`, `messages`, `invitations`, `coachClients`, `bans`, `authTokens`, `passwordResetTokens`.

> ⚠️ Créer un coach nécessite **deux appels séquentiels** : `POST /auth/register` (récupère `userID`) puis `POST /coaches/me/profile` (avec `advisorID`). Sans le second appel, aucune ligne `coachProfiles` n'existe et toutes les requêtes filtrées par advisor échouent.

### Application mobile (Flutter)

- **Session :** `ApiService` expose `checkSession()`, `getUserData()`, `getToken()`, `clearToken()`
- **Navigation :** chaque écran reçoit `clientID`/`coachID`/`advisorID` + `token` en paramètres de constructeur obligatoires
- **Layout :** `MainLayoutCoach` (et équivalent client) est stateful, charge les données de session dans `initState`, affiche un spinner lime pendant le chargement
- **Upload d'images :** Cloudinary via `POST /api/upload/avatar` (Multer, crop 400×400, détection de visage)

### Portail web advisor (Next.js)

- **Accès BDD :** wrapper `lib/db.js` (`.query()` uniquement)
- **Pages :** Accueil, Connexion, Inscription, Dashboard, Profil, Réservations (édition en ligne), Coachs, Mot de passe oublié

---

## ⚙️ Installation

### Prérequis

- Node.js 18+
- MySQL / MariaDB
- Flutter SDK (pour l'app mobile)
- npm ou yarn

### Backend

```bash
cd backend
npm install
cp .env.example .env   # configurer DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, JWT_SECRET
npm run dev
```

### Base de données

```bash
mysql -u root -p fitlekdb < fitlekdb.sql
```

### Application mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

> Sur émulateur Android, l'URL de l'API doit pointer vers `http://10.0.2.2:3000/api`.

### Portail web (Next.js)

```bash
cd web
npm install
cp .env.example .env.local
npm run dev
```

---

## 🔑 Variables d'environnement (backend)

Sirvya Premium uses Stripe for subscription checkout. Copy `backend/.env.example`
to the backend environment file, set the Stripe test keys and price ID, then
apply `backend/migrations/2026_premium_subscriptions.sql` and
`backend/migrations/2026_premium_workouts.sql` and
`backend/migrations/2026_premium_exercise_seed.sql` to the same MySQL database.
For databases that already applied the workout migration, also apply
`backend/migrations/2026_premium_superset_upgrade.sql`.
Configure Stripe to send signed events to
`/api/stripe/webhook`; the webhook secret must stay on the backend.

The current Premium workout API supports exercise search, personal routines,
starting sessions, saving sets, finishing sessions, and workout history under
`/api/premium/workouts`. Every request requires the existing Fitlek JWT and an
active Stripe Premium subscription.

The guided workout UI includes set entry and a rest timer. The workout migration
also supports body weight and routine superset grouping; advanced progression
and media imports remain separate product work.



## 📌 Bonnes pratiques du projet

- Pour les écritures liées, utiliser `pool.getConnection()`, `beginTransaction()`, `commit()`/`rollback()` et libérer la connexion dans `finally`.
- Les endpoints de réservation nécessitent toujours `userID` **et** `role` en query params pour le filtrage
- Toujours vérifier le champ réel `avatarUrl` avant de recourir aux initiales UI-Avatars
- Ne pas coder en dur des noms de police non déclarés dans `pubspec.yaml` (rendu en damier)
- Les listes d'écrans dans un `IndexedStack` ne doivent pas être `const` si elles passent des données via le constructeur — utiliser un state dynamique

---

## 🗺️ Roadmap / État actuel

- ✅ Authentification, gestion des rôles, profils coach/advisor/client
- ✅ Réservations avec gestion des conflits et blocages de disponibilité
- ✅ Messagerie temps réel (conversations + messages)
- ✅ Système d'invitations et de points
- ✅ Dashboard admin avec filtres et approbations
- ✅ Portail advisor complet (profil, coachs, réservations)
- 🔄 Polish UI/UX en cours (animations, thèmes, écrans avancés)

---

## 📄 Licence

Projet privé — tous droits réservés.
