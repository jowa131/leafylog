import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local/file/file_system_repository.dart';
import '../data/local/file/models/plant_model.dart';
import '../data/local/file/photo_service.dart';
import '../data/local/hive/hive_service.dart';

// ── 인프라 계층 Provider ──────────────────────────────────────

/// 앱 전역에서 공유하는 [HiveService] 인스턴스.
///
/// main.dart에서 [HiveService.init]이 완료된 후 주입(override)하여 사용한다.
final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('hiveServiceProvider는 main.dart에서 override해야 한다.');
});

/// 앱 전역에서 공유하는 [FileSystemRepository] 인스턴스.
final fileSystemRepositoryProvider = Provider<FileSystemRepository>((ref) {
  return FileSystemRepository();
});

/// 앱 전역에서 공유하는 [PhotoService] 인스턴스.
final photoServiceProvider = Provider<PhotoService>((ref) {
  final repo = ref.watch(fileSystemRepositoryProvider);
  return PhotoService(repo);
});

/// [getApplicationDocumentsDirectory] 경로를 캐싱하는 Provider.
///
/// 썸네일 이미지 경로 조합 시 사용한다.
final appDocDirProvider = FutureProvider<String>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
});

// ── 식물 목록 상태 Provider ───────────────────────────────────

/// 식물 목록(plants.json)을 비동기로 로드하는 Provider.
///
/// UI에서 ref.watch(plantsProvider)로 구독하면 목록 변경 시 자동 갱신된다.
final plantsProvider =
    StateNotifierProvider<PlantsNotifier, AsyncValue<List<PlantModel>>>((ref) {
  final repo = ref.watch(fileSystemRepositoryProvider);
  return PlantsNotifier(repo);
});

/// 식물 목록 상태를 관리하는 [StateNotifier].
///
/// 식물 등록·수정·아카이브 후 내부적으로 목록을 재로드한다.
class PlantsNotifier extends StateNotifier<AsyncValue<List<PlantModel>>> {
  PlantsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadPlants();
  }

  final FileSystemRepository _repo;

  /// plants.json을 읽어 상태를 갱신한다.
  Future<void> loadPlants() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final index = await _repo.readPlantsIndex();
      return index.plants.where((p) => !p.isArchived).toList();
    });
  }

  /// 새 식물을 등록하고 목록을 갱신한다.
  Future<PlantModel> registerPlant(PlantModel plant) async {
    final created = await _repo.registerPlant(plant);
    await loadPlants();
    return created;
  }

  /// 식물 정보를 수정하고 목록을 갱신한다.
  Future<void> updatePlant(PlantModel plant) async {
    await _repo.updatePlant(plant);
    await loadPlants();
  }

  /// 식물을 아카이브 처리하고 목록에서 제거한다.
  Future<void> archivePlant(String plantId) async {
    await _repo.archivePlant(plantId);
    await loadPlants();
  }
}
