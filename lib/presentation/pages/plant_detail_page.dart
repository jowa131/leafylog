import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/crash_reporter.dart';
import '../../data/local/file/models/history_log_model.dart';
import '../../data/local/file/models/plant_model.dart';
import '../../providers/analysis_providers.dart';
import '../../providers/storage_providers.dart';
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

  int get _ddayElapsed {
    final anchor = DateTime.tryParse(widget.plant.ddayAnchor);
    if (anchor == null) return 0;
    return DateTime.now().difference(anchor).inDays;
  }

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

      // 이력 캐시 무효화 후 결과 화면으로 이동
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
      // 에러를 서버로 즉시 전송한다.
      CrashReporter.instance.report(
        message: 'AI 분석 실패: $e',
        stackTrace: stack.toString(),
        deviceInfo: {'plant_id': widget.plant.id, 'source': 'PlantDetailPage'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 중 오류가 발생했다. 잠시 후 다시 시도하라. ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final historyAsync =
        ref.watch(plantHistoryProvider(widget.plant.id));
    final appDocDirAsync = ref.watch(appDocDirProvider); // Provider<String>

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
            _PlantInfoCard(
              plant: widget.plant,
              ddayElapsed: _ddayElapsed,
              docDir: appDocDirAsync,
            ),
            const SizedBox(height: 20),
            Text('이력', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('이력 로드 실패: $e'),
              data: (log) => log.entries.isEmpty
                  ? Text(
                      '기록된 이력이 없다.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    )
                  : _HistoryTimeline(entries: log.entries.reversed.take(10).toList()),
            ),
            const SizedBox(height: 80), // FAB 여백
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('analyze_button'),
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
    );
  }
}

// ── 식물 정보 카드 ─────────────────────────────────────────────

class _PlantInfoCard extends StatelessWidget {
  const _PlantInfoCard({
    required this.plant,
    required this.ddayElapsed,
    required this.docDir,
  });

  final PlantModel plant;
  final int ddayElapsed;
  final String? docDir;

  String? get _thumbnailPath {
    if (docDir == null || plant.thumbnail == null) return null;
    return '$docDir/leafylog/plants/${plant.id}/photos/${plant.thumbnail}';
  }

  @override
  Widget build(BuildContext context) {
    final thumbPath = _thumbnailPath;
    final thumbFile = thumbPath != null ? File(thumbPath) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: (thumbFile != null && thumbFile.existsSync())
                ? Image.file(thumbFile, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: Icon(
                      Icons.local_florist_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  plant.species,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _InfoChip(label: 'D+$ddayElapsed'),
                    _InfoChip(label: '물주기 ${plant.wateringIntervalDays}일'),
                    ...plant.tags.map((t) => _InfoChip(label: t)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: Theme.of(context).textTheme.labelSmall),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── 이력 타임라인 ─────────────────────────────────────────────

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((e) => _TimelineItem(entry: e)).toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.entry});

  final HistoryEntry entry;

  String _formatDt(DateTime dt) {
    final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }

  IconData get _icon {
    switch (entry.eventType) {
      case EventType.aiAnalysis:
        return Icons.biotech_outlined;
      case EventType.watering:
        return Icons.water_drop_outlined;
      case EventType.fertilizing:
        return Icons.grass_outlined;
      case EventType.repotting:
        return Icons.yard_outlined;
      case EventType.healthCheck:
        return Icons.monitor_heart_outlined;
      case EventType.userNote:
        return Icons.note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = entry.aiResult;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.eventType.value,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _formatDt(entry.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                if (ai != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '건강 점수: ${ai.healthScore}점  신뢰도: ${(ai.confidence * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (ai.summary != null)
                    Text(ai.summary!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
                if (entry.userNote != null)
                  Text(
                    entry.userNote!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
