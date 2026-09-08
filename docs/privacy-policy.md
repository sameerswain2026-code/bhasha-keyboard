# Bhasha Keyboard Privacy Policy

**Last updated: 8 September 2026**

Bhasha Keyboard is a multilingual Android input method. Core typing, keyboard layouts, transliteration, local suggestions, themes, clipboard history, and keyboard settings are processed on the device. Bhasha Keyboard does not sell personal information and does not use typed text for advertising profiles.

## Information processed on the device

The app processes the characters that the user types, edits, copies, pastes, and selects so that it can provide keyboard input, transliteration, suggestions, clipboard history, text editing, and writing tools. Clipboard history and preferences are stored locally on the device. The user can remove clipboard entries from the keyboard and can disable optional features in settings.

The app requests microphone permission only when the user activates voice typing or voice commands. The microphone is not used for background recording. Audio or speech transcripts may be sent to the configured speech service to provide the requested voice feature.

## Optional network features

When the user explicitly activates a network-backed feature, the relevant text, selected text, transcript, or audio may be transmitted to the provider required for that feature. Depending on the enabled configuration, providers may include **Sarvam AI** for speech recognition or translation, **Google Gemini** for grammar correction, rewriting, tone changes, suggested replies, and AI assistance, **Tavily** for optional web search, and **Appwrite or Google Drive** for document-link metadata and document selection.

The app does not intentionally upload the complete clipboard history, unrelated typed text, passwords, or document bytes to a Bhasha server. A network feature receives only the content needed for the user-selected operation. Users should not submit passwords, payment-card numbers, or other sensitive information to optional AI, voice, translation, search, or document tools.

The applicable provider may process and retain requests under its own terms and privacy policy. Bhasha Keyboard does not control third-party retention periods. Users should review the provider policies before enabling optional network features.

## Documents and Google Drive

The local Android document picker can provide a temporary or persisted read-only reference to a document selected by the user. The app uses Android URI permissions and shares supported content with the active editor when requested. If cloud Documents or Google Drive integration is enabled, account authentication and document metadata are handled through the configured Appwrite project and required server-side Functions. Document bytes must not be copied to Bhasha storage unless a future release explicitly changes this policy and updates this document.

Users can unlink a document from the keyboard. Unlinking removes the local permission where possible and removes the associated metadata record when cloud metadata is enabled.

## Security

Provider credentials, OAuth client secrets, refresh tokens, encryption secrets, and Appwrite server API keys must never be included in the Android application. Production builds use a secure backend or keep optional provider features disabled until that backend is configured. The app does not intentionally log typed text, clipboard contents, passwords, audio, credentials, or provider responses.

## Children and advertising

Bhasha Keyboard is a utility application and does not use personal information for targeted advertising. Parents or guardians should supervise use of optional network features by children.

## User choices and deletion

Users can deny microphone permission, disable haptics and optional features, clear clipboard history, unlink documents, sign out of connected services where supported, and uninstall the application. Requests handled directly by third-party providers may need to be deleted through those providers under their own policies.

## Contact

For privacy questions, security reports, or deletion requests, contact the project maintainer through the repository issue tracker: <https://github.com/sameerswain2026-code/bhasha-keyboard/issues>.

This document must be published at a stable HTTPS URL and must match the providers, features, retention behavior, and Data safety declarations of the exact Play Store release.
