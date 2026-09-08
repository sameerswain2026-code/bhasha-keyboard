# Bhasha Keyboard Play Store Release Checklist

## Current engineering status

The Flutter codebase, Android IME, AI writing tools, language switching, automatic script detection, haptic feedback path, suggestion engine, Documents UI, and translation tools are implemented and validated by repository CI. The latest signed production build workflow has passed on `main`.

## Privacy and data-safety gate

Before public release, publish a privacy-policy URL that matches the Play Console Data safety declaration. The policy must identify the configured speech provider, translation provider, Gemini or other AI provider, search provider, and Appwrite/Google Drive services when enabled. It must state what typed text, selected text, transcripts, audio, clipboard content, document metadata, and document bytes leave the device. It must state retention, deletion, account unlinking, support contact, and the user's control over optional network features.

Core typing, layouts, transliteration, suggestions, clipboard history, and local panel state should remain usable without network access. Network-backed features must fail closed with a clear message and must not expose secrets or silently upload typed content.

## Documents and Google Drive gate

The Documents UI and local Android document-picker flow are present. Google Drive/cloud Documents must not be advertised as production-ready until the required authenticated Appwrite Functions are deployed and tested. Those Functions must cover OAuth exchange and refresh, Drive metadata access, unlink/revoke, password verification, and atomic failed-attempt lockout. The server must store only necessary references and metadata; document bytes must not be copied into Bhasha storage or logs.

The Appwrite project, database schema, collection permissions, OAuth configuration, Functions, Google OAuth consent screen, and a non-owner test account must be provisioned outside this repository. No Appwrite connector is configured in the current Manus session, so this external provisioning has not been performed here.

## Device validation gate

Test the signed AAB through an internal Play testing track on Android 13 or newer and one older supported Android version. Test WhatsApp, Telegram, a browser text field, gesture navigation, three-button navigation where available, dark mode, large font settings, RTL Urdu/Kashmiri/Sindhi, microphone permission denial, haptic settings, keyboard switching, rotation, process restart, and low-memory recovery.

The test matrix must include language switching repeatedly, Native and Roman output, automatic script detection, Transcribe, Auto Mix, Translate, manual translation, grammar correction, rewrite, tone changes, suggested replies, document linking/unlinking, OAuth cancellation, provider failure, and lockout expiry.

## Release artifact gate

Create a versioned tag such as `v1.0.0`. The tag workflow runs formatting, analysis, all tests, signed AAB generation, artifact verification, and GitHub Release attachment. Upload the verified AAB to the Play internal testing track before production rollout. Use a staged rollout and monitor crashes and ANRs before widening distribution.
