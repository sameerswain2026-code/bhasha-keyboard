# Bhasha Keyboard Device QA Evidence

**Version:** 1.0.0+1
**Tester:** ____________________
**Date:** ____________________
**CI run:** ____________________

## Devices

| Device | Android version | Build/API | Result | Evidence |
|---|---|---|---|---|
| Newer device | 13 or newer | | | |
| Older supported device | API 23 or newer | | | |

## Test matrix

| ID | Scenario | Expected result | Pass/Fail | Notes/evidence |
|---|---|---|---|---|
| IME-01 | Enable and select Bhasha Keyboard | Keyboard appears in system input method picker | | |
| IME-02 | Type in WhatsApp | Text, cursor, backspace, enter work | | |
| IME-03 | Type in browser and Gmail | Text works in third-party fields | | |
| HAP-01 | Press letter and backspace in third-party app | Native vibration is felt when enabled | | |
| LANG-01 | Select each supported language in Native mode | Keycaps use the selected script | | |
| LANG-02 | Select each supported language in Roman mode | Latin keycaps and transliteration work | | |
| TRN-01 | English to Odia | Target keyboard and output are Odia | | |
| TRN-02 | Telugu to Odia | Target keyboard and output are Odia | | |
| TRN-03 | Odia to Telugu | Target keyboard and output are Telugu | | |
| VOICE-01 | Start, speak, stop, send, back, timeout | Mic session closes on each action | | |
| MEDIA-01 | Insert GIF and sticker in supported app | Rich content is attached, not a URL label | | |
| MEDIA-02 | Insert media in unsupported app | Picker or share fallback opens | | |
| AUTH-01 | Google sign-in success and cancellation | Clear success/cancel state, no stuck screen | | |
| DOC-01 | Link, label, and move a document | Only metadata/reference is stored | | |
| DOC-02 | Voice command with biometric/PIN | Authentication precedes attachment | | |
| DOC-03 | Three failed authentication attempts | 15-minute lockout appears | | |
| DOC-04 | Unlink document | Local URI permission and remote metadata are removed | | |
| A11Y-01 | TalkBack and large font | Labels, focus, touch targets, and contrast are usable | | |
| REL-01 | Reinstall and relaunch | Setup and keyboard state recover correctly | | |

## Sign-off

**Tester signature:** ____________________
**Release owner:** ____________________
**Known issues accepted:** ____________________

**Rule:** Do not mark a scenario passed from emulator-only observation when it depends on device haptics, biometric prompts, vendor keyboard behavior, or another installed application.
