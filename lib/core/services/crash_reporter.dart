import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 앱 전역 예외를 수집하여 원격 로그 서버로 전송하는 서비스.
///
/// 전송 실패 시 error_queue.json에 임시 저장하고,
/// 다음 [flush] 호출 시 재전송을 시도한다.
class CrashReporter {
  CrashReporter._();

  static final CrashReporter instance = CrashReporter._();

  static const _endpoint = 'https://mymel0dy.iptime.org/leafylog/api/log';
  static const _queueFileName = 'error_queue.json';

  // ── 초기화 ──────────────────────────────────────────────

  /// main.dart에서 앱 기동 직후 한 번 호출한다.
  ///
  /// 큐에 쌓인 미전송 로그를 백그라운드에서 재전송 시도한다.
  Future<void> init() async {
    _flushQuietly();
  }

  // ── 공개 API ──────────────────────────────────────────

  /// 에러를 수집하여 서버로 전송한다.
  ///
  /// 전송 실패 시 로컬 큐에 저장한다.
  Future<void> report({
    required String message,
    String stackTrace = '',
    Map<String, dynamic> deviceInfo = const {},
  }) async {
    final payload = {
      'message': message,
      'stackTrace': stackTrace,
      'deviceInfo': deviceInfo,
    };

    final sent = await _send(payload);
    if (!sent) {
      await _enqueue(payload);
    }
  }

  // ── 내부 구현 ─────────────────────────────────────────

  Future<bool> _send(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _enqueue(Map<String, dynamic> payload) async {
    try {
      final file = await _queueFile();
      final queue = await _readQueue(file);
      queue.add(payload);
      await file.writeAsString(jsonEncode(queue), flush: true);
    } catch (e) {
      debugPrint('[CrashReporter] 큐 저장 실패: $e');
    }
  }

  /// 큐에 쌓인 항목을 재전송한다. 성공한 항목만 큐에서 제거한다.
  Future<void> flush() async {
    try {
      final file = await _queueFile();
      if (!file.existsSync()) return;

      final queue = await _readQueue(file);
      if (queue.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final item in queue) {
        final sent = await _send(item);
        if (!sent) remaining.add(item);
      }

      if (remaining.isEmpty) {
        await file.delete();
      } else {
        await file.writeAsString(jsonEncode(remaining), flush: true);
      }
    } catch (e) {
      debugPrint('[CrashReporter] flush 실패: $e');
    }
  }

  void _flushQuietly() {
    flush().catchError((e) {
      debugPrint('[CrashReporter] 백그라운드 flush 실패: $e');
    });
  }

  Future<File> _queueFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/leafylog/$_queueFileName');
  }

  Future<List<Map<String, dynamic>>> _readQueue(File file) async {
    if (!file.existsSync()) return [];
    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
