import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../data/local/file/models/plant_model.dart';
import '../../providers/storage_providers.dart';
import '../../providers/version_providers.dart';
import 'plant_detail_page.dart';
import 'plant_register_page.dart';

/// 등록된 식물 목록을 표시하는 메인 화면.
///
/// [plantsProvider]를 구독하여 등록·수정·아카이브 시 자동으로 갱신된다.
class PlantListPage extends ConsumerWidget {
  const PlantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final docDir = ref.watch(appDocDirProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('leafylog'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: plantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('목록 로드 실패: $e')),
        data: (plants) {
          if (plants.isEmpty) return const _EmptyState();
          return _PlantGrid(plants: plants, docDir: docDir);
        },
      ),
      bottomNavigationBar: const _VersionFooter(),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_plant_fab'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlantRegisterPage()),
        ),
        tooltip: '식물 등록',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 식물이 없을 때 표시하는 안내 위젯.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            '아직 등록된 식물이 없다.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 번째 식물을 추가하라.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

/// 식물 카드 그리드 위젯.
class _PlantGrid extends StatelessWidget {
  const _PlantGrid({required this.plants, required this.docDir});

  final List<PlantModel> plants;
  final String docDir;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: plants.length,
      itemBuilder: (_, i) => _PlantCard(
        plant: plants[i],
        docDir: docDir,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlantDetailPage(plant: plants[i]),
          ),
        ),
      ),
    );
  }
}

/// 개별 식물 카드 위젯.
class _PlantCard extends StatelessWidget {
  const _PlantCard({
    required this.plant,
    required this.docDir,
    required this.onTap,
  });

  final PlantModel plant;
  final String docDir;
  final VoidCallback onTap;

  // D-Day 계산을 core/utils/date_utils.dart 공용 함수로 통일한다.
  int get _ddayElapsed => calcDdayElapsed(plant.ddayAnchor);

  /// 썸네일 파일의 전체 경로를 반환한다.
  String? get _thumbnailPath {
    if (plant.thumbnail == null) return null;
    return '$docDir/leafylog/plants/${plant.id}/photos/${plant.thumbnail}';
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumbnailPath;
    final thumbFile = thumb != null ? File(thumb) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 썸네일 영역
          Expanded(
            child: (thumbFile != null && thumbFile.existsSync())
                ? Image.file(thumbFile, fit: BoxFit.cover, cacheWidth: 300)
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.local_florist_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
          ),
          // 정보 영역
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  plant.species,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _DdayChip(elapsed: _ddayElapsed),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// 앱 하단 버전 정보 푸터.
///
/// 서버 version.json과 비교하여 최신 여부를 표시한다.
class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(versionStatusProvider);

    final (statusText, statusColor) = statusAsync.when(
      loading: () => ('확인 중...', Colors.grey),
      error: (_, __) => ('Unknown', Colors.grey),
      data: (status) => switch (status) {
        VersionStatus.latest => ('Latest', Colors.green),
        VersionStatus.updateAvailable => ('Update Available', Colors.orange),
        VersionStatus.unknown => ('Unknown', Colors.grey),
      },
    );

    return Container(
      height: 28,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        'v$kAppVersion  ·  $statusText',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// D+N 경과일을 표시하는 칩 위젯.
class _DdayChip extends StatelessWidget {
  const _DdayChip({required this.elapsed});

  final int elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'D+$elapsed',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
