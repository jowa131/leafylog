import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 성장 기록(USER_NOTE) 추가용 바텀 시트.
///
/// StatefulBuilder 대신 독립 StatefulWidget으로 분리하여
/// 상태 범위를 명확히 하고 테스트 가능성을 높인다.
///
/// [onSave]에 메모와 선택된 사진 경로(nullable)를 전달한다.
class AddGrowthRecordSheet extends StatefulWidget {
  const AddGrowthRecordSheet({super.key, required this.onSave});

  final void Function(String note, String? photoPath) onSave;

  @override
  State<AddGrowthRecordSheet> createState() => _AddGrowthRecordSheetState();
}

class _AddGrowthRecordSheetState extends State<AddGrowthRecordSheet> {
  final _noteCtrl = TextEditingController();
  String? _pickedPhotoPath;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file != null) {
      setState(() => _pickedPhotoPath = file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('성장 기록 추가', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(_pickedPhotoPath == null ? '사진 선택 (선택)' : '사진 선택됨'),
            onPressed: _pickPhoto,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '메모',
              hintText: '오늘 상태, 특이사항 등',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSave(_noteCtrl.text.trim(), _pickedPhotoPath);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
