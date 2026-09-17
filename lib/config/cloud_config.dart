/// Public AI gateway configuration only. Provider credentials never ship in the APK.
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
  static const aiGatewayFunctionId = String.fromEnvironment(
    'APPWRITE_AI_GATEWAY_FUNCTION_ID',
  );
  static bool get aiGatewayConfigured => aiGatewayFunctionId.isNotEmpty;
}
