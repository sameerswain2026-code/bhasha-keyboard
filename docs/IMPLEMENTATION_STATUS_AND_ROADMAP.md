# Bhasha Aura — Implementation Status, Remaining Work और Production Roadmap

> **उद्देश्य:** यह document Bhasha Aura repository का single handoff document है। कोई developer या AI agent इसे पढ़कर समझ सकता है कि application में क्या बन चुका है, क्या आंशिक है, क्या बाकी है, किन external services की आवश्यकता है, और production release तक कौन-से steps करने हैं।

**Repository:** `sameerswain2026-code/bhasha-keyboard`  
**Product:** Bhasha Aura  
**Tagline:** *Every voice, beautifully understood.*  
**Platform:** Flutter Android application + Android Input Method Editor (IME)  
**Current version:** `1.0.1+2`  
**Latest verified commit:** `a8dea72`  
**Document owner:** Manus AI  
**Document status:** Living implementation and release handoff record  

---

## 1. Executive status

Bhasha Aura का **local keyboard core और automated release pipeline working state में हैं**। Flutter 3.35.2 के साथ `flutter analyze` में कोई issue नहीं है और पूरी automated test suite के **177 tests pass** हुए हैं। Final GitHub workflows में CI, Debug APK, Production Android Build और Pages deployment सफल हुए हैं। ARM64 production APK और Android App Bundle भी generate और checksum-verify किए गए हैं।

यह स्थिति application को **local keyboard release candidate** बनाती है। इसे अभी full public cloud-connected production product नहीं कहा जा सकता, क्योंकि Google Drive, Appwrite Functions, provider proxy, real Android devices और Play Console release gates अलग से पूरे करने हैं।

### Status legend

| Status | अर्थ |
|---|---|
| **Complete** | Code path, UI path और automated validation उपलब्ध है। फिर भी external device validation अलग requirement हो सकती है। |
| **Partial** | Code या UI मौजूद है, लेकिन provider, backend, security, accuracy या device integration अधूरा है। |
| **Blocked** | External credentials, backend deployment, console configuration या user decision के बिना पूरा नहीं हो सकता। |
| **Required before public release** | Feature code मौजूद हो सकता है, लेकिन public release से पहले इसका test, privacy review या operational setup अनिवार्य है। |

---

## 2. क्या-क्या बन चुका है

### 2.1 Application shell और branding

| Feature | Status | Implementation और सीमा |
|---|---|---|
| Bhasha Aura brand | **Complete** | Premium indigo, violet, aqua और magenta visual system लागू है। |
| Animated onboarding | **Complete** | Ambient background, story pages, feature cards, transitions और setup navigation उपलब्ध हैं। |
| Companion dashboard | **Complete** | Branded dashboard, metrics, private canvas और settings surfaces उपलब्ध हैं। |
| App theme system | **Complete** | Light/dark theme और Bhasha Aura accent palette उपलब्ध है। |
| Android IME entrypoint | **Complete** | Android `InputMethodService` Flutter engine से जुड़ा है। |
| Keyboard lifecycle | **Complete** | Input start/finish, editor updates, selection और keyboard height handling मौजूद हैं। |

### 2.2 Typing और language features

| Feature | Status | Implementation और सीमा |
|---|---|---|
| 22-language registry | **Complete** | Shared language registry source of truth है; UI में अलग duplicated language list नहीं रखनी चाहिए। |
| Native mode | **Complete for supported script families** | Devanagari, Bengali/Assamese, Gujarati, Gurmukhi, Odia, Tamil, Telugu, Kannada, Malayalam, Arabic-family, Ol Chiki और Meitei inventories उपलब्ध हैं। Real-device language QA बाकी है। |
| Roman mode | **Complete** | Latin keyboard surface के साथ selected language transliteration/output architecture उपलब्ध है। |
| Auto mode | **Partial** | Architecture और fallback मौजूद हैं; confidence, mixed-language detection और benchmark coverage बाकी है। |
| Transliteration | **Complete for current engine** | Roman input से native output और native translation result से readable Roman output उपलब्ध है। Long sentence और language-quality benchmark बाकी है। |
| Native-to-Roman output | **Complete** | Inherent vowels, matras, virama clusters और punctuation preservation के लिए deterministic conversion जोड़ा गया है। |
| Suggestions | **Partial** | Suggestion path मौजूद है; personalization, long sentences और language-by-language quality review बाकी है। |
| Backspace/cursor/composition | **Implemented** | Automated/widget coverage मौजूद है; WhatsApp, Telegram, Gmail और browser में physical-device verification बाकी है। |
| Emoji | **Complete in application path** | Emoji panel, insert/send/share paths मौजूद हैं; target apps में behavior verification बाकी है। |
| GIF | **Partial** | UI/path मौजूद है; inline insertion और fallback sharing app-by-app test करना है। |
| Stickers | **Partial** | UI/path मौजूद है; supported editors में insertion और fallback share test करना है। |
| Clipboard | **Implemented** | Local clipboard actions मौजूद हैं; Android vendor/device behavior test करना है। |
| Themes/settings | **Implemented** | Local settings और theme controls मौजूद हैं। |
| Haptic feedback | **Implemented** | Native IME vibrator और throttling लागू है; अलग Android vendors पर test बाकी है। |

### 2.3 Voice, translation और AI

| Feature | Status | Implementation और सीमा |
|---|---|---|
| Voice UI | **Partial** | Microphone flow, idle/recording/processing/result/error states मौजूद हैं। |
| Sarvam streaming provider | **Partial** | WebSocket provider, language/script modes, reconnect और key-pool logic मौजूद है। Secure backend proxy और production keys बाकी हैं। |
| Voice Native/Roman output | **Partial** | Script mode के अनुसार output adaptation मौजूद है; 22-language real speech accuracy validation बाकी है। |
| Manual translation | **Complete UI path** | Source/target, Native/Roman selector, review, copy और insertion उपलब्ध हैं। Real provider quality और device test बाकी हैं। |
| Real-time translation | **Partial** | Voice/transcription-to-translation path मौजूद है; secure provider proxy, quota, timeout और failure tests बाकी हैं। |
| Gemini writing assistant | **Partial** | Writing/grammar/rewrite UI/engine path मौजूद है; secure backend proxy, privacy controls, quotas और review UX hardening बाकी है। |
| Tavily/web assistant | **Partial** | Search service path मौजूद है; secure proxy, citations, timeout, rate limits और explicit tool routing बाकी है। |
| Named voice assistant | **Not complete** | Custom wake/name invocation, intent classification, confirmation और safety routing लागू करना बाकी है। |
| AI output review | **Partial** | Generated result को review/copy/insert करने का design है; हर flow में original text preserve और explicit accept behavior verify करना है। |

### 2.4 Documents और cloud

| Feature | Status | Implementation और सीमा |
|---|---|---|
| Local document picker | **Implemented** | System picker, persisted read-only URI permission और lifecycle handling मौजूद है। |
| `commitContent` attachment | **Implemented** | Supported editors में rich content attachment path मौजूद है। |
| Fallback share/picker | **Implemented** | Unsupported editors के लिए fallback path मौजूद है। |
| Device credential protection | **Implemented locally** | Attachment से पहले device authentication और तीन failed attempts पर local 15-minute lockout मौजूद है। |
| Appwrite metadata adapter | **Partial** | Auth/metadata client boundary मौजूद है; production collection permissions और Functions deploy करनी हैं। |
| Google sign-in | **Partial** | Least-privilege `drive.file` scope का client path मौजूद है; Appwrite/Google OAuth console setup और real account testing बाकी है। |
| Google Drive dashboard | **Not complete** | Authorized folders/files, metadata, search, sort, upload और create actions का secure backend workflow बाकी है। |
| Add to AI index | **Not complete** | Authorized metadata reference और retrieval authorization backend में बनाना बाकी है। |
| Folder/file creation और upload | **Not complete** | Secure Drive workflow, progress, retry, cancellation और conflict handling बाकी है। |
| Password-protected documents | **Not complete** | Server-side verification, encrypted references, lockout और no-plaintext-secret policy लागू करनी है। |
| Folder-to-ZIP sharing | **Not complete** | Controlled temporary ZIP, size preview, cancellation और expiry लागू करना है। |
| Unlink/revoke | **Partial** | Client path मौजूद है; server-side token revoke और real permission isolation test बाकी है। |

### 2.5 Engineering और release system

| Area | Status | Details |
|---|---|---|
| Flutter project structure | **Implemented** | `lib/core`, `lib/engine`, `lib/data`, `lib/ui`, `lib/config` boundaries मौजूद हैं। |
| Android native bridge | **Implemented** | IME, haptics, document attachment, clipboard, media और microphone channels मौजूद हैं। |
| Static analysis | **Complete** | Flutter 3.35.2 पर `flutter analyze` में `No issues found`। |
| Automated tests | **Complete for current automated scope** | 177 tests passed। Device/provider/cloud scenarios automated suite में पूरी तरह covered नहीं हैं। |
| Debug APK workflow | **Complete** | GitHub Actions में successful debug APK artifact बनता है। |
| Production APK workflow | **Complete** | Signed ARM64 APK और AAB build होता है, यदि signing secrets मौजूद हों। |
| Release workflow | **Complete** | Version tag से signed AAB और release asset workflow मौजूद है। |
| Secret hygiene | **Complete at repository level** | API keys, keystores और private credentials repository में committed नहीं हैं। |
| Privacy/Data Safety | **Required before public release** | Actual network, audio, transcript, clipboard, document और provider behavior के अनुसार forms/policy बनानी हैं। |

---

## 3. क्या बाकी है और क्यों

### 3.1 सबसे जरूरी blockers

| Priority | Remaining item | क्यों जरूरी है | Completion condition |
|---|---|---|---|
| P0 | Appwrite Functions deploy करना | Client में server secrets नहीं रखे जा सकते। | OAuth exchange, token refresh, Drive metadata, revoke, password verification और lockout Functions deployed और tested हों। |
| P0 | Secure provider proxy | Gemini, Sarvam और Tavily keys APK में नहीं जा सकतीं। | Authenticated backend endpoint, rate limits, timeout, quota mapping और key rotation उपलब्ध हो। |
| P0 | Real Android device QA | IME behavior emulator/Flutter tests से पूरी तरह साबित नहीं होता। | Android 13+ और एक older supported device पर complete test matrix pass हो। |
| P0 | Release privacy/data-safety review | Play Store declaration actual behavior से match करनी चाहिए। | Privacy policy, Data Safety, permissions और retention behavior approved हों। |
| P1 | Google Cloud OAuth configuration | Google sign-in और Drive scope तभी काम करेंगे। | Android package, signing fingerprints, OAuth consent और Appwrite callback setup complete हो। |
| P1 | Drive document workspace | Product promise का cloud document हिस्सा अभी incomplete है। | Browse/search/create/upload/protect/add-to-AI/unlink flows backend सहित pass हों। |
| P1 | AI retrieval authorization | AI को unauthorized document access नहीं मिलना चाहिए। | Every retrieval request user, file ID, scope और password policy re-check करे। |
| P1 | Named assistant intents | Voice assistant का product promise पूरा करना है। | Explicit intent router, confirmation, cancellation, citations और safe tool boundaries उपलब्ध हों। |
| P2 | Language quality benchmark | 22 languages में architecture होने से quality guarantee नहीं होती। | Native/Roman/suggestion/voice/translation samples पर per-language acceptance report हो। |
| P2 | GIF/sticker app matrix | Media insertion हर editor में अलग behave करता है। | WhatsApp, Telegram, Gmail, browser और unsupported editor fallback documented हों। |
| P2 | Accessibility and resilience | Premium UI को usable और reliable रहना चाहिए। | Large text, TalkBack, dark mode, rotation, process restart, low memory और network loss tests pass हों। |

---

## 4. External setup: owner को क्या करना है

Secrets को chat, GitHub code या APK में paste नहीं करना है। इन्हें Appwrite Functions, GitHub Actions encrypted secrets या approved secret manager में रखना है।

### 4.1 Public client configuration

Flutter build में केवल ये public values जा सकती हैं:

```text
APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID
APPWRITE_DATABASE_ID
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID
APPWRITE_OAUTH_SUCCESS_URL
APPWRITE_OAUTH_FAILURE_URL
```

Android mobile build में OAuth success/failure URLs empty रह सकती हैं जब Appwrite mobile deep-link flow use हो। Web build में real HTTPS routes चाहिए।

### 4.2 Server-only configuration

ये values केवल Appwrite Functions या secure backend runtime में रहें:

```text
APPWRITE_API_KEY
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
GOOGLE_TOKEN_ENCRYPTION_SECRET
GEMINI_API_KEYS
SARVAM_API_KEYS
TAVILY_API_KEYS
DOCUMENT_PASSWORD_PEPPER
```

### 4.3 Appwrite setup sequence

1. Production Appwrite project बनाइए या existing project verify कीजिए।
2. Android platform में package `com.bhashakeyboard.ime` add कीजिए।
3. Database बनाकर `document_links` collection बनाइए।
4. Collection में user-scoped read/update/delete permissions लगाइए।
5. Google OAuth provider enable कीजिए।
6. OAuth callback/deep-link configuration Appwrite documentation के अनुसार complete कीजिए।
7. Required Functions deploy कीजिए:
   - Google OAuth exchange
   - Token refresh
   - Drive metadata browse/search
   - Drive create/upload
   - Unlink/revoke
   - Document password verification
   - Atomic failed-attempt lockout
   - Optional Gemini proxy
   - Optional Sarvam proxy
   - Optional Tavily proxy
8. Functions में server-only variables configure कीजिए।
9. Non-owner test account से permissions verify कीजिए।

### 4.4 Google Cloud setup sequence

1. Google Cloud project चुनिए या बनाइए।
2. Google Drive API enable कीजिए।
3. OAuth consent screen configure कीजिए।
4. Android OAuth client में package `com.bhashakeyboard.ime` add कीजिए।
5. Release keystore के SHA-1 और SHA-256 fingerprints add कीजिए।
6. Appwrite-provided callback configuration exact value के साथ register कीजिए।
7. Least-privilege `drive.file` scope से शुरुआत कीजिए।
8. OAuth cancellation, revoked permission, expired session और non-owner isolation test कीजिए।

### 4.5 Provider backend setup

Provider calls को mobile app से direct नहीं करना है। Backend में यह behavior होना चाहिए:

- Authenticated user check
- Request size limit
- Per-user rate limit
- Provider timeout
- Retry policy
- Quota and provider error mapping
- Key rotation
- Abuse prevention
- Minimal logging
- Transcript/document retention policy
- User-visible retry and draft preservation

---

## 5. Local development और validation commands

Flutter version CI के समान रखें: **Flutter 3.35.2 / Dart 3.9.0**.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
```

Release signing के लिए `android/key.properties` और `android/app/upload-keystore.jks` चाहिए। ये files repository में commit नहीं करनी हैं।

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
flutter build appbundle --release
```

Expected outputs:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/bundle/release/app-release.aab
```

### Current verified results

```text
flutter analyze: No issues found
flutter test: 177 tests passed
CI: success
Debug APK: success
Production Android Build: success
Pages deployment: success
```

---

## 6. Real-device end-to-end test plan

Automated tests pass होने के बाद कम-से-कम दो physical Android devices पर test करें: एक Android 13 या newer device और एक older supported device।

### 6.1 Installation और IME activation

1. APK install करें।
2. Android Settings से Bhasha Aura enable करें।
3. Bhasha Aura को default keyboard चुनें।
4. App process restart और device restart के बाद state verify करें।
5. Keyboard को WhatsApp, Telegram, Gmail और browser में open करें।

### 6.2 Typing acceptance

| Scenario | Expected result |
|---|---|
| Hindi Native | Devanagari characters और matras सही output दें। |
| Hindi Roman | Latin surface पर Roman input से Hindi output मिले। |
| Urdu/Arabic-family | RTL text, punctuation और cursor behavior usable हो। |
| English mixed text | URLs, names, numbers और English words corrupt न हों। |
| Backspace/cursor | Selection और composition न टूटे। |
| Language switch | Text loss या unexpected layout jump न हो। |
| Dark/light mode | Text और key contrast accessible रहे। |
| Large font | Overflow और unusable key targets न हों। |

### 6.3 Voice acceptance

1. Microphone permission allow करें।
2. Recording, stop, cancel और review करें।
3. Permission deny करें और verify करें कि keyboard usable रहे।
4. Network loss के दौरान draft preserve हो।
5. Provider failure में retry मिले।
6. Native और Roman outputs को अलग-अलग verify करें।

### 6.4 Documents and cloud acceptance

1. Google sign-in complete करें।
2. OAuth cancel और back flow test करें।
3. Drive metadata केवल authorized account का दिखे।
4. Non-owner account से isolation verify करें।
5. File attach supported editor में `commitContent` से test करें।
6. Unsupported editor में fallback share test करें।
7. तीन गलत document-auth attempts के बाद lockout verify करें।
8. Lockout expiry verify करें।
9. Unlink के बाद token/reference removal verify करें।

### 6.5 Resilience and accessibility

Rotation, process restart, low memory, airplane mode, slow network, Android back navigation, TalkBack, large text, dark mode, three-button navigation और gesture navigation test करें। हर failure में original text और draft preserve रहना चाहिए।

---

## 7. Recommended implementation order

### Phase 1 — Release foundation

पहले Appwrite project, collection permissions, Functions, Google OAuth और secure provider proxy deploy करें। इसके बाद real devices पर local keyboard, document attachment और voice permissions validate करें।

### Phase 2 — Connected intelligence

इसके बाद Gemini, Sarvam और Tavily proxy integrate करें। हर provider call में authenticated user, timeout, quota, retry और privacy behavior जोड़ें। AI result को कभी silently insert या replace न करें।

### Phase 3 — Document workspace

Drive browse/search/create/upload, password policy, Add to AI, retrieval authorization और ZIP sharing को explicit confirmation steps के साथ implement करें। Document bytes को अनावश्यक रूप से Bhasha storage में copy न करें।

### Phase 4 — Assistant orchestration

Named assistant के लिए intent router बनाइए। Search, AI writing, document retrieval और sharing को अलग tools रखें। Sensitive actions के पहले user review और confirmation रखें।

### Phase 5 — Quality and Play release

22-language benchmark, physical-device matrix, accessibility, crash monitoring, privacy policy, Data Safety form, content rating, internal testing और staged rollout complete करें।

---

## 8. Public release decision

### अभी release किया जा सकने वाला scope

पहले release में local-first scope सुरक्षित रूप से दिया जा सकता है:

- Android keyboard
- Supported language layouts
- Native/Roman modes
- Suggestions और transliteration
- Emoji
- Clipboard
- Themes/settings
- Local document picker और safe fallback sharing
- Clearly labeled optional voice/translation UI

### Backend पूरा होने तक रोकने या label करने वाला scope

इन features को backend और device validation के बिना fully production-ready advertise नहीं करना है:

- Google Drive dashboard
- Password-protected cloud document retrieval
- Add to AI
- Gemini writing assistant
- Sarvam production voice
- Tavily web assistant
- Named wake-word assistant
- Folder-to-ZIP cloud sharing

> **Release rule:** Automated green build का अर्थ यह है कि code compile, tests और CI pass हुए हैं। इसका अर्थ यह नहीं है कि Google OAuth, cloud permissions, provider accuracy, Play policy या physical-device behavior स्वतः verified हो गया।

---

## 9. AI agent handoff rules

कोई भी अगला AI agent implementation शुरू करने से पहले इस document और `docs/PRODUCT_SOURCE_OF_TRUTH.md` को पढ़े। उसे निम्न नियमों का पालन करना है:

1. Existing language registry और shared services को duplicate न करें।
2. Provider API keys APK, Dart source, Git history या logs में न डालें।
3. User text, transcript और documents को silently replace, upload या share न करें।
4. Cloud feature को “complete” तभी लिखें जब backend, permissions, error path और device test मौजूद हों।
5. हर new feature के साथ unit/widget/integration test जोड़ें।
6. UI change के बाद dark mode, large text और keyboard-height constraints verify करें।
7. `flutter analyze`, `flutter test` और relevant Android build चलाए बिना commit को production-ready न कहें।
8. Product status table में implementation और external setup को अलग-अलग दर्ज करें।
9. Destructive, financial, legal, privacy या public-release action से पहले explicit confirmation लें।
10. Current release candidate को बिना आवश्यकता downgrade न करें।

---

## 10. Source files और महत्वपूर्ण documents

| Resource | Purpose |
|---|---|
| `lib/main.dart` | Companion app entrypoint, theme और dashboard flow |
| `lib/ui/keyboard_view.dart` | Main keyboard surface और toolbar/panel routing |
| `lib/core/keyboard_controller.dart` | Keyboard state, input actions, translation और assistant orchestration |
| `lib/data/languages.dart` | Supported language registry और script modes |
| `lib/data/layouts.dart` | Native/Latin layout inventories |
| `lib/engine/transliterator.dart` | Roman/native transliteration और Roman output conversion |
| `lib/engine/voice_engine.dart` | Voice provider abstraction और lifecycle |
| `lib/engine/sarvam_speech_provider.dart` | Sarvam streaming speech provider path |
| `lib/engine/gemini_service.dart` | Gemini writing/search summarization path |
| `lib/engine/appwrite_document_repository.dart` | Appwrite auth और document metadata boundary |
| `android/app/src/main/kotlin/com/bhashakeyboard/ime/BhashaImeService.kt` | Native IME bridge |
| `docs/PRODUCT_SOURCE_OF_TRUTH.md` | Detailed product contract और feature behavior |
| `docs/production-setup.md` | Secrets, Appwrite, Google Cloud और release boundary |
| `.github/workflows/ci.yml` | Analyze, tests और debug build |
| `.github/workflows/production-build.yml` | Signed production APK और AAB |
| `.github/workflows/release.yml` | Tag-based Play/release AAB workflow |

---

## 11. Final handoff summary

**बन चुका है:** premium branded Android keyboard shell, onboarding, IME integration, 22-language architecture, Native/Roman modes, transliteration, suggestions path, emoji, settings, local document attachment, manual translation output modes, voice/provider paths, Appwrite client boundary, automated tests और signed build pipeline।

**अभी बाकी है:** secure backend deployment, Google OAuth/Drive integration, provider proxies, server-side document security, named assistant orchestration, 22-language accuracy benchmark, physical Android testing, privacy/data-safety review और Play Console release gates।

**अगला practical step:** पहले Appwrite और Google Cloud setup पूरा करें, फिर secure Functions/proxies deploy करें, उसके बाद दो physical Android devices पर acceptance matrix चलाएँ। केवल इन steps के बाद cloud-connected public production release को complete माना जाए।

---

## References

[1]: https://developer.android.com/develop/ui/views/touch-and-input/creating-an-input-method "Android Input Method Editor documentation"

[2]: https://appwrite.io/docs/products/auth/oauth2 "Appwrite OAuth2 documentation"

[3]: https://appwrite.io/docs/products/functions "Appwrite Functions documentation"

[4]: https://cloud.google.com/docs/authentication "Google Cloud authentication documentation"

[5]: https://support.google.com/google-play/android-developer/answer/10787469 "Google Play Data safety guidance"

[6]: https://support.google.com/google-play/android-developer/answer/9859455 "Google Play app quality and release guidance"
