'use strict';

const crypto = require('node:crypto');
const { Client, Account } = require('node-appwrite');

const MAX_REQUEST_BYTES = 64 * 1024;
const MAX_BODY_BYTES = 16 * 1024;
const MAX_RESPONSE_BYTES = 1024 * 1024;
const WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 30;
const REQUEST_TIMEOUT_MS = 8000;
const requestWindows = new Map();

const providerKeys = {
  gemini: parseKeys(process.env.GEMINI_API_KEYS),
  tavily: parseKeys(process.env.TAVILY_API_KEYS),
  sarvam: parseKeys(process.env.SARVAM_API_KEYS),
};

function parseKeys(value) {
  return (value || '').split(',').map((entry) => entry.trim()).filter(Boolean);
}

function json(res, status, data) { return res.json(data, status); }
function header(req, name) {
  const wanted = name.toLowerCase();
  const entry = Object.entries(req.headers || {}).find(([key]) => key.toLowerCase() === wanted);
  return entry?.[1];
}
function input(req) {
  const raw = typeof req.body === 'string' ? req.body : JSON.stringify(req.bodyJson || req.body || {});
  if (Buffer.byteLength(raw, 'utf8') > MAX_REQUEST_BYTES) throw new GatewayError('REQUEST_TOO_LARGE', 413);
  let parsed;
  try {
    parsed = typeof req.bodyJson === 'object' && req.bodyJson !== null ? req.bodyJson : JSON.parse(raw || '{}');
  } catch (_) {
    throw new GatewayError('INVALID_JSON', 400);
  }
  if (!isPlainObject(parsed)) throw new GatewayError('INVALID_REQUEST', 400);
  return parsed;
}
function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}
function requireEnvironment() {
  for (const name of ['APPWRITE_ENDPOINT', 'APPWRITE_PROJECT_ID']) {
    if (!process.env[name]) throw new GatewayError('FUNCTION_NOT_CONFIGURED', 503);
  }
}
async function authenticate(req) {
  const jwt = header(req, 'x-appwrite-user-jwt');
  if (!jwt) throw new GatewayError('AUTH_REQUIRED', 401);
  const client = new Client().setEndpoint(process.env.APPWRITE_ENDPOINT).setProject(process.env.APPWRITE_PROJECT_ID).setJWT(jwt);
  return new Account(client).get();
}
function allow(userId) {
  const now = Date.now();
  // Remove expired users so a warm Function instance cannot grow forever.
  if (requestWindows.size > 1000) {
    for (const [id, value] of requestWindows) {
      if (now - value.started >= WINDOW_MS) requestWindows.delete(id);
    }
  }
  const window = requestWindows.get(userId) || { started: now, count: 0 };
  if (now - window.started >= WINDOW_MS) {
    window.started = now;
    window.count = 0;
  }
  window.count += 1;
  requestWindows.set(userId, window);
  return window.count <= MAX_REQUESTS_PER_WINDOW;
}
function keyFor(provider) {
  const keys = providerKeys[provider];
  if (!keys?.length) throw new GatewayError('PROVIDER_NOT_CONFIGURED', 503);
  return keys[crypto.randomInt(keys.length)];
}
function normalizedPayload(provider, payload) {
  if (!isPlainObject(payload.body)) throw new GatewayError('INVALID_PROVIDER_BODY', 400);
  if (Buffer.byteLength(JSON.stringify(payload.body), 'utf8') > MAX_BODY_BYTES) {
    throw new GatewayError('PAYLOAD_TOO_LARGE', 413);
  }

  if (provider === 'gemini') {
    const allowed = parseKeys(process.env.GEMINI_ALLOWED_MODELS || 'gemini-2.5-flash-lite');
    const model = String(payload.model || allowed[0]);
    if (!allowed.includes(model)) throw new GatewayError('MODEL_NOT_ALLOWED', 400);
    const body = structuredClone(payload.body);
    body.generationConfig = isPlainObject(body.generationConfig) ? body.generationConfig : {};
    body.generationConfig.maxOutputTokens = Math.min(
      Math.max(Number.parseInt(body.generationConfig.maxOutputTokens, 10) || 1024, 1),
      4096,
    );
    return { model, body };
  }

  if (provider === 'tavily') {
    const query = String(payload.body.query || '').trim();
    if (!query || query.length > 2000) throw new GatewayError('INVALID_QUERY', 400);
    return {
      body: {
        query,
        search_depth: payload.body.search_depth === 'advanced' ? 'advanced' : 'basic',
        max_results: Math.min(Math.max(Number.parseInt(payload.body.max_results, 10) || 1, 1), 5),
        include_answer: Boolean(payload.body.include_answer),
      },
    };
  }

  if (provider === 'sarvam') {
    let endpoint;
    try {
      endpoint = new URL(String(payload.endpoint || ''));
    } catch (_) {
      throw new GatewayError('INVALID_PROVIDER_ENDPOINT', 400);
    }
    const allowedHosts = parseKeys(process.env.SARVAM_ALLOWED_HOSTS || 'api.sarvam.ai');
    if (endpoint.protocol !== 'https:' || !allowedHosts.includes(endpoint.hostname) || endpoint.username || endpoint.password) {
      throw new GatewayError('INVALID_PROVIDER_ENDPOINT', 400);
    }
    return { endpoint: endpoint.toString(), body: payload.body };
  }

  throw new GatewayError('UNKNOWN_PROVIDER', 400);
}
async function readJsonResponse(response) {
  const declaredLength = Number(response.headers.get('content-length') || 0);
  if (declaredLength > MAX_RESPONSE_BYTES) throw new GatewayError('UPSTREAM_RESPONSE_TOO_LARGE', 502);
  const bytes = Buffer.from(await response.arrayBuffer());
  if (bytes.length > MAX_RESPONSE_BYTES) throw new GatewayError('UPSTREAM_RESPONSE_TOO_LARGE', 502);
  if (!bytes.length) return {};
  try {
    return JSON.parse(bytes.toString('utf8'));
  } catch (_) {
    throw new GatewayError('INVALID_UPSTREAM_RESPONSE', 502);
  }
}
async function upstream(provider, rawPayload) {
  const key = keyFor(provider);
  const payload = normalizedPayload(provider, rawPayload);
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), REQUEST_TIMEOUT_MS);
  try {
    let response;
    if (provider === 'gemini') {
      response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(payload.model)}:generateContent?key=${encodeURIComponent(key)}`, {
        method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload.body), signal: abort.signal,
      });
    } else if (provider === 'tavily') {
      response = await fetch('https://api.tavily.com/search', {
        method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` }, body: JSON.stringify(payload.body), signal: abort.signal,
      });
    } else {
      response = await fetch(payload.endpoint, {
        method: 'POST', headers: { 'content-type': 'application/json', 'api-subscription-key': key }, body: JSON.stringify(payload.body), signal: abort.signal,
      });
    }
    return { status: response.status, data: await readJsonResponse(response) };
  } catch (err) {
    if (err.name === 'AbortError') throw new GatewayError('UPSTREAM_TIMEOUT', 504);
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

class GatewayError extends Error {
  constructor(message, status) {
    super(message);
    this.name = 'GatewayError';
    this.status = status;
  }
}

async function handler({ req, res, error = () => {} }) {
  const requestId = crypto.randomUUID();
  try {
    requireEnvironment();
    const user = await authenticate(req);
    if (!allow(user.$id)) return json(res, 429, { error: 'RATE_LIMITED', requestId });
    const request = input(req);
    const provider = String(request.provider || '');
    if (!['gemini', 'tavily', 'sarvam'].includes(provider)) throw new GatewayError('UNKNOWN_PROVIDER', 400);
    const result = await upstream(provider, request);
    if (result.status < 200 || result.status >= 300) return json(res, 502, { error: 'UPSTREAM_FAILED', requestId });
    return json(res, 200, { provider, data: result.data, requestId });
  } catch (err) {
    if (err instanceof GatewayError) return json(res, err.status, { error: err.message, requestId });
    error(`${requestId} ${err.name || 'Error'}: ${err.message || 'FUNCTION_FAILED'}`);
    return json(res, 502, { error: 'PROVIDER_UNAVAILABLE', requestId });
  }
}

module.exports = handler;
// Export pure helpers for regression tests; Appwrite continues to invoke the handler above.
module.exports._test = { input, normalizedPayload, readJsonResponse, GatewayError };
