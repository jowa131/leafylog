import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';
import '../../data/local/file/models/history_log_model.dart';

/// 식물 이력 목록을 타임라인 형식으로 표시하는 위젯.
class HistoryTimeline extends StatelessWidget {
  const HistoryTimeline({super.key, required this.entries});

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
                  formatDisplayDateTime(entry.timestamp),
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
                    Text(
                      ai.summary!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
