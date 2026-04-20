import 'package:hive/hive.dart';

part 'app_settings_hive_model.g.dart';

/// 앱 전역 설정을 Hive에 저장하는 모델.
///
/// Box 이름: `settings`
/// 테마, 알림 설정, Tistory OAuth 토큰을 보관한다.
@HiveType(typeId: 0)
class AppSettingsHiveModel extends HiveObject {
  /// 다크 모드 활성화 여부. 기본값: false
  @HiveField(0)
  bool isDarkMode;

  /// 물주기 알림 활성화 여부. 기본값: true
  @HiveField(1)
  bool notificationsEnabled;

  /// @deprecated Hive에 평문 저장은 보안 취약점이다.
  /// M5 Tistory 연동 시 이 필드를 읽지 말고 SecureTokenService.getTistoryToken()을 사용한다.
  /// 필드 자체는 기존 Hive 어댑터 호환성을 위해 유지한다 (fieldId: 2 불변).
  @HiveField(2)
  @Deprecated('Use SecureTokenService.getTistoryToken() instead')
  String? tistoryAccessToken;

  AppSettingsHiveModel({
    this.isDarkMode = false,
    this.notificationsEnabled = true,
    // ignore: deprecated_member_use_from_same_package
    this.tistoryAccessToken,
  });
}
