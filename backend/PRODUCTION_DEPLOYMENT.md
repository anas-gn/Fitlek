# Production deployment

Production serves https://api.sirvya.com/api. The mobile app and iOS workflow use this URL by default. The backend runs under PM2 on port 4303 behind the existing HTTPS proxy.

## Releases

A push to main runs the backend tests, packages tracked source only, and uploads a distinct release under /var/www/releases/backend-COMMIT/backend. scripts/deploy-production.sh installs locked dependencies, starts the candidate on port 4304, verifies database readiness and Socket.IO, then switches port 4303. Failed activation restarts the previous process. A server lock serializes activation. The active release is recorded by /var/www/sirvya-production-current; repeating a successful release checks health.

Secrets are inherited privately from the previous release, never uploaded by GitHub. The existing Firebase service account is preserved with restrictive permissions. Uploaded files stay in /var/www/sirvya-backend/uploads through a symlink. Keep previous releases for rollback; never delete shared uploads during deployment. NODE_ENV is production.

GitHub Actions requires the existing VPS_HOST, VPS_USER and VPS_SSH_KEY repository secrets. Node 22 runs tests; runtime dependencies also support the existing server Node 20.20.2. Port 4304 is used for local checks, not a public proxy route.

## Verification and rollback

GET /api/health returns 200 only when the database responds, and 503 otherwise. GET /socket.io/?EIO=4&transport=polling checks the transport; chat authentication and membership checks remain mandatory for private rooms. Verify /api/categories and /api/meals/ingredients/generic.webp over public HTTPS after deployment.

To roll back, stop the new backend process and restart the retained previous PM2 backend process on port 4303, verify health, repoint sirvya-production-current and save PM2 state. Do not restart or replace the separate web admin process.

## Data and Azure

The October 17 production schema inspection confirmed existing meal, quota, nutrition and messaging tables. This release does not run a bulk migration or import a database dump. Normal startup retains existing idempotent schema checks.

Configure AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY privately on the server, with AZURE_OPENAI_API_VERSION=v1 for the Foundry agent endpoint. The app never contains this key. The default scan allowance is three daily, with durable admin-configured limits and per-client overrides in MySQL. Review the configured allowance in web_admin; deployment preserves its current values.
