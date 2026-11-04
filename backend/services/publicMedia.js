const legacyHosts = new Set(['127.0.0.1', 'localhost', '51.170.143.251', 'api.sirvya.com']);

export function publicMediaUrl(value, base = process.env.PUBLIC_API_URL || 'https://api.sirvya.com') {
  if (typeof value !== 'string') return value;
  try {
    const old = new URL(value);
    if (!['http:', 'https:'].includes(old.protocol) || !legacyHosts.has(old.hostname) ||
        !old.pathname.startsWith('/uploads/')) return value;
    const production = new URL(base);
    if (production.protocol !== 'https:') return value;
    return new URL(old.pathname + old.search + old.hash, production.origin).href;
  } catch { return value; }
}

export function normalizePublicMedia(value, field = '') {
  if (typeof value === 'string') return /urls?$|avatar$|images?$|photos?$|thumbnails?$/i.test(field) ? publicMediaUrl(value) : value;
  if (Array.isArray(value)) return value.map(item => normalizePublicMedia(item, field));
  if (!value || typeof value !== 'object' || value instanceof Date || Buffer.isBuffer(value)) return value;
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, normalizePublicMedia(item, key)]));
}

export function publicMediaResponses(req, res, next) {
  const json = res.json.bind(res);
  res.json = value => json(normalizePublicMedia(value));
  next();
}
