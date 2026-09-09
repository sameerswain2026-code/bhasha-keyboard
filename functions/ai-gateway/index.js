const crypto = require('node:crypto');
const { Client, Account } = require('node-appwrite');

const providerKeys = {
  gemini: (process.env.GEMINI_API_KEYS || '').split(',').map((v) => v.trim()).filter(Boolean),
  tavily: (process.env.TAVILY_API_KEYS || '').split(',').map((v) => v.trim()).filter(Boolean),
  sarvam: (process.env.SARVAM_API_KEYS || '').split(',').map((v) => v.trim()).filter(Boolean),
};
const MAX_REQUEST_BYTES = 64 * 1024;
const MAX_BODY_BYTES = 16 * 1024;
const WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 30;
const requestWindows = new Map();

function json(res, status, data) { return res.json(data, status); }
function header(req, name) { return req.headers?.[name] || req.headers?.[name.toLowerCase()]; }
function input(req) {
  if (typeof req.bodyJson === 'object' && req.bodyJson) return req.bodyJson;
  const raw = String(req.body || '');
  if (Buffer.byteLength(raw, 'utf8') > MAX_REQUEST_BYTES) throw new Error('REQUEST_TOO_LARGE');
  return JSON.parse(raw || '{}');
}
async function authenticate(req) {
  const jwt = header(req, 'x-appwrite-user-jwt');
  if (!jwt) throw new Error('AUTH_REQUIRED');
  const client = new Client().setEndpoint(process.env.APPWRITE_ENDPOINT).setProject(process.env.APPWRITE_PROJECT_ID).setJWT(jwt);
  return new Account(client).get();
}
function allow(userId) {
  const now = Date.now();
  const window = requestWindows.get(userId) || { started: now, count: 0 };
  if (now - window.started >= WINDOW_MS) { window.started = now; window.count = 0; }
  window.count += 1;
  requestWindows.set(userId, window);
  return window.count <= MAX_REQUESTS_PER_WINDOW;
}
function keyFor(provider) {
  const keys = providerKeys[provider];
  if (!keys || keys.length === 0) throw new Error('PROVIDER_NOT_CONFIGURED');
  return keys[Math.floor(Math.random() * keys.length)];
}
async function upstream(provider, payload) {
  const key = keyFor(provider);
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), 8000);
  try {
    let response;
    if (provider === 'gemini') {
      const model = String(payload.model || 'gemini-2.5-flash-lite');
      response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload.body || {}), signal: abort.signal });
    } else if (provider === 'tavily') {
      response = await fetch('https://api.tavily.com/search', { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` }, body: JSON.stringify(payload.body || {}), signal: abort.signal });
    } else if (provider === 'sarvam') {
      const endpoint = String(payload.endpoint || '');
      if (!endpoint.startsWith('https://')) throw new Error('INVALID_PROVIDER_ENDPOINT');
      response = await fetch(endpoint, { method: 'POST', headers: { 'content-type': 'application/json', 'api-subscription-key': key }, body: JSON.stringify(payload.body || {}), signal: abort.signal });
    } else {
      throw new Error('UNKNOWN_PROVIDER');
    }
    const text = await response.text();
    return { status: response.status, data: text ? JSON.parse(text) : {} };
  } finally {
    clearTimeout(timer);
  }
}
module.exports = async ({ req, res, error }) => {
  const requestId = crypto.randomUUID();
  try {
    const user = await authenticate(req);
    if (!allow(user.$id)) return json(res, 429, { error: 'RATE_LIMITED', requestId });
    const request = input(req);
    if (Buffer.byteLength(JSON.stringify(request.body || {}), 'utf8') > MAX_BODY_BYTES) return json(res, 413, { error: 'PAYLOAD_TOO_LARGE', requestId });
    const provider = String(request.provider || '');
    if (!['gemini', 'tavily', 'sarvam'].includes(provider)) return json(res, 400, { error: 'UNKNOWN_PROVIDER', requestId });
    const result = await upstream(provider, request);
    if (result.status < 200 || result.status >= 300) return json(res, 502, { error: 'UPSTREAM_FAILED', requestId });
    return json(res, 200, { provider, data: result.data, requestId });
  } catch (err) {
    if (err.message === 'AUTH_REQUIRED') return json(res, 401, { error: err.message });
    if (err.message === 'PROVIDER_NOT_CONFIGURED') return json(res, 503, { error: err.message });
    if (['REQUEST_TOO_LARGE', 'PAYLOAD_TOO_LARGE'].includes(err.message)) return json(res, 413, { error: err.message });
    error(`${requestId} ${err.name || 'Error'}: ${err.message || 'FUNCTION_FAILED'}`);
    return json(res, 502, { error: 'PROVIDER_UNAVAILABLE', requestId });
  }
};
