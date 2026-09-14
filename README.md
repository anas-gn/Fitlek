# SIRVYA 🏋️‍♂️

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
- **Base de données :** pool `mysql2` en mode promesse (`.query()` uniquement — pas de transactions sauf extension du pool)


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

## 🏋️ Workout Module (openGym Integration)

Le module workout est intégré dans l'application Sirvya et permet aux clients de suivre leurs entraînements.

### Architecture

Le module workout utilise une architecture à quatre services :

| Service | Port | Commande | Répertoire |
|---------|------|----------|------------|
| Sirvya coaching backend | 3000 | `node index.js` | backend/ |
| Workout API | 3001 | `node server.js` (avec PORT=3001) | workout/api/ |
| Workout frontend (Vite) | 5173 | `npm run dev` avec API_TARGET=http://127.0.0.1:3001 | workout/frontend/ |
| Sirvya Flutter web build | 8090 | `serve build/web/` | repo root |

### Démarrage rapide (Windows)

Pour démarrer tous les services simultanément sur Windows :

```powershell
.\start-all.ps1
```

Pour arrêter tous les services :

```powershell
.\stop-all.ps1
```

### Prérequis

- Node.js 18+
- Flutter SDK
- FIREBASE_SERVICE_ACCOUNT (uniquement pour Google/Apple SSO - email/password SSO ne nécessite pas cette configuration)

### Configuration

Le module workout nécessite une configuration supplémentaire pour l'authentification SSO Firebase (Google/Apple) :

```bash
cd workout
cp .env.example .env
# Configurez FIREBASE_SERVICE_ACCOUNT dans .env pour l'authentification Google/Apple
# Email/password SSO ne nécessite pas cette configuration
```

### Flux d'authentification

1. **Email/password login** : Le token JWT Sirvya est validé contre l'API Sirvya, puis échangé contre une session openGym
2. **Google/Apple SSO** : Le token Firebase ID est vérifié via firebase-admin, puis échangé contre une session openGym
3. **Session persistence** : La session openGym est stockée localement (secure storage sur mobile, sessionStorage sur web) pour permettre la reconnexion sans nouvelle authentification

### Points d'entrée

- **Mobile** : Taper sur le logo SIRVYA dans l'en-tête de l'écran client ouvre le module workout dans une WebView intégrée
- **Web** : Le même logo ouvre le module workout dans le navigateur externe
- **Retour** : Le bouton de retour dans le module workout ramène à l'interface de coaching Sirvya

### Tests de validation

Pour vérifier l'intégration complète :

1. **Email/password SSO** : Connectez-vous avec email/password → tapez le logo SIRVYA → le module workout s'ouvre déjà authentifié
2. **Google/Apple SSO** : Configurez workout/.env avec FIREBASE_SERVICE_ACCOUNT → connectez-vous via Google/Apple → même résultat
3. **Web handoff** : Flutter web utilise #sirvya_login= avec échange same-origin via proxy Vite
4. **Native WebView handoff** : Mobile utilise #sirvya_token= avec échange direct dans WebView intégrée
5. **Relaunch** : Relancez l'app avec une session valide → atterrissage direct dans le module workout
6. **Navigation retour** : Tapez retour → retour à l'interface de coaching avec état Sirvya intact
7. **i18n** : ENG/ESP/FR tous atteignent le point d'entrée workout

### Ce qu'il ne faut PAS changer

- Ne pas toucher backend/ (API Sirvya Express/MySQL)
- Ne pas porter de code entre React et Flutter
- Ne pas remplacer le stockage JSON d'openGym ou MySQL de Sirvya
- Ne pas renommer Fitlek/Sirvya (logos, noms, copy)
- Ne pas utiliser Docker
- Ne pas rendre passkey le flux principal (reste fallback self-hosted)
- Ne pas ajouter de gating premium (fonctionnalités workout gratuites)

---

## 🔑 Variables d'environnement (backend)



## 📌 Bonnes pratiques du projet

- Aucune transaction SQL native disponible — simuler un rollback manuellement si nécessaire (ex : supprimer l'utilisateur si l'insertion du profil échoue)
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