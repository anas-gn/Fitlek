// Bounded per-process burst protection. Reset codes additionally enforce
// account cooldowns and attempt limits in MySQL across API workers.
export function requestLimit({limit = 20, windowMs = 60000, maxKeys = 10000} = {}) {
  const buckets = new Map();
  return (req, res, next) => {
    const now = Date.now();
    const key = req.ip;
    let bucket = buckets.get(key);
    if (!bucket || bucket.until <= now) {
      if (buckets.size >= maxKeys) {
        for (const [id, value] of buckets) if (value.until <= now) buckets.delete(id);
        if (buckets.size >= maxKeys) return res.status(429).json({error: 'Too many requests. Try again shortly.'});
      }
      bucket = {count: 0, until: now + windowMs};
      buckets.set(key, bucket);
    }
    if (++bucket.count > limit) {
      res.set('Retry-After', String(Math.ceil((bucket.until - now) / 1000)));
      return res.status(429).json({error: 'Too many requests. Try again shortly.'});
    }
    next();
  };
}
