# Production setup boundary

The Android app contains only public Appwrite project configuration. It must never contain Appwrite API keys, Google OAuth client secrets, Google refresh tokens, service-account private keys, password peppers, or provider API keys.

## Public build variables

```text
APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID
APPWRITE_DATABASE_ID
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID
APPWRITE_AI_GATEWAY_FUNCTION_ID
APPWRITE_DRIVE_GATEWAY_FUNCTION_ID
APPWRITE_OAUTH_SUCCESS_URL
APPWRITE_OAUTH_FAILURE_URL
```

For the Android Flutter build, `APPWRITE_OAUTH_SUCCESS_URL` and `APPWRITE_OAUTH_FAILURE_URL` may remain empty. The mobile Appwrite SDK uses its callback/deep-link flow when these optional web redirect values are omitted. Supplying an empty string is incorrect because Google treats it as a missing redirect URL. For a web build, set both values to real HTTPS routes owned by the application and add the exact Appwrite-provided callback URL to the Google Cloud OAuth client configuration.

## Server-side Function variables

These belong only in Appwrite Function environment variables or another secure server runtime:

```text
APPWRITE_API_KEY
APPWRITE_DATABASE_ID
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
GOOGLE_TOKEN_ENCRYPTION_SECRET
GOOGLE_OAUTH_REDIRECT_URIS
APPWRITE_DRIVE_TOKENS_COLLECTION_ID
GEMINI_ALLOWED_MODELS
SARVAM_ALLOWED_HOSTS
GEMINI_API_KEYS
SARVAM_API_KEYS
TAVILY_API_KEYS
DOCUMENT_PASSWORD_PEPPER
```

## Required Functions

The repository now contains `functions/drive-gateway` and `functions/ai-gateway` source scaffolding. Deploy them as authenticated Node.js 22 Appwrite Functions. The production document flow requires Functions for Google OAuth exchange and refresh, Drive file/folder metadata, unlink/revoke, document-password verification, and atomic failed-attempt locking. Document bytes must not be written to Appwrite Storage or the Bhasha backend. The Android client stores only references and metadata in the `document_links` collection.

Create a private `google-drive-tokens` table with `userId`, `refreshToken`, and `updatedAt` columns before deploying `drive-gateway`. Enable document security but grant no client create/read/update/delete permissions: only the Function API key may access token rows. Store each refresh token encrypted with `GOOGLE_TOKEN_ENCRYPTION_SECRET`; never expose it to Flutter or log it. Set `GOOGLE_OAUTH_REDIRECT_URIS` to the exact comma-separated callback allowlist registered with Google. The `document-links` table must index `userId` and `driveFileId` (including the query combination used to prevent duplicate private AI-index references).

## Current repository status

The client boundary and Appwrite Auth/metadata adapter are present in `CloudConfig` and `AppwriteDocumentRepository`. The Android client uses the system document picker with persisted read-only URI permissions, sends supported attachments through `commitContent`, and falls back to the target application's picker or share sheet. Device-credential authentication is required before attachment, and three failed attempts create a local 15-minute lockout. Unlinking releases the local URI and deletes the corresponding Appwrite metadata row when one exists.

Google sign-in requests the least-privilege `drive.file` scope. This permits access to files selected or created through the app without requesting broad access to the user's entire Drive. Gemini and Tavily calls route through `ai-gateway` when `APPWRITE_AI_GATEWAY_FUNCTION_ID` is configured. Sarvam's current audio WebSocket still needs a WebSocket-capable relay before its API key can be removed from the streaming path.

Keyboard key feedback is routed through the native `InputMethodService` vibrator with a short duration, reduced amplitude, and client-side throttling. This is required because the keyboard runs in another application's IME window, where activity-only feedback behavior is inconsistent across Android vendors.

Console resources and Function deployment remain external provisioning steps because the Appwrite dashboard session did not expose project controls during setup. The Google Drive exchange, token refresh, revoke, folder mapping, password verification, and atomic server-side lockout functions must be deployed before Google Drive linking can be considered production-complete. Provider API keys must also remain in a secure backend: the public Android release workflows deliberately do not pass Gemini, Sarvam, or Tavily keys into `--dart-define`, because compile-time keys are recoverable from an APK. Until a backend proxy is configured, those optional provider features fail safely instead of exposing credentials. No credentials are committed in this repository.

## Release gate

The application must not be published as a production Google Drive client until the Functions are deployed and tested with a real non-owner test account. The release candidate must also be verified on at least one Android 13 or newer device and one older supported Android device, including haptics in WhatsApp, Telegram, and a browser text field; document attachment in an editor that supports `commitContent`; fallback sharing in an editor that does not; OAuth cancellation; unlink and permission revocation; three failed authentication attempts; and lockout expiry. The sandbox currently lacks the Flutter SDK, so the final signed build and automated Flutter tests must be run in GitHub Actions or a machine with Flutter installed.
