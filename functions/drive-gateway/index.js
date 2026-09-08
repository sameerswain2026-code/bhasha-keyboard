const crypto = require('node:crypto');
const { Client, Account, Databases, ID, Query } = require('node-appwrite');
const { google } = require('@googleapis/drive');
const { OAuth2Client } = require('google-auth-library');

const required = ['APPWRITE_ENDPOINT', 'APPWRITE_PROJECT_ID', 'APPWRITE_API_KEY', 'GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET', 'GOOGLE_TOKEN_ENCRYPTION_SECRET'];
for (const name of required) if (!process.env[name]) throw new Error(`Missing Function variable: ${name}`);

const dbId = process.env.APPWRITE_DATABASE_ID || 'bhasha-db';
const tableId = process.env.APPWRITE_DOCUMENT_LINKS_COLLECTION_ID || 'document-links';
const key = Buffer.from(process.env.GOOGLE_TOKEN_ENCRYPTION_SECRET, 'base64');
if (key.length !== 32) throw new Error('GOOGLE_TOKEN_ENCRYPTION_SECRET must decode to 32 bytes');

function json(res, status, body) { return res.json(body, status); }
function body(req) { return typeof req.bodyJson === 'object' && req.bodyJson ? req.bodyJson : JSON.parse(req.body || '{}'); }
function clientForJwt(jwt) {
  return new Client().setEndpoint(process.env.APPWRITE_ENDPOINT).setProject(process.env.APPWRITE_PROJECT_ID).setKey(process.env.APPWRITE_API_KEY).setJWT(jwt);
}
async function userFrom(req) {
  const jwt = req.headers?.['x-appwrite-user-jwt'] || req.headers?.['X-Appwrite-User-JWT'];
  if (!jwt) throw new Error('AUTH_REQUIRED');
  const account = new Account(clientForJwt(jwt));
  return account.get();
}
function encrypt(value) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return `${iv.toString('base64')}.${cipher.getAuthTag().toString('base64')}.${ciphertext.toString('base64')}`;
}
function decrypt(value) {
  const [iv, tag, ciphertext] = value.split('.').map((part) => Buffer.from(part, 'base64'));
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
}
async function oauthTokens(code, redirectUri) {
  const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET, redirectUri);
  const result = await oauth.getToken(code);
  if (!result.tokens.refresh_token) throw new Error('GOOGLE_REFRESH_TOKEN_NOT_RETURNED');
  return result.tokens;
}
async function driveForToken(token) {
  const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET);
  oauth.setCredentials({ refresh_token: decrypt(token) });
  return google.drive({ version: 'v3', auth: oauth });
}

module.exports = async ({ req, res, log, error }) => {
  try {
    const user = await userFrom(req);
    const input = body(req);
    const route = input.action;
    const databases = new Databases(clientForJwt(req.headers['x-appwrite-user-jwt']));

    if (route === 'exchange') {
      const tokens = await oauthTokens(String(input.code || ''), String(input.redirectUri || ''));
      await databases.createDocument(dbId, 'google-drive-tokens', user.$id, {
        userId: user.$id,
        refreshToken: encrypt(tokens.refresh_token),
        updatedAt: new Date().toISOString(),
      }, [`read("user:${user.$id}")`, `update("user:${user.$id}")`, `delete("user:${user.$id}")`]);
      return json(res, 200, { connected: true });
    }

    const tokenRows = await databases.listDocuments(dbId, 'google-drive-tokens', [Query.equal('userId', user.$id), Query.limit(1)]);
    if (!tokenRows.documents.length) return json(res, 409, { error: 'DRIVE_NOT_CONNECTED' });
    const token = tokenRows.documents[0];
    const drive = await driveForToken(token.refreshToken);

    if (route === 'metadata') {
      const result = await drive.files.get({ fileId: String(input.fileId), fields: 'id,name,mimeType,webViewLink,parents,modifiedTime,size' });
      return json(res, 200, { file: result.data });
    }
    if (route === 'folder') {
      const result = await drive.files.create({ requestBody: { name: String(input.name || 'Bhasha Documents'), mimeType: 'application/vnd.google-apps.folder' }, fields: 'id,name,mimeType,parents' });
      return json(res, 200, { folder: result.data });
    }
    if (route === 'revoke') {
      const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET);
      await oauth.revokeToken(decrypt(token.refreshToken));
      await databases.deleteDocument(dbId, 'google-drive-tokens', token.$id);
      return json(res, 200, { revoked: true });
    }
    return json(res, 400, { error: 'UNKNOWN_ACTION' });
  } catch (err) {
    if (err.message === 'AUTH_REQUIRED') return json(res, 401, { error: err.message });
    error(err.stack || String(err));
    return json(res, 500, { error: 'FUNCTION_FAILED' });
  }
};
