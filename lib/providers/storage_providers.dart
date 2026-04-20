import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

/// 앱 문서 디렉토리 경로. main.dart 기동 시 override하여 주입한다.
///
/// 썸네일 이미지 경로 조합 시 사용한다.
final appDocDirProvider = Provider<String>((ref) {
  throw UnimplementedError('appDocDirProvider는 main.dart에서 override해야 한다.');
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
/// 등록·수정·아카이브 시 메모리 상태를 먼저 선반영(Optimistic Update)하고,
/// 이후 디스크에 비동기로 동기화한다.
class PlantsNotifier extends StateNotifier<AsyncValue<List<PlantModel>>> {
  PlantsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadPlants();
  }

  final FileSystemRepository _repo;
  static const _uuid = Uuid();

  /// plants.json을 읽어 상태를 갱신한다.
  Future<void> loadPlants() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final index = await _repo.readPlantsIndex();
      return index.plants.where((p) => !p.isArchived).toList();
    });
  }

  /// 새 식물을 등록한다.
  ///
  /// 메모리 상태에 즉시 추가한 뒤(Optimistic Update) 디스크에 저장한다.
  /// 디스크 저장 실패 시 메모리 상태를 이전 값으로 롤백한다.
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
      isArchived: false,
    );

    final previous = state;
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, newPlant]);

    try {
      await _repo.saveNewPlant(newPlant);
    } catch (e) {
      state = previous;
      rethrow;
    }
    return newPlant;
  }

  /// 식물 정보를 수정한다.
  ///
  /// 메모리 상태를 먼저 교체하고(Optimistic Update) 디스크에 동기화한다.
  /// 디스크 저장 실패 시 메모리 상태를 이전 값으로 롤백한다.
  Future<void> updatePlant(PlantModel plant) async {
    final previous = state;
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((p) => p.id == plant.id ? plant : p).toList(),
    );

    try {
      await _repo.updatePlant(plant);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  /// 식물을 아카이브 처리하고 목록에서 즉시 제거한다.
  ///
  /// 디스크 저장 실패 시 메모리 상태를 이전 값으로 롤백한다.
  Future<void> archivePlant(String plantId) async {
    final previous = state;
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((p) => p.id != plantId).toList());

    try {
      await _repo.archivePlant(plantId);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}
