// ignore_for_file: avoid_print
// 모델 JSON 직렬화 검증 스크립트 (flutter 의존 없음)
// 실행: dart run tool/verify_models.dart

import 'dart:convert';
import 'dart:io';

import 'package:leafylog/data/local/file/models/plant_model.dart';
import 'package:leafylog/data/local/file/models/history_log_model.dart';

void main() async {
  print('=== leafylog 모델 직렬화 검증 ===\n');

  // 1. PlantModel 직렬화 → 역직렬화 roundtrip 검증
  final plant = PlantModel(
    id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    displayName: '몬스테라 델리시오사',
    species: 'Monstera deliciosa',
    registeredAt: DateTime.parse('2026-01-15T09:00:00+09:00'),
    thumbnail: '20260409_143022_a1b2c3d4.jpg',
    wateringIntervalDays: 7,
    ddayAnchor: '2026-01-15',
    tags: ['실내', '관엽'],
    isArchived: false,
  );

  final plantJson = plant.toJson();
  final plantBack = PlantModel.fromJson(plantJson);
  assert(plantBack.id == plant.id, 'id 불일치');
  assert(plantBack.species == plant.species, 'species 불일치');
  assert(plantBack.tags.length == 2, 'tags 불일치');
  print('[PASS] PlantModel roundtrip 검증 완료');

  // 2. PlantsIndex upsert 검증
  final index = PlantsIndex.empty().upsert(plant);
  assert(index.plants.length == 1, 'upsert 실패');
  final updatedPlant = plant.copyWith(displayName: '몬스테라 (업데이트)');
  final updatedIndex = index.upsert(updatedPlant);
  assert(updatedIndex.plants.length == 1, '중복 insert 발생');
  assert(updatedIndex.plants.first.displayName == '몬스테라 (업데이트)', 'upsert 교체 실패');
  print('[PASS] PlantsIndex.upsert 검증 완료');

  // 3. HistoryEntry (AI_ANALYSIS) 직렬화 검증
  final entry = HistoryEntry(
    entryId: 'log_20260409_143022',
    timestamp: DateTime.parse('2026-04-09T14:30:22+09:00'),
    eventType: EventType.aiAnalysis,
    photoFile: '20260409_143022_a1b2c3d4.jpg',
    aiResult: AiResult(
      healthScore: 82,
      detectedIssues: ['하엽 황화', '과습 의심'],
      recommendations: ['물주기 주기를 10일로 늘릴 것'],
      confidence: 0.91,
      rawResponseHash: 'sha256:abcdef',
      summary: '전체적으로 양호하나 하엽 황화 관찰됨',
    ),
    userNote: '새 흙으로 분갈이 후 첫 분석',
    contextSnapshot: ContextSnapshot(species: 'Monstera deliciosa', ddayElapsed: 84),
  );

  final entryJson = entry.toJson();
  final entryBack = HistoryEntry.fromJson(entryJson);
  assert(entryBack.eventType == EventType.aiAnalysis, 'eventType 불일치');
  assert(entryBack.aiResult!.healthScore == 82, 'healthScore 불일치');
  assert(entryBack.contextSnapshot!.ddayElapsed == 84, 'ddayElapsed 불일치');
  print('[PASS] HistoryEntry(AI_ANALYSIS) roundtrip 검증 완료');

  // 4. 임시 plants.json 파일 생성 (data_inspector 검증용)
  final tmpDir = Directory('/tmp/leafylog');
  if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);

  final plantsIndex = PlantsIndex.empty().upsert(plant);
  final plantsFile = File('/tmp/leafylog/plants.json');
  plantsFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(plantsIndex.toJson()),
  );

  final histDir = Directory('/tmp/leafylog/plants/${plant.id}');
  if (!histDir.existsSync()) histDir.createSync(recursive: true);

  final log = HistoryLogModel.empty(plant.id).append(entry);
  final histFile = File('/tmp/leafylog/plants/${plant.id}/history_log.json');
  histFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(log.toJson()),
  );

  print('\n[생성] /tmp/leafylog/plants.json');
  print('[생성] /tmp/leafylog/plants/${plant.id}/history_log.json');
  print('\n=== 모든 검증 통과 ===');
}
