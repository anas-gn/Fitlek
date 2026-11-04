#!/usr/bin/env bash
set -euo pipefail

# Run from an extracted, immutable release. Secrets and uploads stay on the VPS.
release=$(pwd -P)
case "$release" in /var/www/releases/backend-*/backend) ;; *) echo 'Invalid release directory'; exit 1;; esac
pointer=/var/www/sirvya-production-current
exec 9>/var/www/sirvya-artifacts/.sirvya-deploy.lock
flock -w 300 9
previous=$(readlink -f "$pointer" 2>/dev/null || true)
if [[ "$previous" == "$release" && -f .release-ready ]]; then
  curl --fail --silent --max-time 10 http://127.0.0.1:4303/api/health
  exit 0
fi
if [[ ! -f "$previous/index.js" ]]; then previous=/var/www/releases/backend-7ed149d/backend; fi
old_name=$(pm2 jlist | PREVIOUS="$previous" node --input-type=module -e '
let input=""; for await(const part of process.stdin) input+=part;
const active=JSON.parse(input).find(p=>p.pm2_env.pm_cwd===process.env.PREVIOUS && p.pm2_env.status==="online");
if(!active) process.exit(1); process.stdout.write(active.name);')
name="sirvya-backend-$(basename "$(dirname "$release")" | sed 's/^backend-//')"

if [[ ! -s .env ]]; then install -m 600 "$previous/.env" .env; fi
credential=config/sirvya-app-firebase-adminsdk-fbsvc-5858641a2a.json
if [[ -f "$previous/$credential" && ! -s "$credential" ]]; then install -m 600 "$previous/$credential" "$credential"; fi
if [[ ! -e uploads ]]; then ln -s /var/www/sirvya-backend/uploads uploads; fi
npm ci --omit=dev --no-audit --no-fund
health() {
  local port=$1
  for attempt in $(seq 1 40); do
    if curl --fail --silent --max-time 3 "http://127.0.0.1:$port/api/health" >/dev/null; then return 0; fi
    sleep 1
  done
  return 1
}
switched=0
rollback() {
  pm2 delete "$name" >/dev/null 2>&1 || true
  if [[ "$switched" == 1 ]]; then
    PORT=4303 NODE_ENV=production pm2 restart "$old_name" --update-env >/dev/null
    pm2 save >/dev/null
  fi
  echo 'Release failed; previous production release retained.' >&2
}
trap rollback ERR
PORT=4304 NODE_ENV=production pm2 start index.js --name "$name" --time >/dev/null
health 4304
# Verify the actual Socket.IO transport as well as HTTP/database readiness.
curl --fail --silent --max-time 5 'http://127.0.0.1:4304/socket.io/?EIO=4&transport=polling' | grep -q '^0{'
pm2 stop "$old_name" >/dev/null
switched=1
PORT=4303 NODE_ENV=production pm2 restart "$name" --update-env >/dev/null
health 4303
sudo -n ln -sfn "$release" "$pointer"
touch .release-ready
pm2 save >/dev/null
trap - ERR
echo "Production release active: $name"
