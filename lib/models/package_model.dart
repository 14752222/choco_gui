/// Data model representing a Chocolatey package.
class PackageModel {
  /// The package identifier / name (e.g. 'git').
  final String name;

  /// The installed or available version string.
  final String version;

  /// Optional short description (available in search results).
  final String description;

  /// Whether this package is currently installed locally.
  final bool isInstalled;

  const PackageModel({
    required this.name,
    required this.version,
    this.description = '',
    this.isInstalled = false,
  });

  /// Creates a copy with optional field overrides.
  PackageModel copyWith({
    String? name,
    String? version,
    String? description,
    bool? isInstalled,
  }) {
    return PackageModel(
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }

  @override
  String toString() => 'PackageModel(name: $name, version: $version)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageModel &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Represents a Chocolatey source (repository / feed).
class ChocoSource {
  final String name;
  final String url;
  final bool disabled;
  final String? username;
  final int? priority;

  const ChocoSource({
    required this.name,
    required this.url,
    this.disabled = false,
    this.username,
    this.priority,
  });
}
