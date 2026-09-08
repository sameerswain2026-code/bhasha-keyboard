# Bhasha Aura — Product Source of Truth

> **Purpose:** This document is the permanent handoff contract for human developers and AI agents working on Bhasha Aura. Read it before changing product behavior, onboarding, keyboard architecture, cloud documents, AI tools, voice, translation, or release configuration.

**Product name:** Bhasha Aura  
**Tagline:** *Every voice, beautifully understood.*  
**Repository:** `sameerswain2026-code/bhasha-keyboard`  
**Document status:** Living product specification and implementation ledger  
**Last verified code commit:** `707a6f0`  
**Primary platform:** Android Flutter application with an Android Input Method Editor (IME)  
**Brand mark:** Gradient prism-style `भ` mark using indigo, violet, aqua and magenta

## 1. Product definition

Bhasha Aura is a multilingual Android keyboard and language workspace for Indian users. It combines a system-wide keyboard, native and Roman language modes, voice transcription, translation, AI writing assistance, expressive media, and private document retrieval. The keyboard must remain useful for basic typing without network access. Network-backed features must be explicit, recoverable, privacy-aware, and protected by a secure backend.

The intended experience is not a generic text-entry utility. It is a premium language companion that helps users speak, type, translate, rewrite, retrieve documents, and share content from the same interaction surface.

## 2. Product promise

A successful release must make the following promise true:

> A user can choose one of 22 supported Indian languages, type in Native or Roman mode, speak into the microphone, translate between languages, ask an AI assistant for writing or real-time information, retrieve an authorized document, and share the result into a supported app without losing the original text or losing control of private data.

This promise has two release tiers:

| Tier | Meaning | Required behavior |
|---|---|---|
| Local core | Must work without cloud setup | Keyboard, language layouts, Native/Roman modes, suggestions, emoji, local settings and local UI |
| Connected intelligence | Requires configured backend and providers | Voice, translation, Gemini tools, web assistant, Google Drive, secure document retrieval and cloud sharing |

No feature may be advertised as fully production-ready when its required provider, backend, permission, error, privacy, and real-device tests are missing.

## 3. Current implementation status

The following status is based on repository inspection and the green CI/build validation for commit `707a6f0`. “Implemented” means code and UI paths exist. It does not automatically mean that every external provider is configured or every real-device scenario has passed.

| Area | Current status | Notes |
|---|---|---|
| Flutter companion application | Implemented | Premium Bhasha Aura branding, onboarding and dashboard are present |
| Android IME entrypoint | Implemented | Keyboard entry flow and Android input connection exist |
| Premium onboarding | Implemented | Animated ambient background, story pages, feature cards and setup transition exist |
| Companion dashboard/demo editor | Implemented | Branded header, metrics and private canvas exist |
| 22-language registry/layout architecture | Implemented | Verify every language with real-device language-specific QA |
| Native language mode | Implemented for supported script families | Complete inventories are now generated for Devanagari, Bengali/Assamese, Gujarati, Gurmukhi, Odia, Tamil, Telugu, Kannada, Malayalam, Arabic-family, Ol Chiki and Meitei; device QA is still required |
| Roman language mode | Implemented in architecture | Keyboard remains Latin while output follows the selected language’s Roman/transliteration rules |
| Auto mode | Implemented in architecture | User can speak/type without manually selecting the active language; detection and fallback need benchmark tests |
| Suggestions/transliteration | Implemented | Quality, personalization and long-sentence behavior need test coverage |
| Voice transcription | UI/engine path present | Provider/backend secrets and 22-language accuracy validation are still required |
| Real-time translation | UI/engine path present | Secure provider proxy and failure-state testing are required |
| Manual translation | UI path present | Must support source/target, Native/Roman output, review, copy and insertion |
| AI writing assistant | UI/engine path present | Gemini proxy, quotas, prompt/privacy controls and output review are required |
| Named voice assistant | Product requirement, partial implementation | Custom wake/name invocation and intent routing need implementation and safety design |
| Real-time web assistant | Product requirement, partial implementation | Secure search provider proxy, result citations, timeouts and prompt/tool routing are required |
| Emoji | Implemented | Send, share, download and edit behavior must be verified per target app |
| GIF | UI/path present | Inline insertion and fallback sharing require app-by-app validation |
| Stickers | UI/path present | Inline insertion and fallback sharing require app-by-app validation |
| Text editing tools | Present in keyboard/tool architecture | Must preserve selection and original text across editors |
| Local documents | Picker/UI path present | Local file lifecycle and sharing need real-device tests |
| Google Drive dashboard | Product requirement, not complete | OAuth, Drive metadata, permissions, Functions and security tests are required |
| Add-to-AI document index | Product requirement, not complete | Requires authorized metadata index and assistant retrieval routing |
| Folder/file creation and upload | Product requirement, not complete | Requires secure cloud storage workflow and conflict handling |
| Folder/file passwords | Product requirement, not complete | Must use server-side verification/lockout and encrypted references; never log secrets |
| Password-protected document retrieval | Product requirement, not complete | Must verify before any file bytes are made available to a target app |
| Folder-to-ZIP sharing | Product requirement, not complete | Must create a controlled temporary ZIP, show size, and support cancellation/expiry |
| Secure API key handling | Not complete until backend is deployed | Provider keys must not be shipped in the APK |
| Production privacy/data-safety declaration | Required release gate | Must match actual network, audio, transcript, clipboard and document behavior |
| CI and Android builds | Green for `707a6f0` | CI, Debug APK, Production Android Build and Pages deployment passed |

## 4. Supported language behavior contract

Bhasha Aura supports 22 Indian languages through a shared language registry. The exact registry is the source code authority; any UI copy, documentation or test plan must be generated from that registry rather than maintaining a second hard-coded list.

### 4.1 Native mode

When the user chooses **Native**, the keyboard layout must change to the selected language. It must expose the complete practical character inventory required by that script, including the language’s vowels, consonants, signs, marks, punctuation and secondary characters. It must not show only 26 English positions with a few labels changed.

Examples:

- Hindi: Devanagari characters such as `अ`, `आ`, `क`, `ख`, `ग` and required matras/signs.
- Telugu: Telugu characters and signs in a Telugu-oriented layout.
- Odia: Odia characters and signs in an Odia-oriented layout.
- Urdu, Kashmiri and Sindhi: RTL-aware layout, cursor, punctuation and mixed-script behavior.

Native mode acceptance criteria:

1. The selected language name and active layout agree.
2. Every required character group is reachable without an unusable overflow path.
3. Backspace, cursor movement, composition and combining marks behave correctly.
4. Output remains correct in WhatsApp, Telegram, Gmail and a browser text field.
5. Switching away and back restores the correct language without losing text.

### 4.2 Roman mode

When the user chooses **Roman**, the keyboard remains Latin/English in appearance. The output follows the selected language’s Roman or transliteration behavior.

Examples:

```text
Input:  namaste aap kaise hain
Hindi output:  नमस्ते आप कैसे हैं
```

Roman mode acceptance criteria:

1. The visual keyboard remains Latin.
2. The selected language remains visible in the toolbar.
3. Transliteration suggestions are selectable and reversible.
4. English words, names, URLs and numbers are not corrupted.
5. Space, punctuation and backspace work naturally inside mixed text.

### 4.3 Auto mode

When the user chooses **Auto**, the system may accept speech or typed content from any supported language. Detection must return a language and confidence state. Low-confidence results must be reviewable rather than silently replacing text.

Auto mode acceptance criteria:

1. The active language can change without a confusing layout jump.
2. The output mode remains explicit: Native or Roman.
3. The user can override a wrong detection result.
4. Network/provider failure falls back to the last known language or local typing.
5. Mixed Hindi-English and other common code-switching cases are tested.

## 5. Voice, transcription and translation contract

### 5.1 Transcription

The user opens the microphone from the keyboard toolbar, selects a speech language and selects an output mode. The spoken result appears as editable text before insertion or sending.

```text
Mic → Speech language → Native/Roman output → Record → Stop → Review → Insert/Send
```

For Hindi Native mode, speech must produce Devanagari. For Hindi Roman mode, the keyboard remains Latin and the result is Roman Hindi. The same rule applies to every supported language.

Required states:

| State | Required UI behavior |
|---|---|
| Idle | Clear mic action and provider status |
| Permission needed | Explain why, allow grant or continue without voice |
| Recording | Obvious recording indicator, timer, stop and cancel |
| Processing | Progress state, no duplicate submission |
| Result | Editable transcript, language/mode labels, insert/send |
| Provider failure | Human-readable error, retry, preserve draft |
| Network unavailable | Local fallback or explicit offline state |
| Permission denied | Keyboard remains usable; mic is not repeatedly forced |

### 5.2 Translation

Translation has two paths:

1. **Manual translation:** The user opens the translation panel, selects source and target languages, enters or selects text, chooses Native/Roman output and reviews the result.
2. **Real-time/voice translation:** The user speaks, the system transcribes, translates and returns the target language in the selected output mode.

```text
Source language + source text
  → Translation provider
  → Target language + Native/Roman output
  → Review
  → Copy, Insert or Share
```

The original text must remain recoverable. A failed translation must never clear the source.

## 6. AI assistant contract

The assistant has two distinct responsibilities and must not confuse them.

### 6.1 Gemini writing assistant

Gemini is used for language transformation and writing tasks such as grammar correction, formalization, professional/casual tone, official style, email drafting, summaries and essay/application drafting.

```text
Select text or open assistant
  → Choose task/style
  → Send minimum necessary content to secure backend
  → Show result beside original
  → Accept, edit, copy or insert
```

The assistant must not silently replace user content. Every generated result must be reviewable. The UI should identify AI-generated content and preserve the original.

### 6.2 Named real-time assistant

The user may choose a custom assistant name. When the user invokes that name by voice or assistant control, the system routes the request to a safe intent handler.

Supported intent families:

| Intent | Example | Expected result |
|---|---|---|
| Web lookup | “Aura, find today’s travel information” | Search result summary with source links |
| Music/song lookup | “Aura, get the song details” | Search result or permitted link, not an unauthorized download |
| Summary | “Aura, summarize this” | Reviewable summary |
| Writing | “Aura, write an application” | Draft in the current language/style |
| Grammar | “Aura, correct this” | Before/after result |
| Document retrieval | “Aura, bring my Aadhaar card” | Password check, authorized file retrieval, share preview |
| Document upload | “Aura, upload the education documents” | Select authorized folder, create controlled ZIP, password check, share preview |

Tool calls must be explicit in the backend. Search, AI, file access and sharing must not be combined into an unreviewed opaque action.

## 7. Google Drive and document workspace contract

The companion dashboard is the primary document-management surface. The keyboard is an invocation and sharing surface; it must not become a full cloud file manager.

### 7.1 Sign-in and authorization

The intended flow is:

```text
Onboarding
  → Google sign-in
  → Clearly explain Drive access scope
  → OAuth consent
  → Dashboard
```

The product must request the smallest scope that supports the feature. If broad Drive access is genuinely required, the UI must state what the app can read, create, modify and share. User permission does not remove the need to comply with Google OAuth policies, Android permissions, Play policies or data-safety requirements.

### 7.2 Animated dashboard

After sign-in, the dashboard shows authorized Drive folders and documents as animated cards. Cards must display name, type, modified time, location and access state. The dashboard must support search, sorting, folder navigation, upload, create folder and secure actions.

Required dashboard actions:

| Action | Expected behavior |
|---|---|
| Browse | Show only authorized metadata and recover from API failure |
| Search | Search indexed authorized metadata, never unrelated Drive data |
| Create folder | Create folder with name validation and optional password policy |
| Upload file | Upload with progress, cancellation and retry |
| Add to AI | Add only authorized metadata/reference to assistant index |
| Create document | Create supported file/document with conflict handling |
| Protect folder | Store protection policy/reference, never plaintext password |
| Protect file | Store protection policy/reference, never plaintext password |
| Unlink Drive | Revoke/delete references and confirm resulting state |

### 7.3 Add to AI

“Add to AI” means the assistant is allowed to retrieve the selected file or folder through an authorized backend reference. It does not mean that all document bytes are permanently copied into Bhasha storage.

The index must contain only what is necessary: user ID, provider file ID, name, type, authorized scope, folder relationship, protection state and synchronization metadata. Retrieval must re-check authorization and password protection at request time.

### 7.4 Password-protected retrieval from the keyboard

Example:

```text
User is in WhatsApp
  → Opens keyboard assistant
  → Says: “Aura, bring my Aadhaar card”
  → Intent resolver finds an authorized matching file
  → Assistant explains which file will be shared
  → User enters password in secure popup or confirms through an allowed voice flow
  → Backend verifies password and lockout state
  → File is downloaded/streamed for a short-lived share operation
  → User reviews destination/content
  → App inserts or shares the file
  → Temporary access expires and no secret is logged
```

The default should be a secure on-screen password popup. Voice password entry must not be enabled unless the threat model, device privacy and transcription behavior are explicitly approved and implemented safely.

### 7.5 Folder-to-ZIP upload/share

A folder cannot be blindly inserted into every chat. The intended behavior is:

```text
Assistant resolves folder
  → Re-check authorization and password
  → Calculate file count and size
  → Create temporary ZIP
  → Show name, size and destination preview
  → User confirms share
  → Share ZIP through Android-compatible path
  → Expire/delete temporary archive according to policy
```

The UI must show progress and allow cancellation. ZIP creation must enforce size, file-count, timeout and malicious-file handling limits.

## 8. Screen and navigation contract

### 8.1 Installation to first use

```text
Install
  → Premium Welcome / Aura mark
  → Product promise
  → Feature story with examples
  → Google sign-in or guest exploration
  → Keyboard setup
  → Android Enable keyboard
  → Android Select active keyboard
  → Optional microphone permission
  → Guided demo sentence
  → Companion dashboard or keyboard-ready state
```

### 8.2 Companion dashboard

```text
Dashboard
  ├── Language/workspace status
  ├── Try the keyboard demo
  ├── Voice and translation entry points
  ├── AI assistant setup and custom name
  ├── Documents and Drive workspace
  ├── Theme and appearance
  ├── Privacy/network controls
  └── Keyboard setup status
```

### 8.3 Keyboard toolbar

```text
Keyboard toolbar
  ├── Language selector
  ├── Native / Roman / Auto mode
  ├── Microphone / Transcribe
  ├── Suggestions
  ├── Translate
  ├── AI assistant
  ├── Emoji
  ├── GIF
  ├── Sticker
  ├── Documents / share
  └── Settings
```

Every panel requires loading, empty, success, retry and failure states. A panel must never trap the user inside the keyboard or erase the current draft.

## 9. Real-world acceptance personas

| Persona | Main journey | Proof of readiness |
|---|---|---|
| Hindi-speaking parent | Roman Hindi to Native Hindi in WhatsApp | Setup, transliteration, suggestions, send and offline behavior |
| Hinglish student | Mixed language, emoji, GIF and sticker | Code-switching, expressive media and app fallback |
| Support executive | Selected text translation | Source/target, review, privacy disclosure and insertion |
| Delivery partner | Marathi/Hindi voice message | Permission, noisy speech, transcript review and send |
| Urdu/Kashmiri/Sindhi writer | RTL Native typing | Layout, cursor, punctuation, selection and mixed LTR text |
| Content creator | Gemini grammar/tone/email drafting | Original/result comparison, secure proxy and failure recovery |
| Small-business owner | Drive document retrieval and ZIP share | OAuth, index, password, authorization, preview, share and expiry |

These personas are product acceptance journeys, not marketing claims. Each must become a repeatable test case before the corresponding feature is called production-ready.

## 10. Production architecture requirements

```text
Flutter companion app + Android IME
  ├── Local keyboard engine and language registry
  ├── Local settings, theme, clipboard and draft safety
  ├── Provider clients that call backend endpoints only
  └── UI panels with explicit state machines

Secure backend
  ├── Authentication/session validation
  ├── Gemini proxy
  ├── Speech/transcription proxy
  ├── Translation proxy
  ├── Search/web-assistant proxy
  ├── Google OAuth exchange and refresh
  ├── Drive metadata and file operation functions
  ├── Document authorization/password verification
  ├── Rate limits, quotas and abuse controls
  ├── Audit-safe event metadata
  └── Data deletion/unlink functions

External providers
  ├── Google OAuth/Drive
  ├── Gemini
  ├── Speech/transcription provider
  ├── Translation provider
  └── Search provider
```

API keys and client secrets must remain server-side. The Flutter client must receive short-lived, scoped results or signed references. Backend logs must exclude passwords, raw audio, full document bytes and unnecessary typed text.

## 11. Required backend functions

The production backend must provide, at minimum:

| Function | Requirement |
|---|---|
| `auth/session` | Validate authenticated user and device/session state |
| `ai/writing` | Route grammar, rewrite, tone, email and summary requests |
| `assistant/intent` | Parse named assistant intent into an allowlisted tool call |
| `assistant/search` | Execute web lookup with timeout, citations and safe limits |
| `speech/transcribe` | Transcribe supported languages and return editable text |
| `translate/text` | Translate with source/target/output-mode metadata |
| `drive/oauth/callback` | Exchange OAuth code and store encrypted references |
| `drive/refresh` | Refresh provider token without exposing it to the client |
| `drive/list` | Return authorized metadata only |
| `drive/create-folder` | Create folder with validation and conflict handling |
| `drive/upload` | Upload with progress, retry and size limits |
| `drive/add-to-ai` | Add authorized file reference to AI index |
| `drive/retrieve` | Re-check authorization and protection at request time |
| `document/verify-secret` | Verify protection with attempt limits and lockout |
| `document/create-zip` | Create controlled temporary archive with limits |
| `document/share-token` | Issue short-lived share authorization |
| `drive/unlink` | Revoke access and delete stored references |
| `account/delete-data` | Delete user-owned app metadata and provider links |

## 12. Security and privacy rules

User permission is required, but permission alone is not sufficient security. The implementation must also enforce least privilege, explicit scopes, server-side authorization, secure secret handling, rate limits, lockouts and deletion.

The application must:

1. Keep provider API keys and OAuth client secrets out of the APK.
2. Explain when selected text, audio, transcripts or document metadata leave the device.
3. Preserve local typing when optional network services fail.
4. Never log passwords, raw audio, document bytes or complete sensitive document names unnecessarily.
5. Require authorization again for sensitive document retrieval when policy demands it.
6. Use short-lived download/share tokens.
7. Protect against repeated password attempts with server-side lockout and expiry.
8. Provide Drive unlink, account deletion and data deletion controls.
9. Avoid claiming end-to-end encryption unless it is actually implemented and verified.
10. Maintain a Play Console Data Safety declaration that matches actual behavior.

## 13. UI/UX quality contract

The product must feel premium without hiding system behavior. Visual quality is defined by hierarchy, clarity, responsiveness and recovery, not decoration alone.

Required qualities:

- Branded Aura mark and consistent typography.
- Meaningful animation for onboarding, card entry, state changes and transitions.
- No animation that blocks typing, accessibility or fast dismissal.
- Clear primary action on every setup and permission screen.
- Glass/transparent components only where text contrast remains accessible.
- Loading, empty, error and offline states for every network panel.
- Haptic feedback only when enabled and supported.
- Dark mode, large text, RTL and TalkBack compatibility.
- No misleading feature card that opens an unconfigured or dead action.
- Every feature card must state whether it is local, connected, beta or unavailable.

## 14. Definition of done for a feature

A feature is **done** only when all of the following are true:

1. The user journey is represented by a reachable screen or keyboard action.
2. The feature has success, loading, empty, cancel, timeout, offline and provider-failure states.
3. The implementation has no duplicate dead path or unreachable placeholder component.
4. Secrets are handled through the approved backend boundary.
5. The feature has unit/widget/integration coverage appropriate to its risk.
6. It works on at least one Android 13+ device and one older supported device.
7. It is tested in WhatsApp, Telegram, Gmail and a browser field when it affects IME insertion.
8. Privacy copy and Play data-safety implications are documented.
9. Analytics/crash signals do not capture sensitive content.
10. The product documentation and status table are updated in the same change.

## 15. Prioritized implementation backlog

### P0 — Restore core product capability

1. Verify every one of the 22 language registries and complete Native character inventories.
2. Verify Roman transliteration for every language and preserve English names/URLs/numbers.
3. Add automated tests for Native, Roman and Auto mode transitions.
4. Run real-device IME tests across WhatsApp, Telegram, Gmail and browser fields.
5. Provision secure speech and translation backend proxies.
6. Implement transcription output mode behavior for Native and Roman.
7. Implement manual and real-time translation review/insertion.
8. Provision Gemini proxy for grammar, rewrite, tone, email and summary tasks.
9. Add original-versus-AI-result review UI.
10. Make emoji, GIF and sticker sending/sharing/downloading/editing reliable with fallback behavior.

### P1 — Build the connected assistant and workspace

1. Implement custom assistant name and allowlisted intent routing.
2. Implement web search assistant with source links and safe timeouts.
3. Add Google OAuth and Drive metadata integration.
4. Build animated Drive dashboard cards with browse/search/sort.
5. Implement Add to AI as an authorized metadata/reference index.
6. Implement file upload and folder creation with progress and retries.
7. Implement file/folder protection policy with secure verification and lockout.
8. Implement password-protected keyboard retrieval with review before sharing.
9. Implement folder-to-ZIP creation with limits, cancellation and expiry.
10. Add Drive unlink and full app-data deletion.

### P2 — Premium refinement and scale

1. Improve language-specific onboarding examples and feature films/illustrations.
2. Add local personal dictionary and user-approved phrase learning.
3. Add voice-first mode and better noisy-environment handling.
4. Add custom writing style profiles.
5. Add saved templates for business, education and family users.
6. Add per-app language preferences.
7. Add controlled feature flags for providers and beta features.
8. Add crash/ANR monitoring and privacy-safe diagnostics.
9. Add onboarding analytics that measure completion without recording typed content.
10. Add release automation, Play internal track tests and staged rollout monitoring.

## 16. Required test matrix

| Category | Minimum scenarios |
|---|---|
| Installation | Fresh install, upgrade, uninstall/reinstall, first-run skip |
| Setup | Enable IME, select IME, microphone allow/deny/revoke, sign-in cancel |
| Typing | Hindi, English, Hinglish, Marathi, Telugu, Odia, Urdu, Kashmiri, Sindhi |
| Modes | Native, Roman, Auto, repeated switching, process restart |
| Editors | WhatsApp, Telegram, Gmail, browser, unsupported editor fallback |
| Voice | Quiet room, noisy road, mixed language, timeout, offline, cancel |
| Translation | Manual, voice, Native target, Roman target, provider failure |
| AI | Grammar, formal, professional, casual, official, email, summary, long text |
| Media | Emoji send/share/download/edit, GIF insertion/fallback, sticker insertion/fallback |
| Drive | OAuth, list, search, upload, folder, Add to AI, unlink, refresh failure |
| Security | Wrong password, lockout, expiry, unauthorized file, revoked account |
| UI | Dark mode, large text, RTL, TalkBack, animation reduced motion, rotation |
| Recovery | Low memory, network loss, app killed during upload, provider timeout |

## 17. AI agent handoff protocol

Any AI agent modifying this repository must follow this sequence:

1. Read this document completely.
2. Read the relevant existing source and tests before editing.
3. Identify whether the requested change is Local Core or Connected Intelligence.
4. Do not invent provider configuration or claim a backend is deployed without verification.
5. Reuse existing components and services before creating a duplicate.
6. Remove dead code only after proving it is unreferenced and not required by Android/Flutter reflection or platform entrypoints.
7. Preserve the Android IME behavior while changing companion-app UI.
8. Add or update tests for the changed behavior.
9. Run `git diff --check`, formatter, analyzer, tests and the relevant Android build.
10. Update the implementation status and backlog in this document.
11. Report exact commits, workflow results, remaining external setup and known limitations.

## 18. Current release decision

The premium companion UI and Android build pipeline are green at commit `707a6f0`. The local keyboard is a release candidate. The complete connected product described in this document is **not yet proven end-to-end** until the backend, provider credentials, Drive authorization, document security flows and real-device matrix are completed.

The recommended release sequence is:

1. Ship an internal test build with Local Core enabled.
2. Restore and validate voice, translation and Gemini through secure backend proxies.
3. Validate the named assistant and web tools.
4. Add Google Drive and protected document workflows behind feature flags.
5. Run the full persona matrix.
6. Move from Play internal testing to staged production rollout only after privacy and security gates pass.

## References

[1]: ../docs/production-flow-and-setup-request.md "Bhasha Aura production flow and setup request"
[2]: ../docs/end-to-end-gap-analysis.md "Bhasha Keyboard end-to-end gap analysis"
[3]: ../docs/production-setup.md "Bhasha Keyboard production setup requirements"
[4]: ../docs/play-store-release-checklist.md "Bhasha Keyboard Play Store release checklist"
[5]: ../docs/production-audit.md "Bhasha Keyboard production audit"
