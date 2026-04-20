import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OAuth 토큰 등 민감한 자격증명을 Android Keystore에 암호화하여 저장하는 서비스.
///
/// flutter_secure_storage는 Android에서 EncryptedSharedPreferences를 사용하므로
/// 루팅된 기기에서도 키체인 수준의 보안을 제공한다.
///
/// 사용처:
/// - M5 Tistory OAuth access_token 저장/조회
class SecureTokenService {
  SecureTokenService._();

  static final SecureTokenService instance = SecureTokenService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyTistoryToken = 'tistory_access_token';

  // ── Tistory OAuth ────────────────────────────────────────────

  /// Tistory access_token을 저장한다.
  Future<void> saveTistoryToken(String token) async {
    await _storage.write(key: _keyTistoryToken, value: token);
  }

  /// 저장된 Tistory access_token을 반환한다. 없으면 null.
  Future<String?> getTistoryToken() async {
    return _storage.read(key: _keyTistoryToken);
  }

  /// Tistory access_token을 삭제한다 (로그아웃 시).
  Future<void> deleteTistoryToken() async {
    await _storage.delete(key: _keyTistoryToken);
  }

  // ── 공통 ─────────────────────────────────────────────────────

  /// 저장된 모든 토큰을 삭제한다 (앱 초기화 시).
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
