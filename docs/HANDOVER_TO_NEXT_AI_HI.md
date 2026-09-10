# Bhasha Keyboard — Complete Handover Document for the Next AI

**तारीख:** 9 September 2026
**Repository:** `https://github.com/sameerswain2026-code/bhasha-keyboard`
**Working branch:** `feat/secure-cloud-linked-documents`
**Current HEAD:** `94d9d13`
**Base branch:** `main` at `7708916`

## इस document का उद्देश्य

यह handover document किसी अगले AI/developer को दिया जा सकता है। इसे पढ़कर वह बिना पुराना chat context खोले repository की वर्तमान स्थिति समझ सकता है, सही branch checkout कर सकता है, implemented work को दोबारा नहीं बनाएगा, और remaining production work को क्रम से पूरा करेगा।

Attached audit document `Bhasha_Keyboard__End-to-End_Missing_Features_and_P(1).md` requirements और gaps बताता है। यह handover document उस audit को वर्तमान repository state से जोड़ता है। Attached audit पुराने commit `83eef33` पर आधारित है; वर्तमान feature branch में उसके बाद additional secure-document, OAuth, gateway, haptic, CI, onboarding और release work हुआ है।

## सबसे पहले: सही branch

सारा recent work इस branch में है:

```bash
git clone https://github.com/sameerswain2026-code/bhasha-keyboard.git
cd bhasha-keyboard
git fetch origin
git checkout feat/secure-cloud-linked-documents
git pull --ff-only origin feat/secure-cloud-linked-documents
```

**`main` branch को production implementation की source of truth न मानें।** पहले feature branch checkout करें। कोई नया branch बनाने या नया keyboard/microphone/assistant architecture बनाने से पहले existing code पढ़ें।

## Current branch history

| Commit | Purpose |
|---|---|
| `94d9d13` | Gateway analyzer fix और Hindi release status report |
| `e821019` | Remote main merge and responsive/dashboard fixes |
| `b8cc46c` | Hindi Appwrite deployment guide |
| `bbfaec5` | Appwrite Function folders self-contained बनाना |
| `6bddfcc` | Cloud configuration syntax fix |
| `affcd8c` | Secure gateway scaffolding, provider routing, release docs |
| `2cfda38` | Production audit, fail-closed signing, safer release workflows |
| `6e38e9b` | OAuth, translation target, document folder workflow |
| `658564d` | Mobile OAuth and target-script fixes |
| `b869d86` | Test-safe cloud client initialization |
| `01262c7` | Provider services के secure gateway routing की शुरुआत |

## वर्तमान में क्या बनाया जा चुका है

### Keyboard और Android IME

Existing Flutter keyboard architecture को preserve करते हुए native Android IME bridge बढ़ाया गया है। इसमें key haptics, IME surface resizing, media `commitContent`, document authentication activity, content picker, URI permission handling, voice lifecycle handling और target app fallback behavior शामिल हैं। मुख्य native files `android/app/src/main/kotlin/com/bhashakeyboard/ime/` में हैं।

मुख्य files:

- `BhashaImeService.kt`
- `DocumentAuthActivity.kt`
- `MainActivity.kt`
- `MicStreamHandler.kt`
- `AndroidManifest.xml`

### Language और typing modes

`lib/data/languages.dart`, `lib/engine/layouts.dart`, `lib/engine/transliterator.dart` और `lib/core/keyboard_controller.dart` language registry, Native/Roman mode, script detection, transliteration और translation target synchronization संभालते हैं। Source-level implementation उपलब्ध है। Physical-device validation अभी अनिवार्य है, विशेषकर Hindi, Bengali, Gujarati, Kannada, Malayalam, Marathi, Odia, Punjabi, Tamil, Telugu, Urdu, Sindhi और Kashmiri जैसी script/RTL स्थितियों में।

### Voice, translation और AI writing

Existing voice engine और Sarvam provider को replace नहीं किया गया है। Existing flow में transcription, auto mode, translation, AI assistant, Gemini reasoning, Tavily search, grammar, rewrite, tone और suggested replies के paths हैं।

मुख्य files:

- `lib/engine/voice_engine.dart`
- `lib/engine/sarvam_speech_provider.dart`
- `lib/engine/translation_engine.dart`
- `lib/engine/gemini_service.dart`
- `lib/engine/tavily_search_service.dart`
- `lib/engine/ai_assistant_engine.dart`
- `lib/engine/writing_assistant.dart`

### Secure document management

`lib/engine/document_manager.dart` local linked-document state, labels, groups/folders, lockout, document intent parsing और protected upload/share flow संभालता है। Document bytes Bhasha backend में store नहीं किए जाते। Android system picker से मिले provider URI और minimal metadata store होता है।

`lib/engine/appwrite_document_repository.dart` Appwrite TablesDB में user-scoped document metadata row maintain करता है। `driveFileId`, label, display name, MIME type, URI/reference, group, lock state और timestamps जैसे metadata रखे जाते हैं।

### Cloud gateway

Appwrite Function source:

- `functions/drive-gateway/index.js`
- `functions/drive-gateway/package.json`
- `functions/ai-gateway/index.js`
- `functions/ai-gateway/package.json`

Flutter client:

- `lib/engine/appwrite_gateway_client.dart`
- `lib/config/cloud_config.dart`

User-confirmed deployed Function IDs:

```text
drive-gateway = 6aa12c14001ddeb260df
ai-gateway    = 6aa13043002cddfbdc72
```

इन IDs को public identifiers माना जाता है। API keys, Google client secret, refresh tokens और encryption secret repository या APK में नहीं रखने हैं।

Gemini और Tavily routing Function ID configured होने पर Appwrite AI Function की ओर जाती है। Current Sarvam live speech implementation long-lived WebSocket use करती है; HTTP AI Function अपने-आप इसका secure WebSocket relay नहीं बनती। Public Sarvam streaming के लिए authenticated WebSocket relay बनाना होगा या public feature को disable रखना होगा।

### Onboarding और UI

`lib/ui/welcome_flow_screen.dart`, `lib/ui/setup_flow_screen.dart`, `lib/ui/panels/` और `lib/ui/kb_theme.dart` onboarding, setup, keyboard panels, documents, settings, themes, translation, media और editing flows provide करते हैं। Current UI is a working product shell, not a finished 30-skin commercial design catalog.

### CI/CD और signing

मुख्य workflows:

- `.github/workflows/ci.yml`
- `.github/workflows/debug-apk.yml`
- `.github/workflows/production-build.yml`
- `.github/workflows/release.yml`

Production workflow signed ARM64 APK और AAB बनाता है। Release Gradle configuration missing signing file पर fail closed करता है। Provider secrets public build में `--dart-define` से inject नहीं किए जाने चाहिए।

## External resources user ने configure किए हैं

User confirmation के अनुसार:

- Appwrite project ID: `6a7fc74a001f50afe9e5`
- Appwrite endpoint: `https://nyc.cloud.appwrite.io/v1`
- Database: `bhasha-db`
- Existing metadata table: `document-links`
- Token table: `google-drive-tokens`
- Drive Function deployed
- AI Function deployed
- Function environment variables saved
- GitHub Function ID variables saved

इन external claims को current sandbox token से independently read नहीं किया जा सका क्योंकि GitHub Actions variable listing पर HTTP 403 मिला। अगला AI deployment/build run से definitive verification करे।

## Secret policy

कभी भी इन values को chat, public issue, repository, screenshot या APK में न डालें:

```text
APPWRITE_API_KEY
GOOGLE_CLIENT_SECRET
GOOGLE_TOKEN_ENCRYPTION_SECRET
GEMINI_API_KEYS
SARVAM_API_KEYS
TAVILY_API_KEYS
```

ये केवल Appwrite Function environment में होनी चाहिए। अगर secret गलती से chat/screenshot में चला जाए, तो उसे revoke करके नया secret बनाइए।

## अभी क्या बाकी है

### Priority P0 — release रोकने वाले काम

1. Latest branch commit से production CI फिर चलाएँ और `flutter analyze`, tests, signed APK और signed AAB pass कराएँ।
2. Appwrite Functions का authenticated execution test करें।
3. Google OAuth callback, provider enablement, Android package और release/debug SHA-256 verify करें।
4. Non-owner Google/Appwrite account से verify करें कि user A user B की document metadata नहीं पढ़ सकता।
5. Drive token expiry, revoke, deleted file, quota और network failure map करें।
6. Physical Android devices पर IME haptics, media insertion, OAuth, document auth और voice test करें।
7. Play Console Internal testing में successful AAB upload करें।

### Priority P1 — production-quality work

1. Real dashboard बनाना: account, keyboard status, language, documents, provider status, privacy and support.
2. 30 keyboard skins का scope तय करना और catalog/preview/persistence implement करना।
3. TalkBack, large font, contrast, RTL, reduced motion और touch target audit.
4. Crash/ANR reporting और privacy-safe operational monitoring.
5. Account deletion, data deletion, sign-out and cloud revoke UX.
6. Provider timeout, retry, cancellation, quota and error states.
7. Privacy policy, Data Safety, content rating, target audience, app access and support URL finalization.

### Priority P2 — later improvements

1. Secure Sarvam WebSocket relay.
2. Remote feature flags/kill switch.
3. Non-sensitive analytics.
4. Expanded suggestion quality and per-language evaluation.
5. Advanced theme assets, illustrations and branded marketing polish.
6. AdMob, only if business decision requires it. Ads are not required for Play release.

## Exact next-AI execution plan

### Step A — verify source and CI

```bash
git checkout feat/secure-cloud-linked-documents
git pull --ff-only origin feat/secure-cloud-linked-documents
git status --short --branch
gh workflow run production-build.yml --repo sameerswain2026-code/bhasha-keyboard --ref feat/secure-cloud-linked-documents
gh run list --repo sameerswain2026-code/bhasha-keyboard --workflow production-build.yml --branch feat/secure-cloud-linked-documents --limit 1
```

Do not call the run successful until all workflow steps are green and a signed AAB artifact exists.

### Step B — verify Appwrite Function settings

Use the Hindi setup guide: `docs/appwrite-deployment-guide-hi.md`. Check Function runtime, branch, root directory, entrypoint, `npm install`, authenticated execute access and environment variables. Do not enable anonymous guests.

### Step C — verify OAuth and Drive

Use `docs/production-setup.md` and `docs/release-gates.md`. Test with a non-owner account. Confirm only metadata/reference is stored and no document bytes enter Appwrite Storage or logs.

### Step D — physical QA

Fill `docs/device-qa-template.md` on Android 13+ and an older supported device. Test WhatsApp, Telegram, Gmail, browser, a `commitContent` editor and an editor that requires picker fallback.

### Step E — Play release

Use `docs/play-store-release-checklist.md`, `docs/release-gates.md` and `docs/privacy-policy.html`. Upload only the latest successful signed AAB to Internal testing. Review Play pre-launch report before any public rollout.

## Ready-to-use prompt for the next AI

Copy the following prompt into the next AI session:

> You are continuing the Bhasha Keyboard project. Clone repository `https://github.com/sameerswain2026-code/bhasha-keyboard` and checkout `feat/secure-cloud-linked-documents`, not `main`. Read `docs/HANDOVER_TO_NEXT_AI_HI.md`, `docs/release-status-hi-2026-09-09.md`, `docs/release-gates.md`, `docs/production-setup.md`, and the attached end-to-end audit before editing. Do not create a second keyboard, microphone, assistant, or cloud architecture. Preserve existing Flutter controller, voice, Sarvam, Gemini, Tavily, Appwrite, Android IME, document manager, and CI structure. First verify branch, clean status, latest CI, Appwrite Function IDs, and the two Function source directories. Then fix only confirmed errors. The user-confirmed Function IDs are `6aa12c14001ddeb260df` for `drive-gateway` and `6aa13043002cddfbdc72` for `ai-gateway`; never ask for or print any secret. The immediate goal is to get a green signed production AAB, verify Google OAuth/Drive with a non-owner account, complete physical-device QA, and prepare Play Internal testing. Do not claim public production readiness until CI, Function tests, OAuth tests, device QA, privacy/Data Safety and Play internal testing are evidenced. After P0 gates, continue with the attached audit's dashboard, 30-skin, accessibility, RTL, monitoring and product-polish work.

## Source-of-truth documents

- `docs/HANDOVER_TO_NEXT_AI_HI.md` — this document
- `docs/release-status-hi-2026-09-09.md` — current release status
- `docs/appwrite-deployment-guide-hi.md` — Appwrite console steps
- `docs/production-setup.md` — security boundary and server configuration
- `docs/release-gates.md` — external release gates
- `docs/device-qa-template.md` — physical QA evidence matrix
- `docs/privacy-policy.html` — privacy policy draft
- `docs/play-store-release-checklist.md` — Play checklist
- `docs/production-audit-2026-09-08.md` — repository audit
- `docs/end-to-end-gap-analysis.md` — feature gap analysis

## Final handover rule

The repository is the implementation source of truth, while this document is the continuation map. A successful GitHub build is necessary but not sufficient. The next AI must separate **source implemented**, **externally configured**, **device verified**, and **Play approved** states and must not merge those states into one unsupported “production-ready” claim.

**Prepared by:** Manus AI
