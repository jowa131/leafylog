import 'package:flutter_test/flutter_test.dart';
import 'package:leafylog/core/utils/date_utils.dart';

void main() {
  group('calcDdayElapsed', () {
    test('오늘 날짜를 기준일로 지정하면 0을 반환한다', () {
      final today = DateTime.now();
      final anchor =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(calcDdayElapsed(anchor), 0);
    });

    test('과거 날짜 기준일의 경과일을 정확히 계산한다', () {
      final anchor = DateTime.now().subtract(const Duration(days: 84));
      final anchorStr =
          '${anchor.year}-${anchor.month.toString().padLeft(2, '0')}-${anchor.day.toString().padLeft(2, '0')}';
      expect(calcDdayElapsed(anchorStr), 84);
    });

    test('파싱 불가능한 문자열 입력 시 0을 반환한다', () {
      expect(calcDdayElapsed('not-a-date'), 0);
      expect(calcDdayElapsed(''), 0);
    });
  });

  group('buildPhotoFilename', () {
    test('올바른 파일명 형식(YYYYMMDD_HHMMSS_ShortID.jpg)을 생성한다', () {
      const plantId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      final fixedTime = DateTime(2026, 4, 9, 14, 30, 22);

      final filename = buildPhotoFilename(plantId, fixedTime);

      expect(filename, '20260409_143022_a1b2c3d4.jpg');
    });

    test('파일명에 PlantID 앞 8자리(하이픈 제외)가 포함된다', () {
      const plantId = 'ff00ee11-0000-0000-0000-000000000000';
      final filename = buildPhotoFilename(plantId, DateTime(2026, 1, 1, 0, 0, 0));

      expect(filename, startsWith('20260101_000000_'));
      expect(filename, contains('ff00ee11'));
      expect(filename, endsWith('.jpg'));
    });

    test('월·일·시·분·초가 두 자리로 zero-padding된다', () {
      const plantId = 'a1b2c3d4-0000-0000-0000-000000000000';
      final filename = buildPhotoFilename(plantId, DateTime(2026, 1, 5, 3, 7, 9));

      expect(filename, startsWith('20260105_030709_'));
    });
  });
}
