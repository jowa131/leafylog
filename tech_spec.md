# Technical Specification — leafylog

## Project Overview

- Service: leafylog — 서버리스 · 로컬 우선 · AI 보조 독립형 식물 관리 앱
- Platform: Flutter 3.x (Android 우선)
- Development stage: 1차 (M1~M4, 핵심 기능) → 2차 (M5, Tistory 연동)

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI/Framework | Flutter 3.x (Android) |
| State Management | flutter_riverpod 2.4.9 |
| Local DB | Hive 2.x (cache/settings only) |
| File Storage | `path_provider` + `dart:io` via FileSystemRepository |
| AI | Google Gemini API (gemini-1.5-flash) |
| Routing | go_router 13.0.0 |
| Config | flutter_dotenv |
| Secure Storage | flutter_secure_storage (Android Keystore) |
| Blog Integration (2nd) | Tistory REST API v1 + OAuth2 |
| Testing | `flutter_test` + `integration_test` + mockito |

---

## System Architecture

```
User
  |
Flutter UI (presentation/)
  |-- providers/ (Riverpod)
       |-- domain/usecases/
            |-- data/
                 |-- FileSystemRepository (plants.json, history_log.json)
                 |-- Hive (cache, settings)
                 |-- Gemini API (AI analysis)
                 |-- flutter_secure_storage (OAuth tokens)
```

### Data Flow
```
Photo capture / query
  |
Flutter UI Layer
  |
  |--> Photo Service --> filesystem: YYYYMMDD_HHMMSS_PlantID.jpg
  |
  |--> AI Service --> Gemini API (image + context)
  |         \--> history_log.json
  |
  |--> Plant CRUD --> plants.json (source of truth)
                \--> Hive (settings/cache)
```

---

## Directory Structure

```
leafylog/
├── CLAUDE.md
├── SKILL.md
├── tech_spec.md
├── plan.md
├── .antigravityrules
├── pubspec.yaml
├── lib/                     ← Flutter app source (framework convention)
│   ├── main.dart
│   ├── presentation/        ← UI widgets and pages
│   ├── providers/           ← Riverpod providers
│   ├── domain/              ← UseCases (pure Dart)
│   └── data/                ← Repositories, models, data sources
├── test/                    ← Unit and integration tests
├── android/                 ← Android project files
├── web_dist/                ← Crash log server (Dockerized, separate)
└── tool/                    ← Build scripts
```

Note: `lib/` and `test/` follow Flutter framework conventions and override the standard `src/`/`tests/` structure.

---

## Operating Environment

- Host OS: Windows 11 + WSL2 (Ubuntu)
- Flutter SDK: `~/flutter`
- Android SDK: `~/android-sdk`
- Dev target: USB-connected Android device via `flutter run`
- Release: APK built locally, installed via `adb install`
- Crash log server: Dockerized in `web_dist/`, running on `myproject_default` network

---

## Data Storage Design

| Data | Format | Location | Primary? |
|---|---|---|---|
| Plant records | JSON | `[AppDocDir]/leafylog/plants.json` | Yes |
| Plant photos | JPEG | `[AppDocDir]/leafylog/plants/{UUID}/photos/` | Yes |
| AI history logs | JSON | `[AppDocDir]/leafylog/history/{UUID}/history_log.json` | Yes |
| App settings | Hive | `[AppDocDir]/leafylog/hive/` | Cache only |
| OAuth tokens | Keystore | flutter_secure_storage | Yes |

---

## Key Constraints

- `flutter_riverpod` exclusively for state management.
- `FileSystemRepository` exclusively for file access — no direct `dart:io`.
- Never change existing Hive `typeId` or `fieldId`.
- Do not move `lib/`, `android/`, `ios/`, `pubspec.yaml`.
- Tistory integration (M5) is frozen until M4 approval.
- `.env` must never be committed.

---

## Environment Variables (`.env`)

| Key | Description |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API key |
