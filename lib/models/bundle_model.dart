/// 单个软件选项（免费或付费）
class SoftwareOption {
  final String name;
  final String chocoPackage;
  final String pricingType; // "free" | "paid"
  final String? priceHint; // 付费版价格提示，如 "$149/年"
  final String? description;

  const SoftwareOption({
    required this.name,
    required this.chocoPackage,
    this.pricingType = 'free',
    this.priceHint,
    this.description,
  });

  bool get isFree => pricingType == 'free';
  bool get isPaid => pricingType == 'paid';

  factory SoftwareOption.fromJson(Map<String, dynamic> json) {
    return SoftwareOption(
      name: json['name'] as String,
      chocoPackage: json['chocoPackage'] as String,
      pricingType: (json['pricingType'] as String?) ?? 'free',
      priceHint: json['priceHint'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'chocoPackage': chocoPackage,
        'pricingType': pricingType,
        if (priceHint != null) 'priceHint': priceHint,
        if (description != null) 'description': description,
      };
}

/// 一个软件槽位，包含免费和付费的替代选项
class SoftwareSlot {
  /// 槽位名称，如 "IDE", "数据库"
  final String slotName;

  /// 槽位说明
  final String description;

  /// 备选软件列表，options[0] 始终是免费选项（默认选中）
  final List<SoftwareOption> options;

  const SoftwareSlot({
    required this.slotName,
    required this.description,
    required this.options,
  });

  /// 默认选中索引：始终为 0（免费选项）
  int get defaultSelectedIndex => 0;

  /// 是否有多个选项可供切换
  bool get hasAlternatives => options.length > 1;

  factory SoftwareSlot.fromJson(Map<String, dynamic> json) {
    return SoftwareSlot(
      slotName: json['slotName'] as String,
      description: json['description'] as String? ?? '',
      options: (json['options'] as List<dynamic>)
          .map((e) => SoftwareOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'slotName': slotName,
        'description': description,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

/// 推荐套餐
class RecommendedBundle {
  final String id;
  final String name;
  final String icon; // emoji icon
  final String description;
  final List<SoftwareSlot> slots;

  const RecommendedBundle({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.slots,
  });

  /// 套餐中包含的软件总数（所有槽位可选软件数之和）
  int get totalOptionCount =>
      slots.fold(0, (sum, slot) => sum + slot.options.length);

  /// 默认选中的包名列表（每个槽位选免费版）
  List<String> get defaultPackageNames =>
      slots.map((s) => s.options[s.defaultSelectedIndex].chocoPackage).toList();

  factory RecommendedBundle.fromJson(Map<String, dynamic> json) {
    return RecommendedBundle(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String? ?? '',
      slots: (json['slots'] as List<dynamic>)
          .map((e) => SoftwareSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'slots': slots.map((e) => e.toJson()).toList(),
      };
}
