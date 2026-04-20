import '../../core/utils/date_utils.dart';
import '../../core/utils/json_parser.dart';
import '../../data/local/file/file_system_repository.dart';
import '../../data/local/file/models/history_log_model.dart';
import '../../data/local/file/models/plant_model.dart';
import '../../data/local/file/photo_service.dart';
import '../../data/remote/gemini/gemini_api_client.dart';

/// Gemini AI 식물 분석 유스케이스.
///
/// 실행 순서 (tech_spec.md 3.3항):
/// 1. 사진 압축 저장 → 파일명 확보
/// 2. 컨텍스트 조립 (species + D-Day + 최근 이벤트)
/// 3. 시스템 프롬프트 생성 (tech_spec.md 3.2항 템플릿)
/// 4. Gemini API 멀티모달 호출 (재시도 포함)
/// 5. JSON 응답 파싱 → [AiResult]
/// 6. history_log.json에 AI_ANALYSIS 엔트리 저장
///
/// 파싱 실패 시 원시 응답을 USER_NOTE 엔트리로 저장한 뒤 예외를 던진다.
class AnalyzePlantUseCase {
  AnalyzePlantUseCase({
    required GeminiApiClient geminiClient,
    required FileSystemRepository fsRepo,
    required PhotoService photoService,
  })  : _gemini = geminiClient,
        _fsRepo = fsRepo,
        _photoService = photoService;

  final GeminiApiClient _gemini;
  final FileSystemRepository _fsRepo;
  final PhotoService _photoService;

  /// [plant]에 대해 [photoPath]를 기반으로 AI 분석을 실행한다.
  ///
  /// 성공 시 [AiResult]를 반환하고 history_log.json에 기록한다.
  Future<AiResult> execute({
    required PlantModel plant,
    required String photoPath,
  }) async {
    // 1. 사진 압축 저장 (photos/ 디렉토리)
    final filename = await _photoService.saveFromPath(
      sourcePath: photoPath,
      plantId: plant.id,
    );

    // 2. 저장된 압축 이미지 바이트 로드 (Gemini 전송용)
    final imageBytes = await _photoService.readSavedBytes(
      plantId: plant.id,
      filename: filename,
    );

    // 3. 컨텍스트 조립
    final context = await _buildContext(plant);

    // 4. 시스템 프롬프트 구성 (tech_spec.md 3.2항)
    final prompt = _buildPrompt(context);

    // 5. Gemini API 호출
    final String rawResponse;
    try {
      rawResponse = await _gemini.analyze(imageBytes: imageBytes, prompt: prompt);
    } catch (e) {
      throw Exception('Gemini API 호출 실패: $e');
    }

    // 6. JSON 파싱
    final AiResult result;
    try {
      result = _parseResponse(rawResponse);
    } catch (e) {
      // 파싱 실패 — 원시 응답을 로컬 로그에 보존 후 예외 재전파
      await _saveRawResponse(plant.id, rawResponse, filename);
      throw Exception('응답 JSON 파싱 실패. 원시 응답이 로컬 로그에 저장됐다. 원인: $e');
    }

    // 7. history_log.json에 AI_ANALYSIS 엔트리 저장
    final entry = HistoryEntry(
      entryId: buildEntryId(DateTime.now()),
      timestamp: DateTime.now(),
      eventType: EventType.aiAnalysis,
      photoFile: filename,
      aiResult: result,
      contextSnapshot: context.toSnapshot(),
    );
    await _fsRepo.appendHistoryEntry(plant.id, entry);

    return result;
  }

  // ── 컨텍스트 조립 ──────────────────────────────────────────

  Future<_AnalysisContext> _buildContext(PlantModel plant) async {
    final log = await _fsRepo.readHistoryLog(plant.id);

    // 최근 5개 이벤트를 요약한다
    final recentSummary = log.entries.reversed
        .take(5)
        .map((e) => '${e.eventType.value}(${_shortDate(e.timestamp)})')
        .join(', ');

    final ddayElapsed = calcDdayElapsed(plant.ddayAnchor);

    return _AnalysisContext(
      species: plant.species,
      ddayElapsed: ddayElapsed,
      recentEventsSummary: recentSummary.isEmpty ? '없음' : recentSummary,
    );
  }

  // ── 프롬프트 구성 (tech_spec.md 3.2항 템플릿) ────────────────

  String _buildPrompt(_AnalysisContext ctx) => '''
당신은 전문 식물 병리학자입니다.
아래 제공된 컨텍스트 정보를 반드시 참고하여 분석하십시오.

[식물 정보]
- 등록 종명: ${ctx.species}
- 관리 경과일: D+${ctx.ddayElapsed}
- 최근 이벤트: ${ctx.recentEventsSummary}

[분석 요청]
첨부된 사진을 바탕으로 이 식물(${ctx.species})의 건강 상태를 분석하십시오.
다른 식물로 오인하지 말고 반드시 위 종명을 기준으로 분석하십시오.

[응답 형식] 반드시 아래 JSON 형식으로만 응답하십시오:
{
  "health_score": 0-100,
  "detected_issues": ["이슈1", "이슈2"],
  "recommendations": ["권장사항1", "권장사항2"],
  "confidence": 0.0-1.0,
  "summary": "한 줄 요약"
}''';

  // ── JSON 파싱 (core/utils/json_parser.dart로 위임) ──────────

  AiResult _parseResponse(String raw) => parseAiResult(raw);

  // ── 파싱 실패 시 원시 응답 보존 ─────────────────────────────

  Future<void> _saveRawResponse(
    String plantId,
    String rawResponse,
    String photoFile,
  ) async {
    final entry = HistoryEntry(
      entryId: 'raw_${buildEntryId(DateTime.now())}',
      timestamp: DateTime.now(),
      eventType: EventType.userNote,
      photoFile: photoFile,
      userNote: '[파싱 실패 원시 응답] $rawResponse',
    );
    await _fsRepo.appendHistoryEntry(plantId, entry);
  }

  // ── 유틸 ──────────────────────────────────────────────────

  String _shortDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ── 내부 컨텍스트 모델 ────────────────────────────────────────

class _AnalysisContext {
  const _AnalysisContext({
    required this.species,
    required this.ddayElapsed,
    required this.recentEventsSummary,
  });

  final String species;
  final int ddayElapsed;
  final String recentEventsSummary;

  /// history_log.json에 저장할 스냅샷으로 변환한다.
  ContextSnapshot toSnapshot() =>
      ContextSnapshot(species: species, ddayElapsed: ddayElapsed);
}
