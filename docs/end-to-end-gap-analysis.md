# Bhasha Keyboard: End-to-End Missing Features and Production Gaps

**Audit basis:** Current `main` branch, repository source, automated tests, Android workflows, release documentation, privacy policy, and the latest branded welcome-flow implementation. **Latest audited commit:** `83eef33`.

## Executive assessment

Bhasha Keyboard का **core Android IME और local typing experience काफी आगे है**। Keyboard layouts, multilingual input, Roman/native modes, suggestions, clipboard, haptics, voice modes, translation panels, manual translation, text editing tools, themes, documents UI, onboarding flow और CI-built signed artifacts repository में मौजूद हैं। Latest repository CI में analyzer और पूरी test suite सफल है।

फिर भी इसे बिना किसी qualification के “पूरी तरह production-ready” कहना सही नहीं होगा। सबसे बड़े gaps application UI में नहीं बल्कि **external production infrastructure, provider security, cloud Documents implementation, real-device validation, privacy disclosures, Play Store compliance और operational monitoring** में हैं। Google Play developer account verification के pending रहने से local development और internal testing रुकती नहीं है, लेकिन public production release के लिए नीचे दिए गए release gates पूरे करने होंगे।

## Status legend

| Status | Meaning |
|---|---|
| **Implemented** | Source code में feature मौजूद है और automated validation उपलब्ध है। |
| **Partial** | UI या local path मौजूद है, लेकिन backend, provider, device testing या edge cases बाकी हैं। |
| **Missing / blocker** | Public production के लिए अभी implement या configure करना अनिवार्य है। |
| **External gate** | Code के बाहर Appwrite, Google Cloud, Play Console या real devices पर करना होगा। |

## 1. User-facing application flow

| Area | Current status | Missing or required work |
|---|---|---|
| Branded Welcome / Brand Intro | **Implemented** | Current generic Bhasha branding को final owner name, qualification, designation, approved logo और official tagline से replace करना बाकी है। इन details के बिना personal branding invent नहीं करनी चाहिए। |
| Feature Showcase | **Implemented** | Feature claims को final product wording, screenshots, illustrations/GIF assets और privacy-safe marketing copy से align करना बाकी है। |
| Optional Google login | **Partial** | UI और Appwrite OAuth call मौजूद हैं; Appwrite Google provider enabled होना, client configuration, redirect/deep link और non-owner test account से end-to-end validation बाकी है। |
| Main Dashboard | **Partial** | Current companion app मुख्यतः demo/editor experience है। Production dashboard में account state, keyboard setup status, documents summary, language/mode shortcuts, privacy controls और provider status को एक व्यवस्थित home screen में consolidate करना बाकी है। |
| Keyboard setup on demand | **Implemented** | Welcome page से setup और Settings से guided setup उपलब्ध है। Real Android devices पर every return-from-settings state verify करना बाकी है। |
| 30 visual skins | **Missing** | Current theme system है, लेकिन 30 complete, previewable, branded keyboard skins का product catalog अभी नहीं है। इसमें palette, key shape, background, contrast, dark/light variant, preview और persistence चाहिए। |
| Branded developer/about section | **Partial** | About/settings area को final developer profile, qualification, ownership/IP statement, support link और app version information से complete करना बाकी है। |

## 2. Keyboard and language experience

| Area | Current status | Remaining work |
|---|---|---|
| 22 language registry | **Implemented / verify on device** | Registry और layouts मौजूद हैं; प्रत्येक language के native characters, signs, punctuation, long-press keys, suggestions और IME insertion को physical devices पर verify करना बाकी है। |
| Native/Roman switching | **Implemented** | Repeated switching, cursor/composing behavior और app-specific editor behavior को WhatsApp, Telegram, browser और form fields में validate करना बाकी है। |
| Translate mode Roman output | **Implemented** | English keycaps और Roman output code में हैं; all target/source language combinations और provider failure states का device test बाकी है। |
| Automatic script/language detection | **Implemented / heuristic** | Detection source text/script heuristics पर आधारित है, authoritative language identification नहीं। Mixed text, short text, punctuation, Urdu/Sindhi/Kashmiri और code-switching cases में accuracy evaluation और fallback UX बाकी है। |
| Suggestions | **Implemented / local** | Dictionary coverage, ranking quality, personalization, deletion/reset controls, offensive-word handling और per-language accuracy measurement अभी incomplete हैं। |
| Voice typing | **Partial** | Mic lifecycle और voice modes मौजूद हैं; provider availability, Android vendor differences, interruption, denial, timeout, network loss, background audio policy और all-language accuracy को production devices पर test करना बाकी है। |
| Haptics | **Implemented / device-dependent** | Native throttled vibrator path है; amplitude support, silent mode, vendor behavior, battery impact और user-facing haptic intensity setting को device matrix पर validate करना बाकी है। |
| Accessibility | **Partial** | Tooltips और semantics कुछ controls में हैं; TalkBack labels, focus order, large font, contrast, touch target size, switch access और reduced-motion behavior का formal audit बाकी है। |
| RTL support | **Partial** | Urdu, Sindhi और Kashmiri के लिए layout/runtime support है; RTL visual order, cursor behavior, translation direction, toolbar mirroring और device validation बाकी है। |

## 3. Translation, transcription and AI

| Area | Current status | Critical gap |
|---|---|---|
| Real-time translation | **Partial** | Local translation engine और provider-facing architecture है, लेकिन quality/coverage को “22 languages production translation” मानने से पहले real provider/backend configuration और language-pair evaluation जरूरी है। Offline Indic-to-Indic behavior fallback/transliteration हो सकता है, full translation नहीं। |
| Manual translation | **Implemented / provider-dependent** | Input, source/target selectors, translate, copy और insert मौजूद हैं; offline/timeout/error/retry states और result length handling को polish करना बाकी है। |
| Transcription | **Partial** | Voice flow मौजूद है; configured speech provider, server-side key protection, per-language availability, quota errors, audio/transcript disclosure और accuracy benchmark बाकी है। |
| Auto mode | **Partial** | Auto detection और mode routing code में है; ambiguous/mixed speech, short utterances, code-switching और wrong-detection correction UX बाकी है। |
| Grammar correction | **Partial** | AI writing action मौजूद है, लेकिन secure provider backend आवश्यक है। Public APK में provider keys नहीं होनी चाहिए; backend proxy/function, quotas, timeout, prompt safety और data deletion policy बाकी है। |
| Rewrite text | **Partial** | UI/action path मौजूद है; secure backend, supported languages, preserving names/numbers, undo, length limits और failure UX बाकी है। |
| Tone change | **Partial** | Action मौजूद है; tone catalog, localized labels, safe transformation rules, undo and provider failure handling बाकी है। |
| Suggested replies | **Partial** | Engine/action architecture मौजूद है; conversation context minimization, language-aware replies, sensitive text protection, loading/error UX और quality evaluation बाकी है। |
| AI Assistant and web search | **Partial / backend blocker** | Gemini/Tavily integration code है, लेकिन client APK में keys डालना unsafe है। Secure backend proxy/Appwrite Functions, rate limiting, abuse prevention, source attribution, consent and privacy controls जरूरी हैं। |
| Voice commands for document upload/share | **Partial** | Command handling और share flow मौजूद है; cloud document lookup, authorization, secure confirmation, audit trail और third-party target-app matrix बाकी है। |

## 4. Documents and Google Drive

यह वर्तमान का सबसे बड़ा functional production blocker है। Documents UI और local Android picker मौजूद हैं, लेकिन cloud Google Drive को production feature की तरह advertise करने से पहले authenticated server-side implementation पूरा करना आवश्यक है।

### Existing pieces

- Documents panel with cards, labels, folders and actions.
- Local Android document picker and persisted read-only URI permissions.
- Local unlink path.
- Device credential authentication before protected attachment/share.
- Local failed-attempt lockout behavior.
- Appwrite metadata adapter with user-scoped row permissions.
- Least-privilege Google `drive.file` scope in the mobile OAuth request.

### Missing or externally required pieces

1. **Appwrite Google provider must be enabled** and tested with the exact production project.
2. **Google OAuth client configuration** must match the Appwrite callback URI and Android deep-link configuration.
3. **Server-side OAuth exchange and refresh Function** is required. Refresh tokens and client secrets must never be shipped in the APK.
4. **Drive metadata/list/create/link Function** is required for real Drive file/folder operations.
5. **Unlink/revoke Function** is required to revoke or remove cloud references safely.
6. **Password verification Function** is required if document-level passwords are advertised.
7. **Atomic failed-attempt locking** must be server-enforced, not only local/UI enforced.
8. **Collection/table security** must enforce user-scoped read/update/delete at the database level, not only through client-supplied fields.
9. **Non-owner test account** must verify that one user cannot read or modify another user's document reference.
10. **No document bytes in Appwrite Storage, logs or analytics** must be checked through code and Function logs.
11. **Conflict/offline synchronization behavior** is not fully defined for rename, folder move, unlink and token expiry.
12. **Provider error mapping** must cover expired session, revoked Drive permission, deleted file, quota, rate limit and unavailable provider.

Until these items are deployed and tested, the safe product wording is **“local document sharing and cloud-linking preparation”**, not a fully production-ready Google Drive document service.

## 5. Security and privacy

| Requirement | Current status | Remaining work |
|---|---|---|
| No provider keys in public APK | **Hardened** | Keep this rule permanently; do not re-add `--dart-define` API keys to public Android workflows. |
| Appwrite public config boundary | **Implemented** | Verify production project IDs and empty mobile OAuth success/failure URL behavior. |
| Privacy policy | **Draft/published content exists** | Final policy must match exact providers, retention, data deletion, account unlinking, support contact and Play Data Safety answers. |
| Typed text disclosure | **Documented** | Confirm actual runtime paths do not send unrelated typed text or passwords. |
| Clipboard disclosure | **Documented** | Add explicit in-app explanation and clear-history UX confirmation if required by final policy. |
| Audio/transcript disclosure | **Documented** | Confirm provider retention and user consent wording. |
| Document bytes policy | **Documented** | Verify Functions/logging and third-party share path in production. |
| Account deletion | **Missing / partial** | A production app with account/cloud data needs a clear sign-out, unlink, metadata deletion and account/data deletion path where applicable. |
| Security reporting | **Partial** | Public issue tracker exists; add a dedicated security contact/process and response expectations. |
| Threat model | **Missing** | Document attacks around malicious IME host apps, clipboard leakage, URI permissions, OAuth tokens, prompt injection and document voice commands. |

## 6. Android and device compatibility

Automated Flutter tests cannot prove that an IME behaves correctly across Android vendors. The following device work is still required:

- Android 13 or newer device.
- At least one older supported Android version.
- Pixel/stock Android and one vendor skin such as Samsung, Xiaomi or Oppo.
- WhatsApp, Telegram, browser text field and a standard form field.
- Gesture navigation and three-button navigation where available.
- Rotation, process restart, low-memory recovery and app switching.
- Dark mode, large font, display scaling and TalkBack.
- Keyboard switching from the system picker.
- Microphone permission allow, deny, deny permanently and revoke from Settings.
- Haptics on/off, silent mode and vendor-specific vibration behavior.
- `commitContent` editor and fallback share/picker editor.
- OAuth browser return, cancellation, back navigation and provider-disabled error.
- Network loss during transcription, translation, AI and document operations.
- Repeated language switching and panel open/close after closing the host keyboard.

## 7. QA and observability

Automated tests are strong for the current codebase, but production readiness also needs runtime evidence.

### Missing QA assets

- Formal test case matrix for all 22 languages.
- Golden screenshots or visual regression tests for onboarding, dashboard, panels and 30 future skins.
- Performance budget for IME startup, key response, panel open and voice start.
- Memory/battery checks for emoji, GIF, stickers, voice and AI panels.
- Network timeout and retry tests for every external provider.
- Localization review for all user-facing strings.
- Accessibility test report.
- Security test report for document permissions and OAuth.
- Upgrade test from previous APK version while preserving preferences and clipboard behavior.

### Missing operational tooling

- Crash reporting and ANR monitoring configured with a privacy-safe policy.
- Non-sensitive event logging for setup completion, provider failures and feature usage.
- Alerting for Function failures, OAuth errors, quota exhaustion and elevated crash rate.
- Support channel inside the app or a clearly visible support URL.
- Remote kill switch or feature flags for unsafe optional cloud features.
- Backend rate limits, abuse protection and provider quota monitoring.

## 8. Play Store release and compliance

| Gate | Status | Required action |
|---|---|---|
| Developer account verification | **External pending** | Wait for Google approval; no code change can complete this. |
| Signed APK/AAB build | **Implemented** | Latest production workflow successfully builds signed ARM64 APK and AAB. |
| Versioning | **Needs release action** | Increment version from `1.0.0+1` for each release and create an annotated tag. |
| Internal testing track | **Missing external action** | Upload the signed AAB to Play internal testing after developer access is approved. |
| Data Safety form | **Missing external action** | Complete it from the exact final provider/runtime behavior. |
| Content rating | **Missing external action** | Complete Play Console questionnaire. |
| Target audience/children declaration | **Missing external action** | Declare accurately; keyboard and optional AI features need careful answers. |
| App access instructions | **Missing external action** | Provide reviewer steps for enabling the IME, mic, Google sign-in and optional features. |
| Privacy policy URL | **Must verify** | Stable HTTPS URL must resolve and match the final build. |
| Store listing | **Missing/partial** | Final icon, screenshots, short description, full description, feature graphic, country/language copy and claims review. |
| Account deletion requirements | **Needs review** | If account creation/cloud account is offered, provide the required deletion path and web link if applicable. |
| Pre-launch report | **External** | Review crashes, ANRs, compatibility and privacy warnings from Play Console. |
| Staged rollout | **Missing external action** | Start internal testing, then closed/open testing, then staged production rollout. |

## 9. Product and content gaps

The application needs final product decisions before broad marketing claims are made:

- Official owner/developer name, qualification and designation.
- Final brand logo and visual identity.
- Final tagline and app positioning.
- Exact meaning of “30 skins”: keyboard themes, dashboard skins, or both.
- 30-theme design system, preview assets and licensing confirmation for every image/GIF.
- Ownership/IP statement that does not make unverifiable legal claims.
- Feature availability matrix: local, provider-dependent, Appwrite-dependent and Android-version-dependent.
- Supported language list and any languages with reduced voice/translation support.
- Pricing or quota policy, if AI/provider costs are passed to users later.
- Support, feedback and bug-report workflow.
- Terms of use and third-party provider links.

## 10. Recommended completion order

### Phase 1: Complete now without Play approval

1. Add final branding details and approved assets.
2. Define whether 30 skins means keyboard themes, dashboard skins or both.
3. Build the theme catalog, theme preview and persistence architecture.
4. Consolidate the companion app into a real dashboard instead of only a demo editor.
5. Add Settings sections for account, privacy, providers, documents, keyboard setup and support.
6. Add feature availability/error states that work when Google/Appwrite/providers are disabled.
7. Complete accessibility, localization and responsive layout review.
8. Add widget tests for the new welcome flow and dashboard navigation.

### Phase 2: Complete when Appwrite/Google configuration is available

1. Enable and verify Appwrite Google OAuth.
2. Deploy OAuth exchange/refresh, Drive metadata, unlink/revoke, password and lockout Functions.
3. Verify collection permissions with a non-owner test account.
4. Configure secure Gemini, Sarvam and Tavily backend proxies.
5. Test provider quotas, timeout, retry, cancellation and deletion behavior.

### Phase 3: Complete after Play developer access is approved

1. Increment version and create the release tag.
2. Upload the signed AAB to internal testing.
3. Complete Data Safety, content rating, target audience and app-access forms.
4. Run the full device matrix and fix every crash/ANR or policy warning.
5. Run closed/open testing, monitor results and perform staged rollout.

## Final conclusion

**The application is not empty or at an early prototype stage.** The keyboard core, major panels, multilingual architecture, local features, onboarding redesign and signed CI pipeline are already implemented. The remaining work is concentrated in four categories: **final branded product UI, 30-skin design system, secure backend/provider provisioning, and real-world release QA/compliance**.

The most important technical rule is that **Gemini, Sarvam, Tavily, Google OAuth secrets, refresh tokens and Appwrite server keys must remain server-side**. The most important functional rule is that **Google Drive Documents must not be marketed as production-complete until the required Appwrite Functions and non-owner permission tests pass**. The most important release rule is that **a successful GitHub build is necessary but not sufficient; real-device IME testing and Play Console testing are still required**.

## Repository references

- [`docs/production-setup.md`](production-setup.md)
- [`docs/play-store-release-checklist.md`](play-store-release-checklist.md)
- [`docs/releasing.md`](releasing.md)
- [`docs/privacy-policy.md`](privacy-policy.md)
- [`lib/engine/appwrite_document_repository.dart`](../lib/engine/appwrite_document_repository.dart)
- [`pubspec.yaml`](../pubspec.yaml)
