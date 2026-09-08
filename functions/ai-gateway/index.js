const crypto = require('node:crypto');
const { Client, Account } = require('node-appwrite');

const providerKeys = {
  gemini: (process.env.GEMINI_API_KEYS || '').split(',').map((v) => v.trim()).filter(Boolean),
  tavily: (process.env.TAVILY_API_KEYS || '').split(',').map((v) => v.trim()).filter(Boolean),
  sarvam: (process.env.SARVAM_API_KEYS || '').split(',').map((v) => v.trim()).filter(Boolean),
};

function json(res, status, data) { return res.json(data, status); }
async function authenticate(req) {
  const jwt = req.headers?.['x-appwrite-user-jwt'] || req.headers?.['X-Appwrite-User-JWT'];
  if (!jwt) throw new Error('AUTH_REQUIRED');
  const client = new Client().setEndpoint(process.env.APPWRITE_ENDPOINT).setProject(process.env.APPWRITE_PROJECT_ID).setJWT(jwt);
  return new Account(client).get();
}
function input(req) { return typeof req.bodyJson === 'object' && req.bodyJson ? req.bodyJson : JSON.parse(req.body || '{}'); }
function keyFor(provider) {
  const keys = providerKeys[provider];
  if (!keys || keys.length === 0) throw new Error('PROVIDER_NOT_CONFIGURED');
  return keys[Math.floor(Math.random() * keys.length)];
}
async function upstream(provider, payload) {
  const key = keyFor(provider);
  if (provider === 'gemini') {
    const model = payload.model || 'gemini-2.5-flash-lite';
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload.body) });
    return { status: response.status, data: await response.json() };
  }
  if (provider === 'tavily') {
    const response = await fetch('https://api.tavily.com/search', { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` }, body: JSON.stringify(payload.body) });
    return { status: response.status, data: await response.json() };
  }
  if (provider === 'sarvam') {
    const response = await fetch(payload.endpoint, { method: 'POST', headers: { 'content-type': 'application/json', 'api-subscription-key': key }, body: JSON.stringify(payload.body) });
    return { status: response.status, data: await response.json() };
  }
  throw new Error('UNKNOWN_PROVIDER');
}

module.exports = async ({ req, res, error }) => {
  try {
    await authenticate(req);
    const request = input(req);
    const provider = String(request.provider || '');
    if (!['gemini', 'tavily', 'sarvam'].includes(provider)) return json(res, 400, { error: 'UNKNOWN_PROVIDER' });
    const result = await upstream(provider, request);
    if (result.status < 200 || result.status >= 300) return json(res, 502, { error: 'UPSTREAM_FAILED' });
    return json(res, 200, { provider, data: result.data });
  } catch (err) {
    if (err.message === 'AUTH_REQUIRED') return json(res, 401, { error: err.message });
    if (err.message === 'PROVIDER_NOT_CONFIGURED') return json(res, 503, { error: err.message });
    error(`${crypto.randomUUID()} ${err.stack || String(err)}`);
    return json(res, 500, { error: 'FUNCTION_FAILED' });
  }
};
