export function runtimeConfig(env = process.env) {
  const production = env.NODE_ENV === 'production';
  const origins = (env.CORS_ORIGINS ?? '').split(',').map(v=>v.trim()).filter(Boolean);
  const missing = ['DB_HOST','DB_USER','DB_NAME','JWT_SECRET'].filter(key=>!env[key]);
  if (missing.length) throw new Error(`Missing configuration: ${missing.join(', ')}`);
  if (production && (env.JWT_SECRET.length < 32 || /replace|example/i.test(env.JWT_SECRET))) throw new Error('Production JWT_SECRET must be a random secret of at least 32 characters');
  if (production && !origins.length) throw new Error('Production CORS_ORIGINS must list allowed origins');
  const validOrigin = value => {
    try {
      const url = new URL(value);
      return ['https:','http:'].includes(url.protocol) && !url.username && !url.password && url.pathname === '/' && !url.search && !url.hash;
    } catch { return false; }
  };
  if (origins.some(v=>!validOrigin(v))) throw new Error('CORS_ORIGINS must contain explicit HTTP(S) origins');
  if (env.PUBLIC_API_ORIGIN && !validOrigin(env.PUBLIC_API_ORIGIN)) throw new Error('PUBLIC_API_ORIGIN must be an HTTP(S) origin without a path or credentials');
  if (production && (!env.PUBLIC_API_ORIGIN || new URL(env.PUBLIC_API_ORIGIN).protocol !== 'https:')) throw new Error('Production PUBLIC_API_ORIGIN must use HTTPS');
  const trustProxy = Number(env.TRUST_PROXY_HOPS ?? 0);
  if (!Number.isInteger(trustProxy) || trustProxy<0 || trustProxy>5) throw new Error('TRUST_PROXY_HOPS must be between 0 and 5');
  return {production,origins,trustProxy};
}

export function publicOrigin(req) {
  return (process.env.PUBLIC_API_ORIGIN || `${req.protocol}://${req.get('host')}`).replace(/\/$/,'');
}
