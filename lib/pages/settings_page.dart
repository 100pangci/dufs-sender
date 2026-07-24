import 'package:flutter/material.dart';

import '../l10n/localization.dart';
import '../state/server_controller.dart';

class SettingsPage extends StatelessWidget {
  final ServerController serverController;

  const SettingsPage({
    super.key,
    required this.serverController,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
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
                    loc.settingsDefaultServer,
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
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Text(loc.settingsNoServers),
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
                    loc.settingsUploadBehavior,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: Text(loc.settingsAutoSelectDefault),
                  subtitle: Text(loc.settingsAutoSelectDefaultDesc),
                  value: true,
                  onChanged: (_) {},
                ),
                SwitchListTile(
                  title: Text(loc.settingsAutoUploadShare),
                  subtitle: Text(loc.settingsAutoUploadShareDesc),
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
                    loc.settingsAbout,
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
                  subtitle: Text(loc.settingsVersion),
                ),
                ListTile(
                  leading: Icon(
                    Icons.cloud_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('dufs'),
                  subtitle: Text(loc.settingsDufsDesc),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
