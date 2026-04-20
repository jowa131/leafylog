import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/crash_reporter.dart';
import '../../core/utils/date_utils.dart';
import '../../data/local/file/models/history_log_model.dart';
import '../../data/local/file/models/plant_model.dart';
import '../../providers/analysis_providers.dart';
import '../../providers/storage_providers.dart';
import '../widgets/add_growth_record_sheet.dart';
import '../widgets/history_timeline.dart';
import '../widgets/plant_info_card.dart';
import 'analysis_result_page.dart';

/// 식물 상세 화면.
///
/// 식물 정보, 이력 타임라인, AI 분석 버튼을 표시한다.
/// "AI 분석 시작" FAB → 사진 선택 → [AnalyzePlantUseCase] 실행 → [AnalysisResultPage].
class PlantDetailPage extends ConsumerStatefulWidget {
  const PlantDetailPage({super.key, required this.plant});

  final PlantModel plant;

  @override
  ConsumerState<PlantDetailPage> createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends ConsumerState<PlantDetailPage> {
  bool _isAnalyzing = false;
  bool _isSavingRecord = false;

  int get _ddayElapsed => calcDdayElapsed(widget.plant.ddayAnchor);

  // ── AI 분석 플로우 ────────────────────────────────────────

  void _startAnalysis() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '분석할 사진을 선택하라',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    setState(() => _isAnalyzing = true);
    try {
      final useCase = ref.read(analyzePlantUseCaseProvider);
      final result = await useCase.execute(
        plant: widget.plant,
        photoPath: file.path,
      );

      ref.invalidate(plantHistoryProvider(widget.plant.id));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultPage(result: result),
          ),
        );
      }
    } catch (e, stack) {
      CrashReporter.instance.report(
        message: 'AI 분석 실패: $e',
        stackTrace: stack.toString(),
        deviceInfo: {'plant_id': widget.plant.id, 'source': 'PlantDetailPage'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('분석 중 오류가 발생했다. 잠시 후 다시 시도하라.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ── 성장 기록 추가 플로우 ─────────────────────────────────

  void _showAddGrowthRecordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddGrowthRecordSheet(
        onSave: (note, photoPath) =>
            _saveGrowthRecord(note: note, photoPath: photoPath),
      ),
    );
  }

  /// USER_NOTE 이력 엔트리를 history_log.json에 저장한다.
  Future<void> _saveGrowthRecord({
    required String note,
    String? photoPath,
  }) async {
    if (note.isEmpty && photoPath == null) return;

    setState(() => _isSavingRecord = true);
    try {
      String? savedFilename;
      if (photoPath != null) {
        final photoService = ref.read(photoServiceProvider);
        savedFilename = await photoService.saveFromPath(
          sourcePath: photoPath,
          plantId: widget.plant.id,
        );
      }

      final now = DateTime.now();
      final entry = HistoryEntry(
        entryId: buildEntryId(now),
        timestamp: now,
        eventType: EventType.userNote,
        photoFile: savedFilename,
        userNote: note.isEmpty ? null : note,
      );

      final repo = ref.read(fileSystemRepositoryProvider);
      await repo.appendHistoryEntry(widget.plant.id, entry);

      ref.invalidate(plantHistoryProvider(widget.plant.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성장 기록이 저장됐다.')),
        );
      }
    } catch (e, stack) {
      CrashReporter.instance.report(
        message: '성장 기록 저장 실패: $e',
        stackTrace: stack.toString(),
        deviceInfo: {'plant_id': widget.plant.id, 'source': 'PlantDetailPage'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했다. 잠시 후 다시 시도하라.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingRecord = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(plantHistoryProvider(widget.plant.id));
    final docDir = ref.watch(appDocDirProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlantInfoCard(
              plant: widget.plant,
              ddayElapsed: _ddayElapsed,
              docDir: docDir,
            ),
            const SizedBox(height: 20),
            Text('이력', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('이력 로드 실패: $e'),
              data: (log) => log.entries.isEmpty
                  ? Text(
                      '기록된 이력이 없다.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    )
                  : HistoryTimeline(
                      entries: log.entries.reversed.take(10).toList(),
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            key: const Key('add_growth_record_button'),
            heroTag: 'add_growth',
            onPressed: (_isSavingRecord || _isAnalyzing)
                ? null
                : _showAddGrowthRecordSheet,
            tooltip: '성장 기록 추가',
            child: _isSavingRecord
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            key: const Key('analyze_button'),
            heroTag: 'analyze',
            onPressed: _isAnalyzing ? null : _startAnalysis,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.biotech_outlined),
            label: Text(_isAnalyzing ? '분석 중...' : 'AI 분석 시작'),
          ),
        ],
      ),
    );
  }
}
