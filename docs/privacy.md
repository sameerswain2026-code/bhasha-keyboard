# Privacy notes

Bhasha Keyboard processes typed text locally for core keyboard behavior. Voice typing requires microphone permission and may send audio or transcripts to the configured speech provider when the user activates that feature. Optional AI and search features send only the requested prompt or query through the authenticated provider gateway when enabled.

Linked documents remain in the user's selected Google Drive or Android document provider. Bhasha stores only a provider reference, display metadata, label, group, lock state, and timestamps. It does not store document bytes in Appwrite Storage or on Bhasha servers. Google Drive access can be unlinked and revoked by the user.

The application should not log passwords, typed text, clipboard contents, audio, API credentials, document bytes, or provider responses. A production distribution must publish a complete privacy policy, disclose Appwrite, Google Drive, Gemini, Sarvam, and Tavily use and retention periods, provide account/data deletion instructions, and provide a support contact before enabling network-backed features.
