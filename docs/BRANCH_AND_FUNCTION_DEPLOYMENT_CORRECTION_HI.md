# Branch और Appwrite Function Deployment Correction

**महत्वपूर्ण correction:** Bhasha Keyboard में दो अलग चीज़ों को एक जैसा नहीं समझना है:

1. Android/Flutter application की production source branch।
2. Appwrite Functions की Git deployment branch।

## वर्तमान संबंध

दो Functions पहले इस branch से deploy किए गए थे:

```text
feat/secure-cloud-linked-documents
```

Functions:

```text
drive-gateway = 6aa12c14001ddeb260df
ai-gateway    = 6aa13043002cddfbdc72
```

इन Functions की Appwrite settings में सम्भवतः यह configured है:

```text
Production branch: feat/secure-cloud-linked-documents
```

इसका अर्थ है कि उस branch को delete, rename या force-reset करने पर future Function deployments प्रभावित हो सकते हैं। इसलिए branch को अभी delete नहीं करना है।

## Current main स्थिति

Latest branch audit के अनुसार secure document, gateway, dashboard, theme और IME code `origin/main` में merge हो चुका है। इसलिए application release validation के लिए अब `main` production integration base है।

लेकिन इसका अर्थ यह नहीं है कि Functions की Appwrite Git branch अपने-आप `main` हो गई है। Appwrite Console में Function-level branch setting अलग से बदलनी पड़ती है।

## सुरक्षित विकल्प

### Option A — अभी recommended

Functions को अभी भी इस branch से चलने दें:

```text
feat/secure-cloud-linked-documents
```

और इस branch को कम-से-कम Play Store public release स्वीकार होने तक रखें। इससे deployed Function source और existing Appwrite configuration में कोई अचानक break नहीं होगा। App app source के लिए `main` validate किया जा सकता है, लेकिन Function branch को बिना migration के delete नहीं करना है।

### Option B — बाद में migration

जब `main` पर final release commit freeze हो जाए, तब दोनों Functions को धीरे-धीरे `main` branch पर switch करें:

1. पहले verify करें कि `main` में ये files मौजूद हैं:
   - `functions/drive-gateway/index.js`
   - `functions/drive-gateway/package.json`
   - `functions/ai-gateway/index.js`
   - `functions/ai-gateway/package.json`
2. `drive-gateway` में Production branch को `main` करें।
3. Root directory वही रखें: `functions/drive-gateway`.
4. Entrypoint वही रखें: `index.js`.
5. Build command वही रखें: `npm install`.
6. Environment variables को दोबारा verify करें; secrets बदलने की जरूरत नहीं है।
7. Deploy करें और Function logs में successful deployment देखें।
8. पहले Drive metadata/list/link/unlink test करें।
9. फिर `ai-gateway` को उसी तरीके से `main` पर switch करें।
10. Gemini/Tavily test करें।
11. दोनों Functions के stable होने के बाद ही feature branch archive/delete पर विचार करें।

Function IDs आम तौर पर वही रह सकते हैं क्योंकि existing Function को update किया जा रहा है। नया Function बनाकर पुराने IDs replace करने की जरूरत नहीं है।

## अभी क्या नहीं करना है

- `feat/secure-cloud-linked-documents` delete नहीं करना है।
- Appwrite में Function को नया ID देकर duplicate Function नहीं बनाना है।
- Function root directory को repository root `./` नहीं करना है।
- `main.dart` को Node Function entrypoint नहीं बनाना है।
- Appwrite API keys या provider keys branch में commit नहीं करनी हैं।
- `main` और feature branch को blind merge नहीं करना है।

## Next AI के लिए exact instruction

> Bhasha Keyboard में application source और Appwrite Function deployment branch अलग हो सकती हैं। `origin/main` current integration base है, लेकिन `drive-gateway` और `ai-gateway` पहले `feat/secure-cloud-linked-documents` से deploy किए गए हैं। जब तक दोनों Functions को Appwrite Console में safely `main` पर migrate और test नहीं किया जाता, feature branch delete या reset मत करना। Existing Function IDs preserve करो। Root directories `functions/drive-gateway` और `functions/ai-gateway`, entrypoint `index.js`, और build command `npm install` बनाए रखो। पहले branch mapping और Function settings verify करो, फिर ही migration करो।

## Release decision

अभी सुरक्षित स्थिति यह है:

```text
Application release validation base: origin/main
Appwrite Function deployment source: feat/secure-cloud-linked-documents
Feature branch: preserve; do not delete yet
```

यह arrangement production में चल सकता है, लेकिन release documentation में इसे स्पष्ट रखना जरूरी है। Final release के बाद branch consolidation तभी करें जब दोनों Functions `main` से redeploy होकर successfully tested हों।
