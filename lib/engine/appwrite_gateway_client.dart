import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../config/cloud_config.dart';

/// Calls an Appwrite Function without exposing provider credentials to Flutter.
/// The Function receives the user's existing Appwrite session automatically.
class AppwriteGatewayClient {
  AppwriteGatewayClient({Client? client})
      : _functions = Functions(client ?? _newClient());

  static Client _newClient() => Client()
    ..setEndpoint(CloudConfig.endpoint)
    ..setProject(CloudConfig.projectId);

  final Functions _functions;

  Future<Map<String, dynamic>?> callAi({
    required String provider,
    required Map<String, dynamic> body,
    String? endpoint,
    String? model,
  }) async {
    if (!CloudConfig.aiGatewayConfigured) return null;
    final payload = <String, dynamic>{
      'provider': provider,
      'body': body,
      if (endpoint != null) 'endpoint': endpoint,
      if (model != null) 'model': model,
    };
    final result = await _functions.createExecution(
      functionId: CloudConfig.aiGatewayFunctionId,
      body: jsonEncode(payload),
      xasync: false,
    );
    if (result.status != 'completed' || result.responseBody.isEmpty) {
      throw StateError('AI gateway execution did not complete');
    }
    final decoded = jsonDecode(result.responseBody);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('AI gateway returned an invalid response');
    }
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }
}
