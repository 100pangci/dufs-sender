import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../l10n/localization.dart';
import '../models/dufs_server.dart';
import '../models/upload_item.dart';
import '../state/server_controller.dart';
import '../state/upload_controller.dart';
import 'server_edit_page.dart';
import 'upload_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final ServerController serverController;
  final UploadController uploadController;
  final List<UploadItem>? sharedItems;
  final VoidCallback? onClearSharedItems;

  const HomePage({
    super.key,
    required this.serverController,
    required this.uploadController,
    this.sharedItems,
    this.onClearSharedItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    serverController: serverController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: serverController,
        builder: (context, _) {
          if (!serverController.loaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sharedItems != null && sharedItems!.isNotEmpty) {
            return _buildSharedFileView(context);
          }

          final servers = serverController.servers;

          if (servers.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildServerList(context, servers);
        },
      ),
      floatingActionButton: sharedItems != null && sharedItems!.isNotEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _addServer(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              loc.homeNoServers,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              loc.homeNoServersDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _addServer(context),
              icon: const Icon(Icons.add),
              label: Text(loc.homeAddServer),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickFiles(context),
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(loc.homeSelectFiles),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickFolder(context),
              icon: const Icon(Icons.folder_open),
              label: Text(loc.homeSelectFolder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerList(BuildContext context, List<DufsServer> servers) {
    final loc = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () => serverController.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                loc.homeServers,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addServer(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(loc.homeAdd),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...servers.map((server) => _buildServerCard(context, server)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickFiles(context),
            icon: const Icon(Icons.file_upload_outlined),
            label: Text(loc.homeSelectFiles),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickFolder(context),
            icon: const Icon(Icons.folder_open),
            label: Text(loc.homeSelectFolder),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, DufsServer server) {
    final isDefault = server.isDefault;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectServerAndUpload(context, server),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDefault
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dns_outlined,
                  color: isDefault
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          server.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                              child: Text(
                              AppLocalizations.of(context).homeDefault,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      server.baseUrl,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServerEditPage(
                            serverController: serverController,
                            server: server,
                          ),
                        ),
                      );
                      break;
                    case 'delete':
                      _confirmDelete(context, server);
                      break;
                    case 'default':
                      serverController.setDefault(server.id);
                      break;
                  }
                },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context).homeEdit),
                        ],
                      ),
                    ),
                    if (!server.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            const Icon(Icons.star_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).homeSetDefault),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context).homeDelete,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedFileView(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = sharedItems!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.homeSharedFiles(items.length),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      Text(
                        items.map((i) => i.displayName).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _goToUpload(context, items),
          icon: const Icon(Icons.cloud_upload),
          label: Text(loc.homeUploadNow),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _addAndUpload(context, items),
          icon: const Icon(Icons.dns_outlined),
          label: Text(loc.homeSelectServerUpload),
        ),
      ],
    );
  }

  void _addServer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerEditPage(
          serverController: serverController,
        ),
      ),
    );
  }

  void _selectServerAndUpload(BuildContext context, DufsServer server) {
    uploadController.selectedServer = server;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadPage(
          serverController: serverController,
          uploadController: uploadController,
          preSelectedServer: server,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DufsServer server) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.homeDeleteTitle),
        content: Text(loc.homeDeleteConfirm(server.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.homeCancel),
          ),
          FilledButton(
            onPressed: () {
              serverController.delete(server.id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.homeDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      const uuid = Uuid();
      final items = result.files.map((f) {
        return UploadItem(
          id: uuid.v4(),
          displayName: f.name,
          localPath: f.path,
          size: f.size,
          mimeType: 'application/octet-stream',
        );
      }).toList();

      uploadController.addItems(items);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UploadPage(
              serverController: serverController,
              uploadController: uploadController,
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && result.isNotEmpty) {
      await uploadController.addDirectory(result);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UploadPage(
              serverController: serverController,
              uploadController: uploadController,
            ),
          ),
        );
      }
    }
  }

  void _goToUpload(BuildContext context, List<UploadItem> items) {
    uploadController.addItems(items);
    onClearSharedItems?.call();
    if (serverController.defaultServer != null) {
      uploadController.selectedServer = serverController.defaultServer;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadPage(
          serverController: serverController,
          uploadController: uploadController,
        ),
      ),
    );
  }

  void _addAndUpload(BuildContext context, List<UploadItem> items) {
    uploadController.addItems(items);
    onClearSharedItems?.call();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadPage(
          serverController: serverController,
          uploadController: uploadController,
        ),
      ),
    );
  }
}
