# Dufs Sender

A lightweight Android app for uploading files to a [dufs](https://github.com/sigoden/dufs) file server on your local network.

Replace the "open browser → navigate to dufs → select file → upload" flow with a single share action.

## Features

- Add multiple dufs servers with Basic Auth support
- Upload files directly from the app
- Receive files via Android share menu (file manager, gallery, Telegram, etc.)
- Upload progress per file
- Test connection before saving
- Material Design 3 (Material You)
- Dark / Light theme

## Screenshots

*(Add screenshots here after building)*

## Quick Start

### 1. dufs Server Setup

Using Podman / Docker Compose:

```yaml
services:
  dufs:
    image: docker.io/sigoden/dufs:latest
    container_name: dufs
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./data:/data:Z
    command:
      - /data
      - --bind
      - 0.0.0.0
      - --port
      - "5000"
      - --allow-upload
      - --allow-search
      - --auth
      - "admin:change-this-password@/:rw"
```

Start the server:

```bash
mkdir -p data
podman compose up -d
```

Fedora firewall (if needed):

```bash
sudo firewall-cmd --add-port=5000/tcp --permanent
sudo firewall-cmd --reload
```

Plain dufs command:

```bash
dufs /path/to/data --allow-upload --auth admin:password@/:rw
```

### 2. Build the App

#### Using GitHub Actions (recommended)

1. Fork / clone this repo
2. Push to GitHub
3. Go to Actions → Build APK → Run workflow
4. Download the APK from the workflow artifacts

#### Local Build

Requirements:

- Flutter SDK 3.10+ (stable channel)
- Android SDK 34+
- JDK 17

```bash
# Clone
git clone https://github.com/your-username/dufs_sender.git
cd dufs_sender

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# Or split per ABI
flutter build apk --release --split-per-abi
```

APK files will be at `build/app/outputs/flutter-apk/`.

### 3. Install on Android

Transfer the APK to your phone and install it. You may need to enable "Install from unknown sources" in Settings.

### 4. Configure a Server

1. Open Dufs Sender
2. Tap **+** (FAB)
3. Enter:
   - Server Name: e.g. "Fedora Inbox"
   - Server URL: e.g. `http://192.168.1.10:5000`
   - Default Upload Directory: e.g. `/inbox/` (optional)
   - Username & Password (if Basic Auth is enabled)
4. Tap **Test Connection** to verify
5. Tap **Save**

### 5. Upload Files

#### From the App

1. Open Dufs Sender
2. Tap **Select Files to Upload**
3. Pick one or more files
4. Select a server from the dropdown
5. Tap **Upload**

#### From Android Share Menu

1. In any app (Files, Gallery, Telegram, etc.), select a file
2. Tap **Share**
3. Choose **Dufs Sender** from the share sheet
4. The app opens with the shared file(s) pre-loaded
5. Select a server and tap **Upload**

## How It Works

- Files are uploaded via HTTP PUT to the dufs server
- Supports Basic Authentication
- File names are URL-encoded (Chinese characters, spaces, etc. are preserved)
- Upload progress is shown per file
- Content URIs from share intents are copied to a temp directory first, then uploaded, and cleaned up after

## Upload Protocol

```
PUT http://server:port/[remoteDir/]filename.ext
Authorization: Basic base64(username:password)
Content-Type: application/octet-stream
```

Equivalent curl:

```bash
curl -u admin:password -T file.zip http://192.168.1.10:5000/inbox/file.zip
```

## Architecture

```
lib/
├── main.dart                      # App entry, theme, DI
├── models/
│   ├── dufs_server.dart           # Server data model
│   └── upload_item.dart           # Upload item model
├── services/
│   ├── dufs_client.dart           # HTTP client (dio)
│   ├── server_store.dart          # Server config persistence
│   ├── secure_store.dart          # Password storage (flutter_secure_storage)
│   ├── share_intent_service.dart  # Android share intent listener
│   └── content_uri_helper.dart    # Android content:// URI helper (platform channel)
├── state/
│   ├── server_controller.dart     # Server list state (ChangeNotifier)
│   └── upload_controller.dart     # Upload state (ChangeNotifier)
├── pages/
│   ├── home_page.dart             # Server list, quick upload, share entry
│   ├── server_edit_page.dart      # Add / edit server form
│   ├── upload_page.dart           # Upload progress page
│   └── settings_page.dart         # Settings (default server, etc.)
└── utils/
    ├── url_utils.dart             # URL normalization & upload URL builder
    └── file_utils.dart            # File helpers (temp copy, cleanup)
```

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| dio | ^5.4.0 | HTTP client for dufs PUT/GET |
| file_picker | ^8.0.0 | In-app file selection |
| flutter_secure_storage | ^9.0.0 | Encrypted password storage |
| shared_preferences | ^2.2.0 | Server config persistence |
| path_provider | ^2.1.0 | Cache / temp directory |
| receive_sharing_intent | ^1.8.0 | Android share intent handling |
| uuid | ^4.2.0 | Unique IDs |
| intl | ^0.19.0 | Formatting |

## Troubleshooting

### Connection fails

- Make sure dufs is running: `curl http://your-server:5000/`
- Check firewall: `sudo firewall-cmd --list-port`
- If using `https://` without a valid cert, switch to `http://`
- For local network, the URL must be reachable from the phone (same WiFi)

### Authentication fails

- Verify username and password in dufs config
- Test with curl: `curl -u user:pass http://server:5000/`
- The app uses Basic Auth (base64-encoded credentials in HTTP header)

### Upload shows 404

- The remote directory may not exist on the dufs server
- Try uploading without a default directory (just to root)
- Check dufs startup flags for any path restrictions

### Share to Dufs Sender not appearing

- Reboot the phone after installing
- Make sure the app is installed (not just the APK downloaded)
- Try sharing from different apps (Files by Google, Telegram, etc.)

## Security Notes

- Passwords are stored using `flutter_secure_storage` (Android Keystore-backed encryption)
- Server config (without passwords) is stored in `shared_preferences`
- Content URIs from share intents are copied to app temp directory and cleaned up after upload
- The app only connects to servers you explicitly configure
- No data is sent outside your local network (unless you configure a remote server)

## License

MIT

## Acknowledgments

- [dufs](https://github.com/sigoden/dufs) - The lightweight file server this app targets
- [Flutter](https://flutter.dev/) - Cross-platform UI framework
