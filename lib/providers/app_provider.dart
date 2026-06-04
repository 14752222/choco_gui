import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/package_model.dart';
import '../services/choco_service.dart';

/// Global application state managed via [ChangeNotifier].
///
/// Access via [AppProviderScope.of(context)] from any widget.
class AppProvider extends ChangeNotifier {
  final ChocoService _service = ChocoService();

  // ---- Theme -----------------------------------------------------------------
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Exposed as [ValueNotifier] so [ChocoApp] can rebuild the [MaterialApp]
  /// without rebuilding the full widget tree.
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = _themeMode;
    notifyListeners();
  }

  // ---- Install Directory -----------------------------------------------------
  /// Default install directory. Empty string means use Chocolatey's default.
  String _installDir = '';
  String get installDir => _installDir;

  /// Chocolatey 实际安装路径 (from env:ChocolateyInstall)
  String _chocoInstallPath = '';
  String get chocoInstallPath => _chocoInstallPath;

  static const _kInstallDirKey = 'install_dir';

  /// Load the persisted install directory from SharedPreferences.
  Future<void> loadInstallDir() async {
    final prefs = await SharedPreferences.getInstance();
    _installDir = prefs.getString(_kInstallDirKey) ?? '';
    _chocoInstallPath = await _service.getChocoInstallPath();
    notifyListeners();
  }

  void setInstallDir(String dir) {
    _installDir = dir.trim();
    // Persist immediately
    SharedPreferences.getInstance().then((prefs) {
      if (_installDir.isEmpty) {
        prefs.remove(_kInstallDirKey);
      } else {
        prefs.setString(_kInstallDirKey, _installDir);
      }
    });
    notifyListeners();
  }

  // ---- Source management -----------------------------------------------------
  List<ChocoSource> _sources = [];
  List<ChocoSource> get sources => _sources;
  bool _loadingSources = false;
  bool get loadingSources => _loadingSources;

  Future<void> loadSources() async {
    _loadingSources = true;
    notifyListeners();
    _sources = await _service.listSources();
    _loadingSources = false;
    notifyListeners();
  }

  Future<bool> addSource({
    required String name,
    required String url,
    int? priority,
  }) async {
    final result = await _service.addSource(name: name, url: url, priority: priority);
    if (result) await loadSources();
    return result;
  }

  Future<bool> removeSource(String name) async {
    final result = await _service.removeSource(name);
    if (result) await loadSources();
    return result;
  }

  Future<bool> enableSource(String name) async {
    final result = await _service.enableSource(name);
    if (result) await loadSources();
    return result;
  }

  Future<bool> disableSource(String name) async {
    final result = await _service.disableSource(name);
    if (result) await loadSources();
    return result;
  }

  // ---- Chocolatey detection --------------------------------------------------
  bool _chocoInstalled = false;
  bool get chocoInstalled => _chocoInstalled;

  String _chocoVersion = '';
  String get chocoVersion => _chocoVersion;

  bool _detectingChoco = false;
  bool get detectingChoco => _detectingChoco;

  Future<void> detectChoco() async {
    _detectingChoco = true;
    notifyListeners();

    _chocoInstalled = await _service.isChocoInstalled();
    if (_chocoInstalled) {
      _chocoVersion = await _service.getChocoVersion() ?? '';
    } else {
      _chocoVersion = '';
    }

    _detectingChoco = false;
    notifyListeners();
  }

  // ---- Chocolatey self-install log ------------------------------------------
  String _chocoInstallLog = '';
  String get chocoInstallLog => _chocoInstallLog;

  Future<bool> installChocolatey() async {
    _chocoInstallLog = '';
    notifyListeners();

    final result = await _service.installChocolatey(
      onOutput: (line) {
        _chocoInstallLog += '$line\n';
        notifyListeners();
      },
    );
    if (result) {
      await detectChoco();
    }
    return result;
  }

  /// 清理 Chocolatey 安装失败遗留的缓存文件。
  /// 返回清理结果日志列表。
  Future<List<String>> cleanupChocoFailedInstall() async {
    return _service.cleanupFailedInstall();
  }

  // ---- Installed packages ----------------------------------------------------
  List<PackageModel> _installedPackages = [];
  List<PackageModel> get installedPackages => _installedPackages;

  bool _loadingInstalled = false;
  bool get loadingInstalled => _loadingInstalled;

  int _installedPage = 0;
  int get installedPage => _installedPage;

  static const int pageSize = 20;

  int get installedTotalPages =>
      (_installedPackages.length / pageSize).ceil().clamp(1, 99999);

  List<PackageModel> get installedPageItems {
    final start = _installedPage * pageSize;
    final end = (start + pageSize).clamp(0, _installedPackages.length);
    if (start >= _installedPackages.length) return [];
    return _installedPackages.sublist(start, end);
  }

  // ---- Installed package paths -----------------------------------------------
  /// Map of packageName.toLowerCase() -> install path
  Map<String, String> _packagePaths = {};
  Map<String, String> get packagePaths => _packagePaths;

  bool _loadingPaths = false;
  bool get loadingPaths => _loadingPaths;

  /// Returns the install path for [packageName], or null if not found.
  String? getPackagePath(String packageName) =>
      _packagePaths[packageName.toLowerCase()];

  Future<void> loadInstalledPackages() async {
    _loadingInstalled = true;
    _installedPage = 0;
    notifyListeners();

    _installedPackages = await _service.listInstalled();
    _loadingInstalled = false;
    notifyListeners();

    // Load paths in background
    _loadPackagePaths();
  }

  Future<void> _loadPackagePaths() async {
    _loadingPaths = true;
    notifyListeners();
    _packagePaths = await _service.getInstalledPackagePaths();
    _loadingPaths = false;
    notifyListeners();
  }

  void setInstalledPage(int page) {
    if (page < 0 || page >= installedTotalPages) return;
    _installedPage = page;
    notifyListeners();
  }

  // ---- Search ----------------------------------------------------------------
  List<PackageModel> _searchResults = [];
  List<PackageModel> get searchResults => _searchResults;

  bool _searching = false;
  bool get searching => _searching;

  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  int _searchPage = 0;
  int get searchPage => _searchPage;

  int get searchTotalPages =>
      (_searchResults.length / pageSize).ceil().clamp(1, 99999);

  List<PackageModel> get searchPageItems {
    final start = _searchPage * pageSize;
    final end = (start + pageSize).clamp(0, _searchResults.length);
    if (start >= _searchResults.length) return [];
    return _searchResults.sublist(start, end);
  }

  Future<void> searchPackages(String query, {bool exact = false}) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _lastQuery = '';
      _searchPage = 0;
      notifyListeners();
      return;
    }

    _searching = true;
    _lastQuery = query;
    _searchPage = 0;
    notifyListeners();

    _searchResults = await _service.search(query, exact: exact);
    _searching = false;
    notifyListeners();
  }

  void setSearchPage(int page) {
    if (page < 0 || page >= searchTotalPages) return;
    _searchPage = page;
    notifyListeners();
  }

  // ---- Install / Uninstall ---------------------------------------------------
  bool _operationInProgress = false;
  bool get operationInProgress => _operationInProgress;

  String _operationLog = '';
  String get operationLog => _operationLog;

  bool _lastOperationSuccess = false;
  bool get lastOperationSuccess => _lastOperationSuccess;

  /// Installs [packageName]. Optionally pass [installDir] to override the
  /// location for this single installation. Falls back to [_installDir].
  Future<bool> installPackage(
    String packageName, {
    String? installDir,
    String? version,
  }) async {
    _operationInProgress = true;
    _operationLog = '';
    notifyListeners();

    final effectiveDir =
        (installDir != null && installDir.trim().isNotEmpty)
            ? installDir.trim()
            : (_installDir.isNotEmpty ? _installDir : null);

    final result = await _service.installPackage(
      packageName,
      installDir: effectiveDir,
      version: version,
      onOutput: (line) {
        _operationLog += '$line\n';
        notifyListeners();
      },
    );

    _operationInProgress = false;
    _lastOperationSuccess = result;
    notifyListeners();

    if (result) {
      await loadInstalledPackages();
    }

    return result;
  }

  /// Uninstalls [packageName]. Streams output into [operationLog].
  Future<bool> uninstallPackage(String packageName) async {
    _operationInProgress = true;
    _operationLog = '';
    notifyListeners();

    final result = await _service.uninstallPackage(
      packageName,
      onOutput: (line) {
        _operationLog += '$line\n';
        notifyListeners();
      },
    );

    _operationInProgress = false;
    _lastOperationSuccess = result;
    notifyListeners();

    if (result) {
      await loadInstalledPackages();
    }

    return result;
  }

  /// Clears the streaming operation log.
  void clearOperationLog() {
    _operationLog = '';
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// InheritedWidget scope
// ---------------------------------------------------------------------------

/// Injects [AppProvider] into the widget tree via [InheritedNotifier].
///
/// All descendants can call [AppProviderScope.of(context)] to get the
/// provider and subscribe to rebuild notifications.
class AppProviderScope extends InheritedNotifier<AppProvider> {
  const AppProviderScope({
    super.key,
    required AppProvider provider,
    required super.child,
  }) : super(notifier: provider);

  /// Returns the nearest [AppProvider]. Subscribes the calling widget to
  /// rebuild when the provider calls [notifyListeners].
  static AppProvider of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppProviderScope>();
    assert(scope != null, 'No AppProviderScope found in widget tree');
    return scope!.notifier!;
  }
}
