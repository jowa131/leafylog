import 'package:flutter/material.dart';

import '../../data/local/file/models/history_log_model.dart';

/// Gemini AI 분석 결과를 표시하는 화면.
///
/// [result]를 직접 전달받아 렌더링한다.
/// Confidence Score가 0.7 미만이면 "낮은 신뢰도" 경고 배너를 표시한다.
class AnalysisResultPage extends StatelessWidget {
  const AnalysisResultPage({super.key, required this.result});

  final AiResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 분석 결과'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HealthScoreCard(score: result.healthScore),
            const SizedBox(height: 16),
            if (result.confidence < 0.7) ...[
              _LowConfidenceBanner(confidence: result.confidence),
              const SizedBox(height: 16),
            ],
            if (result.summary != null) ...[
              _SummaryCard(summary: result.summary!),
              const SizedBox(height: 16),
            ],
            _IssueSection(
              title: '감지된 문제',
              icon: Icons.warning_amber_outlined,
              iconColor: Colors.orange,
              items: result.detectedIssues,
              emptyText: '특이 사항이 없다.',
            ),
            const SizedBox(height: 16),
            _IssueSection(
              title: '권장 사항',
              icon: Icons.lightbulb_outline,
              iconColor: Colors.green,
              items: result.recommendations,
              emptyText: '특별한 권장 사항이 없다.',
            ),
            const SizedBox(height: 24),
            _ConfidenceRow(confidence: result.confidence),
          ],
        ),
      ),
    );
  }
}

// ── 건강 점수 카드 ─────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.score});

  final int score;

  Color get _color {
    if (score >= 71) return Colors.green;
    if (score >= 41) return Colors.orange;
    return Colors.red;
  }

  String get _label {
    if (score >= 71) return '양호';
    if (score >= 41) return '주의 필요';
    return '위험';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Text('건강 점수', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      key: const Key('health_score_display'),
                      value: score / 100.0,
                      strokeWidth: 14,
                      color: _color,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _color,
                            ),
                      ),
                      Text(
                        _label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _color,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 낮은 신뢰도 경고 배너 ──────────────────────────────────────

/// Confidence Score 0.7 미만 시 표시하는 경고 배너.
class _LowConfidenceBanner extends StatelessWidget {
  const _LowConfidenceBanner({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '낮은 신뢰도 (${(confidence * 100).toStringAsFixed(0)}%) — '
              '이 결과는 참고용으로만 사용하라. '
              '더 선명한 사진으로 재분석을 권장한다.',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 요약 카드 ─────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이슈·권장 사항 섹션 ────────────────────────────────────────

class _IssueSection extends StatelessWidget {
  const _IssueSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── 신뢰도 행 ─────────────────────────────────────────────────

class _ConfidenceRow extends StatelessWidget {
  const _ConfidenceRow({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.verified_outlined,
            size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Text(
          '분석 신뢰도: ${(confidence * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
