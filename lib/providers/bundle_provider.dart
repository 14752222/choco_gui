import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bundle_model.dart';
import '../models/imported_config.dart';
import '../services/choco_service.dart';

/// 套餐状态管理
///
/// 负责加载 JSON 数据、管理每个槽位的选中选项、
/// 执行一键批量安装。
class BundleProvider extends ChangeNotifier {
  final ChocoService _service = ChocoService();

  // ---- 套餐列表 ----
  List<RecommendedBundle> _bundles = [];
  List<RecommendedBundle> get bundles => _bundles;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // ---- 用户选择状态 ----
  /// key: "${bundleId}:${slotIndex}" → 用户选中的 option 索引集合
  /// 默认每个槽位选中 options[0]（免费选项）
  Map<String, Set<int>> _selectedOptions = {};

  /// key: "${bundleId}:${slotIndex}" → 表示该槽位被取消勾选（整体不安装）
  final Set<String> _disabledSlots = {};

  /// 检查某个 slot 是否被勾选（默认全部勾选，除非用户主动取消）
  bool isSlotEnabled(String bundleId, int slotIndex) {
    return !_disabledSlots.contains('$bundleId:$slotIndex');
  }

  /// 切换某个 slot 的启用/禁用状态
  void toggleSlot(String bundleId, int slotIndex) {
    final key = '$bundleId:$slotIndex';
    if (_disabledSlots.contains(key)) {
      _disabledSlots.remove(key);
    } else {
      _disabledSlots.add(key);
    }
    _savePreferences();
    notifyListeners();
  }

  /// 获取某个 slot 当前选中的所有 option 索引
  Set<int> getSelectedIndices(String bundleId, int slotIndex) {
    final key = '$bundleId:$slotIndex';
    return _selectedOptions[key] ?? {0}; // 默认选索引 0（免费）
  }

  /// 某个 option 是否被选中
  bool isOptionSelected(String bundleId, int slotIndex, int optionIndex) {
    return getSelectedIndices(bundleId, slotIndex).contains(optionIndex);
  }

  /// 切换某个 slot 内某个 option 的选中状态
  /// 至少保留一个选中项，不可全部取消
  void toggleSlotOption(String bundleId, int slotIndex, int optionIndex) {
    final key = '$bundleId:$slotIndex';
    final current = _selectedOptions[key] ?? {0};
    final updated = Set<int>.from(current);

    if (updated.contains(optionIndex)) {
      // 如果要取消的是最后一个选中项，阻止
      if (updated.length <= 1) return;
      updated.remove(optionIndex);
    } else {
      updated.add(optionIndex);
    }

    _selectedOptions[key] = updated;
    _savePreferences();
    notifyListeners();
  }

  /// 直接设置某个 slot 的选中集合（用于多选面板确认）
  void setSlotSelection(String bundleId, int slotIndex, Set<int> indices) {
    if (indices.isEmpty) return; // 不允许空选
    _selectedOptions['$bundleId:$slotIndex'] = indices;
    _savePreferences();
    notifyListeners();
  }

  // ---- 批量安装状态 ----
  bool _installing = false;
  bool get installing => _installing;

  double _installProgress = 0;
  double get installProgress => _installProgress;

  String _installLog = '';
  String get installLog => _installLog;

  String _currentPackage = '';
  String get currentPackage => _currentPackage;

  final List<String> _installResults = [];
  List<String> get installResults => _installResults;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  /// 加载套餐 JSON 数据和用户选择偏好
  Future<void> loadBundles() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final jsonStr =
          await rootBundle.loadString('lib/data/bundles/bundles.json');
      final List<dynamic> data = jsonDecode(jsonStr);
      _bundles = data
          .map((e) => RecommendedBundle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '加载套餐数据失败: $e';
    }

    // 加载用户选择偏好
    await _loadPreferences();

    _loading = false;
    notifyListeners();
  }

  /// 获取某个 bundle 中某个 slot 当前选中的所有 SoftwareOption
  List<SoftwareOption> getSelectedOptions(String bundleId, int slotIndex) {
    final bundle = _bundles.firstWhere(
      (b) => b.id == bundleId,
      orElse: () => throw Exception('Bundle not found: $bundleId'),
    );
    if (slotIndex >= bundle.slots.length) return [];
    final slot = bundle.slots[slotIndex];
    final indices = getSelectedIndices(bundleId, slotIndex);
    return indices
        .where((i) => i < slot.options.length)
        .map((i) => slot.options[i])
        .toList();
  }

  /// 获取某个 bundle 当前选中的所有包名列表（跳过已取消的槽位 + 多选展开）
  List<String> getSelectedPackageNames(String bundleId) {
    final bundle = _bundles.firstWhere((b) => b.id == bundleId);
    final names = <String>[];
    for (int i = 0; i < bundle.slots.length; i++) {
      if (!isSlotEnabled(bundleId, i)) continue;
      for (final opt in getSelectedOptions(bundleId, i)) {
        names.add(opt.chocoPackage);
      }
    }
    return names;
  }

  /// 获取某个 bundle 当前勾选的包数量（多选展开计数）
  int getSelectedCount(String bundleId) {
    final bundle = _bundles.firstWhere((b) => b.id == bundleId);
    int count = 0;
    for (int i = 0; i < bundle.slots.length; i++) {
      if (!isSlotEnabled(bundleId, i)) continue;
      count += getSelectedIndices(bundleId, i).length;
    }
    return count;
  }

  /// 一键安装整个套餐（一次 UAC 提权，批量安装）
  Future<bool> installBundle(String bundleId) async {
    if (_installing) return false;

    final packages = getSelectedPackageNames(bundleId);
    if (packages.isEmpty) return false;

    _installing = true;
    _installProgress = 0;
    _installLog = '';
    _currentPackage = '';
    _installResults.clear();
    _currentIndex = 0;
    _totalCount = packages.length;
    notifyListeners();

    bool allOk = true;

    await _service.installPackages(
      packages,
      onOutput: (line) {
        _installLog += '$line\n';

        // 检测包名行：--- [PACKAGE] name ---
        if (line.startsWith('--- [PACKAGE] ')) {
          final pkg = line.substring(15, line.length - 4).trim();
          _currentPackage = pkg;
          _currentIndex = packages.indexOf(pkg);
          if (_currentIndex >= 0) {
            _installProgress = _currentIndex / packages.length;
          }
        }

        // 检测结果行：EXIT:OK:name 或 EXIT:FAIL:name:code
        if (line.startsWith('EXIT:OK:')) {
          final pkg = line.substring(8).trim();
          _installResults.add('✅ $pkg 安装成功');
        } else if (line.startsWith('EXIT:FAIL:')) {
          final rest = line.substring(10);
          final colon = rest.lastIndexOf(':');
          final pkg = colon > 0 ? rest.substring(0, colon).trim() : rest.trim();
          final code = colon > 0 ? rest.substring(colon + 1).trim() : '?';
          _installResults.add('❌ $pkg 安装失败 (退出码: $code)');
          allOk = false;
        }

        notifyListeners();
      },
    );

    _installProgress = 1.0;
    _currentPackage = '';
    _installLog += '\n--- 安装完成 ---\n';
    _installLog +=
        '成功: ${_installResults.where((r) => r.startsWith('✅')).length} / '
        '失败: ${_installResults.where((r) => r.startsWith('❌')).length}\n';
    _installing = false;
    notifyListeners();

    return allOk;
  }

  /// 停止安装
  void cancelInstall() {
    _installing = false;
    notifyListeners();
  }

  /// 清理安装日志
  void clearInstallLog() {
    _installLog = '';
    _installResults.clear();
    notifyListeners();
  }

  // ---- 导出 / 导入 ----

  /// 导出当前套餐的选中配置为 ImportedConfig
  ImportedConfig exportBundleConfig(String bundleId) {
    final bundle = _bundles.firstWhere((b) => b.id == bundleId);
    final packages = getSelectedPackageNames(bundleId);
    return ImportedConfig(
      name: '${bundle.name} 配置',
      description: '从 Chocolatey GUI 导出的 ${bundle.name} 软件配置',
      packages: packages,
    );
  }

  /// 批量验证包名是否存在
  Future<Map<String, bool>> verifyPackages(List<String> packages) {
    return _service.verifyPackages(packages);
  }

  /// 一键安装导入的配置（仅安装验证通过的包）
  Future<bool> installImportedConfig(ImportedConfig config) async {
    if (_installing) return false;
    if (config.packages.isEmpty) return false;

    _installing = true;
    _installProgress = 0;
    _installLog = '';
    _currentPackage = '';
    _installResults.clear();
    _currentIndex = 0;
    _totalCount = config.packages.length;
    notifyListeners();

    bool allOk = true;

    await _service.installPackages(
      config.packages,
      onOutput: (line) {
        _installLog += '$line\n';

        if (line.startsWith('--- [PACKAGE] ')) {
          final pkg = line.substring(15, line.length - 4).trim();
          _currentPackage = pkg;
          _currentIndex = config.packages.indexOf(pkg);
          if (_currentIndex >= 0) {
            _installProgress = _currentIndex / config.packages.length;
          }
        }

        if (line.startsWith('EXIT:OK:')) {
          final pkg = line.substring(8).trim();
          _installResults.add('✅ $pkg 安装成功');
        } else if (line.startsWith('EXIT:FAIL:')) {
          final rest = line.substring(10);
          final colon = rest.lastIndexOf(':');
          final pkg = colon > 0 ? rest.substring(0, colon).trim() : rest.trim();
          final code = colon > 0 ? rest.substring(colon + 1).trim() : '?';
          _installResults.add('❌ $pkg 安装失败 (退出码: $code)');
          allOk = false;
        }

        notifyListeners();
      },
    );

    _installProgress = 1.0;
    _currentPackage = '';
    _installLog += '\n--- 安装完成 ---\n';
    _installLog +=
        '成功: ${_installResults.where((r) => r.startsWith('✅')).length} / '
        '失败: ${_installResults.where((r) => r.startsWith('❌')).length}\n';
    _installing = false;
    notifyListeners();

    return allOk;
  }

  // ---- 持久化 ----
  static const _kSelectedOptionsKey = 'bundle_selected_options';
  static const _kDisabledSlotsKey = 'bundle_disabled_slots';

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getString(_kSelectedOptionsKey);
      if (saved != null) {
        final Map<String, dynamic> data = jsonDecode(saved);
        _selectedOptions = data.map(
          (k, v) => MapEntry(k, (v as List<dynamic>).cast<int>().toSet()),
        );
      }

      final disabled = prefs.getStringList(_kDisabledSlotsKey);
      if (disabled != null) {
        _disabledSlots.addAll(disabled);
      }
    } catch (_) {
      _selectedOptions = {};
      _disabledSlots.clear();
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kSelectedOptionsKey,
        jsonEncode(_selectedOptions.map((k, v) => MapEntry(k, v.toList()))),
      );
      await prefs.setStringList(_kDisabledSlotsKey, _disabledSlots.toList());
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// InheritedWidget scope
// ---------------------------------------------------------------------------

class BundleProviderScope extends InheritedNotifier<BundleProvider> {
  const BundleProviderScope({
    super.key,
    required BundleProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static BundleProvider of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BundleProviderScope>();
    assert(scope != null, 'No BundleProviderScope found in widget tree');
    return scope!.notifier!;
  }
}
