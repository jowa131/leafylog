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

  /// Tistory OAuth access token. 미연동 시 null
  @HiveField(2)
  String? tistoryAccessToken;

  AppSettingsHiveModel({
    this.isDarkMode = false,
    this.notificationsEnabled = true,
    this.tistoryAccessToken,
  });
}
