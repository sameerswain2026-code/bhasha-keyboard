# Production setup boundary

The Android app contains only public Appwrite project configuration. It must never contain Appwrite API keys, Google OAuth client secrets, Google refresh tokens, service-account private keys, password peppers, or provider API keys.

## Public build variables

```text
APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID
APPWRITE_DATABASE_ID
APPWRITE_DOCUMENT_LINKS_COLLECTION_ID
APPWRITE_OAUTH_SUCCESS_URL
APPWRITE_OAUTH_FAILURE_URL
```

## Server-side Function variables

These belong only in Appwrite Function environment variables or another secure server runtime:

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

## Required Functions

The production document flow requires authenticated Functions for Google OAuth exchange and refresh, Drive file/folder metadata, unlink/revoke, document-password verification, and atomic failed-attempt locking. Document bytes must not be written to Appwrite Storage or the Bhasha backend. The Android client stores only references and metadata in the `document_links` collection.

## Current repository status

The client boundary and Appwrite Auth/metadata adapter are present in `CloudConfig` and `AppwriteDocumentRepository`. Console resources and Function deployment remain external provisioning steps because the Appwrite dashboard session did not expose project controls during setup. No credentials are committed in this repository.
