# Bhasha server-side Functions

These Functions are the production security boundary for Google Drive and AI providers. They must be deployed in Appwrite; they must not be bundled into the Android APK.

## Functions

| Directory | Purpose |
|---|---|
| `drive-gateway` | Authenticated Google OAuth code exchange, token refresh, Drive metadata/folder operations, unlink/revoke, and document-link metadata access. It never returns document bytes. |
| `ai-gateway` | Authenticated proxy for Gemini, Sarvam, and Tavily. Provider credentials stay in Function environment variables. |

## Required environment variables

`APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_TOKEN_ENCRYPTION_SECRET`, `GEMINI_API_KEYS`, `SARVAM_API_KEYS`, and `TAVILY_API_KEYS` belong only in Appwrite Function variables. `GOOGLE_TOKEN_ENCRYPTION_SECRET` must be a randomly generated 32-byte key encoded as base64.

The Drive Function also requires `GOOGLE_OAUTH_REDIRECT_URIS` for code exchange. Set it to a comma-separated allowlist of the exact callback URI(s) registered with Google; caller-selected redirect URIs are rejected. Optional variables are `APPWRITE_DATABASE_ID`, `APPWRITE_DRIVE_TOKENS_COLLECTION_ID`, `GEMINI_ALLOWED_MODELS` (comma-separated, defaults to `gemini-2.5-flash-lite`), and `SARVAM_ALLOWED_HOSTS` (defaults to `api.sarvam.ai`).

The Functions expect the Appwrite user JWT in `x-appwrite-user-jwt`. They use the JWT to establish the caller identity and reject unauthenticated requests. Configure execution permissions so only authenticated users can invoke them. The `google-drive-tokens` collection must have document security enabled and no client create/read/update/delete permissions; token rows are intentionally accessible only through the Drive Function's API key.

## Deployment

Deploy each directory as a separate Appwrite Function using the Node.js 22 runtime. Install dependencies from the local `package.json`, set the Function variables in the Appwrite console, and configure the Function IDs in the mobile build as public identifiers only. Do not put `APPWRITE_API_KEY`, Google client secret, refresh tokens, or provider keys in Flutter `--dart-define` values.

Before production, test with a non-owner Google account, revoke access, confirm token deletion, and verify that no request or log contains document bytes or authorization codes.

## Operational requirements

Use Appwrite execution logs only for request IDs, route names, status codes, and latency. Never log prompts, transcripts, file contents, tokens, or provider responses. Add rate limits at the Function/API gateway and rotate all secrets before the first public release.

**Status:** source scaffolding is included; deployment and external console configuration remain required.

**References**

[1]: https://appwrite.io/docs/products/functions "Appwrite Functions documentation"
[2]: https://developers.google.com/drive/api/guides/about-sdk "Google Drive API documentation"
[3]: https://ai.google.dev/gemini-api/docs "Gemini API documentation"
[4]: https://docs.tavily.com/documentation/api-reference/endpoint/search "Tavily Search API documentation"
[5]: https://www.sarvam.ai/api "Sarvam AI API documentation"

[1] [2] [3] [4] [5]

**No document bytes are accepted or stored by these Functions.**

**End.**
