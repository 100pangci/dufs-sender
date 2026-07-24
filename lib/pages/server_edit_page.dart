import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/localization.dart';
import '../models/dufs_server.dart';
import '../services/dufs_client.dart';
import '../state/server_controller.dart';

class ServerEditPage extends StatefulWidget {
  final ServerController serverController;
  final DufsServer? server;

  const ServerEditPage({
    super.key,
    required this.serverController,
    this.server,
  });

  @override
  State<ServerEditPage> createState() => _ServerEditPageState();
}

class _ServerEditPageState extends State<ServerEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _dirController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _client = DufsClient();
  bool _testing = false;
  bool _saving = false;

  bool get _isEditing => widget.server != null;

  @override
  void initState() {
    super.initState();
    final server = widget.server;
    if (server != null) {
      _nameController.text = server.name;
      _urlController.text = server.baseUrl;
      _dirController.text = server.defaultRemoteDir;
      _usernameController.text = server.username;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _dirController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _testing = true);

    final testServer = DufsServer(
      id: '',
      name: _nameController.text,
      baseUrl: _urlController.text,
      defaultRemoteDir: _dirController.text,
      username: _usernameController.text,
      hasPassword: _passwordController.text.isNotEmpty,
    );

    final result = await _client.testConnection(
      testServer,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _testing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result.message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    const uuid = Uuid();
    final now = DateTime.now();

    if (_isEditing) {
      final updated = widget.server!.copyWith(
        name: _nameController.text.trim(),
        baseUrl: _urlController.text.trim(),
        defaultRemoteDir: _dirController.text.trim(),
        username: _usernameController.text.trim(),
      );
      await widget.serverController.update(
        updated,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
      );
    } else {
      final server = DufsServer(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        baseUrl: _urlController.text.trim(),
        defaultRemoteDir: _dirController.text.trim(),
        username: _usernameController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await widget.serverController.add(
        server,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? loc.serverEditEditTitle : loc.serverEditAddTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.serverEditServerInfo,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: loc.serverEditServerName,
                          hintText: loc.serverEditServerNameHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.label_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? loc.serverEditRequired : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: loc.serverEditServerUrl,
                          hintText: loc.serverEditServerUrlHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return loc.serverEditRequired;
                          }
                          final url = v.trim();
                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            return loc.serverEditMustStartWithHttp;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dirController,
                        decoration: InputDecoration(
                          labelText: loc.serverEditDefaultDir,
                          hintText: loc.serverEditDefaultDirHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.folder_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.serverEditAuth,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: loc.serverEditUsername,
                          hintText: loc.serverEditUsernameHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: _isEditing ? loc.serverEditPasswordKeep : loc.serverEditPassword,
                          hintText: loc.serverEditPasswordHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(_testing ? loc.serverEditTesting : loc.serverEditTestConnection),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isEditing ? loc.serverEditUpdate : loc.serverEditSave),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
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
}
