class DufsServer {
  final String id;
  String name;
  String baseUrl;
  String defaultRemoteDir;
  String username;
  bool hasPassword;
  bool isDefault;
  DateTime createdAt;
  DateTime updatedAt;

  DufsServer({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.defaultRemoteDir = '',
    this.username = '',
    this.hasPassword = false,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'defaultRemoteDir': defaultRemoteDir,
        'username': username,
        'hasPassword': hasPassword,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DufsServer.fromJson(Map<String, dynamic> json) => DufsServer(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        defaultRemoteDir: json['defaultRemoteDir'] as String? ?? '',
        username: json['username'] as String? ?? '',
        hasPassword: json['hasPassword'] as bool? ?? false,
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  DufsServer copyWith({
    String? name,
    String? baseUrl,
    String? defaultRemoteDir,
    String? username,
    bool? hasPassword,
    bool? isDefault,
  }) =>
      DufsServer(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        defaultRemoteDir: defaultRemoteDir ?? this.defaultRemoteDir,
        username: username ?? this.username,
        hasPassword: hasPassword ?? this.hasPassword,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
