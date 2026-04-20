/// 이력 엔트리 ID를 생성한다.
///
/// 형식: `log_YYYYMMDD_HHMMSS` (tech_spec.md 2.3항)
String buildEntryId(DateTime now) {
  final d = '${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final t = '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
  return 'log_${d}_$t';
}

/// 이력 타임라인 표시용 날짜/시각 포맷.
///
/// 형식: `YYYY-MM-DD  HH:MM`
String formatDisplayDateTime(DateTime dt) {
  final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
  final t = '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
  return '$d  $t';
}

/// D-Day 기준일로부터 오늘까지 경과일을 계산한다.
///
/// [ddayAnchor]: ISO 8601 날짜 문자열 (예: "2026-01-15")
/// 반환값: 경과 일수 (0 이상). 파싱 실패 시 0을 반환한다.
int calcDdayElapsed(String ddayAnchor) {
  final anchor = DateTime.tryParse(ddayAnchor);
  if (anchor == null) return 0;
  final today = DateTime.now();
  final diff = DateTime(today.year, today.month, today.day)
      .difference(DateTime(anchor.year, anchor.month, anchor.day));
  return diff.inDays.clamp(0, diff.inDays.abs());
}

/// 사진 파일명을 생성한다.
///
/// 형식: `YYYYMMDD_HHMMSS_{plantId앞8자리}.jpg` (tech_spec.md 2.4항)
/// [now]를 주입받아 테스트 시 고정 시각을 사용할 수 있다.
String buildPhotoFilename(String plantId, DateTime now) {
  final date = '${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final time = '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
  final shortId = plantId.replaceAll('-', '').substring(0, 8);
  return '${date}_${time}_$shortId.jpg';
}
