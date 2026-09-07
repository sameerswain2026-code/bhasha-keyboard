/// Secure Cloud-Linked Document Management.
///
/// Only user-granted Android content URIs and minimal metadata are stored.
/// File bytes never pass through Bhasha or any application backend.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appwrite_document_repository.dart';

class LinkedDocument {
  final String id;
  final String label;
  final String groupName;
  final String driveFileId;
  final String driveFolderId;
  final String remoteRowId;
  final String displayName;
  final String uri;
  final String mimeType;
  final DateTime linkedAt;
  final String lockStatus;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const LinkedDocument({
    required this.id,
    required this.label,
    this.groupName = 'General',
    this.driveFileId = '',
    this.driveFolderId = '',
    this.remoteRowId = '',
    required this.displayName,
    required this.uri,
    required this.mimeType,
    required this.linkedAt,
    this.lockStatus = 'unlocked',
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  factory LinkedDocument.fromJson(Map<String, dynamic> json) => LinkedDocument(
        id: json['id'] as String? ?? json['uri'] as String? ?? '',
        label: json['label'] as String? ?? 'General',
        groupName: json['groupName'] as String? ?? 'General',
        driveFileId: json['driveFileId'] as String? ?? '',
        driveFolderId: json['driveFolderId'] as String? ?? '',
        remoteRowId: json['remoteRowId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Document',
        uri: json['uri'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        linkedAt: DateTime.tryParse(json['linkedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        lockStatus: json['lockStatus'] as String? ?? 'unlocked',
        failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
        lockedUntil: DateTime.tryParse(json['lockedUntil'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'groupName': groupName,
        'driveFileId': driveFileId,
        'driveFolderId': driveFolderId,
        'remoteRowId': remoteRowId,
        'displayName': displayName,
        'uri': uri,
        'mimeType': mimeType,
        'linkedAt': linkedAt.toIso8601String(),
        'lockStatus': lockStatus,
        'failedAttempts': failedAttempts,
        if (lockedUntil != null) 'lockedUntil': lockedUntil!.toIso8601String(),
      };
}

enum DocumentOperationResult { uploaded, pickerRequired, authenticationRequired, notFound, unsupported }

class DocumentOperation {
  final DocumentOperationResult result;
  final String message;
  const DocumentOperation(this.result, this.message);
}

class DocumentManager {
  static const _prefsKey = 'linkedDocuments.v1';
  static const MethodChannel _channel = MethodChannel('bhasha/documents');
  static const _maxFailedAttempts = 3;
  static const _lockout = Duration(minutes: 15);

  List<LinkedDocument> _documents = const [];
  bool _loaded = false;
  final AppwriteDocumentRepository? repository;

  DocumentManager({this.repository});

  List<LinkedDocument> get documents => List.unmodifiable(_documents);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    _documents = raw
        .map((value) {
          try {
            return LinkedDocument.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<LinkedDocument>()
        .where((doc) => doc.uri.isNotEmpty)
        .toList(growable: false);
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _documents.map((doc) => jsonEncode(doc.toJson())).toList(),
    );
  }

  Future<LinkedDocument?> linkDocument({String label = 'General'}) async {
    await load();
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'pickDocument',
      );
      if (raw == null) return null;
      final uri = raw['uri'] as String?;
      if (uri == null || uri.isEmpty) return null;
      final document = LinkedDocument(
        id: uri,
        label: label.trim().isEmpty ? 'General' : label.trim(),
        groupName: raw['groupName'] as String? ?? label.trim(),
        driveFileId: raw['driveFileId'] as String? ?? '',
        driveFolderId: raw['driveFolderId'] as String? ?? '',
        displayName: raw['displayName'] as String? ?? 'Document',
        uri: uri,
        mimeType: raw['mimeType'] as String? ?? 'application/octet-stream',
        linkedAt: DateTime.now(),
      );
      _documents = [
        ..._documents.where((item) => item.id != document.id),
        document,
      ];
      await _save();
      if (repository != null) {
        try {
          final row = await repository!.saveReference(
            document: document,
            driveFileId: document.driveFileId.isEmpty ? document.uri : document.driveFileId,
            driveFolderId: document.driveFolderId,
            groupName: document.groupName,
          );
          if (row != null) {
            final synced = LinkedDocument(
              id: document.id,
              label: document.label,
              groupName: document.groupName,
              driveFileId: document.driveFileId,
              driveFolderId: document.driveFolderId,
              remoteRowId: row.$id,
              displayName: document.displayName,
              uri: document.uri,
              mimeType: document.mimeType,
              linkedAt: document.linkedAt,
            );
            _documents = [..._documents.where((item) => item.id != document.id), synced];
            await _save();
            return synced;
          }
        } catch (_) {
          // The local reference remains usable when Appwrite auth is absent.
        }
      }
      return document;
    } on PlatformException {
      return null;
    }
  }

  Future<void> unlink(String id) async {
    await load();
    final target = _documents.where((doc) => doc.id == id).firstOrNull;
    _documents = _documents.where((doc) => doc.id != id).toList(growable: false);
    await _save();
    if (target != null) {
      if (repository != null && target.remoteRowId.isNotEmpty) {
        try { await repository!.deleteReference(target.remoteRowId); } catch (_) {}
      }
      try {
        await _channel.invokeMethod('releaseDocument', {'uri': target.uri});
      } catch (_) {}
    }
  }

  Future<void> relabel(String id, String label) async {
    await load();
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    _documents = _documents
        .map((doc) => doc.id == id
            ? LinkedDocument(
                id: doc.id,
                label: trimmed,
                groupName: doc.groupName,
                driveFileId: doc.driveFileId,
                driveFolderId: doc.driveFolderId,
                remoteRowId: doc.remoteRowId,
                displayName: doc.displayName,
                uri: doc.uri,
                mimeType: doc.mimeType,
                linkedAt: doc.linkedAt,
                lockStatus: doc.lockStatus,
                failedAttempts: doc.failedAttempts,
                lockedUntil: doc.lockedUntil,
              )
            : doc)
        .toList(growable: false);
    await _save();
  }

  Future<void> moveToGroup(String id, String group) async {
    await load();
    final trimmed = group.trim();
    if (trimmed.isEmpty) return;
    _documents = _documents
        .map((doc) => doc.id == id
            ? LinkedDocument(
                id: doc.id,
                label: doc.label,
                groupName: trimmed,
                driveFileId: doc.driveFileId,
                driveFolderId: doc.driveFolderId,
                remoteRowId: doc.remoteRowId,
                displayName: doc.displayName,
                uri: doc.uri,
                mimeType: doc.mimeType,
                linkedAt: doc.linkedAt,
                lockStatus: doc.lockStatus,
                failedAttempts: doc.failedAttempts,
                lockedUntil: doc.lockedUntil,
              )
            : doc)
        .toList(growable: false);
    await _save();
    final target = _documents.firstWhere((doc) => doc.id == id);
    if (repository != null && target.remoteRowId.isNotEmpty) {
      try {
        await repository!.updateReference(target);
      } catch (_) {}
    }
  }

  LinkedDocument? findByLabel(String label) {
    final normalized = label.trim().toLowerCase();
    for (final doc in _documents) {
      if (doc.label.toLowerCase() == normalized ||
          doc.displayName.toLowerCase().contains(normalized)) {
        return doc;
      }
    }
    return null;
  }

  Future<DocumentOperation> upload(LinkedDocument document) async {
    if (document.lockedUntil != null &&
        document.lockedUntil!.isAfter(DateTime.now())) {
      return const DocumentOperation(
        DocumentOperationResult.authenticationRequired,
        'Document is temporarily locked. Try again after 15 minutes.',
      );
    }
    try {
      final authenticated = await _channel.invokeMethod<bool>(
            'authenticateDocument',
          ) ??
          false;
      if (!authenticated) {
        await _recordFailedAttempt(document.id);
        return const DocumentOperation(
          DocumentOperationResult.authenticationRequired,
          'Unlock Bhasha Keyboard in the app before uploading a linked document.',
        );
      }
      final committed = await _channel.invokeMethod<bool>(
            'commitDocument',
            {
              'uri': document.uri,
              'displayName': document.displayName,
              'mimeType': document.mimeType,
            },
          ) ??
          false;
      if (committed) {
        await _resetFailedAttempts(document.id);
        return const DocumentOperation(
          DocumentOperationResult.uploaded,
          'Document shared securely from your cloud provider.',
        );
      }
      return const DocumentOperation(
        DocumentOperationResult.pickerRequired,
        'This app does not accept direct document input. Choose the file in its picker.',
      );
    } on PlatformException catch (error) {
      return DocumentOperation(
        DocumentOperationResult.unsupported,
        error.message ?? 'Document upload is not supported in this field.',
      );
    }
  }

  Future<void> _recordFailedAttempt(String id) async {
    await load();
    _documents = _documents.map((doc) {
      if (doc.id != id) return doc;
      final attempts = doc.failedAttempts + 1;
      final locked = attempts >= _maxFailedAttempts;
      return LinkedDocument(
        id: doc.id,
        label: doc.label,
        groupName: doc.groupName,
        driveFileId: doc.driveFileId,
        driveFolderId: doc.driveFolderId,
        remoteRowId: doc.remoteRowId,
        displayName: doc.displayName,
        uri: doc.uri,
        mimeType: doc.mimeType,
        linkedAt: doc.linkedAt,
        lockStatus: locked ? 'locked' : 'unlocked',
        failedAttempts: attempts,
        lockedUntil: locked ? DateTime.now().add(_lockout) : null,
      );
    }).toList(growable: false);
    await _save();
  }

  Future<void> _resetFailedAttempts(String id) async {
    await load();
    _documents = _documents.map((doc) => doc.id == id
        ? LinkedDocument(
            id: doc.id,
            label: doc.label,
            groupName: doc.groupName,
            driveFileId: doc.driveFileId,
            driveFolderId: doc.driveFolderId,
            remoteRowId: doc.remoteRowId,
            displayName: doc.displayName,
            uri: doc.uri,
            mimeType: doc.mimeType,
            linkedAt: doc.linkedAt,
            lockStatus: 'unlocked',
          )
        : doc).toList(growable: false);
    await _save();
  }

  Future<void> openManager() async {
    try {
      await _channel.invokeMethod('openDocumentManager');
    } catch (_) {}
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class DocumentCommand {
  final String label;
  const DocumentCommand(this.label);

  static DocumentCommand? parse(String utterance) {
    final normalized = utterance.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    final match = RegExp(
      r'\b(?:upload|attach|send|share|use|open)\s+(?:my\s+)?(resume|cv|education|certificate|degree|document|marksheet|aadhaar|passport)\b',
    ).firstMatch(normalized);
    if (match == null) return null;
    final value = match.group(1)!;
    return DocumentCommand(value == 'cv' ? 'Resume' : value[0].toUpperCase() + value.substring(1));
  }
}
const _documentCommandNotice = 'Document command detected';
String documentCommandNotice() => _documentCommandNotice;
