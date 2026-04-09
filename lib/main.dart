import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'data/local/hive/hive_service.dart';
import 'presentation/pages/plant_list_page.dart';
import 'providers/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드 — GEMINI_API_KEY 등 환경변수 초기화
  await dotenv.load(fileName: '.env');

  // Hive 초기화 — 모든 어댑터 등록 및 박스 오픈
  final hiveService = HiveService();
  await hiveService.init();

  // 앱 문서 디렉토리 경로를 기동 시 1회 캐싱한다.
  // appDocDirProvider(Provider<String>)에 override하여 UI 깜빡임을 제거한다.
  final appDocDir = await getApplicationDocumentsDirectory();

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
        appDocDirProvider.overrideWithValue(appDocDir.path),
      ],
      child: const LeafyLogApp(),
    ),
  );
}

class LeafyLogApp extends StatelessWidget {
  const LeafyLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'leafylog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PlantListPage(),
    );
  }
}
