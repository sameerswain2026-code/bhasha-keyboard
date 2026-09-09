import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;

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
    if (result.status != enums.ExecutionStatus.completed ||
        result.responseBody.isEmpty) {
      throw StateError('AI gateway execution did not complete');
    }
    final decoded = jsonDecode(result.responseBody);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('AI gateway returned an invalid response');
    }
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  /// Calls the server-side Drive workflow. The client receives metadata or a
  /// status object only; OAuth refresh tokens and document bytes stay server
  /// side.
  Future<Map<String, dynamic>?> callDrive({
    required String action,
    Map<String, dynamic> body = const <String, dynamic>{},
  }) async {
    if (!CloudConfig.driveGatewayConfigured) return null;
    final result = await _functions.createExecution(
      functionId: CloudConfig.driveGatewayFunctionId,
      body: jsonEncode(<String, dynamic>{'action': action, ...body}),
      xasync: false,
    );
    if (result.status != enums.ExecutionStatus.completed ||
        result.responseBody.isEmpty) {
      throw StateError('Drive gateway execution did not complete');
    }
    final decoded = jsonDecode(result.responseBody);
    if (decoded is! Map) {
      throw const FormatException('Drive gateway returned an invalid response');
    }
    final data = decoded['data'];
    return Map<String, dynamic>.from(data is Map ? data : decoded);
  }
}
