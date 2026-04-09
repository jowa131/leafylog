import 'package:flutter_test/flutter_test.dart';
import 'package:leafylog/core/utils/json_parser.dart';

void main() {
  group('extractJson', () {
    test('날(raw) JSON 문자열을 그대로 반환한다', () {
      const input = '{"health_score": 82, "confidence": 0.91}';
      expect(extractJson(input), input);
    });

    test('```json 코드 블록에서 JSON을 추출한다', () {
      const input = '```json\n{"health_score": 75}\n```';
      expect(extractJson(input), '{"health_score": 75}');
    });

    test('``` 코드 블록(언어 없음)에서도 JSON을 추출한다', () {
      const input = '```\n{"health_score": 60}\n```';
      expect(extractJson(input), '{"health_score": 60}');
    });

    test('코드 블록 앞뒤에 텍스트가 있어도 JSON을 추출한다', () {
      const input =
          '분석 결과입니다.\n```json\n{"health_score": 90}\n```\n이상입니다.';
      expect(extractJson(input), '{"health_score": 90}');
    });

    test('JSON 블록이 없으면 FormatException을 던진다', () {
      expect(
        () => extractJson('건강 상태가 양호합니다.'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('parseAiResult', () {
    const validJson = '''
{
  "health_score": 82,
  "detected_issues": ["하엽 황화", "과습 의심"],
  "recommendations": ["물주기 10일로 조정"],
  "confidence": 0.91,
  "summary": "전체적으로 양호하다"
}''';

    test('유효한 JSON을 AiResult로 정확히 파싱한다', () {
      final result = parseAiResult(validJson);

      expect(result.healthScore, 82);
      expect(result.confidence, closeTo(0.91, 0.001));
      expect(result.detectedIssues, hasLength(2));
      expect(result.detectedIssues, contains('하엽 황화'));
      expect(result.recommendations, hasLength(1));
      expect(result.summary, '전체적으로 양호하다');
    });

    test('마크다운으로 감싸진 응답도 올바르게 파싱한다', () {
      final wrapped = '```json\n$validJson\n```';
      final result = parseAiResult(wrapped);
      expect(result.healthScore, 82);
    });

    test('health_score가 정수로 변환된다 (num → int)', () {
      const input = '{"health_score": 75.0, "detected_issues": [], '
          '"recommendations": [], "confidence": 0.8}';
      final result = parseAiResult(input);
      expect(result.healthScore, isA<int>());
      expect(result.healthScore, 75);
    });

    test('detected_issues / recommendations가 없으면 빈 리스트를 반환한다', () {
      const input =
          '{"health_score": 50, "confidence": 0.5}';
      final result = parseAiResult(input);
      expect(result.detectedIssues, isEmpty);
      expect(result.recommendations, isEmpty);
    });

    test('JSON이 아닌 문자열 입력 시 예외를 던진다', () {
      expect(
        () => parseAiResult('이것은 유효하지 않은 응답이다.'),
        throwsA(anything),
      );
    });

    test('필수 필드(health_score) 누락 시 예외를 던진다', () {
      const input = '{"confidence": 0.9, "detected_issues": []}';
      expect(() => parseAiResult(input), throwsA(anything));
    });
  });
}
