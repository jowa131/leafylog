import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/crash_reporter.dart';
import '../../data/local/file/models/plant_model.dart';
import '../../providers/analysis_providers.dart';
import '../../providers/storage_providers.dart';

/// 새 식물을 등록하는 화면.
///
/// 입력: 표시명, 종명(species), D-Day 기준일, 물주기 간격, 썸네일 사진.
/// 저장 버튼을 누르면 [PlantsNotifier.registerPlant]를 호출하고 이전 화면으로 돌아간다.
class PlantRegisterPage extends ConsumerStatefulWidget {
  const PlantRegisterPage({super.key});

  @override
  ConsumerState<PlantRegisterPage> createState() => _PlantRegisterPageState();
}

class _PlantRegisterPageState extends ConsumerState<PlantRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _wateringCtrl = TextEditingController(text: '7');

  DateTime _ddayAnchor = DateTime.now();
  String? _pendingThumbnailPath; // 임시 사진 파일 경로 (저장 전)
  bool _isSaving = false;
  bool _isAutofilling = false; // AI Auto-fill 진행 중 여부

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speciesCtrl.dispose();
    _wateringCtrl.dispose();
    super.dispose();
  }

  // ── 사진 선택 ──────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    // PhotoService는 plantId가 필요하므로, 등록 전 임시로 XFile 경로를 저장한다.
    // 실제 압축·저장은 registerPlant 시점에 수행한다.
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    setState(() => _pendingThumbnailPath = file.path);

    // 사진 선택 즉시 AI Auto-fill을 백그라운드에서 시작한다.
    _runAutofill(file.path);
  }

  /// Gemini로 종명·물주기·요약을 추출하여 폼 필드에 자동 입력한다.
  Future<void> _runAutofill(String imagePath) async {
    setState(() => _isAutofilling = true);
    try {
      final photoService = ref.read(photoServiceProvider);
      final imageBytes = await photoService.readBytes(imagePath);
      final gemini = ref.read(geminiApiClientProvider);
      final raw = await gemini.autofill(imageBytes: imageBytes);

      final json = jsonDecode(raw) as Map<String, dynamic>;

      final species = (json['species'] as String?) ?? '';
      final wateringDays = (json['watering_interval_days'] as int?) ?? 7;

      if (!mounted) return;
      setState(() {
        if (species.isNotEmpty) _speciesCtrl.text = species;
        _wateringCtrl.text = wateringDays.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI가 종명과 물주기 간격을 자동 입력했다. 확인 후 수정하라.')),
        );
      }
    } catch (e, stack) {
      CrashReporter.instance.report(
        message: 'Auto-fill 실패: $e',
        stackTrace: stack.toString(),
        deviceInfo: {'source': 'PlantRegisterPage.autofill'},
      );
      // Auto-fill 실패는 사용자에게 조용히 처리한다 — 폼은 그대로 사용 가능하다.
    } finally {
      if (mounted) setState(() => _isAutofilling = false);
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── D-Day 날짜 선택 ────────────────────────────────────────

  Future<void> _pickDdayDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ddayAnchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'D-Day 기준일 선택',
    );
    if (picked != null) setState(() => _ddayAnchor = picked);
  }

  // ── 저장 ──────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // 1단계: 식물 등록 (UUID 생성됨)
      final draft = PlantModel(
        id: '', // registerPlant 내부에서 UUID v4로 교체된다
        displayName: _nameCtrl.text.trim(),
        species: _speciesCtrl.text.trim(),
        registeredAt: DateTime.now(),
        wateringIntervalDays: int.tryParse(_wateringCtrl.text) ?? 7,
        ddayAnchor: _ddayAnchor.toIso8601String().substring(0, 10),
      );

      final registered =
          await ref.read(plantsProvider.notifier).registerPlant(draft);

      // 2단계: 사진이 있으면 압축 저장 후 썸네일 업데이트
      if (_pendingThumbnailPath != null) {
        final photoService = ref.read(photoServiceProvider);
        final filename = await photoService.saveFromPath(
          sourcePath: _pendingThumbnailPath!,
          plantId: registered.id,
        );
        await ref
            .read(plantsProvider.notifier)
            .updatePlant(registered.copyWith(thumbnail: filename));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식물 등록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  _ThumbnailPicker(
                    imagePath: _pendingThumbnailPath,
                    onTap: _isAutofilling ? null : _showPhotoSourceSheet,
                  ),
                  if (_isAutofilling)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text('AI 분석 중...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('plant_name_field'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '표시명 *',
                  hintText: '예) 우리 집 몬스테라',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '표시명을 입력하라.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('species_field'),
                controller: _speciesCtrl,
                decoration: const InputDecoration(
                  labelText: '종명 (Species) *',
                  hintText: '예) Monstera deliciosa',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '종명을 입력하라.' : null,
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'D-Day 기준일',
                value: _ddayAnchor,
                onTap: _pickDdayDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wateringCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '물주기 간격 (일)',
                  border: OutlineInputBorder(),
                  suffixText: '일',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return '1 이상의 숫자를 입력하라.';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('save_plant_button'),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 썸네일 사진 선택 영역 위젯.
class _ThumbnailPicker extends StatelessWidget {
  const _ThumbnailPicker({required this.imagePath, required this.onTap});

  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: (imagePath != null && File(imagePath!).existsSync())
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    '사진 추가 (선택)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 날짜 선택 필드 위젯.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  String _format(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(_format(value)),
      ),
    );
  }
}
