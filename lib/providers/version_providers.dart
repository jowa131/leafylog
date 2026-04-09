import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// 현재 앱 버전 상수.
///
/// 릴리즈 시 release_manager 스킬이 이 값을 함께 업데이트한다.
const String kAppVersion = '1.2.0';

/// version.json 엔드포인트.
const String _versionUrl =
    'http://mymel0dy.iptime.org/leafylog/version.json';

/// 서버 최신 버전과의 비교 결과.
enum VersionStatus { latest, updateAvailable, unknown }

/// 서버에서 최신 버전을 조회하여 현재 앱 버전과 비교한다.
///
/// 네트워크 오류나 파싱 실패 시 [VersionStatus.unknown]을 반환한다.
final versionStatusProvider =
    FutureProvider<VersionStatus>((ref) async {
  try {
    final response = await http
        .get(Uri.parse(_versionUrl))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return VersionStatus.unknown;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final latest = json['version'] as String? ?? '';

    return latest == kAppVersion
        ? VersionStatus.latest
        : VersionStatus.updateAvailable;
  } catch (_) {
    return VersionStatus.unknown;
  }
});
