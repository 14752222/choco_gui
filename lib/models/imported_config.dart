import 'dart:convert';

/// 导入/导出的配置模型
///
/// 用于分享软件配置清单。支持 JSON 序列化/反序列化。
class ImportedConfig {
  final String name;
  final String? description;
  final String? author;
  final List<String> packages;

  const ImportedConfig({
    required this.name,
    this.description,
    this.author,
    required this.packages,
  });

  /// 从 JSON Map 反序列化
  factory ImportedConfig.fromJson(Map<String, dynamic> json) {
    final packages = <String>[];
    if (json['packages'] is List) {
      for (final p in json['packages']) {
        if (p is String && p.trim().isNotEmpty) {
          packages.add(p.trim());
        }
      }
    }
    return ImportedConfig(
      name: (json['name'] as String?) ?? '未命名配置',
      description: json['description'] as String?,
      author: json['author'] as String?,
      packages: packages,
    );
  }

  /// 从 JSON 字符串反序列化
  factory ImportedConfig.fromString(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ImportedConfig.fromJson(data);
  }

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() => {
        'version': 1,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (author != null && author!.isNotEmpty) 'author': author,
        'packages': packages,
      };

  /// 序列化为格式化的 JSON 字符串
  String toJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  /// 是否有效（至少有一个包名）
  bool get isValid => packages.isNotEmpty;
}
