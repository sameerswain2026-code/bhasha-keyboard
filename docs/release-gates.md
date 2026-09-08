# Bhasha Keyboard Release Gates

**Scope:** Google Drive documents, secure AI routing, OAuth, device QA, and Google Play publication.

## Gate 1: Deploy Appwrite Functions

Create a private Appwrite table named `google-drive-tokens` with `userId`, `refreshToken`, and `updatedAt` columns. Restrict every row to its owner. Deploy `functions/drive-gateway` and `functions/ai-gateway` with Node.js 22. Configure the variables listed in `functions/README.md` only in the Function environment.

The Drive Function exchanges authorization codes, encrypts refresh tokens with AES-256-GCM, reads Drive metadata, creates folders, and revokes access. It never receives or stores document bytes. The AI Function proxies Gemini, Tavily, and Sarvam HTTP requests and returns only the upstream JSON response.

The repository does not contain an Appwrite management connector or CLI credentials in this session. Therefore, Function deployment cannot be truthfully marked complete from the sandbox. The source and deployment contract are prepared; deployment must be performed by an authenticated Appwrite project owner.

## Gate 2: Secure provider routing

Set the public Flutter defines `APPWRITE_AI_GATEWAY_FUNCTION_ID` and `APPWRITE_DRIVE_GATEWAY_FUNCTION_ID` after Functions are deployed. These are identifiers, not secrets. The Flutter client now routes Gemini and Tavily calls through the AI Function when the AI Function ID is configured. It retains the existing injectable direct clients for tests and private development only.

Sarvam streaming speech remains a direct WebSocket integration because the current provider uses a long-lived audio WebSocket. Do not ship Sarvam API keys in a public APK. Before enabling public voice, add a WebSocket-capable authenticated relay or change the Function boundary to a supported streaming proxy. The current AI Function supports Sarvam HTTP requests, not the existing streaming WebSocket.

## Gate 3: Google OAuth and Appwrite configuration

In Appwrite, create the Android platform for package `com.bhashakeyboard.ime`. Add the release SHA-256 certificate fingerprint and the debug fingerprint used for development. Enable Google as an OAuth provider. In Google Cloud, configure the OAuth client with the exact Appwrite callback URL shown by Appwrite. Do not invent or add a wildcard callback.

For Android, leave `APPWRITE_OAUTH_SUCCESS_URL` and `APPWRITE_OAUTH_FAILURE_URL` empty unless a web build is being configured. The mobile SDK uses its deep-link callback. For web, use application-owned HTTPS routes.

Test login, cancellation, expired session, unlink/revoke, and relaunch. Confirm that the Google account is the intended account and that only `drive.file` scope is requested.

## Gate 4: Physical-device QA

Run this matrix on one Android 13-or-newer device and one older supported device. Record device model, Android version, app version, test result, and evidence screenshot/video.

| Area | Test | Expected result |
|---|---|---|
| IME | Type in WhatsApp, Telegram, Gmail, and browser | Correct text, cursor behavior, editor actions |
| Haptics | Press letter, backspace, enter, toolbar, and panel actions | Native vibration is felt in third-party apps when enabled |
| Languages | Select each supported pack in Native mode | Keycaps use the selected script, not generic A-B-C keys |
| Roman mode | Select each non-Latin pack in Roman mode | Latin keycaps and transliteration behavior are shown |
| Translation | English→Odia, Telugu→Odia, Odia→Telugu | Target language updates live keyboard and output |
| Voice | Start, speak, send, back, timeout, deny permission | Session closes cleanly and no microphone remains active |
| Media | GIF, sticker, image, unsupported editor | `commitContent` works or picker/share fallback opens |
| OAuth | Sign in, cancel, relaunch, expired session | Clear success/error state and no stuck onboarding |
| Documents | Link, label, folder, voice command, biometric/PIN | Metadata only; authentication precedes attachment |
| Lockout | Three failed attempts then retry | 15-minute lockout and clear recovery instruction |
| Unlink | Unlink a file and inspect provider permissions | Local URI permission and metadata row are removed |
| Accessibility | TalkBack, large font, dark mode, RTL text | Labels, focus order, contrast, and bidi layout are usable |

## Gate 5: Google Play compliance

Before internal testing, publish a privacy policy that names Appwrite, Google Drive, Gemini, Sarvam, and Tavily; explains data categories, purposes, retention, deletion, and contact information; and states that document bytes are not stored by Bhasha. Complete the Play Data Safety form consistently with the actual deployed Functions and enabled providers.

Provide an in-app account/session sign-out path, Google Drive unlink/revoke path, and account/data deletion request path. Prepare store listing title, short description, full description, icon, feature graphic, phone screenshots, content rating, target audience answers, and an explanation of the keyboard IME permission. Use Play internal testing first. Do not claim Google Drive or AI capabilities in the public listing until their Functions and device tests pass.

## Release evidence

Keep the signed AAB, APK checksum, CI run URL, Function IDs, OAuth configuration screenshot, device QA matrix, privacy policy URL, Data Safety answers, and internal-track test notes together for the release version.

## References

[1]: https://appwrite.io/docs/products/functions "Appwrite Functions documentation"
[2]: https://appwrite.io/docs/products/auth/oauth2 "Appwrite OAuth2 documentation"
[3]: https://developers.google.com/drive/api/guides/about-sdk "Google Drive API documentation"
[4]: https://support.google.com/googleplay/android-developer/answer/9859152 "Google Play quality and release guidance"
[5]: https://support.google.com/googleplay/android-developer/answer/10787469 "Google Play Data safety guidance"

**Prepared by:** Manus AI

**Status:** Source changes and release evidence templates are prepared. External deployment, Google Cloud configuration, physical-device testing, and Play Console submission remain external actions.
