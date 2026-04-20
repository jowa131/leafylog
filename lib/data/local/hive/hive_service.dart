import 'package:hive_flutter/hive_flutter.dart';

import 'app_settings_hive_model.dart';
import 'cache_entry_hive_model.dart';

/// Hive 박스 이름 상수
class HiveBoxNames {
  static const settings = 'settings';
  static const cache = 'cache';
}

/// Hive 초기화 및 박스 접근을 담당하는 서비스.
///
/// 앱 시작 시 [init]을 호출하여 모든 어댑터를 등록하고 박스를 연다.
class HiveService {
  late Box<AppSettingsHiveModel> _settingsBox;
  late Box<CacheEntryHiveModel> _cacheBox;

  /// Hive를 초기화하고 모든 박스를 연다.
  ///
  /// `main.dart`의 `runApp` 호출 전에 실행해야 한다.
  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(AppSettingsHiveModelAdapter());
    Hive.registerAdapter(CacheEntryHiveModelAdapter());

    _settingsBox = await Hive.openBox<AppSettingsHiveModel>(HiveBoxNames.settings);
    _cacheBox = await Hive.openBox<CacheEntryHiveModel>(HiveBoxNames.cache);

    // 설정 초기 데이터가 없으면 기본값으로 생성한다.
    if (_settingsBox.isEmpty) {
      await _settingsBox.put('default', AppSettingsHiveModel());
    }
  }

  // ── Settings ──────────────────────────────────────────────

  /// 현재 앱 설정을 반환한다.
  AppSettingsHiveModel getSettings() {
    return _settingsBox.get('default') ?? AppSettingsHiveModel();
  }

  /// 앱 설정을 저장한다.
  Future<void> saveSettings(AppSettingsHiveModel settings) async {
    await _settingsBox.put('default', settings);
  }

  // ── Cache ─────────────────────────────────────────────────

  /// [cacheKey]에 해당하는 유효한 캐시 항목을 반환한다. 없거나 만료됐으면 null.
  CacheEntryHiveModel? getCache(String cacheKey) {
    final entry = _cacheBox.get(cacheKey);
    if (entry == null || !entry.isValid) return null;
    return entry;
  }

  /// [cacheKey]로 캐시를 저장한다. TTL 기본값: 24시간.
  Future<void> putCache({
    required String cacheKey,
    required String jsonData,
    Duration ttl = const Duration(hours: 24),
  }) async {
    final entry = CacheEntryHiveModel.withTtl(cacheKey: cacheKey, jsonData: jsonData, ttl: ttl);
    await _cacheBox.put(cacheKey, entry);
  }

  /// 만료된 캐시 항목을 모두 삭제한다.
  ///
  /// 단일 순회로 만료 키를 수집하고, 없으면 deleteAll 호출을 건너뛴다.
  Future<void> evictExpiredCache() async {
    final expiredKeys = <dynamic>[];
    for (final key in _cacheBox.keys) {
      final entry = _cacheBox.get(key);
      if (entry != null && !entry.isValid) expiredKeys.add(key);
    }
    if (expiredKeys.isEmpty) return;
    await _cacheBox.deleteAll(expiredKeys);
  }

  /// 모든 박스를 닫는다.
  Future<void> close() async {
    await _settingsBox.close();
    await _cacheBox.close();
  }
}
