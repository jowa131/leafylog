/// 식물 이력 로그(history_log.json)의 루트 모델.
///
/// tech_spec.md 2.3항 스키마를 정확히 따른다.
class HistoryLogModel {
  final String plantId;
  final List<HistoryEntry> entries;

  const HistoryLogModel({
    required this.plantId,
    required this.entries,
  });

  factory HistoryLogModel.empty(String plantId) =>
      HistoryLogModel(plantId: plantId, entries: []);

  factory HistoryLogModel.fromJson(Map<String, dynamic> json) => HistoryLogModel(
        plantId: json['plant_id'] as String,
        entries: (json['entries'] as List<dynamic>)
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'plant_id': plantId,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  /// [entry]를 목록 끝에 추가한 새 로그를 반환한다.
  HistoryLogModel append(HistoryEntry entry) {
    return HistoryLogModel(
      plantId: plantId,
      entries: [...entries, entry],
    );
  }
}

/// 식물 이력 이벤트 단위 모델.
class HistoryEntry {
  final String entryId;
  final DateTime timestamp;
  final EventType eventType;

  /// 연결된 사진 파일명. 사진 없는 이벤트는 null.
  final String? photoFile;

  /// AI 분석 결과. [EventType.aiAnalysis]일 때만 존재.
  final AiResult? aiResult;

  final String? userNote;

  /// 분석 시점의 식물 상태 스냅샷. [EventType.aiAnalysis]일 때만 존재.
  final ContextSnapshot? contextSnapshot;

  const HistoryEntry({
    required this.entryId,
    required this.timestamp,
    required this.eventType,
    this.photoFile,
    this.aiResult,
    this.userNote,
    this.contextSnapshot,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        entryId: json['entry_id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        eventType: EventType.fromString(json['event_type'] as String),
        photoFile: json['photo_file'] as String?,
        aiResult: json['ai_result'] != null
            ? AiResult.fromJson(json['ai_result'] as Map<String, dynamic>)
            : null,
        userNote: json['user_note'] as String?,
        contextSnapshot: json['context_snapshot'] != null
            ? ContextSnapshot.fromJson(
                json['context_snapshot'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'entry_id': entryId,
        'timestamp': timestamp.toIso8601String(),
        'event_type': eventType.value,
        'photo_file': photoFile,
        if (aiResult != null) 'ai_result': aiResult!.toJson(),
        'user_note': userNote,
        if (contextSnapshot != null)
          'context_snapshot': contextSnapshot!.toJson(),
      };
}

/// tech_spec.md 2.3항에 정의된 이벤트 타입.
enum EventType {
  aiAnalysis('AI_ANALYSIS'),
  watering('WATERING'),
  fertilizing('FERTILIZING'),
  repotting('REPOTTING'),
  userNote('USER_NOTE'),
  healthCheck('HEALTH_CHECK');

  const EventType(this.value);
  final String value;

  static EventType fromString(String s) =>
      EventType.values.firstWhere((e) => e.value == s);
}

/// Gemini AI 분석 결과 모델.
class AiResult {
  /// 건강 점수 (0~100)
  final int healthScore;
  final List<String> detectedIssues;
  final List<String> recommendations;

  /// 분석 신뢰도 (0.0~1.0). 0.7 미만이면 낮은 신뢰도 경고를 표시한다.
  final double confidence;

  /// 원본 응답 해시 (sha256). 재파싱 검증용.
  final String? rawResponseHash;

  /// 한 줄 요약
  final String? summary;

  const AiResult({
    required this.healthScore,
    required this.detectedIssues,
    required this.recommendations,
    required this.confidence,
    this.rawResponseHash,
    this.summary,
  });

  factory AiResult.fromJson(Map<String, dynamic> json) => AiResult(
        healthScore: json['health_score'] as int,
        detectedIssues:
            List<String>.from(json['detected_issues'] as List<dynamic>),
        recommendations:
            List<String>.from(json['recommendations'] as List<dynamic>),
        confidence: (json['confidence'] as num).toDouble(),
        rawResponseHash: json['raw_response_hash'] as String?,
        summary: json['summary'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'health_score': healthScore,
        'detected_issues': detectedIssues,
        'recommendations': recommendations,
        'confidence': confidence,
        if (rawResponseHash != null) 'raw_response_hash': rawResponseHash,
        if (summary != null) 'summary': summary,
      };
}

/// AI 분석 시점에 캡처된 식물 상태 스냅샷.
class ContextSnapshot {
  final String species;

  /// 분석 시점 기준 D+N 경과일
  final int ddayElapsed;

  const ContextSnapshot({required this.species, required this.ddayElapsed});

  factory ContextSnapshot.fromJson(Map<String, dynamic> json) => ContextSnapshot(
        species: json['species'] as String,
        ddayElapsed: json['dday_elapsed'] as int,
      );

  Map<String, dynamic> toJson() => {
        'species': species,
        'dday_elapsed': ddayElapsed,
      };
}
