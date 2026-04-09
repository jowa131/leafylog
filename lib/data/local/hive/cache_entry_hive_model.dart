import 'package:hive/hive.dart';

part 'cache_entry_hive_model.g.dart';

/// Gemini API 응답을 TTL 기반으로 캐싱하는 Hive 모델.
///
/// Box 이름: `cache`
/// TTL 기본값: 24시간. [expiresAt] 이후 항목은 무효 처리된다.
@HiveType(typeId: 1)
class CacheEntryHiveModel extends HiveObject {
  /// 캐시 키 (plant_id + timestamp 조합 등)
  @HiveField(0)
  String cacheKey;

  /// 직렬화된 JSON 문자열
  @HiveField(1)
  String jsonData;

  /// 캐시 만료 시각 (UTC)
  @HiveField(2)
  DateTime expiresAt;

  CacheEntryHiveModel({
    required this.cacheKey,
    required this.jsonData,
    required this.expiresAt,
  });

  /// TTL 24시간으로 만료 시각을 자동 설정하여 생성한다.
  factory CacheEntryHiveModel.withTtl({
    required String cacheKey,
    required String jsonData,
    Duration ttl = const Duration(hours: 24),
  }) {
    return CacheEntryHiveModel(
      cacheKey: cacheKey,
      jsonData: jsonData,
      expiresAt: DateTime.now().toUtc().add(ttl),
    );
  }

  /// 현재 시각 기준 캐시 유효 여부를 반환한다.
  bool get isValid => DateTime.now().toUtc().isBefore(expiresAt);
}
