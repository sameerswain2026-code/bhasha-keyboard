/// Appwrite-backed identity and document-reference storage.
///
/// This module stores metadata only. Google tokens, OAuth client secrets,
/// document bytes, and password peppers belong in server-side Functions.
library;

import 'package:appwrite/appwrite.dart';

import '../config/cloud_config.dart';
import 'document_manager.dart';

class AppwriteDocumentRepository {
  AppwriteDocumentRepository({Client? client})
      : _client = client ??
            (Client()
              ..setEndpoint(CloudConfig.endpoint)
              ..setProject(CloudConfig.projectId)),
        _account = Account(client ?? _newClient()),
        _databases = Databases(client ?? _newClient());

  static Client _newClient() => Client()
    ..setEndpoint(CloudConfig.endpoint)
    ..setProject(CloudConfig.projectId);

  final Client _client;
  late final Account _account;
  late final Databases _databases;

  Future<User?> currentUser() async {
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
      provider: OAuthProvider.google,
      success: Uri.parse(CloudConfig.oauthSuccessUrl),
      failure: Uri.parse(CloudConfig.oauthFailureUrl),
    );
  }

  Future<Document?> saveReference({
    required LinkedDocument document,
    required String driveFileId,
    String? driveFolderId,
    String? groupName,
  }) async {
    if (!CloudConfig.databaseConfigured) {
      throw StateError('Appwrite database is not configured');
    }
    final user = await _account.get();
    return _databases.createDocument(
      databaseId: CloudConfig.databaseId,
      collectionId: CloudConfig.documentLinksCollectionId,
      documentId: ID.unique(),
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
    await _databases.deleteDocument(
      databaseId: CloudConfig.databaseId,
      collectionId: CloudConfig.documentLinksCollectionId,
      documentId: documentId,
    );
  }

  Client get client => _client;
}
