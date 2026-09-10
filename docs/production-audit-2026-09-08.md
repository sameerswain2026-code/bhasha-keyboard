# Bhasha Keyboard Production Audit

**Date:** 2026-09-08  
**Branch:** `feat/secure-cloud-linked-documents`  
**Starting commit:** `6e38e9b`

## Conclusion

The repository contains a working Flutter Android IME with native-script layouts, Roman transliteration, voice input, translation, media insertion, haptics, document metadata linking, biometric/PIN gating, and signed Android build automation.

It is not yet ready for a public Play Store release. No deployable Appwrite Functions or server-side gateway exists for Google Drive token exchange, Drive folder management, OAuth revocation, or AI provider proxying. These services are required to keep refresh tokens, client secrets, provider keys, rate limits, and audit controls off the mobile binary.

## Audit findings

| Area | Finding | Priority |
|---|---|---:|
| Branches | `main` and `copilot/deep-research-global-problems` point to the same older commit. Feature work is isolated on `feat/secure-cloud-linked-documents`. | Medium |
| Architecture | No duplicate microphone or assistant architecture was found. Existing controller, voice, translation, and IME bridges should be preserved. | Low |
| Backend | No Appwrite Function, server, proxy, or deployable Drive gateway source exists. | P0 |
| UX | The product is panel-driven with one launcher setup screen, not thirty independent screens. A shared design system is safer than artificial screen inflation. | P1 |
| Accessibility/RTL | Broad `Semantics`, `Directionality`, and localization coverage was not found. | P1 |
| Device QA | OAuth, actual IME haptics, `commitContent`, Drive, and Play flows need physical-device evidence. | P0 |

## Security changes in this audit

The mobile Appwrite OAuth call now omits empty success/failure redirect values and requests the least-privilege `drive.file` scope. Web builds still require real HTTPS redirect routes and the exact Appwrite callback must be configured in Google Cloud.

Production and tag-release workflows no longer pass Gemini, Sarvam, or Tavily keys through `--dart-define`; compile-time defines can be extracted from a mobile binary. Provider-backed features remain disabled until a server gateway is deployed.

Release Gradle configuration now fails closed when `android/key.properties` is absent instead of falling back to the debug keystore. The tag-release workflow restores the keystore under `android/app`, matching the module configuration.

## Product findings

The language registry and layout map cover the supported Indian language packs. Translation configuration now synchronizes the live keyboard language with the selected target and selects Native mode for non-Latin targets. Device verification remains required for every supported language and for Sarvam/offline fallback behavior.

The document manager stores URI/reference metadata, requires device authentication before sharing, applies local failed-attempt lockout, releases URI permissions on unlink, and supports custom labels and folder/group movement. Drive folder creation, token rotation, revocation, and secure server-side file lookup remain blocked by the missing backend gateway.

## Production gates

| Priority | Gate | Evidence |
|---|---|---|
| P0 | Deploy Appwrite OAuth/Drive and AI gateway Functions | Function IDs, environment variables, scope/revocation tests |
| P0 | Configure Appwrite Android platform and Google callback | Package name, SHA-256 fingerprints, successful device login |
| P0 | Prove no secrets in release artifacts | Secret scan, workflow review, binary inspection |
| P0 | Complete physical-device IME QA | WhatsApp/Telegram/Gmail typing, haptics, media, voice, documents |
| P1 | Accessibility and bidi QA | TalkBack, focus order, RTL, large-font tests |
| P1 | Monitoring and privacy-safe analytics | Crash reporting, opt-in events, no content logging |
| P1 | Play compliance | Data Safety, privacy policy, deletion path, listing, rating, target SDK |
| P2 | Premium visual pass | Official brand package, lightweight illustrations, dark/light evidence |

## Recommended order

Deploy the server-side security boundary first. Verify OAuth and Drive on a physical Android device. Complete the shared design system and accessibility pass. Publish to Play internal testing before public release.

## References

[1]: https://appwrite.io/docs/products/auth/oauth2 "Appwrite OAuth2 documentation"
[2]: https://developer.android.com/guide/topics/text/copy-paste "Android rich content and clipboard documentation"
[3]: https://developer.android.com/guide/topics/manifest/permission-element "Android permissions documentation"
[4]: https://support.google.com/googleplay/android-developer/answer/9859152 "Google Play app quality and release guidance"

**Status vocabulary:** “Implemented” means source code exists. “Verified” means automated evidence exists. “Ready” requires P0 external evidence.

**Important limitation:** This report does not claim that Appwrite Functions, Google Cloud callback configuration, Play Console submission, or physical-device QA were completed.

**Prepared by:** Manus AI
