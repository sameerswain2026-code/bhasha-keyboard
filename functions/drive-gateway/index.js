'use strict';

const crypto = require('node:crypto');
const { Client, Account, Databases, Users } = require('node-appwrite');
const { google } = require('@googleapis/drive');
const { OAuth2Client } = require('google-auth-library');

const MAX_REQUEST_BYTES = 32 * 1024;
const UPSTREAM_TIMEOUT_MS = 10000;
const required = [
  'APPWRITE_ENDPOINT',
  'APPWRITE_PROJECT_ID',
  'APPWRITE_API_KEY',
  'GOOGLE_CLIENT_ID',
  'GOOGLE_CLIENT_SECRET',
  'GOOGLE_TOKEN_ENCRYPTION_SECRET',
];

function validateEnvironment() {
  for (const name of required) {
    if (!process.env[name]) throw new DriveError('FUNCTION_NOT_CONFIGURED', 503);
  }
}

const dbId = () => process.env.APPWRITE_DATABASE_ID || 'bhasha-db';
const tokenCollectionId = () => process.env.APPWRITE_DRIVE_TOKENS_COLLECTION_ID || 'google-drive-tokens';
function encryptionKey() {
  const key = Buffer.from(process.env.GOOGLE_TOKEN_ENCRYPTION_SECRET || '', 'base64');
  if (key.length !== 32) throw new DriveError('FUNCTION_NOT_CONFIGURED', 503);
  return key;
}

function json(res, status, responseBody) { return res.json(responseBody, status); }
function header(req, name) {
  const wanted = name.toLowerCase();
  const entry = Object.entries(req.headers || {}).find(([key]) => key.toLowerCase() === wanted);
  return entry?.[1];
}
function body(req) {
  const raw = typeof req.body === 'string' ? req.body : JSON.stringify(req.bodyJson || req.body || {});
  if (Buffer.byteLength(raw, 'utf8') > MAX_REQUEST_BYTES) throw new DriveError('REQUEST_TOO_LARGE', 413);
  let parsed;
  try {
    parsed = typeof req.bodyJson === 'object' && req.bodyJson !== null ? req.bodyJson : JSON.parse(raw || '{}');
  } catch (_) {
    throw new DriveError('INVALID_JSON', 400);
  }
  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) throw new DriveError('INVALID_REQUEST', 400);
  return parsed;
}
function userClient(jwt) {
  return new Client().setEndpoint(process.env.APPWRITE_ENDPOINT).setProject(process.env.APPWRITE_PROJECT_ID).setJWT(jwt);
}
function adminClient() {
  return new Client().setEndpoint(process.env.APPWRITE_ENDPOINT).setProject(process.env.APPWRITE_PROJECT_ID).setKey(process.env.APPWRITE_API_KEY);
}
async function authenticate(req) {
  const jwt = header(req, 'x-appwrite-user-jwt');
  if (!jwt) throw new DriveError('AUTH_REQUIRED', 401);
  return new Account(userClient(jwt)).get();
}
function encrypt(value) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', encryptionKey(), iv);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return `${iv.toString('base64')}.${cipher.getAuthTag().toString('base64')}.${ciphertext.toString('base64')}`;
}
function decrypt(value) {
  try {
    const parts = String(value).split('.');
    if (parts.length !== 3) throw new Error('invalid token');
    const [iv, tag, ciphertext] = parts.map((part) => Buffer.from(part, 'base64'));
    if (iv.length !== 12 || tag.length !== 16 || ciphertext.length === 0) throw new Error('invalid token');
    const decipher = crypto.createDecipheriv('aes-256-gcm', encryptionKey(), iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
  } catch (_) {
    throw new DriveError('DRIVE_RECONNECT_REQUIRED', 409);
  }
}
function validId(value) {
  const id = String(value || '').trim();
  if (!/^[A-Za-z0-9_-]{3,200}$/.test(id)) throw new DriveError('INVALID_FILE_ID', 400);
  return id;
}
function driveQueryLiteral(value) {
  return String(value).replaceAll('\\', '\\\\').replaceAll("'", "\\'");
}
function validRedirectUri(value) {
  const uri = String(value || '').trim();
  const allowed = (process.env.GOOGLE_OAUTH_REDIRECT_URIS || '').split(',').map((item) => item.trim()).filter(Boolean);
  if (!uri || !allowed.includes(uri)) throw new DriveError('INVALID_REDIRECT_URI', 400);
  return uri;
}
async function withTimeout(operation) {
  let timer;
  try {
    return await Promise.race([
      operation,
      new Promise((_, reject) => {
        timer = setTimeout(
          () => reject(new DriveError('UPSTREAM_TIMEOUT', 504)),
          UPSTREAM_TIMEOUT_MS,
        );
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}
async function oauthTokens(code, redirectUri) {
  const cleanCode = String(code || '').trim();
  if (!cleanCode || cleanCode.length > 4096) throw new DriveError('INVALID_AUTHORIZATION_CODE', 400);
  const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET, validRedirectUri(redirectUri));
  const result = await withTimeout(oauth.getToken(cleanCode));
  if (!result.tokens.refresh_token) throw new DriveError('GOOGLE_REFRESH_TOKEN_NOT_RETURNED', 409);
  return result.tokens;
}
function driveForToken(token) {
  const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET);
  oauth.setCredentials({ refresh_token: decrypt(token) });
  return google.drive({ version: 'v3', auth: oauth });
}
async function saveToken(databases, userId, refreshToken) {
  const data = { userId, refreshToken: encrypt(refreshToken), updatedAt: new Date().toISOString() };
  try {
    // Tokens are server-only rows. Do not grant the mobile client read access,
    // even though the refresh token is encrypted at rest.
    await databases.createDocument(dbId(), tokenCollectionId(), userId, data, []);
  } catch (err) {
    if (err.code !== 409) throw err;
    await databases.updateDocument(dbId(), tokenCollectionId(), userId, data, []);
  }
}

class DriveError extends Error {
  constructor(message, status) {
    super(message);
    this.name = 'DriveError';
    this.status = status;
  }
}

async function handler({ req, res, error = () => {} }) {
  try {
    validateEnvironment();
    const user = await authenticate(req);
    const input = body(req);
    const route = String(input.action || '');
    const databases = new Databases(adminClient());

    if (route === 'exchange') {
      const tokens = await oauthTokens(input.code, input.redirectUri);
      await saveToken(databases, user.$id, tokens.refresh_token);
      return json(res, 200, { connected: true });
    }

    if (route === 'connect') {
      const jwt = header(req, 'x-appwrite-user-jwt');
      const session = await new Account(userClient(jwt)).getSession('current');
      const refreshToken = String(session.providerRefreshToken || '').trim();
      if (!refreshToken) throw new DriveError('GOOGLE_RECONNECT_REQUIRED', 409);
      await saveToken(databases, user.$id, refreshToken);
      return json(res, 200, { connected: true });
    }

    if (route === 'delete-account') {
      if (String(input.confirmation || '') !== user.$id) {
        throw new DriveError('ACCOUNT_DELETION_NOT_CONFIRMED', 400);
      }
      try {
        const savedToken = await databases.getDocument(dbId(), tokenCollectionId(), user.$id);
        try {
          const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET);
          await withTimeout(oauth.revokeToken(decrypt(savedToken.refreshToken)));
        } catch (err) {
          error(`Google token revoke during account deletion failed: ${err.message || 'unknown error'}`);
        }
        await databases.deleteDocument(dbId(), tokenCollectionId(), savedToken.$id);
      } catch (err) {
        if (err.code !== 404) throw err;
      }
      await new Users(adminClient()).delete(user.$id);
      return json(res, 200, { deleted: true });
    }

    let token;
    try {
      token = await databases.getDocument(dbId(), tokenCollectionId(), user.$id);
    } catch (err) {
      if (err.code === 404) return json(res, 409, { error: 'DRIVE_NOT_CONNECTED' });
      throw err;
    }
    // The deterministic document ID and this check prevent cross-user token use
    // even if the backing collection is accidentally misconfigured.
    if (token.userId !== user.$id) throw new DriveError('DRIVE_NOT_CONNECTED', 409);

    if (route === 'revoke') {
      const refreshToken = decrypt(token.refreshToken);
      const oauth = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET);
      try {
        await withTimeout(oauth.revokeToken(refreshToken));
      } catch (err) {
        // An already-revoked Google token must not stop local disconnection.
        error(`Google token revoke failed: ${err.message || 'unknown error'}`);
      }
      await databases.deleteDocument(dbId(), tokenCollectionId(), token.$id);
      return json(res, 200, { revoked: true });
    }

    const drive = driveForToken(token.refreshToken);
    if (route === 'list' || route === 'search') {
      const parentId = input.parentId == null ? null : validId(input.parentId);
      const search = String(input.query || '').trim();
      if (search.length > 200) throw new DriveError('INVALID_QUERY', 400);
      const clauses = ['trashed = false'];
      if (parentId) clauses.push(`'${driveQueryLiteral(parentId)}' in parents`);
      if (route === 'search' && search) {
        clauses.push(`name contains '${driveQueryLiteral(search)}'`);
      }
      const result = await withTimeout(drive.files.list({
        q: clauses.join(' and '),
        fields: 'nextPageToken,files(id,name,mimeType,webViewLink,parents,modifiedTime,size)',
        orderBy: 'folder,name_natural',
        pageSize: 100,
        spaces: 'drive',
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      }));
      return json(res, 200, {
        files: result.data.files || [],
        nextPageToken: result.data.nextPageToken || null,
      });
    }
    if (route === 'metadata') {
      const result = await withTimeout(drive.files.get({
        fileId: validId(input.fileId),
        fields: 'id,name,mimeType,webViewLink,parents,modifiedTime,size',
        supportsAllDrives: true,
      }));
      return json(res, 200, { file: result.data });
    }
    if (route === 'folder') {
      const name = String(input.name || 'Bhasha Documents').trim();
      if (!name || name.length > 255) throw new DriveError('INVALID_FOLDER_NAME', 400);
      const parentId = input.parentId == null ? null : validId(input.parentId);
      const result = await withTimeout(drive.files.create({
        requestBody: {
          name,
          mimeType: 'application/vnd.google-apps.folder',
          ...(parentId ? { parents: [parentId] } : {}),
        },
        fields: 'id,name,mimeType,parents',
        supportsAllDrives: true,
      }));
      return json(res, 200, { folder: result.data });
    }
    if (route === 'create-document') {
      const name = String(input.name || '').trim();
      if (!name || name.length > 255) throw new DriveError('INVALID_DOCUMENT_NAME', 400);
      const parentId = input.parentId == null ? null : validId(input.parentId);
      const result = await withTimeout(drive.files.create({
        requestBody: {
          name,
          mimeType: 'application/vnd.google-apps.document',
          ...(parentId ? { parents: [parentId] } : {}),
        },
        fields: 'id,name,mimeType,webViewLink,parents,modifiedTime',
        supportsAllDrives: true,
      }));
      return json(res, 200, { file: result.data });
    }
    throw new DriveError('UNKNOWN_ACTION', 400);
  } catch (err) {
    if (err instanceof DriveError) return json(res, err.status, { error: err.message });
    error(`${err.name || 'Error'}: ${err.message || 'FUNCTION_FAILED'}`);
    return json(res, 500, { error: 'FUNCTION_FAILED' });
  }
}

module.exports = handler;
module.exports._test = {
  body,
  encrypt,
  decrypt,
  driveQueryLiteral,
  validId,
  validRedirectUri,
  DriveError,
};
