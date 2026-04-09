# leafylog 개발 플랜

**버전**: 1.0.0  
**작성일**: 2026-04-09  
**개발 방식**: 애자일 마일스톤 (UI → 데이터 → AI → 테스트/빌드)

> **개발 단계 구분**  
> - **1차 개발 (M1~M4)**: 핵심 기능 — 식물 관리, 로컬 저장, AI 분석, 테스트/릴리즈  
> - **2차 개발 (M5)**: 확장 기능 — Tistory 블로그 연동 (1차 완료 후 착수)

---

## 마일스톤 개요

| 단계 | 마일스톤 | 핵심 산출물 | 완료 기준 |
|---|---|---|---|
| M1 | Flutter 초기화 & UI 스캐폴딩 | 프로젝트 구조, 4개 화면, 라우팅 | 화면 전환 가능, 더미 데이터 표시 |
| M2 | 로컬 데이터 저장 | Hive 어댑터, FileSystemRepo, PhotoService | 재시작 후 데이터 유지, 사진 저장 |
| M3 | Gemini AI 연동 | GeminiApiClient, AnalyzePlantUseCase | 실 기기 사진 → AI 건강 점수 표시 |
| M4 | E2E 테스트 & 릴리즈 빌드 | 전 계층 테스트, 릴리즈 APK | 모든 테스트 통과, APK 생성 |
| M5 *(2차)* | Tistory 연동 | OAuth2, 블로그 포스트 생성 | M4 완료 후 착수 |

---

## M1 — Flutter 초기화 & UI 스캐폴딩

**목표**: 앱 골격 구축. 실제 데이터 없이 화면 전환과 UI 레이아웃 검증.

### 작업 목록

- [ ] `flutter create leafylog` 실행, 기본 생성 파일 정리 (counter 앱 제거)
- [ ] `pubspec.yaml` 의존성 등록

  ```yaml
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.0
  flutter_dotenv: ^5.1.0
  flutter_secure_storage: ^9.0.0
  google_generative_ai: ^0.4.0
  image: ^4.1.0
  uuid: ^4.0.0
  flutter_riverpod: ^2.4.9
  get_it: ^7.6.0
  go_router: ^13.0.0
  ```

- [ ] `.env` 파일 생성, `.gitignore`에 등록
- [ ] `get_it` DI 컨테이너 초기 설정 (`lib/core/di/`)
- [ ] `go_router` 라우팅 설정 (`lib/core/config/`)
- [ ] 화면 4개 스캐폴딩 (더미 데이터 사용)
  - `PlantListPage` — 식물 목록
  - `PlantDetailPage` — 식물 상세 + 이력 타임라인
  - `PlantRegisterPage` — 식물 등록 폼
  - `AnalysisResultPage` — AI 분석 결과 카드
- [ ] 공통 위젯: AppBar, FAB, BottomNavigationBar

### 완료 기준

- `flutter run` 실행 시 앱 정상 구동
- 4개 화면 간 전환 가능
- 더미 데이터로 목록/상세 표시

---

## M2 — 로컬 데이터 저장

**목표**: 앱 재시작 후에도 데이터가 유지되는 완전한 로컬 저장 레이어 구축.

### 작업 목록

- [ ] **Hive 어댑터** 생성 (`lib/data/local/hive/`)
  - `PlantHiveModel` — 식물 메타데이터
  - `AppSettingsHiveModel` — 테마, 알림 설정
  - `build_runner`로 어댑터 코드 자동 생성
- [ ] **FileSystemRepository** 구현 (`lib/data/local/file/`)
  - `plants.json` 읽기/쓰기/업데이트
  - `history_log.json` 읽기/항목 추가
  - 디렉토리 자동 생성 로직
- [ ] **PhotoService** 구현 (`lib/data/local/file/`)
  - 카메라 촬영 또는 갤러리 선택
  - 이미지 압축 (1.5MB 이하)
  - 파일명: `YYYYMMDD_HHMMSS_{PlantID앞8자리}.jpg`
- [ ] 식물 등록 플로우 연결: `PlantRegisterPage` → `FileSystemRepository` → `plants.json`
- [ ] 목록 조회 플로우 연결: `plants.json` → `PlantListPage`
- [ ] `data_inspector` 스킬로 저장 데이터 검증

### 완료 기준

- 식물 등록 후 앱 재시작 시 목록에 유지
- `[AppDocDir]/leafylog/plants/{UUID}/photos/` 경로에 사진 파일 정상 저장
- `plants.json` 및 `history_log.json` 스키마 tech_spec.md 2.2/2.3항과 일치

---

## M3 — Gemini AI 연동

**목표**: 사진 + Context 기반 AI 건강 분석 파이프라인 완성.

### 작업 목록

- [ ] **GeminiApiClient** 구현 (`lib/data/remote/gemini/`)
  - `google_generative_ai` SDK 초기화
  - 이미지 + 텍스트 프롬프트 멀티모달 요청
  - HTTP 429/503 Exponential Backoff 재시도 (최대 3회: 1s→2s→4s)
- [ ] **AnalyzePlantUseCase** 구현 (`lib/domain/usecases/`)
  - Context 조립: `species` + `dday_elapsed` + 최근 5개 이벤트
  - tech_spec.md 3.2항 프롬프트 템플릿 적용
  - 응답 JSON 파싱 및 유효성 검증
  - `history_log.json`에 `AI_ANALYSIS` 엔트리 저장
- [ ] **Hive 캐시** 연동: Gemini 응답 캐시 (TTL 24h)
- [ ] **오프라인 모드**: 네트워크 없을 때 캐시 fallback, 로컬 로그만 조회
- [ ] `AnalysisResultPage` UI 연결: 건강 점수, 감지된 이슈, 권장 사항 표시
- [ ] Confidence Score 0.7 미만 시 "낮은 신뢰도" 경고 표시

### 완료 기준

- 실 기기에서 사진 촬영 → Gemini 분석 → 건강 점수 UI 표시 성공
- `history_log.json`에 `AI_ANALYSIS` 엔트리 자동 기록
- 비행기 모드에서 앱 크래시 없이 캐시 데이터 표시

---

## M4 — E2E 테스트 & 릴리즈 빌드

**목표**: 전 계층 테스트 통과 후 ProGuard 난독화 적용 릴리즈 APK 생성.

### 작업 목록

- [ ] **Unit Tests** (`test/`)
  - D-Day 계산 로직
  - 사진 파일명 생성 포매터
  - Gemini 응답 JSON 파서
  - UUID 중복 검사 로직
- [ ] **Widget Tests** (`test/`)
  - `PlantListPage` 식물 목록 렌더링
  - `PlantRegisterPage` 폼 유효성 검사
  - `AnalysisResultPage` 결과 카드 표시
- [ ] **Integration Tests** (`integration_test/`)
  - 전체 플로우: 식물 등록 → AI 분석 → `history_log.json` 기록
  - Mock Gemini Client 사용 (API 비용 절감)
  - 파일 시스템: 실제 임시 디렉토리 사용
- [ ] **`/flutter_qa_builder` 스킬** 실행으로 테스트 → APK 빌드 자동화
- [ ] `AndroidManifest.xml` 권한 최종 점검 (CAMERA, READ_EXTERNAL_STORAGE 등)
- [ ] ProGuard 규칙 (`proguard-rules.pro`) 설정
- [ ] 보안 체크리스트 완료 (tech_spec.md 5.1항)

### 완료 기준

- `flutter test` 전체 통과
- `flutter test integration_test/` 전체 통과
- `flutter build apk --release --obfuscate --split-debug-info=build/symbols` 성공
- 생성된 APK 실 기기 설치 및 전체 플로우 동작 확인

---

## [2차] M5 — Tistory 연동 *(확장 기능)*

> **착수 조건**: M4 완료 및 릴리즈 APK 검증 완료 후.  
> 상세 설계는 `tech_spec.md` 섹션 4 참조.

### 작업 개요

- OAuth2 인증 흐름 (`leafylog://callback` 딥링크)
- `history_log.json` 시계열 병합 → HTML 포스트 생성 (평어체 칼럼 스타일)
- Tistory REST API `POST /apis/post` 연동
- 발행 URL 로컬 로그 저장

---

## 스킬 참조

| 스킬 | 호출 방법 | 용도 |
|---|---|---|
| `flutter_qa_builder` | `/flutter_qa_builder` | 테스트 → APK 빌드 자동화 (M4) |
| `data_inspector` | `/data_inspector [plants\|history\|hive]` | 로컬 데이터 검증 (M2~M3) |
