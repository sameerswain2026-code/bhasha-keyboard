/// Secure Cloud-Linked Document Management.
///
/// Only user-granted Android content URIs and minimal metadata are stored.
/// File bytes never pass through Bhasha or any application backend.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkedDocument {
  final String id;
  final String label;
  final String displayName;
  final String uri;
  final String mimeType;
  final DateTime linkedAt;

  const LinkedDocument({
    required this.id,
    required this.label,
    required this.displayName,
    required this.uri,
    required this.mimeType,
    required this.linkedAt,
  });

  factory LinkedDocument.fromJson(Map<String, dynamic> json) => LinkedDocument(
        id: json['id'] as String? ?? json['uri'] as String? ?? '',
        label: json['label'] as String? ?? 'General',
        displayName: json['displayName'] as String? ?? 'Document',
        uri: json['uri'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        linkedAt: DateTime.tryParse(json['linkedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'displayName': displayName,
        'uri': uri,
        'mimeType': mimeType,
        'linkedAt': linkedAt.toIso8601String(),
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

  List<LinkedDocument> _documents = const [];
  bool _loaded = false;

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
                displayName: doc.displayName,
                uri: doc.uri,
                mimeType: doc.mimeType,
                linkedAt: doc.linkedAt,
              )
            : doc)
        .toList(growable: false);
    await _save();
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
    try {
      final authenticated = await _channel.invokeMethod<bool>(
            'authenticateDocument',
          ) ??
          false;
      if (!authenticated) {
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
      r'\b(?:upload|attach|send|share|use)\s+(?:my\s+)?(resume|cv|education|certificate|degree|document)\b',
    ).firstMatch(normalized);
    if (match == null) return null;
    final value = match.group(1)!;
    return DocumentCommand(value == 'cv' ? 'Resume' : value[0].toUpperCase() + value.substring(1));
  }
}
const _documentCommandNotice = 'Document command detected';
String documentCommandNotice() => _documentCommandNotice;
