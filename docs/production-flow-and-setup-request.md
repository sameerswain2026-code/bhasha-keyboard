# Bhasha Keyboard: End-to-End Screen Flow, Feature Map, and Production Setup Request

## Executive summary

Bhasha Keyboard में दो अलग runtime flows हैं। **Companion app flow** installation के बाद onboarding, keyboard setup और demo editor दिखाता है। **Android IME flow** किसी भी host app के text field के ऊपर keyboard surface दिखाता है और typed text को `InputConnection` के माध्यम से host app में भेजता है। Web preview में Android system settings उपलब्ध नहीं होने के कारण सीधे demo editor खुलता है।

Automated build pipeline production APK और AAB बना सकता है और Flutter analyze तथा tests सफल हैं। फिर भी आज ही public production release को end-to-end complete कहने के लिए Appwrite Functions, secure provider backend, Google OAuth configuration, real-device testing और Play Console gates पूरे करना आवश्यक है। इन external dependencies के बिना local keyboard features चलेंगे, लेकिन Google Drive, cloud documents और network AI/voice features को production-complete नहीं कहा जा सकता।

## 1. Installation से पहला screen

| क्रम | Screen या state | User action | अगला परिणाम | वर्तमान स्थिति |
|---|---|---|---|---|
| 1 | Android installer / Play Store | APK या AAB install करता है | `MainActivity` शुरू होती है | Implemented |
| 2 | First-run decision | App `welcome_flow_seen` preference पढ़ता है | पहली बार Welcome flow; बाद में Demo Editor | Implemented |
| 3 | Welcome: Brand page | `Next` दबाता है | Features page | Implemented |
| 4 | Welcome: Features page | `Next` या `Skip` दबाता है | Get Started page | Implemented |
| 5 | Welcome: Get Started | `Continue with Google` दबाता है | Appwrite Google OAuth browser/deep-link flow | Partial; Appwrite Google provider और OAuth setup आवश्यक |
| 6 | Welcome: Get Started | `Set up keyboard later` या `Continue as guest` दबाता है | Setup flow या Demo Editor | Implemented |
| 7 | Welcome: Get Started | `Open dashboard` दबाता है | Companion app का Demo Editor | Implemented; अभी पूर्ण account dashboard नहीं |

### Welcome screens का व्यवहार

**Brand page** पर “Your voice. Every language.” संदेश और Bhasha branding आती है। **Features page** पर 22 languages, voice-first typing और protected document sharing की जानकारी आती है। **Get Started page** पर Google sign-in, keyboard setup और guest continuation के विकल्प आते हैं। `Skip` सीधे तीसरे page पर जाता है। पहली बार flow पूरा होने के बाद preference save होती है और अगली बार Welcome flow नहीं दिखता।

## 2. Keyboard setup flow

Setup flow Welcome screen से `Set up keyboard later` दबाने पर खुलता है। इसे बाद में keyboard toolbar के **Settings** panel से भी खोला जा सकता है। Screen lifecycle resume होने पर status दोबारा पढ़ा जाता है, इसलिए user Android Settings से लौटने के बाद वास्तविक state देखता है।

| क्रम | Setup step | Button | Android action | Done state |
|---|---|---|---|---|
| 1 | Enable the keyboard | `Open settings` | Android Input Method settings खोलता है | “Enabled in system settings” |
| 2 | Select as active keyboard | `Choose keyboard` | System keyboard picker खोलता है | “Bhasha Keyboard is the active input method” |
| 3 | Allow microphone access | `Grant permission` | `RECORD_AUDIO` permission request करता है | “Voice typing is ready” |
| Optional | Connect Google | `Connect Google` | Appwrite Google OAuth शुरू करता है | Cloud account connected |
| End | Setup footer | `Continue` / `Try it now` / `Skip for now` | Companion app पर लौटता है | Demo Editor |

Setup complete होने पर `Try it now` और `Continue` उपलब्ध होते हैं। Setup अधूरा हो तो `Skip for now` से app चलती है; typing demo में काम कर सकती है, लेकिन system-wide keyboard के लिए पहले दो steps आवश्यक हैं। Microphone केवल voice typing के लिए आवश्यक है।

## 3. Companion app का Demo Editor

Demo Editor में ऊपर Bhasha Keyboard title, supported-language label और “22 Indian languages · Voice · Emoji · GIF” subtitle आते हैं। बीच में read-only text editor है, जिसमें keyboard से text insert होता है। `Clear` editor text साफ करता है। नीचे वही `KeyboardView` आती है जो Android IME में भी उपयोग होती है।

Android पर system keyboard use करने के लिए user किसी दूसरे app का text field खोलता है। Bhasha IME उसी host field में काम करती है। Companion app का editor केवल local demonstration और setup verification के लिए है; यह पूर्ण account dashboard नहीं है।

## 4. Default keyboard screen

Keyboard का idle layout fixed-height IME surface के लिए बनाया गया है। सामान्य state में ऊपर toolbar और नीचे key rows दिखती हैं। Panel खुलने पर toolbar छिप जाता है और panel पूरे keyboard height में फैल जाता है। Panel transitions छोटे fade/slide animation से आते हैं।

### Toolbar से उपलब्ध controls

| Control | Click करने पर | अगली state |
|---|---|---|
| Current language label | Language panel खोलता है | Language selection |
| Suggestions row | Suggested word को current word की जगह apply करता है | Updated host text |
| Mic indicator | Voice capture शुरू/रोकता है | Transcribe, Translate या Auto-mix state |
| Mic language/mode control | Voice language/style या mic mode configuration खोलता है | Transcribe Language या Translate Config panel |
| Menu / tools icon | Tools grid खोलता है | Menu panel |
| Backspace | Host text से character/word हटाता है | Updated host text |
| Enter/action key | Host editor action चलाता है | Next/done/search/send behavior host field पर निर्भर |
| Space | Space या Roman transliteration commit करता है | Updated host text |
| Shift/caps | Case state बदलता है | Key labels बदलते हैं |
| Globe/language key | Language या script switch | Current language/script बदलता है |

Text insertion में controller और Android `ImeBridge` host selection, cursor position, deletion, composing text और surrogate pairs संभालते हैं। Host app के वास्तविक selected text के बिना clipboard को selected text मानकर overwrite नहीं किया जाता।

## 5. Language panel flow

**Toolbar language control** दबाने पर Language panel खुलता है। ऊपर back button और search field आते हैं। Language list में supported Indian languages और English metadata दिखता है। किसी language पर tap करने पर language set होती है और panel बंद होकर keyboard वापस आता है।

Language panel में script mode भी मिलता है:

- **Native**: native script keycaps और native output।
- **Roman**: Latin keycaps से transliteration और Roman output behavior।
- **Translate output configuration**: speech या typing translation का source/target behavior अलग panel से तय होता है।

Language registry में 22 language entries और layouts मौजूद हैं। प्रत्येक language के characters, signs, punctuation और physical-device behavior को अलग device matrix पर validate करना बाकी है।

## 6. Tools menu और उसके बाद आने वाले सभी panels

Toolbar का Tools/Menu button दबाने पर चार-column grid खुलता है। हर tile या तो panel खोलती है या inline toggle करती है। सभी panels में back button keyboard पर लौटाता है।

### 6.1 Theme

`Theme` दबाने पर Theme panel खुलता है। Theme चुनने पर keyboard colors, key backgrounds, accents और panel appearance बदलते हैं तथा preference में save होते हैं। Current theme system मौजूद है, लेकिन requested 30-theme product catalog, complete previews और final branded assets अभी बाकी हैं।

### 6.2 Documents

`Documents` दबाने पर Documents panel खुलता है। Local document picker से PDF, Word, text और images चुनने की तैयारी उपलब्ध है। Document attach/share action से पहले device credential authentication माँगी जाती है। Authentication सफल होने पर supported editors में `commitContent` और unsupported editors में picker/share fallback उपयोग होता है। तीन failed attempts के बाद local 15-minute lockout लागू होता है। Unlink local URI permission हटाता है और metadata row delete करने का प्रयास करता है।

Cloud Documents के लिए अभी ये server-side steps आवश्यक हैं:

1. Google OAuth exchange और refresh Function।
2. Drive metadata/list/create/link Function।
3. Unlink/revoke Function।
4. Document password verification Function।
5. Atomic server-side failed-attempt lockout।
6. User-scoped Appwrite collection permissions।

जब तक ये Functions deployed और non-owner account से tested नहीं हैं, UI को production Google Drive service नहीं माना जाना चाहिए।

### 6.3 Manual Translate

`Manual Translate` दबाने पर source text workspace खुलता है। User source language और target language चुनता है, mini keyboard से text लिखता है, फिर Translate action दबाता है। Result preview आता है। Result को copy किया जा सकता है या active host field में insert किया जा सकता है। Provider unavailable, timeout और retry behavior को production backend के साथ validate करना बाकी है।

### 6.4 GIF

`GIF` दबाने पर GIF panel खुलता है। Search field और categories से GIF खोजे जाते हैं। GIF चुनने पर keyboard host app में content commit/share करने का प्रयास करता है। Host app support न करे तो fallback share/picker path आता है। Provider availability, licensing, network timeout और target-app matrix की production validation बाकी है।

### 6.5 Sticker

`Sticker` दबाने पर local sticker catalog panel खुलता है। Sticker tap करने पर content host app में insert/share होता है। Asset licensing और target-editor compatibility को release से पहले verify करना आवश्यक है।

### 6.6 Emoji

`Emoji` दबाने पर category tabs और search field वाला emoji panel खुलता है। Emoji tap करते ही active text field में insert होता है। Category बदलने पर grid update होती है। Back button keyboard पर लौटाता है।

### 6.7 Text Editing

`Text Editing` panel selected/host text पर editing tools देता है। Available writing actions में copy, cut, paste, select/delete और AI writing actions शामिल हैं। Action host selection उपलब्ध होने पर ही operate करता है। AI grammar correction, rewrite और tone actions secure backend proxy के बिना production-safe नहीं माने जा सकते।

### 6.8 Resize

`Resize` panel keyboard height/size preferences बदलता है। One-handed adjustment में inline control strip आती है। Resize icon दबाने पर drag handle और `Reset`/`Done` controls आते हैं। `Done` adjusted width save करता है।

### 6.9 Floating Keyboard

`Floating Keyboard` tile full-screen panel नहीं खोलती। यह keyboard को compact rounded card में बदलती है। Top drag handle से card move होती है। Dock/pin icon से default bottom position पर लौटती है। यह Flutter IME surface के भीतर floating behavior है; वास्तविक Android overlay window नहीं है।

### 6.10 One-Handed Mode

`One-Handed Mode` tile mode cycle करती है और keyboard को left या right side anchor करती है। Inline control strip से side switch, resize और exit options मिलते हैं। Resize overlay में drag handle, `Reset` और `Done` होते हैं।

## 7. Voice flow

Mic control दबाने पर configured `MicMode` के आधार पर तीन paths होते हैं:

| Mic mode | Input | Output |
|---|---|---|
| Transcribe | User speech | Same-language transcript host field में insert |
| Translate | User speech | Configured target language में translated output |
| Auto-mix | Speech and language heuristics | Detected route के अनुसार transcript/translation |

Mic permission denied होने पर error state आती है। Network/provider failure पर keyboard crash नहीं होना चाहिए; provider layer failure को safe error state में बदलती है। Voice partial text, listening state, timeout और final transcript toolbar status में दिखते हैं। Sarvam/provider backend keys public APK में नहीं होनी चाहिए।

### Voice configuration screens

**Transcribe Language panel** में speech language और Native/Roman output style चुनते हैं। Native language चुनने पर visible keyboard language/script भी synchronize होता है। **Translate Config panel** में source language, target language और output style चुनते हैं। Apply दबाने पर configuration save होती है और panel बंद होता है।

## 8. Clipboard flow

`Clipboard` panel में current selection/text copy करने का action, clipboard history और clear history action मिलता है। History item tap करने पर text host field में paste होता है। Clear history सभी stored entries हटाता है। Clipboard content device-local preference में रहता है; Play Data Safety और privacy policy में इस behavior को स्पष्ट करना होगा।

## 9. Settings flow

Tools या keyboard settings path से Settings panel खुलता है। Current settings groups में ये controls हैं:

| Setting | Effect |
|---|---|
| Keyboard setup | Android IME settings खोलता है |
| Switch to Bhasha Keyboard | System keyboard picker खोलता है |
| Microphone permission | Permission request करता है |
| Mic mode | Transcribe, Translate या Auto-mix चुनता है |
| AI Web Assistant | Wake-word assistant on/off करता है |
| Assistant name | Wake word बदलता है |
| Haptics | Key vibration on/off करता है |
| Sound | Key sound behavior on/off करता है |
| Editor action | Host editor action चुनता है |
| Theme | Theme panel खोलता है |
| Documents | Document panel खोलता है |

AI Web Assistant enabled होने पर configured wake word voice input में detect होता है। Normal speech pass-through रहती है। Wake word command web search path में जाती है और result summary वापस insert हो सकती है। Tavily/Gemini credentials public mobile build में नहीं होनी चाहिए। Current repository में account deletion, complete privacy controls, provider status dashboard और in-app support flow अभी incomplete हैं।

## 10. End-to-end feature availability matrix

| Feature | Local code | External setup | Production status |
|---|---|---|---|
| Native/Roman typing | Yes | Android IME enable/select | Ready for device validation |
| 22 language registry/layouts | Yes | Device matrix | Implemented, quality validation pending |
| Suggestions | Yes | None for local path | Implemented, language-quality tuning pending |
| Clipboard | Yes | None | Implemented, privacy copy/clear UX review pending |
| Emoji/stickers | Yes | Asset/licensing review | Implemented, target-app testing pending |
| GIF | Client path | Provider/config/licensing | Partial |
| Voice transcription | Client/provider architecture | Secure speech backend and mic/device tests | Partial |
| Voice translation | Client/provider architecture | Secure translation backend and language-pair tests | Partial |
| Manual translation | UI and engine | Provider backend or approved local coverage | Partial |
| AI writing tools | UI and engine | Secure AI proxy, quotas, prompt/data policy | Partial |
| AI web assistant | UI and routing | Secure Gemini/Tavily backend | Partial |
| Local document sharing | Yes | Android device credential | Implemented, device validation pending |
| Google Drive documents | Metadata adapter/UI | Appwrite Functions, Google OAuth, Drive config | Blocked until backend deployment |
| Themes | Yes | Final product catalog/assets | Partial |
| Onboarding | Yes | Final approved branding | Implemented, content finalization pending |
| Signed release | CI | Release secrets already configured | Build verified |
| Play production release | No | Play Console approval/forms/testing | External blocker |

## 11. Production release checklist

### A. Google Cloud setup

The owner should create or verify a Google Cloud project and OAuth consent configuration. The Android OAuth client must use package name `com.bhashakeyboard.ime` and the release certificate SHA-1/SHA-256 fingerprints. The exact Appwrite OAuth callback URL must be configured wherever Appwrite requires it. Google Drive scope should remain least-privilege `drive.file`.

Google client secret, refresh tokens and service-account private keys must not be sent in chat, committed to GitHub, or embedded in Flutter `--dart-define`. They belong in Appwrite Functions or another secured backend runtime.

### B. Appwrite setup

The owner needs to provide or configure:

| Item | Required value/action |
|---|---|
| Endpoint | Appwrite endpoint URL |
| Project | Production project ID |
| Android platform | Package `com.bhashakeyboard.ime` |
| Google provider | Enable OAuth2 Google provider |
| Database | Production database ID |
| Collection | `document_links` collection ID |
| Permissions | User-scoped read/update/delete permissions |
| Functions | OAuth, Drive metadata, unlink/revoke, password, lockout |
| Test account | Non-owner Google/Appwrite account |
| Secrets | Function environment variables only |

The required server-only variables are `APPWRITE_API_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_TOKEN_ENCRYPTION_SECRET`, `GEMINI_API_KEYS`, `SARVAM_API_KEYS`, `TAVILY_API_KEYS` and `DOCUMENT_PASSWORD_PEPPER`.

### C. Secure provider backend

Gemini, Sarvam and Tavily calls need a backend proxy or Appwrite Functions. The mobile client should call the proxy using authenticated short-lived access, not direct provider API keys. The backend needs authentication, per-user rate limits, timeout/retry policy, quota/error mapping, abuse prevention, request-size limits and a documented deletion/retention policy.

### D. Required owner-provided decisions

Before final release, the owner must confirm the official developer name, app logo, tagline, support email/URL, privacy policy URL, whether “30 skins” means keyboard themes or another catalog, supported language claims, provider availability wording, account deletion behavior and whether Google Drive is enabled in the first public build.

### E. Real-device release validation

At minimum, test one Android 13-or-newer device and one older supported Android device. Test system keyboard enable/select, WhatsApp, Telegram, browser text fields, standard forms, gesture and three-button navigation, rotation, process restart, low memory, dark mode, large text, TalkBack, microphone allow/deny/revoke, haptics, `commitContent` editors, fallback share editors, OAuth cancel/back flow, expired provider sessions and network loss.

### F. Play Console release

The release candidate requires a version increment from `1.0.0+1`, a tagged signed AAB, internal testing upload, privacy policy verification, Data Safety form, content rating, target-audience declaration, app-access instructions for reviewers, store listing assets, pre-launch report review and staged rollout. A successful GitHub build alone does not complete these gates.

## 12. Exact information needed from the owner

To proceed with production provisioning, provide configuration values through the agreed secure secret-management channel, not by pasting secret values into chat:

1. Production Appwrite endpoint, project ID, database ID and document-links collection ID.
2. Confirmation that Google OAuth provider is enabled in Appwrite.
3. Google Cloud project and OAuth client setup, including package/fingerprint registration.
4. Deployment access or Function configuration for Appwrite server-side Functions.
5. Secure backend endpoint for Gemini, Sarvam and Tavily, or authorization to deploy Appwrite Functions for these providers.
6. Approved branding: logo, official developer name, tagline, support contact and privacy policy URL.
7. Decision on whether Google Drive and AI provider features are enabled for the first release.
8. A non-owner test account for permission isolation testing.
9. Physical Android test devices or a device-lab access path.
10. Play Console access and approval status.

## Final release judgment

**Local keyboard release candidate:** automated checks and signed build are green. **Full public production release:** not yet honestly complete until the external setup and real-device gates above pass. The fastest safe route is to release a narrowly scoped first build with local typing, languages, suggestions, emoji, stickers, clipboard, themes and clearly labeled optional features, while keeping Google Drive and provider-backed AI/voice disabled or clearly marked unavailable until their secure backend validation is complete.

## References

[1]: https://developer.android.com/develop/ui/views/touch-and-input/creating-an-input-method "Android input method documentation"
[2]: https://support.google.com/googleplay/android-developer/answer/9859455 "Google Play app quality and release guidance"
[3]: https://support.google.com/googleplay/android-developer/answer/10787469 "Google Play Data safety section guidance"
[4]: https://cloud.google.com/docs/authentication "Google Cloud authentication guidance"
[5]: https://appwrite.io/docs/products/auth/oauth2 "Appwrite OAuth2 documentation"
[6]: https://appwrite.io/docs/products/functions "Appwrite Functions documentation"

---

**Prepared by:** Manus AI
**Repository:** `sameerswain2026-code/bhasha-keyboard`
**Latest verified code commit:** `befdc8c`
