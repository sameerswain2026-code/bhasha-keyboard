/// Public cloud configuration only. Never place API keys, OAuth client
/// secrets, refresh tokens, or password peppers in this file or the APK.
library;

class CloudConfig {
  static const endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://nyc.cloud.appwrite.io/v1',
  );
  static const projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '6a7fc74a001f50afe9e5',
  );
  static const databaseId = String.fromEnvironment(
    'APPWRITE_DATABASE_ID',
    defaultValue: 'bhasha-db',
  );
  static const documentLinksCollectionId = String.fromEnvironment(
    'APPWRITE_DOCUMENT_LINKS_COLLECTION_ID',
    defaultValue: 'document-links',
  );
  static const driveGatewayFunctionId = String.fromEnvironment(
    'APPWRITE_DRIVE_GATEWAY_FUNCTION_ID',
  );
  static const aiGatewayFunctionId = String.fromEnvironment(
    'APPWRITE_AI_GATEWAY_FUNCTION_ID',
  );
  static const oauthSuccessUrl = String.fromEnvironment(
    'APPWRITE_OAUTH_SUCCESS_URL',
  );
  static const oauthFailureUrl = String.fromEnvironment(
    'APPWRITE_OAUTH_FAILURE_URL',
  );

  static bool get databaseConfigured =>
      databaseId.isNotEmpty && documentLinksCollectionId.isNotEmpty;

  static bool get aiGatewayConfigured => aiGatewayFunctionId.isNotEmpty;
  static bool get driveGatewayConfigured => driveGatewayFunctionId.isNotEmpty;
}
EOF
