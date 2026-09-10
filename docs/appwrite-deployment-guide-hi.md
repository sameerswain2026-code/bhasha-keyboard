# Appwrite setup guide — Bhasha Keyboard

यह guide उस Appwrite स्क्रीन के लिए है जिसमें **Create function** लिखा हुआ है। इस setup में दो अलग Functions बनानी हैं। Root में एक ही Function `bhasha-keyboard` मत बनाइए।

## पहले: `google-drive-tokens` table बनाइए

1. Appwrite Console खोलें।
2. अपना project खोलें: **GitHub Student Organization / Bhasha Keyboard**.
3. **Databases** खोलें।
4. **Bhasha Keyboard Database** खोलें।
5. **Create table** दबाएँ।
6. Table name और ID दोनों रखें: `Google Drive Tokens` / `google-drive-tokens`.
7. Table permissions में public/all-users permission न दें। Row security या document security enabled रखें।
8. ये columns बनाइए:

| Column name | Type | Required | Size |
|---|---|---:|---:|
| `userId` | String | Yes | 128 |
| `refreshToken` | String | Yes | 4096 |
| `updatedAt` | Datetime | Yes | — |

`refreshToken` में app केवल encrypted value रखेगा। Document PDF, image, Aadhaar, resume या कोई file bytes इस table में कभी नहीं जाएँगे।

## दूसरा: Function 1 — `drive-gateway`

Screenshot वाली **Create function** screen में ये values डालें:

| Screen field | Value |
|---|---|
| Repository | `sameerswain2026-code/bhasha-keyboard` |
| Name | `drive-gateway` |
| Runtime | `Node.js 22` |
| CPU and memory | Default `2 CPU, 2048 MB RAM` ठीक है |
| Entrypoint | `index.js` |
| Production branch | `feat/secure-cloud-linked-documents` |
| Root directory | `functions/drive-gateway` |

**Root directory बहुत महत्वपूर्ण है।** `./` या repository root न रखें। `functions/drive-gateway` ही रखें।

### Execute access

**Execute access** खोलें और केवल authenticated users/users access चुनें। Anonymous/public access न चुनें। Function request में Appwrite user session का JWT लगेगा।

### Environment variables

**Environment variables → Add variable** में ये नाम डालें:

```text
APPWRITE_ENDPOINT=https://nyc.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=6a7fc74a001f50afe9e5
APPWRITE_API_KEY=<Appwrite server API key>
APPWRITE_DATABASE_ID=bhasha-db
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID=document-links
GOOGLE_CLIENT_ID=<Google OAuth client ID>
GOOGLE_CLIENT_SECRET=<Google OAuth client secret>
GOOGLE_TOKEN_ENCRYPTION_SECRET=<32-byte base64 secret>
```

`APPWRITE_API_KEY`, Google client secret और encryption secret किसी chat, GitHub file या APK में न डालें। इन्हें केवल Appwrite Function environment में डालें।

### Encryption secret बनाना

Windows PowerShell में यह चलाएँ:

```powershell
$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

जो एक लंबी base64 value मिले, वही `GOOGLE_TOKEN_ENCRYPTION_SECRET` की value है। इसे सुरक्षित password manager में रखें। मुझे यह value भेजने की जरूरत नहीं है।

फिर **Deploy** दबाएँ। Deploy पूरा होने के बाद Function का ID copy करें। यह secret नहीं है।

## तीसरा: Function 2 — `ai-gateway`

फिर दोबारा **Functions → Create function** खोलें।

| Screen field | Value |
|---|---|
| Repository | `sameerswain2026-code/bhasha-keyboard` |
| Name | `ai-gateway` |
| Runtime | `Node.js 22` |
| CPU and memory | Default `2 CPU, 2048 MB RAM` ठीक है |
| Entrypoint | `index.js` |
| Production branch | `feat/secure-cloud-linked-documents` |
| Root directory | `functions/ai-gateway` |

Execute access में authenticated users/users चुनें। Anonymous access न दें।

### AI Function environment variables

```text
APPWRITE_ENDPOINT=https://nyc.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=6a7fc74a001f50afe9e5
GEMINI_API_KEYS=<comma-separated Gemini keys>
SARVAM_API_KEYS=<comma-separated Sarvam keys>
TAVILY_API_KEYS=<comma-separated Tavily keys>
```

Provider API keys केवल Function environment में रखें। APK build में इन keys को `--dart-define` से न डालें।

Deploy के बाद `ai-gateway` Function ID copy करें।

## चौथा: GitHub repository variables

GitHub repository खोलें:

`Settings → Secrets and variables → Actions → Variables`

**Secrets में नहीं, Variables tab में** ये दो entries बनाइए:

```text
APPWRITE_DRIVE_GATEWAY_FUNCTION_ID=<drive-gateway Function ID>
APPWRITE_AI_GATEWAY_FUNCTION_ID=<ai-gateway Function ID>
```

इनकी values Function IDs होंगी, API keys नहीं।

## पाँचवाँ: Google OAuth और Appwrite

1. Appwrite में **Auth → Settings → Providers → Google** खोलें।
2. Google provider enable करें।
3. Google Cloud Console में वही OAuth client खोलें।
4. Appwrite द्वारा दिखाया गया exact callback URL Google Cloud के **Authorized redirect URIs** में डालें।
5. Android platform package name रखें:

```text
com.bhashakeyboard.ime
```

6. Release SHA-256 fingerprint और development/debug SHA-256 fingerprint add करें।
7. Google Drive API enable करें।
8. Scope केवल `drive.file` रखें।

Android build के लिए `APPWRITE_OAUTH_SUCCESS_URL` और `APPWRITE_OAUTH_FAILURE_URL` खाली रखे जा सकते हैं। Mobile SDK deep-link callback का उपयोग करेगा।

## छठा: GitHub Actions build

Function IDs GitHub Variables में भरने के बाद feature branch पर नया build चलाएँ। Successful build में:

- `flutter analyze` pass होना चाहिए।
- `flutter test` pass होना चाहिए।
- signed APK बनना चाहिए।
- signed AAB बनना चाहिए।

## Security check

Deploy के बाद यह verify करें:

- Function logs में token, password, prompt, transcript या file bytes नहीं दिखते।
- Appwrite Storage में document files नहीं हैं।
- `google-drive-tokens` में केवल encrypted refresh-token metadata है।
- `document-links` में केवल metadata/reference है।
- Anonymous Function execution disabled है।
- Provider keys APK/AAB में नहीं हैं।

## महत्वपूर्ण limitation

Current Sarvam live speech integration long-lived WebSocket उपयोग करती है। `ai-gateway` HTTP requests proxy करता है, लेकिन public Sarvam streaming के लिए WebSocket relay अभी अलग से चाहिए। जब तक relay deploy न हो, Sarvam API key को public APK में डालकर release न करें।
