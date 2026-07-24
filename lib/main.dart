import 'package:flutter/material.dart';

import 'models/upload_item.dart';
import 'services/dufs_client.dart';
import 'services/secure_store.dart';
import 'services/server_store.dart';
import 'services/share_intent_service.dart';
import 'state/server_controller.dart';
import 'state/upload_controller.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DufsSenderApp());
}

class DufsSenderApp extends StatelessWidget {
  const DufsSenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dufs Sender',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const AppRoot(),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final SecureStore _secureStore;
  late final ServerStore _serverStore;
  late final DufsClient _dufsClient;
  late final ServerController _serverController;
  late final UploadController _uploadController;
  late final ShareIntentService _shareIntentService;

  List<UploadItem>? _sharedItems;

  @override
  void initState() {
    super.initState();
    _secureStore = SecureStore();
    _serverStore = ServerStore(_secureStore);
    _dufsClient = DufsClient();
    _serverController = ServerController(_serverStore);
    _uploadController = UploadController(_dufsClient, _secureStore);
    _shareIntentService = ShareIntentService();

    _serverController.load();
    _setupShareIntent();
  }

  void _setupShareIntent() {
    _shareIntentService.listen((items) {
      if (!mounted) return;
      setState(() {
        _sharedItems = items;
      });
    });
  }

  void _clearSharedItems() {
    setState(() {
      _sharedItems = null;
    });
  }

  @override
  void dispose() {
    _shareIntentService.dispose();
    _serverController.dispose();
    _uploadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      serverController: _serverController,
      uploadController: _uploadController,
      sharedItems: _sharedItems,
      onClearSharedItems: _clearSharedItems,
    );
  }
}
