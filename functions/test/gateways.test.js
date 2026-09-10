'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const ai = require('../ai-gateway/index.js')._test;
const drive = require('../drive-gateway/index.js')._test;

function request(value, headers = {}) {
  return { body: typeof value === 'string' ? value : JSON.stringify(value), headers };
}

test('AI input rejects malformed, non-object, and oversized requests', () => {
  assert.throws(() => ai.input(request('{')), (error) => error.message === 'INVALID_JSON' && error.status === 400);
  assert.throws(() => ai.input(request([])), (error) => error.message === 'INVALID_REQUEST');
  assert.throws(() => ai.input(request('x'.repeat(65537))), (error) => error.message === 'REQUEST_TOO_LARGE' && error.status === 413);
});

test('AI bodyJson cannot bypass request size checking', () => {
  const req = { bodyJson: { value: 'x'.repeat(65537) }, headers: {} };
  assert.throws(() => ai.input(req), (error) => error.message === 'REQUEST_TOO_LARGE');
});

test('Gemini model allowlist and output-token cap are enforced', () => {
  process.env.GEMINI_ALLOWED_MODELS = 'gemini-safe';
  assert.throws(
    () => ai.normalizedPayload('gemini', { model: 'gemini-expensive', body: {} }),
    (error) => error.message === 'MODEL_NOT_ALLOWED',
  );
  const payload = ai.normalizedPayload('gemini', {
    model: 'gemini-safe',
    body: { contents: [], generationConfig: { maxOutputTokens: 999999 } },
  });
  assert.equal(payload.body.generationConfig.maxOutputTokens, 4096);
  delete process.env.GEMINI_ALLOWED_MODELS;
});

test('Tavily requests are reduced to an approved schema', () => {
  const payload = ai.normalizedPayload('tavily', {
    body: { query: '  current news  ', max_results: 500, include_answer: true, api_key: 'attacker' },
  });
  assert.deepEqual(payload.body, {
    query: 'current news',
    search_depth: 'basic',
    max_results: 5,
    include_answer: true,
  });
});

test('Sarvam endpoint blocks SSRF and credentials', () => {
  assert.throws(
    () => ai.normalizedPayload('sarvam', { endpoint: 'https://127.0.0.1/internal', body: {} }),
    (error) => error.message === 'INVALID_PROVIDER_ENDPOINT',
  );
  assert.throws(
    () => ai.normalizedPayload('sarvam', { endpoint: 'not a url', body: {} }),
    (error) => error.message === 'INVALID_PROVIDER_ENDPOINT',
  );
  const payload = ai.normalizedPayload('sarvam', { endpoint: 'https://api.sarvam.ai/translate', body: {} });
  assert.equal(payload.endpoint, 'https://api.sarvam.ai/translate');
});

test('upstream response parser rejects invalid and oversized responses', async () => {
  await assert.rejects(
    ai.readJsonResponse(new Response('not-json')),
    (error) => error.message === 'INVALID_UPSTREAM_RESPONSE',
  );
  await assert.rejects(
    ai.readJsonResponse(new Response('{}', { headers: { 'content-length': String(1024 * 1024 + 1) } })),
    (error) => error.message === 'UPSTREAM_RESPONSE_TOO_LARGE',
  );
});

test('Drive input validation rejects malformed and oversized requests', () => {
  assert.throws(() => drive.body(request('{')), (error) => error.message === 'INVALID_JSON');
  assert.throws(() => drive.body(request('x'.repeat(32769))), (error) => error.message === 'REQUEST_TOO_LARGE');
  assert.throws(() => drive.validId('../secret'), (error) => error.message === 'INVALID_FILE_ID');
  assert.equal(drive.validId('file_Id-123'), 'file_Id-123');
  assert.equal(drive.driveQueryLiteral("parent\\'id"), "parent\\\\\\'id");
});

test('Drive OAuth redirect URI must be explicitly allowlisted', () => {
  process.env.GOOGLE_OAUTH_REDIRECT_URIS = 'https://cloud.appwrite.io/v1/account/sessions/oauth2/callback/google/app-id';
  assert.throws(
    () => drive.validRedirectUri('https://attacker.example/callback'),
    (error) => error.message === 'INVALID_REDIRECT_URI',
  );
  assert.equal(
    drive.validRedirectUri('https://cloud.appwrite.io/v1/account/sessions/oauth2/callback/google/app-id'),
    process.env.GOOGLE_OAUTH_REDIRECT_URIS,
  );
  delete process.env.GOOGLE_OAUTH_REDIRECT_URIS;
});

test('Drive refresh tokens use authenticated encryption and reject tampering', () => {
  process.env.GOOGLE_TOKEN_ENCRYPTION_SECRET = Buffer.alloc(32, 7).toString('base64');
  const encrypted = drive.encrypt('refresh-token');
  assert.notEqual(encrypted, 'refresh-token');
  assert.equal(drive.decrypt(encrypted), 'refresh-token');
  const pieces = encrypted.split('.');
  pieces[2] = Buffer.from('tampered').toString('base64');
  assert.throws(() => drive.decrypt(pieces.join('.')), (error) => error.message === 'DRIVE_RECONNECT_REQUIRED');
  delete process.env.GOOGLE_TOKEN_ENCRYPTION_SECRET;
});
