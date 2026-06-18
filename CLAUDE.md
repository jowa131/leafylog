# leafylog — Agent Context

Read `.antigravityrules` in this directory for leafylog coding constraints and agent roles.
Read `SKILL.md` for tech stack, system architecture, and feature specification.

---

# Flutter/Android Exception

This is a Flutter/Android native app. Docker/Nginx rules do not apply to the app itself.

- App is NOT Dockerized. APK is installed directly on device.
- Windows: `flutter run` targets an emulator or USB-connected Android device.
- Check configured devices with `flutter devices`.
- Flutter SDK: `C:\Tools\flutter`
- Android tooling: Android Studio and its managed Android SDK

# Build Commands

```bash
# Dev build (USB device required)
flutter run --dart-define-from-file=.env

# Release APK
flutter build apk --release --dart-define-from-file=.env --obfuscate --split-debug-info=build/symbols

# Hive code generation (after model changes)
flutter pub run build_runner build --delete-conflicting-outputs
```

# APK Deployment

1. `flutter build apk --release ...`
2. Confirm artifact: `build/app/outputs/flutter-apk/app-release.apk`
3. Install: `adb install build/app/outputs/flutter-apk/app-release.apk`

# Web Crash Log Server

`web_dist/` runs a separate Dockerized crash report server on `myproject_default`:

```bash
Set-Location C:\MyProject\leafylog\web_dist
docker compose up -d --build
```

- `leafylog-web` (172.18.0.7): static web + crash report UI
- `leafylog-log-server` (172.18.0.8): crash log receiver
- Log volume: `leafylog_logs` (persists across restarts)
