import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/file/models/history_log_model.dart';
import '../data/remote/gemini/gemini_api_client.dart';
import '../domain/usecases/analyze_plant_use_case.dart';
import 'storage_providers.dart';

/// [GeminiApiClient] 싱글톤 Provider.
///
/// API 키를 Provider 계층에서 주입하여 클라이언트가 환경변수에 직접 의존하지 않는다.
final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return GeminiApiClient(apiKey: apiKey);
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
/// 화면 이탈 후 5분간 캐시를 유지하여 재진입 시 디스크 I/O를 생략한다.
final plantHistoryProvider = FutureProvider.autoDispose
    .family<HistoryLogModel, String>((ref, plantId) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final repo = ref.watch(fileSystemRepositoryProvider);
  return repo.readHistoryLog(plantId);
});
