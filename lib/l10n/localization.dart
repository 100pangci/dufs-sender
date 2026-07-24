import 'package:flutter/material.dart';

import 'translations.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _data;

  AppLocalizations(this.locale, this._data);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  String tr(String key, {Map<String, String>? args}) {
    var text = _data[key];
    if (text == null) return key;
    if (args != null) {
      for (final e in args.entries) {
        text = text!.replaceAll('{$e.key}', e.value);
      }
    }
    return text!;
  }

  String get appTitle => _data['appTitle'] ?? 'Dufs Sender';

  String get homeNoServers => _data['homeNoServers'] ?? 'No servers yet';
  String get homeNoServersDesc =>
      _data['homeNoServersDesc'] ?? 'Add a dufs server to start uploading files';
  String get homeAddServer => _data['homeAddServer'] ?? 'Add Server';
  String get homeSelectFiles =>
      _data['homeSelectFiles'] ?? 'Select Files to Upload';
  String get homeSelectFolder =>
      _data['homeSelectFolder'] ?? 'Select Folder to Upload';
  String get homeServers => _data['homeServers'] ?? 'Servers';
  String get homeAdd => _data['homeAdd'] ?? 'Add';
  String get homeDefault => _data['homeDefault'] ?? 'Default';
  String get homeEdit => _data['homeEdit'] ?? 'Edit';
  String get homeSetDefault => _data['homeSetDefault'] ?? 'Set as Default';
  String get homeDelete => _data['homeDelete'] ?? 'Delete';
  String get homeDeleteTitle => _data['homeDeleteTitle'] ?? 'Delete Server';
  String homeDeleteConfirm(String name) =>
      tr('homeDeleteConfirm', args: {'name': name});
  String homeSharedFiles(int count) =>
      tr('homeSharedFiles', args: {'count': '$count'});
  String get homeUploadNow => _data['homeUploadNow'] ?? 'Upload Now';
  String get homeSelectServerUpload =>
      _data['homeSelectServerUpload'] ?? 'Select Server & Upload';
  String get homeCancel => _data['homeCancel'] ?? 'Cancel';

  String get uploadTitle => _data['uploadTitle'] ?? 'Upload';
  String get uploadAddFiles => _data['uploadAddFiles'] ?? 'Add files';
  String get uploadAddFolder => _data['uploadAddFolder'] ?? 'Add folder';
  String get uploadClearAll => _data['uploadClearAll'] ?? 'Clear all';
  String get uploadNoFiles =>
      _data['uploadNoFiles'] ?? 'No files to upload';
  String get uploadNoFilesDesc =>
      _data['uploadNoFilesDesc'] ??
      'Select files from the home page or share them from other apps';
  String get uploadSelectServer =>
      _data['uploadSelectServer'] ?? 'Select server';
  String get uploadSelectServerFirst =>
      _data['uploadSelectServerFirst'] ?? 'Please select a server first';
  String get uploadRemove => _data['uploadRemove'] ?? 'Remove';
  String uploadRetryFailed(int count) =>
      tr('uploadRetryFailed', args: {'count': '$count'});
  String get uploadUploading => _data['uploadUploading'] ?? 'Uploading...';
  String uploadUploadCount(int count) =>
      tr('uploadUploadCount', args: {'count': '$count'});
  String get uploadCancel => _data['uploadCancel'] ?? 'Cancel';
  String uploadDone(int ok, int fail) =>
      tr('uploadDone', args: {'ok': '$ok', 'fail': '$fail'});
  String get uploadUnknownSize =>
      _data['uploadUnknownSize'] ?? 'Unknown size';

  String get serverEditAddTitle =>
      _data['serverEditAddTitle'] ?? 'Add Server';
  String get serverEditEditTitle =>
      _data['serverEditEditTitle'] ?? 'Edit Server';
  String get serverEditServerInfo =>
      _data['serverEditServerInfo'] ?? 'Server Info';
  String get serverEditServerName =>
      _data['serverEditServerName'] ?? 'Server Name';
  String get serverEditServerNameHint =>
      _data['serverEditServerNameHint'] ?? 'e.g. Fedora Inbox';
  String get serverEditServerUrl =>
      _data['serverEditServerUrl'] ?? 'Server URL';
  String get serverEditServerUrlHint =>
      _data['serverEditServerUrlHint'] ?? 'http://192.168.1.10:5000';
  String get serverEditDefaultDir =>
      _data['serverEditDefaultDir'] ?? 'Default Upload Directory (optional)';
  String get serverEditDefaultDirHint =>
      _data['serverEditDefaultDirHint'] ?? '/upload/';
  String get serverEditAuth =>
      _data['serverEditAuth'] ?? 'Authentication (optional)';
  String get serverEditUsername => _data['serverEditUsername'] ?? 'Username';
  String get serverEditUsernameHint =>
      _data['serverEditUsernameHint'] ?? 'admin';
  String get serverEditPassword => _data['serverEditPassword'] ?? 'Password';
  String get serverEditPasswordKeep =>
      _data['serverEditPasswordKeep'] ?? 'Password (leave blank to keep)';
  String get serverEditPasswordHint =>
      _data['serverEditPasswordHint'] ?? 'Enter password';
  String get serverEditTestConnection =>
      _data['serverEditTestConnection'] ?? 'Test Connection';
  String get serverEditTesting =>
      _data['serverEditTesting'] ?? 'Testing...';
  String get serverEditUpdate => _data['serverEditUpdate'] ?? 'Update';
  String get serverEditSave => _data['serverEditSave'] ?? 'Save';
  String get serverEditRequired =>
      _data['serverEditRequired'] ?? 'Required';
  String get serverEditMustStartWithHttp =>
      _data['serverEditMustStartWithHttp'] ??
      'Must start with http:// or https://';

  String get settingsTitle => _data['settingsTitle'] ?? 'Settings';
  String get settingsDefaultServer =>
      _data['settingsDefaultServer'] ?? 'Default Server';
  String get settingsNoServers =>
      _data['settingsNoServers'] ?? 'No servers added yet';
  String get settingsUploadBehavior =>
      _data['settingsUploadBehavior'] ?? 'Upload Behavior';
  String get settingsAutoSelectDefault =>
      _data['settingsAutoSelectDefault'] ?? 'Auto-select default server';
  String get settingsAutoSelectDefaultDesc =>
      _data['settingsAutoSelectDefaultDesc'] ??
      'Pre-select default server in upload page';
  String get settingsAutoUploadShare =>
      _data['settingsAutoUploadShare'] ?? 'Auto-upload from share';
  String get settingsAutoUploadShareDesc =>
      _data['settingsAutoUploadShareDesc'] ??
      'Start upload immediately when sharing files (coming soon)';
  String get settingsAbout => _data['settingsAbout'] ?? 'About';
  String get settingsVersion =>
      _data['settingsVersion'] ?? 'Version 1.0.0';
  String get settingsDufsDesc =>
      _data['settingsDufsDesc'] ?? 'A lightweight file server by sigoden';

  String statusCannotReadFile(String error) =>
      tr('statusCannotReadFile', args: {'error': error});
  String get statusNoFilePath => _data['statusNoFilePath'] ?? 'No file path available';
  String statusFileNotFound(String path) =>
      tr('statusFileNotFound', args: {'path': path});
  String get statusUploaded =>
      _data['statusUploaded'] ?? 'Upload completed successfully';
  String get statusCancelled =>
      _data['statusCancelled'] ?? 'Upload cancelled';
  String get statusAuthFailed =>
      _data['statusAuthFailed'] ?? 'Authentication failed';
  String get statusPermissionDenied =>
      _data['statusPermissionDenied'] ?? 'Permission denied';
  String get statusPathNotFound =>
      _data['statusPathNotFound'] ?? 'Path not found on server';
  String get statusConflict =>
      _data['statusConflict'] ?? 'File already exists (conflict)';
  String get statusFileTooLarge =>
      _data['statusFileTooLarge'] ?? 'File too large for server';
  String statusServerError(int code) =>
      tr('statusServerError', args: {'code': '$code'});
  String get statusTimeout =>
      _data['statusTimeout'] ?? 'Connection timed out during upload';
  String statusUploadFailed(String message) =>
      tr('statusUploadFailed', args: {'message': message});
  String statusUnexpectedError(String error) =>
      tr('statusUnexpectedError', args: {'error': error});
  String get statusCannotResolvePath =>
      _data['statusCannotResolvePath'] ?? 'Cannot resolve file path';
  String get statusServerRequiresAuth =>
      _data['statusServerRequiresAuth'] ?? 'Server requires authentication';
  String get statusAuthFailedDetail =>
      _data['statusAuthFailedDetail'] ?? 'Authentication failed';
  String get statusAccessDenied =>
      _data['statusAccessDenied'] ?? 'Access denied (HTTP 403)';
  String get statusConnectionTimeout =>
      _data['statusConnectionTimeout'] ?? 'Connection timed out';
  String statusConnectionError(String message) =>
      tr('statusConnectionError', args: {'message': message});
  String statusConnectionFailed(String message) =>
      tr('statusConnectionFailed', args: {'message': message});
  String statusConnected(int code) =>
      tr('statusConnected', args: {'code': '$code'});
  String statusServerResponded(int code) =>
      tr('statusServerResponded', args: {'code': '$code'});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final langCode = locale.languageCode;
    final data = translations[langCode] ?? translations['en']!;
    return AppLocalizations(locale, data);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
