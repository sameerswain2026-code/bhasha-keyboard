import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/appwrite_document_repository.dart';
import '../engine/appwrite_gateway_client.dart';
import 'kb_theme.dart';

class DriveWorkspaceScreen extends StatefulWidget {
  const DriveWorkspaceScreen({super.key, this.repository});

  final AppwriteDocumentRepository? repository;

  @override
  State<DriveWorkspaceScreen> createState() => _DriveWorkspaceScreenState();
}

class _DriveWorkspaceScreenState extends State<DriveWorkspaceScreen> {
  late final AppwriteDocumentRepository _repository;
  final _search = TextEditingController();
  final List<DriveItem> _folderStack = [];
  Timer? _debounce;
  List<DriveItem> _items = const [];
  bool _loading = true;
  String? _error;
  String _sort = 'name';

  String? get _parentId => _folderStack.isEmpty ? null : _folderStack.last.id;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppwriteDocumentRepository();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.listDriveItems(
        parentId: _parentId,
        query: _search.text,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } on GatewayException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error.code));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Drive is unavailable. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  String _messageFor(String code) {
    switch (code) {
      case 'DRIVE_NOT_CONNECTED':
      case 'GOOGLE_RECONNECT_REQUIRED':
      case 'DRIVE_RECONNECT_REQUIRED':
        return 'Reconnect Google Drive from the account card.';
      case 'UPSTREAM_TIMEOUT':
        return 'Google Drive took too long to respond. Please retry.';
      default:
        return 'Drive request failed. Please retry without losing your work.';
    }
  }

  Future<void> _create(bool folder) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder ? 'Create folder' : 'Create document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: folder ? 'Folder name' : 'Document name',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    try {
      if (folder) {
        await _repository.createDriveFolder(name, parentId: _parentId);
      } else {
        await _repository.createDriveDocument(name, parentId: _parentId);
      }
      if (mounted) await _load();
    } on GatewayException catch (error) {
      if (mounted) _showMessage(_messageFor(error.code));
    } catch (_) {
      if (mounted) _showMessage('Could not create the item. Please retry.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addToAi(DriveItem item) async {
    try {
      await _repository.addDriveItemToAi(item);
      if (mounted) {
        _showMessage(
          '${item.name} reference was added to your private AI index.',
        );
      }
    } catch (_) {
      if (mounted) _showMessage('Could not add this item to AI. Please retry.');
    }
  }

  void _openFolder(DriveItem item) {
    setState(() {
      _folderStack.add(item);
      _search.clear();
    });
    _load();
  }

  void _goBack() {
    if (_folderStack.isEmpty) {
      Navigator.maybePop(context);
      return;
    }
    setState(() {
      _folderStack.removeLast();
      _search.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = KbTheme.of(context);
    final location = _folderStack.isEmpty
        ? 'My authorized files'
        : _folderStack.map((folder) => folder.name).join(' / ');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _folderStack.isEmpty ? 'Back' : 'Parent folder',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Drive workspace'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort files',
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Sort by name')),
              PopupMenuItem(
                value: 'modified',
                child: Text('Sort by modified time'),
              ),
              PopupMenuItem(value: 'type', child: Text('Folders first')),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Create',
            onSelected: (value) => _create(value == 'folder'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'folder', child: Text('New folder')),
              PopupMenuItem(value: 'document', child: Text('New document')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search authorized files',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent(t)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(true),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New folder'),
      ),
    );
  }

  Widget _buildContent(KbTheme t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: t.keyTextSecondary,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _search.text.trim().isEmpty
                ? 'No authorized files yet. Create a folder or choose files through Bhasha Aura.'
                : 'No files match this search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.keyTextSecondary),
          ),
        ),
      );
    }
    final items = [..._items]..sort(_compareItems);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: Icon(
              item.isFolder ? Icons.folder_rounded : Icons.description_outlined,
              color: item.isFolder ? t.accent : t.icon,
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.modifiedTime == null
                  ? item.mimeType
                  : 'Modified ${_date(item.modifiedTime!)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Actions for ${item.name}',
              onSelected: (value) {
                if (value == 'ai') _addToAi(item);
                if (value == 'open' && item.isFolder) _openFolder(item);
              },
              itemBuilder: (_) => [
                if (item.isFolder)
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Open folder'),
                  ),
                const PopupMenuItem(value: 'ai', child: Text('Add to AI')),
              ],
            ),
            onTap: item.isFolder ? () => _openFolder(item) : null,
          ),
        );
      },
    );
  }

  int _compareItems(DriveItem first, DriveItem second) {
    if (_sort == 'modified') {
      final firstTime =
          first.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondTime =
          second.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondTime.compareTo(firstTime);
    }
    if (_sort == 'type' && first.isFolder != second.isFolder) {
      return first.isFolder ? -1 : 1;
    }
    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
