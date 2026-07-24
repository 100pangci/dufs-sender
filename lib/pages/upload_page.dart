import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/dufs_server.dart';
import '../models/upload_item.dart';
import '../state/server_controller.dart';
import '../state/upload_controller.dart';

class UploadPage extends StatefulWidget {
  final ServerController serverController;
  final UploadController uploadController;
  final DufsServer? preSelectedServer;

  const UploadPage({
    super.key,
    required this.serverController,
    required this.uploadController,
    this.preSelectedServer,
  });

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  DufsServer? _selectedServer;

  @override
  void initState() {
    super.initState();
    _selectedServer =
        widget.preSelectedServer ?? widget.uploadController.selectedServer;
  }

  Future<void> _startUpload() async {
    if (_selectedServer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a server first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await widget.uploadController.startUpload(_selectedServer!);
  }

  void _retryFailed() {
    if (_selectedServer == null) return;
    widget.uploadController.retryFailed(_selectedServer!);
  }

  Future<void> _addMoreFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final uuid = const Uuid();
      final items = result.files.map((f) {
        return UploadItem(
          id: uuid.v4(),
          displayName: f.name,
          localPath: f.path,
          size: f.size,
          mimeType: 'application/octet-stream',
        );
      }).toList();
      widget.uploadController.addItems(items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                widget.uploadController.uploading ? null : _addMoreFiles,
            tooltip: 'Add files',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: widget.uploadController.uploading
                ? null
                : () {
                    widget.uploadController.clearAll();
                  },
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.serverController,
          widget.uploadController,
        ]),
        builder: (context, _) {
          final servers = widget.serverController.servers;
          final items = widget.uploadController.items;
          final uploading = widget.uploadController.uploading;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No files to upload',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select files from the home page or share them from other apps',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (servers.isNotEmpty)
                _buildServerSelector(context, servers),
              Expanded(
                child: _buildFileList(context, items, uploading),
              ),
              _buildBottomBar(context, items, uploading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServerSelector(
      BuildContext context, List<DufsServer> servers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DufsServer>(
              value: _selectedServer != null &&
                      servers.any((s) => s.id == _selectedServer!.id)
                  ? _selectedServer
                  : null,
              hint: const Text('Select server'),
              isExpanded: true,
              items: servers.map((server) {
                return DropdownMenuItem(
                  value: server,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              server.baseUrl,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (server.isDefault)
                        Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: uploading
                  ? null
                  : (server) {
                      setState(() => _selectedServer = server);
                    },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(
      BuildContext context, List<UploadItem> items, bool uploading) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildFileTile(context, item, uploading);
      },
    );
  }

  Widget _buildFileTile(BuildContext context, UploadItem item, bool uploading) {
    final statusColor = switch (item.status) {
      UploadStatus.pending => Theme.of(context).colorScheme.onSurfaceVariant,
      UploadStatus.uploading => Theme.of(context).colorScheme.primary,
      UploadStatus.success => Colors.green,
      UploadStatus.failed => Theme.of(context).colorScheme.error,
      UploadStatus.cancelled => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    final statusIcon = switch (item.status) {
      UploadStatus.pending => Icons.hourglass_empty,
      UploadStatus.uploading => Icons.cloud_upload,
      UploadStatus.success => Icons.check_circle,
      UploadStatus.failed => Icons.error,
      UploadStatus.cancelled => Icons.cancel,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.sizeFormatted,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (item.status == UploadStatus.uploading)
                  Text(
                    '${(item.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                if (item.status != UploadStatus.uploading &&
                    item.status != UploadStatus.success)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: uploading
                        ? null
                        : () => widget.uploadController.removeItem(item.id),
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (item.status == UploadStatus.uploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: item.progress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
            if (item.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                item.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, List<UploadItem> items, bool uploading) {
    final hasFailed = items.any((i) => i.status == UploadStatus.failed);
    final allDone = items.every(
      (i) =>
          i.status == UploadStatus.success ||
          i.status == UploadStatus.cancelled,
    );
    final pendingCount = items
        .where((i) =>
            i.status == UploadStatus.pending || i.status == UploadStatus.failed)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFailed && !uploading && pendingCount > 0)
              OutlinedButton.icon(
                onPressed: _retryFailed,
                icon: const Icon(Icons.refresh),
                label: Text('Retry Failed ($pendingCount)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            if (!allDone && pendingCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton.icon(
                  onPressed: (uploading || _selectedServer == null)
                      ? null
                      : _startUpload,
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    uploading
                        ? 'Uploading...'
                        : 'Upload ($pendingCount files)',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            if (uploading)
              TextButton(
                onPressed: () => widget.uploadController.cancelUpload(),
                child: const Text('Cancel'),
              ),
            if (allDone && items.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  widget.uploadController.clearAll();
                },
                icon: const Icon(Icons.done_all),
                label: Text(
                  'Done (${widget.uploadController.successCount} ok, ${widget.uploadController.failCount} failed)',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
