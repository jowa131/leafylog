import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini API와 통신하는 클라이언트.
///
/// 모델: `gemini-1.5-flash` (MVP 모바일 환경 Latency 최소화)
/// API 키: [GeminiApiClient] 생성 시 외부에서 주입받는다.
/// 재시도: HTTP 429/503 발생 시 Exponential Backoff (1s → 2s → 4s, 최대 3회).
class GeminiApiClient {
  GeminiApiClient({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
      ),
    );
  }

  late final GenerativeModel _model;

  static const _maxAttempts = 3;

  /// 이미지와 텍스트 프롬프트를 멀티모달로 전송하고 응답 텍스트를 반환한다.
  ///
  /// [imageBytes]: JPEG 압축된 이미지 바이트
  /// [prompt]: 시스템 프롬프트 + 컨텍스트가 조합된 전체 프롬프트
  ///
  /// 재시도 가능한 오류(429/503)는 Exponential Backoff 후 최대 3회 재시도한다.
  Future<String> analyze({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    final content = Content.multi([
      DataPart('image/jpeg', imageBytes),
      TextPart(prompt),
    ]);

    return _callWithRetry(content);
  }

  /// 사진을 보고 식물 등록 폼 자동완성 정보를 반환한다.
  ///
  /// 반환 JSON 예시:
  /// {"species": "Monstera deliciosa", "watering_interval_days": 7, "summary": "한 줄 요약"}
  Future<String> autofill({required Uint8List imageBytes}) async {
    const prompt = '''
첨부된 사진에서 식물 종명을 식별하고, 아래 JSON 형식으로만 응답하십시오.
{
  "species": "학명 또는 통용명 (한국어 가능)",
  "watering_interval_days": 7,
  "summary": "식물 상태 한 줄 요약"
}
식별이 불가능하면 species를 빈 문자열로 두고 watering_interval_days는 7로 반환하십시오.
''';
    final content = Content.multi([
      DataPart('image/jpeg', imageBytes),
      TextPart(prompt),
    ]);
    return _callWithRetry(content);
  }

  /// Exponential Backoff 재시도 래퍼.
  ///
  /// 지연 시간: 1s, 2s, 4s (2^attempt * 1000ms)
  Future<String> _callWithRetry(Content content) async {
    Object? lastError;

    for (int attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await _model.generateContent([content]);
        return response.text ?? '';
      } catch (e) {
        lastError = e;
        if (!_isRetryable(e) || attempt == _maxAttempts - 1) break;

        final delayMs = 1000 * (1 << attempt); // 1s, 2s, 4s
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    throw Exception('Gemini API 호출 실패 ($_maxAttempts회 시도): $lastError');
  }

  /// 재시도 가능한 오류인지 판별한다.
  ///
  /// HTTP 429 (Rate Limit), 503 (Service Unavailable) 해당.
  bool _isRetryable(Object e) {
    if (e is ServerException) {
      return e.message.contains('429') ||
          e.message.contains('503') ||
          e.message.toLowerCase().contains('resource exhausted') ||
          e.message.toLowerCase().contains('unavailable');
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('503') ||
        msg.contains('rate') ||
        msg.contains('exhausted') ||
        msg.contains('unavailable');
  }
}
