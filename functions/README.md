# Bhasha server-side AI Functions

The remaining Function is the production security boundary for optional Gemini, Sarvam, and Tavily providers. Provider credentials stay in Function environment variables and are never bundled into the Android APK.

## Function

| Directory | Purpose |
|---|---|
| `ai-gateway` | Authenticated proxy for AI, translation, speech, and search providers. |

## Required environment variables

`GEMINI_API_KEYS`, `SARVAM_API_KEYS`, and `TAVILY_API_KEYS` belong only in the Appwrite Function environment. The mobile build receives only public Appwrite endpoint, project ID, and Function ID values.

The Function expects an authenticated Appwrite user JWT in `x-appwrite-user-jwt`. Configure execution permissions so only authenticated users can invoke it. Add rate limits at the Function/API gateway and never log prompts, transcripts, provider responses, or credentials.

## Validation

Run `npm test` and `node --check ai-gateway/index.js` before deploying. The mobile app remains fully local-first when the AI gateway is not configured.
