/// Appwrite-backed identity and document-reference storage.
///
/// This module stores metadata only. Google tokens, OAuth client secrets,
/// document bytes, and password peppers belong in server-side Functions.
library;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

import '../config/cloud_config.dart';
import 'document_manager.dart';

class AppwriteDocumentRepository {
  AppwriteDocumentRepository({Client? client})
      : _client = client ?? _newClient() {
    _account = Account(_client);
    _tables = TablesDB(_client);
  }

  static Client _newClient() => Client()
    ..setEndpoint(CloudConfig.endpoint)
    ..setProject(CloudConfig.projectId);

  final Client _client;
  late final Account _account;
  late final TablesDB _tables;

  Future<models.User?> currentUser() async {
    try {
      return await _account.get();
    } on AppwriteException {
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    if (CloudConfig.oauthSuccessUrl.isEmpty ||
        CloudConfig.oauthFailureUrl.isEmpty) {
      throw StateError('Appwrite OAuth redirect URLs are not configured');
    }
    await _account.createOAuth2Session(
      provider: enums.OAuthProvider.google,
      success: CloudConfig.oauthSuccessUrl,
      failure: CloudConfig.oauthFailureUrl,
    );
  }

  Future<models.Row?> saveReference({
    required LinkedDocument document,
    required String driveFileId,
    String? driveFolderId,
    String? groupName,
  }) async {
    if (!CloudConfig.databaseConfigured) {
      throw StateError('Appwrite database is not configured');
    }
    final user = await _account.get();
    return _tables.createRow(
      databaseId: CloudConfig.databaseId,
      tableId: CloudConfig.documentLinksCollectionId,
      rowId: ID.unique(),
      permissions: [
        Permission.read(Role.user(user.$id)),
        Permission.update(Role.user(user.$id)),
        Permission.delete(Role.user(user.$id)),
      ],
      data: {
        'userId': user.$id,
        'driveFileId': driveFileId,
        'driveFolderId': driveFolderId,
        'label': document.label,
        'groupName': groupName,
        'driveUri': document.uri,
        'displayName': document.displayName,
        'mimeType': document.mimeType,
        'lockStatus': 'unlocked',
        'failedAttempts': 0,
        'createdAt': document.linkedAt.toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> deleteReference(String documentId) async {
    if (!CloudConfig.databaseConfigured) return;
    await _tables.deleteRow(
      databaseId: CloudConfig.databaseId,
      tableId: CloudConfig.documentLinksCollectionId,
      rowId: documentId,
    );
  }

  Client get client => _client;
}
