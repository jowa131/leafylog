# Windows Setup

## Requirements

- Flutter SDK at `C:\Tools\flutter`
- Android Studio with an Android SDK and emulator
- USB debugging enabled when using a physical device

## Setup

```powershell
.\setup-windows.ps1
C:\Tools\flutter\bin\flutter.bat devices
```

## Run and Build

```powershell
C:\Tools\flutter\bin\flutter.bat run --dart-define-from-file=.env
C:\Tools\flutter\bin\flutter.bat build apk --release --dart-define-from-file=.env
```

For an Android emulator, `10.0.2.2` in `.env` points back to the Windows host.
When `android/key.properties` is absent, local release builds use the debug
signing key. Production publishing still requires the original release key.

## Local Crash Log Server

```powershell
Set-Location web_dist
docker compose -f compose.windows.yml up --build
```

- Static web UI: http://localhost:8082
- Crash log API: http://localhost:5001
