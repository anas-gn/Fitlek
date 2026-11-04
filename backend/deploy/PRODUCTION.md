# Production API: api.sirvya.com

1. In the DNS provider for sirvya.com, create an A record named `api`, value `51.170.143.251`, TTL Auto/default. If using Cloudflare, start with DNS only while configuring the certificate.
2. In Oracle Cloud, allow inbound TCP 80 and 443 in the instance's applicable network security group or subnet security list (source 0.0.0.0/0). Ensure the operating-system firewall also permits these ports.
3. Install `nginx-api.conf` as an enabled server configuration. It expects the backend on local port 4303. Validate with `sudo nginx -t` before `sudo systemctl reload nginx`.
4. Install Certbot and its Nginx plugin using the instructions for the VPS operating system at https://certbot.eff.org/instructions . Once DNS resolves to the VPS, run `sudo certbot --nginx -d api.sirvya.com` and enable HTTP-to-HTTPS redirection. Check renewal with `sudo certbot renew --dry-run`.
5. Keep secrets only in the server environment or private credential file. Set `PUBLIC_API_URL=https://api.sirvya.com/api`. Copy other required settings from `.env.example` using the existing production DB, JWT and email credentials; do not replace these with blank example values. Configure Firebase Admin using `FIREBASE_SERVICE_ACCOUNT` or the private local credential file supported by `config/firebase.js`.
6. Deploy the source and install locked dependencies with `npm ci`. Restart the existing process manager only after configuration/migrations are ready. Check `https://api.sirvya.com/api/categories` returns JSON and authenticated coach/client APIs and Socket.IO work over HTTPS/WSS.

The mobile app defaults to `https://api.sirvya.com/api`. Socket.IO derives the HTTPS server from the same URL. Development can override `API_BASE_URL` at build time. DNS and certificate setup must finish before the app can connect to this new address.

Pushing source to GitHub does not deploy it to the VPS unless deployment automation is configured. Retain the existing uploads directory and private environment during deployment. Database schema initialization needs the configured migration privileges; apply the new migrations through the existing deployment workflow if the runtime account cannot create/alter tables.

An existing Firebase Admin key and a migration script containing a database password were tracked in older repository history. This publication removes the key from the current tree and uses environment variables in the script. Rotate exposed credentials separately; deleting the current file does not remove old Git history. Never add the replacement keys to Git.
