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
/// 파싱 실패 시 [FormatException]을 던진다.
AiResult parseAiResult(String rawText) {
  final jsonStr = extractJson(rawText);
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

  return AiResult(
    healthScore: (decoded['health_score'] as num).toInt(),
    detectedIssues:
        List<String>.from(decoded['detected_issues'] as List<dynamic>? ?? []),
    recommendations:
        List<String>.from(decoded['recommendations'] as List<dynamic>? ?? []),
    confidence: (decoded['confidence'] as num).toDouble(),
    summary: decoded['summary'] as String?,
  );
}
