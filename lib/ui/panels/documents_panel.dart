/// Cloud-linked document manager. The app stores only URI references and
/// labels; the provider retains the actual document bytes.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/keyboard_controller.dart';
import '../kb_theme.dart';

class DocumentsPanel extends StatelessWidget {
  const DocumentsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final kb = context.watch<KeyboardController>();
    final t = KbTheme.of(context);
    return Container(
      color: t.panelBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 12, 2),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to keyboard',
                  icon: Icon(Icons.arrow_back, size: 20, color: t.icon),
                  onPressed: kb.closePanel,
                ),
                Icon(Icons.cloud_outlined, size: 17, color: t.icon),
                const SizedBox(width: 8),
                Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.keyText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Link document',
                  icon: Icon(Icons.add, color: t.accent),
                  onPressed: () => _linkCustomDocument(context, kb),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text(
              'Files stay in your selected cloud provider. Bhasha stores only a permission-backed reference and label.',
              style: TextStyle(fontSize: 11, color: t.keyTextSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.accent.withValues(alpha: 0.18)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.record_voice_over_outlined,
                      size: 18,
                      color: t.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Try: “Bhasha, upload my Aadhaar Card”. You will be asked for device PIN or biometric before sharing.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: t.keyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (kb.documentStatus != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(
                kb.documentStatus!,
                style: TextStyle(fontSize: 11, color: t.accent),
              ),
            ),
          Expanded(
            child: kb.documents.documents.isEmpty
                ? Center(
                    child: Text(
                      'No linked documents yet.\nTap + to choose from Google Drive or storage.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: t.keyTextSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: kb.documents.documents.length,
                    itemBuilder: (_, index) {
                      final doc = kb.documents.documents[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.description_outlined,
                          color: t.accent,
                        ),
                        title: Text(
                          doc.displayName,
                          style: TextStyle(fontSize: 13, color: t.keyText),
                        ),
                        subtitle: Text(
                          doc.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: t.keyTextSecondary,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Document actions',
                          icon: Icon(Icons.more_vert, size: 18, color: t.icon),
                          onSelected: (action) async {
                            if (action == 'unlink') {
                              await kb.unlinkDocument(doc.id);
                            } else {
                              final group = await _askText(
                                context,
                                action == 'label'
                                    ? 'Rename label'
                                    : 'Move to folder',
                                action == 'label' ? doc.label : doc.groupName,
                              );
                              if (group != null && group.trim().isNotEmpty) {
                                if (action == 'label') {
                                  await kb.documents.relabel(doc.id, group);
                                  await kb.refreshLinkedDocuments();
                                } else {
                                  await kb.moveDocumentToGroup(doc.id, group);
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'label',
                              child: Text('Rename label'),
                            ),
                            PopupMenuItem(
                              value: 'group',
                              child: Text('Move to folder'),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'unlink',
                              child: Text('Unlink document'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _linkCustomDocument(
    BuildContext context,
    KeyboardController kb,
  ) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _DocumentDetailsDialog(),
    );
    if (values == null) return;
    await kb.linkDocument(label: values[0]);
    final linked = kb.documents.findByLabel(values[0]);
    if (linked != null) {
      await kb.documents.moveToGroup(linked.id, values[1]);
    }
    await kb.refreshLinkedDocuments();
  }

  Future<String?> _askText(
    BuildContext context,
    String title,
    String initial,
  ) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DocumentDetailsDialog extends StatefulWidget {
  const _DocumentDetailsDialog();
  @override
  State<_DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<_DocumentDetailsDialog> {
  final _label = TextEditingController(text: 'General');
  final _folder = TextEditingController(text: 'General');
  @override
  void dispose() {
    _label.dispose();
    _folder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Link a document'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _label,
          decoration: const InputDecoration(labelText: 'Label (e.g. Aadhaar)'),
        ),
        TextField(
          controller: _folder,
          decoration: const InputDecoration(
            labelText: 'Folder (e.g. Identity)',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, [_label.text, _folder.text]),
        child: const Text('Choose file'),
      ),
    ],
  );
}
