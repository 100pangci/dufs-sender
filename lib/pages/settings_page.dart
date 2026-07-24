import 'package:flutter/material.dart';

import '../state/server_controller.dart';

class SettingsPage extends StatelessWidget {
  final ServerController serverController;

  const SettingsPage({
    super.key,
    required this.serverController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Default Server',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                ListenableBuilder(
                  listenable: serverController,
                  builder: (context, _) {
                    final servers = serverController.servers;
                    if (servers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Text('No servers added yet'),
                      );
                    }
                    return Column(
                      children: servers.map((server) {
                        final isSelected =
                            serverController.defaultServer?.id == server.id;
                        return ListTile(
                          title: Text(server.name),
                          subtitle: Text(server.baseUrl,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color:
                                      Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () => serverController.setDefault(server.id),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Upload Behavior',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Auto-select default server'),
                  subtitle: const Text(
                    'Pre-select default server in upload page',
                  ),
                  value: true,
                  onChanged: (_) {},
                ),
                SwitchListTile(
                  title: const Text('Auto-upload from share'),
                  subtitle: const Text(
                    'Start upload immediately when sharing files (coming soon)',
                  ),
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'About',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Dufs Sender'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.cloud_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('dufs'),
                  subtitle: const Text(
                      'A lightweight file server by sigoden'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
