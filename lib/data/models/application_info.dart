import 'dart:typed_data';

/// Single authoritative model representing an installed application with its lock state.
class ApplicationInfo {
  final String name;
  final String packageName;
  final Uint8List? iconBytes;
  final String? versionName;
  final bool isSystemApp;
  final bool isKnoxProtected;
  bool isLocked;

  ApplicationInfo({
    required this.name,
    required this.packageName,
    this.iconBytes,
    this.versionName,
    this.isSystemApp = false,
    this.isKnoxProtected = false,
    this.isLocked = false,
  });

  ApplicationInfo copyWith({
    String? name,
    String? packageName,
    Uint8List? iconBytes,
    String? versionName,
    bool? isSystemApp,
    bool? isKnoxProtected,
    bool? isLocked,
  }) {
    return ApplicationInfo(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      iconBytes: iconBytes ?? this.iconBytes,
      versionName: versionName ?? this.versionName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isKnoxProtected: isKnoxProtected ?? this.isKnoxProtected,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Backward compatibility alias
typedef AppInfoItem = ApplicationInfo;

/// Authoritative application filtering state/type.
enum ApplicationFilter { all, locked }

/// Backward compatibility alias
typedef AppFilterType = ApplicationFilter;
