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
                Text('Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.keyText)),
                const Spacer(),
                IconButton(
                  tooltip: 'Link document',
                  icon: Icon(Icons.add, color: t.accent),
                  onPressed: () async {
                    final label = await showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(120, 48, 8, 0),
                      items: const [
                        PopupMenuItem(value: 'Resume', child: Text('Resume')),
                        PopupMenuItem(value: 'Education', child: Text('Education')),
                        PopupMenuItem(value: 'General', child: Text('General')),
                      ],
                    );
                    if (label != null) await kb.linkDocument(label: label);
                  },
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
          if (kb.documentStatus != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(kb.documentStatus!, style: TextStyle(fontSize: 11, color: t.accent)),
            ),
          Expanded(
            child: kb.documents.documents.isEmpty
                ? Center(
                    child: Text('No linked documents yet.\nTap + to choose from Google Drive or storage.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: t.keyTextSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: kb.documents.documents.length,
                    itemBuilder: (_, index) {
                      final doc = kb.documents.documents[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.description_outlined, color: t.accent),
                        title: Text(doc.displayName, style: TextStyle(fontSize: 13, color: t.keyText)),
                        subtitle: Text(doc.label, style: TextStyle(fontSize: 11, color: t.keyTextSecondary)),
                        trailing: IconButton(
                          tooltip: 'Unlink',
                          icon: Icon(Icons.link_off, size: 18, color: t.icon),
                          onPressed: () => kb.unlinkDocument(doc.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
