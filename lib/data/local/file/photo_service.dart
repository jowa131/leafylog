import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/date_utils.dart';
import 'file_system_repository.dart';

/// 사진 촬영·선택·압축·저장을 담당하는 서비스.
///
/// 파일명 형식: `YYYYMMDD_HHMMSS_{PlantID앞8자리}.jpg` (tech_spec.md 2.4항)
/// 저장 경로: `[AppDocDir]/leafylog/plants/{UUID}/photos/`
/// 압축 목표: 1.5MB 이하, 최대 해상도 2048px
class PhotoService {
  PhotoService(this._repo);

  final FileSystemRepository _repo;
  final _picker = ImagePicker();

  static const _maxFileSizeBytes = 1.5 * 1024 * 1024; // 1.5MB
  static const _maxDimension = 2048;

  /// 이미 선택된 파일 경로를 압축하여 저장한다.
  ///
  /// 등록 화면에서 미리 선택한 이미지를 저장할 때 사용한다.
  /// 성공 시 저장된 파일명을 반환한다.
  Future<String> saveFromPath({
    required String sourcePath,
    required String plantId,
  }) async {
    return _compressAndSave(XFile(sourcePath), plantId);
  }

  /// 카메라로 촬영하거나 갤러리에서 선택한 사진을 압축 저장한다.
  ///
  /// [plantId]: 저장할 식물의 UUID
  /// [source]: [ImageSource.camera] 또는 [ImageSource.gallery]
  ///
  /// 사용자가 취소하면 null을 반환한다.
  /// 성공 시 저장된 파일명(경로 제외)을 반환한다.
  Future<String?> pickAndSave({
    required String plantId,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;
    return _compressAndSave(picked, plantId);
  }

  /// [file]을 압축하여 [plantId]의 photos 디렉토리에 저장한다.
  Future<String> _compressAndSave(XFile file, String plantId) async {
    final sourceBytes = await file.readAsBytes();
    final compressed = _compress(sourceBytes);

    final filename = _buildFilename(plantId);
    final photosDir = await _repo.getPhotosDirPath(plantId);
    final dest = File('$photosDir/$filename');
    await dest.writeAsBytes(compressed);

    return filename;
  }

  /// 이미지를 1.5MB 이하로 압축한다.
  ///
  /// 1. 최대 해상도 2048px로 리사이즈
  /// 2. JPEG quality 85에서 시작, 초과 시 10씩 감소 (최소 40)
  Uint8List _compress(Uint8List sourceBytes) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) return sourceBytes;

    // 최대 해상도 제한
    final resized = (decoded.width > _maxDimension || decoded.height > _maxDimension)
        ? img.copyResize(
            decoded,
            width: decoded.width > decoded.height ? _maxDimension : null,
            height: decoded.height >= decoded.width ? _maxDimension : null,
          )
        : decoded;

    // 원본이 이미 1.5MB 이하면 quality 85로 단순 인코딩
    var quality = 85;
    var encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));

    while (encoded.length > _maxFileSizeBytes && quality > 40) {
      quality -= 10;
      encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return encoded;
  }

  /// `YYYYMMDD_HHMMSS_{plantId앞8자리}.jpg` 형식의 파일명을 생성한다.
  String _buildFilename(String plantId) =>
      buildPhotoFilename(plantId, DateTime.now());
}
