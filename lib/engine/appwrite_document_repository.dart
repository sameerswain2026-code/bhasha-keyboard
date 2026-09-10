/// Appwrite-backed identity and document-reference storage.
///
/// This module stores metadata only. Google tokens, OAuth client secrets,
/// document bytes, and password peppers belong in server-side Functions.
library;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

import '../config/cloud_config.dart';
import 'appwrite_gateway_client.dart';
import 'document_manager.dart';

class DriveItem {
  const DriveItem({
    required this.id,
    required this.name,
    required this.mimeType,
    this.webViewLink,
    this.modifiedTime,
    this.size,
    this.parents = const [],
  });

  factory DriveItem.fromJson(Map<dynamic, dynamic> json) => DriveItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Untitled',
    mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
    webViewLink: json['webViewLink']?.toString(),
    modifiedTime: DateTime.tryParse(json['modifiedTime']?.toString() ?? ''),
    size: int.tryParse(json['size']?.toString() ?? ''),
    parents:
        (json['parents'] as List?)?.map((value) => value.toString()).toList() ??
        const [],
  );

  final String id;
  final String name;
  final String mimeType;
  final String? webViewLink;
  final DateTime? modifiedTime;
  final int? size;
  final List<String> parents;

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';
}

class AppwriteDocumentRepository {
  AppwriteDocumentRepository({Client? client, AppwriteGatewayClient? gateway})
    : _client = client ?? _newClient() {
    _account = Account(_client);
    _tables = TablesDB(_client);
    _gateway = gateway ?? AppwriteGatewayClient(client: _client);
  }

  static Client _newClient() => Client()
    ..setEndpoint(CloudConfig.endpoint)
    ..setProject(CloudConfig.projectId);

  final Client _client;
  late final Account _account;
  late final TablesDB _tables;
  late final AppwriteGatewayClient _gateway;

  Future<models.User?> currentUser() async {
    try {
      return await _account.get();
    } catch (_) {
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    final success = CloudConfig.oauthSuccessUrl.trim();
    final failure = CloudConfig.oauthFailureUrl.trim();
    // Appwrite's Flutter mobile flow returns through the SDK deep-link
    // handler. Explicit success/failure URLs are web-only; passing empty
    // strings causes the provider to reject the request as a missing URL.
    await _account.createOAuth2Session(
      provider: enums.OAuthProvider.google,
      success: success.isEmpty ? null : success,
      failure: failure.isEmpty ? null : failure,
      scopes: const ['https://www.googleapis.com/auth/drive.file'],
    );
  }

  Future<void> connectDrive() async {
    if (!CloudConfig.driveGatewayConfigured) {
      throw StateError('Drive gateway is not configured');
    }
    await _gateway.callDrive(action: 'connect');
  }

  Future<void> signOut() async {
    if (CloudConfig.driveGatewayConfigured) {
      try {
        await _gateway.callDrive(action: 'revoke');
      } catch (_) {
        // Local sign-out must remain available when Google is offline or
        // access was already revoked. A later account reconnect can retry.
      }
    }
    await _account.deleteSession(sessionId: 'current');
  }

  Future<void> deleteAccountAndCloudData() async {
    if (!CloudConfig.driveGatewayConfigured) {
      throw StateError('Account deletion service is not configured');
    }
    final user = await _account.get();
    if (CloudConfig.databaseConfigured) {
      while (true) {
        final page = await _tables.listRows(
          databaseId: CloudConfig.databaseId,
          tableId: CloudConfig.documentLinksCollectionId,
          queries: [Query.equal('userId', user.$id), Query.limit(100)],
        );
        if (page.rows.isEmpty) break;
        for (final row in page.rows) {
          await _tables.deleteRow(
            databaseId: CloudConfig.databaseId,
            tableId: CloudConfig.documentLinksCollectionId,
            rowId: row.$id,
          );
        }
        if (page.rows.length < 100) break;
      }
    }
    await _gateway.callDrive(
      action: 'delete-account',
      body: {'confirmation': user.$id},
    );
  }

  Future<List<DriveItem>> listDriveItems({
    String? parentId,
    String query = '',
  }) async {
    final response = await _gateway.callDrive(
      action: query.trim().isEmpty ? 'list' : 'search',
      body: {
        if (parentId != null) 'parentId': parentId,
        if (query.trim().isNotEmpty) 'query': query.trim(),
      },
    );
    final files = response?['files'];
    if (files is! List) return const [];
    return files
        .whereType<Map>()
        .map((file) => DriveItem.fromJson(file))
        .where((file) => file.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<DriveItem> createDriveFolder(String name, {String? parentId}) async {
    final response = await _gateway.callDrive(
      action: 'folder',
      body: {'name': name, if (parentId != null) 'parentId': parentId},
    );
    final folder = response?['folder'];
    if (folder is! Map) throw const FormatException('Drive returned no folder');
    return DriveItem.fromJson(folder);
  }

  Future<DriveItem> createDriveDocument(String name, {String? parentId}) async {
    final response = await _gateway.callDrive(
      action: 'create-document',
      body: {'name': name, if (parentId != null) 'parentId': parentId},
    );
    final file = response?['file'];
    if (file is! Map) throw const FormatException('Drive returned no document');
    return DriveItem.fromJson(file);
  }

  Future<models.Row?> addDriveItemToAi(DriveItem item) async {
    if (!CloudConfig.databaseConfigured) {
      throw StateError('Appwrite database is not configured');
    }
    final user = await _account.get();
    final existing = await _tables.listRows(
      databaseId: CloudConfig.databaseId,
      tableId: CloudConfig.documentLinksCollectionId,
      queries: [
        Query.equal('userId', user.$id),
        Query.equal('driveFileId', item.id),
        Query.limit(1),
      ],
    );
    if (existing.rows.isNotEmpty) return existing.rows.first;
    final reference = LinkedDocument(
      id: item.id,
      label: item.name,
      groupName: item.isFolder ? item.name : 'Drive',
      driveFileId: item.id,
      driveFolderId: item.isFolder ? item.id : '',
      displayName: item.name,
      uri: 'drive://${item.id}',
      mimeType: item.mimeType,
      linkedAt: DateTime.now().toUtc(),
    );
    return saveReference(
      document: reference,
      driveFileId: item.id,
      driveFolderId: item.isFolder ? item.id : null,
      groupName: reference.groupName,
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

  Future<models.Row?> updateReference(LinkedDocument document) async {
    if (!CloudConfig.databaseConfigured || document.remoteRowId.isEmpty) {
      return null;
    }
    return _tables.updateRow(
      databaseId: CloudConfig.databaseId,
      tableId: CloudConfig.documentLinksCollectionId,
      rowId: document.remoteRowId,
      data: {
        'label': document.label,
        'groupName': document.groupName,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Client get client => _client;
}
