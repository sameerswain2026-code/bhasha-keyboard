import 'package:flutter_test/flutter_test.dart';
import 'package:bhasha_keyboard/engine/document_manager.dart';

void main() {
  group('Secure Cloud-Linked Document Management', () {
    test('detects supported upload commands', () {
      expect(DocumentCommand.parse('Upload my resume')?.label, 'Resume');
      expect(
        DocumentCommand.parse('please attach my education')?.label,
        'Education',
      );
      expect(DocumentCommand.parse('send my CV')?.label, 'Resume');
    });

    test('does not intercept ordinary speech', () {
      expect(DocumentCommand.parse('I am writing a resume'), isNull);
      expect(DocumentCommand.parse('upload the image'), isNull);
    });

    test('serializes only minimal reference metadata', () {
      final doc = LinkedDocument(
        id: 'content://drive/document/1',
        label: 'Resume',
        displayName: 'resume.pdf',
        uri: 'content://drive/document/1',
        mimeType: 'application/pdf',
        linkedAt: DateTime.utc(2026, 1, 1),
      );
      final json = doc.toJson();
      expect(
        json.keys,
        containsAll(<String>{
          'id',
          'label',
          'displayName',
          'uri',
          'mimeType',
          'linkedAt',
        }),
      );
      expect(json.keys, isNot(contains('bytes')));
      expect(LinkedDocument.fromJson(json).uri, doc.uri);
    });
  });
}
