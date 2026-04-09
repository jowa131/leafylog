---
name: flutter_qa_builder
description: 단위/E2E 테스트를 순차 실행하고 전체 통과 시 릴리즈 APK를 빌드한다. 테스트 실패 시 빌드를 중단하고 실패 원인을 보고한다.
---

leafylog Flutter 프로젝트의 QA 파이프라인을 실행하라.
작업 디렉토리: `/home/mymelody/projects/leafylog`

아래 단계를 순서대로 실행하라. 각 단계가 실패하면 즉시 중단하고 실패 원인을 보고하라.

## 1단계 — 단위 & 위젯 테스트

```bash
cd /home/mymelody/projects/leafylog && flutter test
```

- 성공 기준: exit code 0, "All tests passed" 확인
- 실패 시: 실패한 테스트 파일명, 테스트명, 오류 메시지를 목록으로 출력 후 중단

## 2단계 — Integration(E2E) 테스트

```bash
cd /home/mymelody/projects/leafylog && flutter test integration_test/ --dart-define-from-file=.env.test
```

- 성공 기준: exit code 0
- `.env.test` 없으면 사용자에게 파일 생성 요청 후 중단
- 실패 시: 실패한 시나리오명과 스택 트레이스 요약 출력 후 중단

## 3단계 — 릴리즈 APK 빌드

```bash
cd /home/mymelody/projects/leafylog && flutter build apk --release \
  --dart-define-from-file=.env \
  --obfuscate \
  --split-debug-info=build/symbols
```

- 성공 기준: exit code 0, `build/app/outputs/flutter-apk/app-release.apk` 생성
- 완료 후 APK 파일 경로와 파일 크기(MB)를 출력하라

## 최종 보고 형식

모든 단계 완료 후 아래 형식으로 요약하라:

```
## QA 빌드 결과

| 단계 | 결과 | 비고 |
|---|---|---|
| 단위/위젯 테스트 | ✅ 통과 / ❌ 실패 | 테스트 수 |
| E2E 테스트 | ✅ 통과 / ❌ 실패 / ⏭ 스킵 | 시나리오 수 |
| 릴리즈 APK 빌드 | ✅ 성공 / ❌ 실패 / ⏭ 스킵 | APK 크기 |

APK 경로: build/app/outputs/flutter-apk/app-release.apk
```
