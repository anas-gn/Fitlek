export default {
  async fetch(request) {
    const url = new URL(request.url);
    const match = url.pathname.match(/^\/invite\/([A-Za-z0-9-]{4,64})\/?$/);
    if (!match) return new Response('Invitation not found', {status: 404});
    if (!['GET', 'HEAD'].includes(request.method)) return new Response('Method not allowed', {status: 405});
    const upstream = await fetch(`https://api.sirvya.com/api/invite/${encodeURIComponent(match[1])}`, {
      method: request.method,
      headers: {'Accept': 'text/html'},
      redirect: 'manual',
    });
    if (upstream.status >= 300 && upstream.status < 400) return new Response('Invitation temporarily unavailable. Please try again.', {status: 503});
    const headers = new Headers(upstream.headers);
    headers.set('Cache-Control', 'no-store');
    headers.set('X-Content-Type-Options', 'nosniff');
    headers.delete('Set-Cookie');
    return new Response(upstream.body, {status: upstream.status, headers});
  },
};

