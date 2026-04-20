import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/local/file/models/plant_model.dart';

/// 식물 상세 화면 상단의 썸네일 + 기본 정보 카드.
class PlantInfoCard extends StatelessWidget {
  const PlantInfoCard({
    super.key,
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
