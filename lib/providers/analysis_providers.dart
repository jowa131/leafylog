import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/file/models/history_log_model.dart';
import '../data/remote/gemini/gemini_api_client.dart';
import '../domain/usecases/analyze_plant_use_case.dart';
import 'storage_providers.dart';

/// [GeminiApiClient] 싱글톤 Provider.
final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  return GeminiApiClient();
});

/// [AnalyzePlantUseCase] 싱글톤 Provider.
final analyzePlantUseCaseProvider = Provider<AnalyzePlantUseCase>((ref) {
  return AnalyzePlantUseCase(
    geminiClient: ref.watch(geminiApiClientProvider),
    fsRepo: ref.watch(fileSystemRepositoryProvider),
    photoService: ref.watch(photoServiceProvider),
  );
});

/// 특정 식물의 history_log를 비동기로 로드하는 Provider.
///
/// plantId를 family 파라미터로 받는다.
/// autoDispose로 화면을 벗어나면 자동 해제된다.
final plantHistoryProvider = FutureProvider.autoDispose
    .family<HistoryLogModel, String>((ref, plantId) async {
  final repo = ref.watch(fileSystemRepositoryProvider);
  return repo.readHistoryLog(plantId);
});
