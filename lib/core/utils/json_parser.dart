import 'dart:convert';

import '../../data/local/file/models/history_log_model.dart';

/// Gemini 응답 텍스트에서 JSON 블록을 추출한다.
///
/// 마크다운 코드 블록(```json ... ```) 또는 날(raw) JSON 모두 처리한다.
/// 추출 가능한 JSON이 없으면 [FormatException]을 던진다.
String extractJson(String text) {
  // ```json ... ``` 또는 ``` ... ``` 처리
  final codeBlock =
      RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
  if (codeBlock != null) return codeBlock.group(1)!.trim();

  // 중괄호로 감싸진 JSON 블록 탐색
  final jsonBlock = RegExp(r'\{[\s\S]*\}').firstMatch(text);
  if (jsonBlock != null) return jsonBlock.group(0)!.trim();

  throw const FormatException('응답에서 JSON 블록을 찾을 수 없다.');
}

/// [rawText]를 파싱하여 [AiResult]를 반환한다.
///
/// 필수 필드(health_score, confidence) 누락 또는 범위 위반 시 [FormatException]을 던진다.
AiResult parseAiResult(String rawText) {
  final jsonStr = extractJson(rawText);
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

  // 필수 필드 존재 검증
  if (decoded['health_score'] == null) {
    throw const FormatException('Gemini 응답에 health_score 필드가 없다.');
  }
  if (decoded['confidence'] == null) {
    throw const FormatException('Gemini 응답에 confidence 필드가 없다.');
  }

  final healthScore = (decoded['health_score'] as num).toInt();
  final confidence = (decoded['confidence'] as num).toDouble();

  // 값 범위 검증
  if (healthScore < 0 || healthScore > 100) {
    throw FormatException('health_score 범위 오류: $healthScore (0~100 이어야 한다)');
  }
  if (confidence < 0.0 || confidence > 1.0) {
    throw FormatException('confidence 범위 오류: $confidence (0.0~1.0 이어야 한다)');
  }

  return AiResult(
    healthScore: healthScore,
    detectedIssues:
        List<String>.from(decoded['detected_issues'] as List<dynamic>? ?? []),
    recommendations:
        List<String>.from(decoded['recommendations'] as List<dynamic>? ?? []),
    confidence: confidence,
    summary: decoded['summary'] as String?,
  );
}
