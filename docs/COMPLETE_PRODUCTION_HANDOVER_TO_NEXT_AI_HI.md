# Bhasha Keyboard — Complete Production Handover to the Next AI

**तैयारकर्ता:** Manus AI  
**तारीख:** 11 September 2026  
**Repository:** `https://github.com/sameerswain2026-code/bhasha-keyboard`  
**वर्तमान working branch:** `feat/secure-cloud-linked-documents`  
**वर्तमान latest commit:** `5041c7c`  
**मुख्य उद्देश्य:** अगले AI/developer को बिना पुराने chat context के Bhasha Keyboard को सुरक्षित रूप से आगे बढ़ाने, validate करने और Google Play release तक ले जाने में सक्षम बनाना।

---

## 1. सबसे महत्वपूर्ण निष्कर्ष

यह repository किसी नए keyboard, नए microphone या नए assistant architecture की जरूरत वाली स्थिति में नहीं है। Existing Flutter keyboard, Android `InputMethodService`, voice flow, Gemini, Sarvam, Tavily, Appwrite और document manager को preserve करना अनिवार्य है। अगला AI पहले source और branch mapping पढ़े और केवल confirmed blockers पर काम करे।

**Application source के लिए वर्तमान सुरक्षित working branch `feat/secure-cloud-linked-documents` है।** इस branch में secure cloud documents, Appwrite gateways, onboarding, haptics, media insertion, dynamic translation target, paged native layouts और latest microphone changes मौजूद हैं।

**Appwrite Functions भी पहले इसी branch से deploy की गई थीं।** इसलिए इस feature branch को अभी delete, rename, force-reset या बिना समझे rebase नहीं करना है। Functions की Appwrite Git branch application branch से अलग deployment dependency है।

**Latest CI run अभी failed है।** GitHub Actions run `34445728365` में source logic पर नहीं, बल्कि `dart format --output=none --set-exit-if-changed .` step पर failure हुआ। इसलिए इस run को release candidate न मानें। पहले formatting ठीक करें, फिर पूरा production workflow दोबारा चलाएँ।

**Public Play Store release अभी verified नहीं है।** Signed AAB, Appwrite Function tests, Google OAuth/Drive tests, physical-device QA और Play Internal testing evidence अभी अलग-अलग verify करना बाकी है।

---

## 2. Repository को सही तरीके से प्राप्त करना

अगला AI यह exact sequence चलाए:

```bash
git clone https://github.com/sameerswain2026-code/bhasha-keyboard.git
cd bhasha-keyboard
git fetch --all --prune
git checkout feat/secure-cloud-linked-documents
git pull --ff-only origin feat/secure-cloud-linked-documents
git status --short --branch
git log -10 --oneline --decorate
```

यदि working tree में किसी पुराने AI के uncommitted changes हों, तो उन्हें तुरंत discard न करें। पहले `git diff`, `git status` और changed-file list पढ़ें। User की अनुमति के बिना दूसरे काम का code delete नहीं करना है।

पहले ये documents पढ़ना अनिवार्य है:

```text
docs/COMPLETE_PRODUCTION_HANDOVER_TO_NEXT_AI_HI.md
docs/HANDOVER_TO_NEXT_AI_HI.md
docs/BRANCH_AND_FUNCTION_DEPLOYMENT_CORRECTION_HI.md
docs/production-setup.md
docs/appwrite-deployment-guide-hi.md
docs/release-gates.md
docs/device-qa-template.md
docs/play-store-release-checklist.md
docs/end-to-end-gap-analysis.md
docs/privacy.md
docs/privacy-policy.html
```

---

## 3. Branch map और प्रत्येक branch का काम

Repository में मिले branches का अर्थ नीचे दिया गया है। Branch names को केवल नाम देखकर merge या delete न करें।

| Branch | वर्तमान स्थिति | इसमें क्या है | क्या करना है |
|---|---|---|---|
| `feat/secure-cloud-linked-documents` | **मुख्य working branch** | Secure document manager, Appwrite metadata, Drive gateway, AI gateway, OAuth setup, haptics, media, onboarding, dynamic language target, paged native keyboard और latest mic fixes | इसी branch से current fixes और validation करें। इसे सुरक्षित रखें। |
| `origin/main` | Integration/base branch | Feature branch का बड़ा भाग merge हो चुका है। Main में production integration और पुराने release changes हैं, लेकिन Functions की deployment branch अपने-आप main नहीं हुई है | Play release base बनाने से पहले latest feature changes और CI result carefully compare करें। Blind merge न करें। |
| `origin/arena/01a088fc-bhasha-keyboard` | पुराने hardening work का arena branch | Gateway hardening, release checks और production audit से जुड़े commits | Reference/archive branch। इसमें नया work सीधे न करें। |
| `origin/arena/01a0894d-bhasha-keyboard` | पुराने compile-fix arena branch | Duplicate `_StatusChip` compile fix और arena CI changes | Reference/archive branch। Production source न मानें। |
| `origin/copilot/deep-research-global-problems` | पुराने research/base state के करीब | पुराने global problem analysis और main-संबंधित state | केवल history/reference के लिए। |
| `origin/HEAD` | Symbolic pointer | सामान्यतः `origin/main` को point करता है | कोई source branch नहीं। |

वर्तमान branch देखने के लिए:

```bash
git branch -a -vv
git log --all --graph --decorate --oneline -40
```

### Branch policy

- `feat/secure-cloud-linked-documents` को अभी delete नहीं करना है।
- Appwrite Functions को नया duplicate ID देकर recreate नहीं करना है।
- Function source को repository root से deploy नहीं करना है।
- Existing Function IDs preserve करने हैं।
- `main` में migration तभी करें जब दोनों Functions को Appwrite Console में `main` branch से redeploy करके test किया जा चुका हो।
- `main` और feature branch का blind merge न करें। पहले file-level diff और commit ancestry समझें।

---

## 4. Appwrite Functions और branch dependency

दो existing Functions user के अनुसार Appwrite में deploy हो चुकी हैं:

| Function | Function ID | Source directory | Entrypoint | Runtime | Original deployment branch |
|---|---|---|---|---|---|
| Drive gateway | `6aa12c14001ddeb260df` | `functions/drive-gateway` | `index.js` | Node.js 22 | `feat/secure-cloud-linked-documents` |
| AI gateway | `6aa13043002cddfbdc72` | `functions/ai-gateway` | `index.js` | Node.js 22 | `feat/secure-cloud-linked-documents` |

Appwrite Console में प्रत्येक Function के लिए ये settings verify करें:

```text
Runtime: Node.js 22
Production branch: feat/secure-cloud-linked-documents
Root directory: functions/drive-gateway या functions/ai-gateway
Entrypoint: index.js
Build command: npm install
Execute access: authenticated Appwrite users only
Anonymous guests: disabled
```

Drive Function के लिए root directory:

```text
functions/drive-gateway
```

AI Function के लिए root directory:

```text
functions/ai-gateway
```

**Screenshot में दिखने वाली Appwrite Create Function screen में `main.dart` या repository root नहीं चुनना है।** Node Function के लिए `index.js` चुनना है। `main.dart` Flutter application entrypoint है और Appwrite Node Function का entrypoint नहीं है।

### Functions को अभी feature branch पर रखना क्यों सुरक्षित है

Functions पहले feature branch से deploy हुई थीं। यदि feature branch delete या reset की गई, तो Appwrite का अगला Git deployment fail हो सकता है या पुराना source unexpectedly बदल सकता है। Application को `main` से validate किया जा सकता है, लेकिन Functions को तब तक feature branch पर रखें जब तक migration complete न हो।

### बाद में Functions को `main` पर migrate करने का सुरक्षित तरीका

1. Confirm करें कि `main` में ये चार files मौजूद हैं:
   - `functions/drive-gateway/index.js`
   - `functions/drive-gateway/package.json`
   - `functions/ai-gateway/index.js`
   - `functions/ai-gateway/package.json`
2. पहले `drive-gateway` की Appwrite production branch को `main` करें।
3. Root directory, entrypoint और build command न बदलें।
4. Environment variables दोबारा verify करें।
5. Deploy करें।
6. Authenticated Drive metadata, folder, revoke और unlink tests चलाएँ।
7. फिर `ai-gateway` को उसी तरीके से `main` पर migrate करें।
8. Gemini और Tavily tests चलाएँ।
9. दोनों Functions stable होने के बाद ही feature branch archive/delete पर विचार करें।

---

## 5. Appwrite project और database configuration

User-confirmed public/non-secret configuration:

```text
APPWRITE_ENDPOINT=https://nyc.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=6a7fc74a001f50afe9e5
APPWRITE_DATABASE_ID=bhasha-db
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID=document-links
```

User-confirmed metadata tables:

```text
document-links
google-drive-tokens
```

### `document-links` table का उद्देश्य

इस table में document bytes नहीं रखने हैं। यह केवल user-scoped minimal metadata और provider reference रखे:

| Field | उद्देश्य |
|---|---|
| `userId` | Appwrite authenticated user की ownership |
| `driveFileId` | User Drive file reference, यदि Drive document linked है |
| `label` | उदाहरण: Resume, Aadhaar, Education |
| `displayName` | UI में दिखने वाला file name |
| `mimeType` | Attachment MIME type |
| `lockStatus` | Lock state |
| `failedAttempts` | Local/server lockout counter के लिए metadata |
| `lockedUntil` | Temporary lock expiry |
| `groupName` | User folder/group label |
| `driveFolderId` | User Drive folder reference |
| `driveUri` | Provider URI/reference, यदि applicable |
| `createdAt` और `updatedAt` | Metadata timestamps |

### `google-drive-tokens` table का उद्देश्य

इस table में केवल encrypted Google refresh-token metadata रखना है। निम्न चीजें नहीं रखनी हैं:

- Google Drive document bytes
- PDF/image/video content
- Extracted document content
- Plaintext access token
- Plaintext refresh token
- User password
- Provider API keys

Google refresh token को server-side encryption के बाद store करें। Encryption key केवल Appwrite Function environment variable में रहे। APK, Flutter source, GitHub repository और Appwrite database में plaintext secret नहीं होना चाहिए।

### Appwrite permissions

- हर document row में ownership check अनिवार्य है।
- User A को User B की rows पढ़ने या बदलने की अनुमति नहीं होनी चाहिए।
- Function execution केवल authenticated users के लिए रखें।
- Admin API key को client app में न डालें।
- Database permissions को broad “all users CRUD” से production में tighten करें यदि वर्तमान table में ऐसा permission दिया गया हो। Recommended policy: user-scoped access through authenticated Function or row-level ownership enforcement।

---

## 6. Secrets और environment variables

इन values को कभी भी repository, APK, public issue, screenshot या chat में न डालें:

```text
APPWRITE_API_KEY
GOOGLE_CLIENT_SECRET
GOOGLE_TOKEN_ENCRYPTION_SECRET
GEMINI_API_KEYS
SARVAM_API_KEYS
TAVILY_API_KEYS
```

ये values केवल संबंधित Appwrite Function environment variables में होनी चाहिए। GitHub Actions में केवल आवश्यक signing secrets और public Function IDs रखें।

Expected Function variables:

### `drive-gateway`

```text
APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID
APPWRITE_API_KEY
APPWRITE_DATABASE_ID
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID
google client ID
google client secret
Google token encryption secret
Google Drive OAuth redirect configuration
```

Actual variable names source और existing deployment guide के अनुसार verify करें। अनुमान लगाकर नया नाम न बनाएं।

### `ai-gateway`

```text
APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID
GEMINI_API_KEYS
SARVAM_API_KEYS
TAVILY_API_KEYS
GEMINI_ALLOWED_MODELS
SARVAM_ALLOWED_HOSTS
```

API keys comma-separated rotation pool में रखी जा सकती हैं, लेकिन Function logs में keys print नहीं करनी हैं।

GitHub repository variables expected:

```text
APPWRITE_DRIVE_GATEWAY_FUNCTION_ID=6aa12c14001ddeb260df
APPWRITE_AI_GATEWAY_FUNCTION_ID=6aa13043002cddfbdc72
```

Secret values देखने या print करने की कोशिश न करें। केवल names और presence verify करें।

---

## 7. Code architecture और important files

### Android IME

```text
android/app/src/main/kotlin/com/bhashakeyboard/ime/BhashaImeService.kt
android/app/src/main/kotlin/com/bhashakeyboard/ime/MainActivity.kt
android/app/src/main/kotlin/com/bhashakeyboard/ime/DocumentAuthActivity.kt
android/app/src/main/kotlin/com/bhashakeyboard/ime/MicStreamHandler.kt
android/app/src/main/AndroidManifest.xml
```

`BhashaImeService.kt` active text editor, haptics, media `commitContent`, document picker, biometric/PIN activity, URI release और microphone bridge संभालता है।

### Flutter controller और keyboard

```text
lib/core/keyboard_controller.dart
lib/ui/keyboard_view.dart
lib/ui/key_widget.dart
lib/data/languages.dart
lib/data/layouts.dart
lib/engine/transliterator.dart
```

Native script keyboard में page state `nativePage` है। Page navigation `setNativePage`, `nextNativePage` और `previousNativePage` से होता है। Layout resolver `layoutPageFor` और `nativePageCount` का उपयोग करता है।

### Voice और AI

```text
lib/engine/voice_engine.dart
lib/engine/android_mic_source.dart
lib/engine/sarvam_speech_provider.dart
lib/engine/translation_engine.dart
lib/engine/gemini_service.dart
lib/engine/tavily_search_service.dart
lib/engine/ai_assistant_engine.dart
lib/engine/writing_assistant.dart
```

Existing voice architecture को replace नहीं करना है। Microphone source में EventChannel subscription पहले स्थापित होकर native start उसके बाद होना चाहिए।

### Documents

```text
lib/engine/document_manager.dart
lib/engine/appwrite_document_repository.dart
lib/ui/panels/documents_panel.dart
lib/engine/appwrite_gateway_client.dart
functions/drive-gateway/index.js
```

Document bytes Bhasha backend में copy नहीं होने चाहिए। Direct URI/provider reference और user-owned Drive file reference ही इस्तेमाल करें।

### Configuration

```text
lib/config/cloud_config.dart
```

यह file केवल public endpoint, project ID और Function IDs रख सकती है। इसमें API key, OAuth secret, refresh token या encryption secret नहीं होना चाहिए।

---

## 8. अभी किए गए latest keyboard और microphone changes

Latest commit `5041c7c` में निम्न changes push किए गए:

1. Native layouts को 10–9–7 key rows में page किया गया।
2. Native page indicator और next/previous behavior जोड़ा गया।
3. Full-width rows के लिए squeezed horizontal scrolling हटाई गई।
4. Native inventories में अतिरिक्त Devanagari language data जोड़ा गया।
5. IME से missing microphone permission होने पर launcher activity खोलने का flow जोड़ा गया।
6. EventChannel microphone subscription और native AudioRecord startup ordering ठीक की गई।
7. Manual translation panel में input preview को embedded keyboard के ऊपर रखा गया।
8. Document picker bridge और existing `bhasha/documents` channel preserve किया गया।
9. Native layout inventory regression test जोड़ा गया।

### सावधानी

Latest changes अभी GitHub Actions के formatting gate से verify नहीं हुई हैं। Local sandbox में `dart` और Gradle wrapper उपलब्ध नहीं थे, इसलिए local validation नहीं चली। अगले AI को CI failure को पहले fix करना है।

---

## 9. Latest CI failure और उसे ठीक करने का तरीका

Latest triggered workflow:

```text
Run ID: 34445728365
URL: https://github.com/sameerswain2026-code/bhasha-keyboard/actions/runs/34445728365
HEAD: 5041c7c
Result: failure
Failed step: dart format --output=none --set-exit-if-changed .
```

यह failure formatting gate पर हुआ और बाद के build jobs run नहीं हुए। Exact recovery:

```bash
cd bhasha-keyboard
git checkout feat/secure-cloud-linked-documents
git pull --ff-only origin feat/secure-cloud-linked-documents

dart format lib/data/layouts.dart \
  lib/core/keyboard_controller.dart \
  lib/ui/keyboard_view.dart \
  lib/engine/android_mic_source.dart \
  lib/ui/panels/manual_translate_panel.dart \
  test/native_layout_inventory_test.dart

git diff --check
flutter analyze
flutter test
```

यदि `dart format` पूरे repository पर required हो:

```bash
dart format .
```

Formatting के बाद केवल intended changes commit करें:

```bash
git status --short
git diff --check
git add <only-intended-files>
git commit -m "style: format keyboard and microphone changes"
git push origin feat/secure-cloud-linked-documents
```

फिर production workflow चलाएँ:

```bash
gh workflow run production-build.yml \
  --repo sameerswain2026-code/bhasha-keyboard \
  --ref feat/secure-cloud-linked-documents
```

Run status:

```bash
gh run list \
  --repo sameerswain2026-code/bhasha-keyboard \
  --workflow production-build.yml \
  --branch feat/secure-cloud-linked-documents \
  --limit 5
```

Successful run में ये सभी gates green होने चाहिए:

```text
Dart formatting
Flutter analyze
Flutter tests
Backend gateway validation
Signed ARM64 APK
Signed production AAB
Signed output verification
Artifact upload
```

Green workflow के बिना APK/AAB को release candidate न कहें।

---

## 10. Drive document end-to-end requirements

Expected user flow:

1. User onboarding में Appwrite/Google sign-in करता है।
2. User Google Drive authorization देता है।
3. User Documents panel में `+` दबाता है।
4. User label चुनता या custom label बनाता है, जैसे Resume, Aadhaar या Education।
5. Android system picker या Drive reference से document select होता है।
6. App केवल URI, Drive file ID, label, MIME type, group और lock metadata रखता है।
7. Voice command जैसे “Upload my Aadhaar Card” label resolver से matching document ढूँढता है।
8. Device PIN/biometric authentication मांगी जाती है।
9. Failed attempts policy लागू होती है। Repeated failure के बाद 15-minute lockout होना चाहिए।
10. Supported editor में `commitContent` से attachment जाता है।
11. Unsupported editor में Android chooser/file picker fallback खुलता है।
12. Unlink पर local persisted URI permission release और Google access revoke behavior verify होता है।

### Mandatory security tests

- User A cannot list User B metadata.
- User A cannot use User B’s Drive token.
- Expired token refresh path works.
- Revoke immediately blocks subsequent Drive access.
- Deleted Drive file produces a safe recoverable error.
- File bytes are not written to Appwrite Storage.
- File bytes are not written to application logs.
- Failed attempts reset after successful authentication.
- Lock expires after the defined 15 minutes.
- Account sign-out clears local protected state appropriately.

---

## 11. Sarvam voice limitation

Gemini और Tavily के लिए HTTP Appwrite gateway path मौजूद है। Current Sarvam live speech implementation long-lived WebSocket stream का उपयोग करती है। Existing HTTP `ai-gateway` अपने-आप WebSocket relay नहीं है। इसलिए production में निम्न में से एक choice करनी होगी:

| विकल्प | निर्णय |
|---|---|
| Authenticated Sarvam WebSocket relay | सबसे complete production solution |
| Buffered audio HTTP transcription gateway | सरल, लेकिन real-time अनुभव अलग होगा |
| Android SpeechRecognizer fallback | Device-based fallback, Sarvam language parity सीमित हो सकती है |
| Sarvam live voice disable करना | Incomplete feature को public claim से रोकता है |

**APK में Sarvam API key डालकर इस limitation को bypass नहीं करना है।** इससे key extraction और abuse का खतरा होगा।

---

## 12. Physical-device QA

CI source correctness दिखाता है, लेकिन Android IME का वास्तविक behavior device और host app पर निर्भर करता है। कम-से-कम निम्न परीक्षण करें:

| Test area | Apps/devices | Expected result |
|---|---|---|
| Haptics | WhatsApp, Telegram, browser | Key press पर native vibration महसूस हो |
| English | WhatsApp/Gmail | A–Z complete QWERTY और readable keys |
| Native scripts | Hindi, Odia, Telugu, Tamil, Bengali, Urdu | Page navigation और correct script characters |
| Roman mode | Hindi/Odia/Telugu | English alphabet typing और transliteration |
| Translation | English→Odia, Telugu→Odia, Odia→Telugu | Target language keycaps बदलें |
| Mic permission | Fresh install | Permission flow खुलता है, silent failure नहीं |
| Voice | Android 13+ और older device | Audio stream, transcription, stop/back/send behavior |
| Documents | WhatsApp/Gmail/editor | Direct attachment या safe picker fallback |
| Biometric/PIN | Device with and without biometrics | Device credential fallback काम करे |
| Lockout | Repeated wrong auth | 15-minute lock और clear recovery message |
| Media | GIF/sticker-capable host | Actual rich content, केवल text label नहीं |
| Resize | Gesture and three-button navigation | Bottom row hidden या overlapped न हो |
| Dark/light | System theme changes | Readable contrast और no clipped controls |
| Accessibility | Large font/TalkBack | Main controls reachable और labeled हों |

QA evidence को `docs/device-qa-template.md` में दर्ज करें। Important failures के screenshots और screen recordings रखें।

---

## 13. Google OAuth और Drive release checklist

Google Cloud में:

1. Google Drive API enable करें।
2. OAuth consent screen complete करें।
3. Appwrite callback URL को exact रूप से configure करें।
4. Android package name verify करें: `com.bhashakeyboard.ime`।
5. Debug और release SHA-256 fingerprints add करें।
6. Least-privilege `drive.file` scope उपयोग करें।
7. Test account और non-owner account दोनों से login test करें।
8. Login cancellation, relaunch, expired session और revoke test करें।

Appwrite में:

1. Google provider enabled रखें।
2. Success/failure redirect configuration source और deployment guide से match करें।
3. Authenticated Function execution रखें।
4. OAuth client secret केवल Function environment में रखें।
5. Token table में encrypted refresh-token metadata ही रखें।

---

## 14. Play Store release steps

### Source और CI

1. Feature branch पर formatting fix करें।
2. `flutter analyze` और `flutter test` pass करें।
3. Signed AAB build करें।
4. AAB checksum और artifact size record करें।
5. Release signing fail-closed behavior verify करें।

### Play Console

1. Google Play Console में app create/configure करें।
2. Privacy policy URL publish करें।
3. Data Safety form भरें।
4. Account deletion और cloud unlink behavior document करें।
5. Content rating complete करें।
6. Target audience और app access declarations complete करें।
7. App icon, feature graphic, screenshots और support email add करें।
8. Signed AAB को Internal testing track में upload करें।
9. Internal testers के device पर install और upgrade test करें।
10. Pre-launch report, crashes और ANRs ठीक करें।
11. Closed testing या staged production rollout शुरू करें।
12. Public rollout तभी करें जब critical device and cloud tests pass हों।

### Ads के बारे में

AdMob या कोई “ads Function” Play release के लिए required नहीं है। Ads बाद में जोड़े जा सकते हैं। Ads जोड़ने पर consent, privacy, Data Safety, ad SDK और child-audience compliance फिर से review करनी होगी। अभी ads जोड़ना release को delay नहीं करना चाहिए।

---

## 15. Production gates का final status

| Gate | स्थिति |
|---|---|
| Existing architecture preserved | Source में complete |
| Secure document metadata design | Source में implemented |
| Document bytes absent from Bhasha storage | Design/documented; runtime logs and Function test verify करना बाकी |
| Drive gateway source | Ready |
| AI gateway source | Ready |
| Drive Function deployment | User-confirmed; independently verify करना बाकी |
| AI Function deployment | User-confirmed; independently verify करना बाकी |
| Function environment variables | User-confirmed; presence and names verify करना बाकी |
| Latest branch push | Complete, commit `5041c7c` |
| Latest production CI | Failed at formatting gate; retry required |
| Signed APK/AAB from latest commit | Not yet evidenced |
| OAuth physical-device test | Pending |
| Non-owner isolation test | Pending |
| Sarvam live streaming | Not complete without WebSocket/buffered relay |
| Device QA | Pending |
| Play Internal testing | Pending |
| Public Play release | Not yet safe to claim |

---

## 16. Ready-to-use prompt for the next AI

नीचे का prompt सीधे दूसरे AI को दें:

> You are continuing the existing Bhasha Keyboard repository. Do not create a new keyboard, microphone, assistant, document system, or cloud architecture. Clone `https://github.com/sameerswain2026-code/bhasha-keyboard` and checkout `feat/secure-cloud-linked-documents`. Read `docs/COMPLETE_PRODUCTION_HANDOVER_TO_NEXT_AI_HI.md`, `docs/HANDOVER_TO_NEXT_AI_HI.md`, `docs/BRANCH_AND_FUNCTION_DEPLOYMENT_CORRECTION_HI.md`, `docs/production-setup.md`, `docs/release-gates.md`, and `docs/device-qa-template.md` before editing. The current latest commit is `5041c7c`. First fix the GitHub Actions formatting failure from run `34445728365` by running Dart formatting, then run analyze, tests, and the signed production workflow. Do not print or request secrets. Existing Appwrite Function IDs are `6aa12c14001ddeb260df` for `drive-gateway` and `6aa13043002cddfbdc72` for `ai-gateway`. Both Functions were originally deployed from `feat/secure-cloud-linked-documents`, so do not delete or reset that branch. Function roots must remain `functions/drive-gateway` and `functions/ai-gateway`, entrypoint `index.js`, runtime Node.js 22, and build command `npm install`. Preserve the privacy rule that document bytes never enter Bhasha storage or logs. After CI is green, verify Function authentication, Google OAuth/Drive with a non-owner account, token refresh/revoke, document attachment fallback, biometric/PIN lockout, haptics, all native language pages, translation target synchronization, microphone permission and voice behavior on physical Android devices. Do not claim Play production readiness until a successful signed AAB, runtime evidence, Play Internal testing and compliance forms are complete. Current known limitation: Sarvam live voice uses a long-lived WebSocket while the existing AI Function is HTTP; implement an authenticated relay, buffered endpoint, or safe fallback before advertising public Sarvam live transcription.

---

## 17. Final operating rule

इस project में चार अलग states को हमेशा अलग रखें:

1. **Source implemented:** code repository में मौजूद है।
2. **Externally configured:** Appwrite, Google Cloud और GitHub settings save हैं।
3. **Device verified:** वास्तविक Android device पर feature सफलतापूर्वक चला है।
4. **Play approved:** Play Console testing और policy review pass हुए हैं।

इन चारों में से केवल पहली या दूसरी state देखकर application को public production-ready न कहें। Final release का प्रमाण successful CI, signed AAB, authenticated cloud tests, physical-device QA और Play Internal testing का combined evidence है।

## References

[1]: https://appwrite.io/docs/products/functions "Appwrite Functions documentation"

[2]: https://appwrite.io/docs/products/auth/oauth2 "Appwrite OAuth2 documentation"

[3]: https://developers.google.com/drive/api/guides/about-sdk "Google Drive API documentation"

[4]: https://support.google.com/googleplay/android-developer/answer/9859152 "Google Play release guidance"

[5]: https://support.google.com/googleplay/android-developer/answer/10787469 "Google Play Data Safety guidance"

**Prepared by:** Manus AI
