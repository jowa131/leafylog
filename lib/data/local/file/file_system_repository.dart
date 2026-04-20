import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'models/history_log_model.dart';
import 'models/plant_model.dart';

/// 로컬 파일 시스템에서 plants.json과 history_log.json을 관리하는 저장소.
///
/// 디렉토리 구조 (tech_spec.md 2.1항):
/// ```
/// [AppDocDir]/leafylog/
/// ├── plants.json
/// └── plants/{UUID}/
///     ├── history_log.json
///     └── photos/
/// ```
class FileSystemRepository {
  static const _rootDir = 'leafylog';
  static const _plantsFile = 'plants.json';
  static const _historyFile = 'history_log.json';

  /// Isolate 파싱 임계값: 64KB 미만은 메인 스레드에서 파싱한다.
  ///
  /// 소규모 JSON에 Isolate 컨텍스트 스위칭 오버헤드가 더 크다.
  static const _isolateThresholdBytes = 64 * 1024;

  final _uuid = const Uuid();

  // ── 경로 헬퍼 ─────────────────────────────────────────────

  Future<Directory> _getRootDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final root = Directory('${appDir.path}/$_rootDir');
    if (!root.existsSync()) await root.create(recursive: true);
    return root;
  }

  Future<File> _getPlantsIndexFile() async {
    final root = await _getRootDir();
    return File('${root.path}/$_plantsFile');
  }

  Future<Directory> _getPlantDir(String plantId) async {
    final root = await _getRootDir();
    final dir = Directory('${root.path}/plants/$plantId');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _getPhotosDir(String plantId) async {
    final plantDir = await _getPlantDir(plantId);
    final photosDir = Directory('${plantDir.path}/photos');
    if (!photosDir.existsSync()) await photosDir.create(recursive: true);
    return photosDir;
  }

  // ── plants.json (Master Index) ────────────────────────────

  /// plants.json 전체를 읽어 [PlantsIndex]를 반환한다.
  ///
  /// 파일이 없으면 빈 인덱스를 반환한다.
  Future<PlantsIndex> readPlantsIndex() async {
    final file = await _getPlantsIndexFile();
    if (!file.existsSync()) return PlantsIndex.empty();

    final raw = await file.readAsString();
    if (raw.length < _isolateThresholdBytes) {
      return PlantsIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    return Isolate.run(
      () => PlantsIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    );
  }

  /// [PlantsIndex]를 plants.json에 덮어쓴다.
  Future<void> _writePlantsIndex(PlantsIndex index) async {
    final file = await _getPlantsIndexFile();
    final json = index.toJson();
    final encoded = json.toString().length < _isolateThresholdBytes
        ? const JsonEncoder.withIndent('  ').convert(json)
        : await Isolate.run(() => const JsonEncoder.withIndent('  ').convert(json));
    await file.writeAsString(encoded);
  }

  /// 새 식물을 등록하고, 생성된 UUID를 포함한 [PlantModel]을 반환한다.
  ///
  /// plants/{UUID}/ 디렉토리와 photos/ 하위 디렉토리를 자동 생성한다.
  /// plants.json 중복 검사 후 upsert한다.
  Future<PlantModel> registerPlant(PlantModel plant) async {
    final newPlant = PlantModel(
      id: _uuid.v4(),
      displayName: plant.displayName,
      species: plant.species,
      registeredAt: plant.registeredAt,
      thumbnail: plant.thumbnail,
      wateringIntervalDays: plant.wateringIntervalDays,
      ddayAnchor: plant.ddayAnchor,
      tags: plant.tags,
      isArchived: plant.isArchived,
    );

    // 디렉토리 구조 사전 생성
    await _getPhotosDir(newPlant.id);

    // 빈 history_log.json 생성
    await _writeHistoryLog(HistoryLogModel.empty(newPlant.id));

    // plants.json 업데이트
    final index = await readPlantsIndex();
    await _writePlantsIndex(index.upsert(newPlant));

    return newPlant;
  }

  /// 기존 식물 정보를 업데이트한다.
  Future<void> updatePlant(PlantModel plant) async {
    final index = await readPlantsIndex();
    await _writePlantsIndex(index.upsert(plant));
  }

  /// [plantId]에 해당하는 식물을 아카이브 처리한다 (완전 삭제 대신 이력 보존).
  Future<void> archivePlant(String plantId) async {
    final index = await readPlantsIndex();
    final plant = index.plants.firstWhere((p) => p.id == plantId);
    await _writePlantsIndex(index.upsert(plant.copyWith(isArchived: true)));
  }

  // ── history_log.json ──────────────────────────────────────

  /// [plantId]의 이력 로그를 읽어 반환한다.
  ///
  /// 파일이 없으면 빈 로그를 반환한다.
  Future<HistoryLogModel> readHistoryLog(String plantId) async {
    final plantDir = await _getPlantDir(plantId);
    final file = File('${plantDir.path}/$_historyFile');
    if (!file.existsSync()) return HistoryLogModel.empty(plantId);

    final raw = await file.readAsString();
    if (raw.length < _isolateThresholdBytes) {
      return HistoryLogModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    return Isolate.run(
      () => HistoryLogModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    );
  }

  Future<void> _writeHistoryLog(HistoryLogModel log) async {
    final plantDir = await _getPlantDir(log.plantId);
    final file = File('${plantDir.path}/$_historyFile');
    final json = log.toJson();
    final encoded = json.toString().length < _isolateThresholdBytes
        ? const JsonEncoder.withIndent('  ').convert(json)
        : await Isolate.run(() => const JsonEncoder.withIndent('  ').convert(json));
    await file.writeAsString(encoded);
  }

  /// [plantId]의 이력 로그에 [entry]를 추가한다.
  Future<void> appendHistoryEntry(String plantId, HistoryEntry entry) async {
    final log = await readHistoryLog(plantId);
    await _writeHistoryLog(log.append(entry));
  }

  /// [plantId]에 속한 사진 저장 경로를 반환한다.
  Future<String> getPhotosDirPath(String plantId) async {
    final dir = await _getPhotosDir(plantId);
    return dir.path;
  }

  /// 사전에 ID가 부여된 신규 식물을 저장한다.
  ///
  /// [PlantsNotifier]에서 낙관적 갱신 후 디스크 동기화 시 호출된다.
  Future<void> saveNewPlant(PlantModel plant) async {
    await _getPhotosDir(plant.id);
    await _writeHistoryLog(HistoryLogModel.empty(plant.id));
    final index = await readPlantsIndex();
    await _writePlantsIndex(index.upsert(plant));
  }
}
