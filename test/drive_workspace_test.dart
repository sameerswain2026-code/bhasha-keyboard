import 'package:flutter_test/flutter_test.dart';

import 'package:bhasha_keyboard/engine/appwrite_document_repository.dart';

void main() {
  test('DriveItem parses metadata defensively', () {
    final item = DriveItem.fromJson({
      'id': 'folder-1',
      'name': 'Education',
      'mimeType': 'application/vnd.google-apps.folder',
      'modifiedTime': '2026-09-10T08:30:00.000Z',
      'parents': ['root'],
    });

    expect(item.id, 'folder-1');
    expect(item.name, 'Education');
    expect(item.isFolder, isTrue);
    expect(item.modifiedTime, isNotNull);
    expect(item.parents, ['root']);
  });

  test('DriveItem tolerates incomplete provider metadata', () {
    final item = DriveItem.fromJson(const {});
    expect(item.id, isEmpty);
    expect(item.name, 'Untitled');
    expect(item.isFolder, isFalse);
    expect(item.parents, isEmpty);
  });
}
