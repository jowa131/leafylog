# leafylog — Skill Profile

**앱 개요**: 서버리스(Serverless) · 로컬 우선(Local-First) · AI 보조(AI-Augmented) 독립형 식물 관리 앱  
**플랫폼**: Flutter 3.x (Android 우선)  
**개발 단계**: 1차(M1~M4, 핵심 기능) → 2차(M5, Tistory 연동)

---

## 목차

1. [기술 스택](#1-기술-스택)
2. [시스템 아키텍처](#2-시스템-아키텍처)
3. [데이터 및 저장소 설계](#3-데이터-및-저장소-설계)
4. [AI 로직 — Gemini 하이브리드 파이프라인](#4-ai-로직--gemini-하이브리드-파이프라인)
5. [Tistory 연동 설계 *(2차 개발)*](#5-tistory-연동-설계-2차-개발)
6. [마일스톤 & 개발 계획](#6-마일스톤--개발-계획)
7. [보안 전략](#7-보안-전략)
8. [테스트 전략](#8-테스트-전략)
9. [리스크 매트릭스](#9-리스크-매트릭스)
10. [스킬 참조](#10-스킬-참조)

---

## 1. 기술 스택

| 레이어 | 기술 | 선택 근거 |
|---|---|---|
| UI/Framework | Flutter 3.x (Android) | 단일 코드베이스, 고성능 렌더링 |
| 상태 관리 | flutter_riverpod 2.4.9 | 반응형 상태, DI 통합 |
| 로컬 NoSQL DB | Hive 2.x | 스키마리스, 암호화 지원, Flutter 네이티브 |
| 로컬 파일 시스템 | `path_provider` + `dart:io` | 사진·JSON 구조적 저장 |
| AI 엔진 | Google Gemini API (gemini-1.5-flash) | 멀티모달(이미지+텍스트), 낮은 레이턴시 |
| 라우팅 | go_router 13.0.0 | 선언적 라우팅 |
| 환경변수 | flutter_dotenv | API 키 소스코드 분리 |
| 보안 저장소 | flutter_secure_storage | Android Keystore 연동 |
| 블로그 연동 *(2차)* | Tistory REST API v1 + OAuth2 | 국내 주요 블로그 플랫폼 |
| 테스트 | `flutter_test` + `integration_test` + mockito | 유닛~E2E 전 계층 |

### 핵심 패키지 의존성

```yaml
dependencies:
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

dev_dependencies:
  hive_generator: ^2.0.0
  build_runner: ^2.4.0
  mockito: ^5.4.0
```

---

## 2. 시스템 아키텍처

### 2.1 전체 데이터 흐름도

```
사용자
  │ 촬영 / 조회 요청
  ▼
Flutter UI Layer
  ├─▶ Photo Service ──▶ 파일 시스템 (YYYYMMDD_HHMMSS_PlantID.jpg)
  │
  ├─▶ AI Service ──▶ Gemini API (사진 + Context)
  │         └──▶ history_log.json (결과 저장)
  │
  ├─▶ Blog Service *(2차)* ──▶ history_log.json 시계열 병합
  │                    └──▶ Tistory REST API (OAuth2 + HTML)
  │
  └─▶ 로컬 저장소
       ├── Hive DB (설정·캐시·알림 스케줄)
       ├── plants.json (Master Index)
       └── plants/{UUID}/history_log.json (식물별 이력)
```

### 2.2 Flutter 모듈 디렉토리 구조

```
lib/
├── core/
│   ├── config/          # 환경변수 로딩, 앱 상수
│   ├── di/              # 의존성 주입 (get_it)
│   └── utils/           # 날짜 포매터, UUID 생성기 등
├── data/
│   ├── local/
│   │   ├── hive/        # Hive 어댑터, 박스 정의
│   │   └── file/        # FileSystemRepository (JSON·사진 I/O)
│   └── remote/
│       ├── gemini/      # GeminiApiClient
│       └── tistory/     # TistoryApiClient, OAuth2Handler (2차)
├── domain/
│   ├── entities/        # Plant, HealthLog, AnalysisResult
│   ├── repositories/    # 인터페이스 정의
│   └── usecases/        # AnalyzePlant, PublishBlogPost 등
├── presentation/
│   ├── pages/           # 4개 화면
│   └── widgets/
└── main.dart
```

### 2.3 Riverpod Provider 계층

```
인프라 Provider (main.dart에서 override)
  hiveServiceProvider → HiveService (Hive 초기화)
  appDocDirProvider   → 앱 문서 디렉토리 경로
  fileSystemRepositoryProvider → FileSystemRepository
  photoServiceProvider → PhotoService
  geminiApiClientProvider → GeminiApiClient

비즈니스 로직 Provider
  plantsProvider (StateNotifier) → 식물 목록 CRUD + Optimistic Update
  analyzePlantUseCaseProvider   → AI 분석 UseCase
  plantHistoryProvider (FutureProvider.family) → plantId별 이력 (5분 캐시)
```

---

## 3. 데이터 및 저장소 설계

### 3.1 파일 시스템 디렉토리

앱 전용 저장 경로: `getApplicationDocumentsDirectory()`

```
[AppDocDir]/
└── leafylog/
    ├── plants.json                          ← Master Index
    └── plants/
        └── {UUID}/                          ← 식물 고유 디렉토리
            ├── history_log.json             ← 해당 식물 전체 이력
            └── photos/
                ├── 20260409_143022_a1b2c3d4.jpg
                └── 20260410_091500_a1b2c3d4.jpg
```

> **설계 원칙**: 각 식물을 네트워크 장비 1대로 취급한다. UUID = Serial Number, `history_log.json` = Change Log, `plants.json` = NMS 인벤토리 테이블.

### 3.2 Master Index: `plants.json` 스키마

```json
{
  "version": 1,
  "last_updated": "2026-04-09T14:30:22+09:00",
  "plants": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "display_name": "몬스테라 델리시오사",
      "species": "Monstera deliciosa",
      "registered_at": "2026-01-15T09:00:00+09:00",
      "thumbnail": "20260409_143022_a1b2c3d4.jpg",
      "watering_interval_days": 7,
      "dday_anchor": "2026-01-15",
      "tags": ["실내", "관엽"],
      "is_archived": false
    }
  ]
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | UUID v4 (String) | 식물 고유 식별자. 영구 불변 |
| `species` | String | AI Context 주입용 학명 또는 일반명 |
| `dday_anchor` | ISO 8601 Date | D-Day 계산 기준일 (분갈이·입양일 등) |
| `watering_interval_days` | int | 물주기 알림 기준값 |
| `is_archived` | bool | 삭제 대신 아카이브 처리 (이력 보존) |

### 3.3 식물 이력 로그: `history_log.json` 스키마

```json
{
  "plant_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "entries": [
    {
      "entry_id": "log_20260409_143022",
      "timestamp": "2026-04-09T14:30:22+09:00",
      "event_type": "AI_ANALYSIS",
      "photo_file": "20260409_143022_a1b2c3d4.jpg",
      "ai_result": {
        "health_score": 82,
        "detected_issues": ["하엽 황화", "과습 의심"],
        "recommendations": ["물주기 주기를 10일로 늘릴 것", "직사광선 피할 것"],
        "confidence": 0.91,
        "raw_response_hash": "sha256:abcdef..."
      },
      "user_note": "새 흙으로 분갈이 후 첫 분석",
      "context_snapshot": {
        "species": "Monstera deliciosa",
        "dday_elapsed": 84
      }
    },
    {
      "entry_id": "log_20260410_091500",
      "timestamp": "2026-04-10T09:15:00+09:00",
      "event_type": "WATERING",
      "photo_file": null,
      "user_note": "물 300ml 공급"
    }
  ]
}
```

**이벤트 타입 정의**:

| `event_type` | 설명 |
|---|---|
| `AI_ANALYSIS` | Gemini 분석 수행 및 결과 저장 |
| `WATERING` | 물주기 수동 기록 |
| `FERTILIZING` | 비료 공급 기록 |
| `REPOTTING` | 분갈이 기록 |
| `USER_NOTE` | 자유 메모 |
| `HEALTH_CHECK` | 사진 없는 상태 점검 |

### 3.4 사진 명명 규칙

```
YYYYMMDD_HHMMSS_PlantID(8자리).jpg
예시: 20260409_143022_a1b2c3d4.jpg
```

- `PlantID` = UUID 앞 8자리(하이픈 제외)
- 파일명만으로 촬영 시각 + 식물 역추적 가능
- 저장 경로: `[AppDocDir]/leafylog/plants/{FULL_UUID}/photos/`
- 압축 기준: 1.5MB 이하, JPEG quality 85

### 3.5 Hive 박스 정의

| Box 이름 | 저장 내용 | 이유 |
|---|---|---|
| `settings` | 테마, 알림 설정, OAuth 토큰 | 빠른 키-값 접근 |
| `cache` | Gemini 최근 응답 캐시 (TTL 24h) | API 호출 절감 |
| `notification_schedule` | 물주기 알림 예약 데이터 | 앱 재시작 후 복원 |

> **데이터 원칙**: JSON 파일이 1차 진실 공급원(Source of Truth). Hive는 캐시/설정 전용. Hive 초기화 실패 시 JSON 파일로 자동 복원.

### 3.6 데이터 마이그레이션

`plants.json`의 `version` 필드로 스키마 버전 관리. 앱 업데이트 시 `MigrationRunner`가 현재 버전 확인 후 순차 실행.

```
v1 → v2 (예시): dday_anchor 필드 추가, 기존 registered_at 값으로 자동 채움
```

---

## 4. AI 로직 — Gemini 하이브리드 파이프라인

### 4.1 Context 주입 전략 (오인식 방지)

사진만으로 분석 시 유사 식물 혼동 문제를 방지하기 위해 **사용자 등록 종(Species) 정보를 Gemini 프롬프트의 시스템 컨텍스트로 주입**한다.

```
사용자: 사진 촬영
  │
  ▼
Photo Service (압축 & 저장)
  │
  ▼
Context Builder
  ├── species: Monstera deliciosa
  ├── dday_elapsed: 84일 (D+84)
  └── recent_events: [분갈이, 물주기×3]
  │
  ▼
Prompt Assembler (시스템 프롬프트 + 이미지 + Context)
  │
  ▼
Gemini API (gemini-1.5-flash)
  │
  ▼
Response Parser (JSON 추출)
  │
  ▼
history_log.json (AI_ANALYSIS 엔트리 저장)
  │
  ▼
UI: 분석 결과 표시
```

### 4.2 Gemini 시스템 프롬프트 템플릿

```
당신은 전문 식물 병리학자입니다.
아래 제공된 컨텍스트 정보를 반드시 참고하여 분석하십시오.

[식물 정보]
- 등록 종명: {species}
- 관리 경과일: D+{dday_elapsed}
- 최근 이벤트: {recent_events_summary}

[분석 요청]
첨부된 사진을 바탕으로 이 식물({species})의 건강 상태를 분석하십시오.
다른 식물로 오인하지 말고 반드시 위 종명을 기준으로 분석하십시오.

[응답 형식] 반드시 아래 JSON 형식으로만 응답하십시오:
{
  "health_score": 0-100,
  "detected_issues": ["이슈1", "이슈2"],
  "recommendations": ["권장사항1", "권장사항2"],
  "confidence": 0.0-1.0,
  "summary": "한 줄 요약"
}
```

### 4.3 AnalyzePlantUseCase 구현 규격

```dart
class AnalyzePlantUseCase {
  Future<AnalysisResult> execute(AnalysisRequest request) async {
    // 1. 사진 압축 (Gemini 업로드 한도: 20MB, 권장 2MB 이하)
    final compressedPhoto = await _photoService.compress(
      request.photoPath, maxSizeKB: 1500, quality: 85,
    );
    // 2. Context 조립 (species + dday + 최근 5개 이벤트)
    final context = AnalysisContext(
      species: request.plant.species,
      ddayElapsed: _calcDday(request.plant.ddayAnchor),
      recentEvents: await _logRepo.getRecentEvents(request.plant.id, limit: 5),
    );
    // 3. Gemini API 호출 (Exponential Backoff 재시도)
    final rawResponse = await _geminiClient.analyze(
      image: compressedPhoto,
      context: context,
      retryPolicy: RetryPolicy(maxAttempts: 3, backoffMs: 1000),
    );
    // 4. 파싱 & 유효성 검증
    final result = _parseAndValidate(rawResponse);
    // 5. history_log.json에 AI_ANALYSIS 엔트리 저장
    await _logRepo.appendEntry(request.plant.id, LogEntry(
      eventType: EventType.aiAnalysis,
      aiResult: result,
      contextSnapshot: context.toSnapshot(),
    ));
    return result;
  }
}
```

### 4.4 재시도 정책 & 오류 처리

| 시나리오 | 처리 방식 |
|---|---|
| HTTP 429 (Rate Limit) | Exponential Backoff: 1s → 2s → 4s |
| HTTP 503 (서버 오류) | 최대 3회 재시도 후 사용자 알림 |
| 응답 JSON 파싱 실패 | `raw_response`를 로컬 저장 후 재파싱 시도 |
| 네트워크 없음 | 오프라인 모드 전환, 로컬 로그만 조회 가능 |
| Confidence < 0.7 | UI에 "낮은 신뢰도" 경고 표시 |

---

## 5. Tistory 연동 설계 *(2차 개발)*

> **착수 조건**: M4 완료 및 릴리즈 APK 검증 완료 후. 1차 빌드에서는 이 섹션의 코드를 포함하지 않는다.

### 5.1 OAuth2 인증 흐름

```
사용자: "블로그 연동" 버튼 탭
  ▼
In-App WebView 오픈
  URL: https://www.tistory.com/oauth/authorize
       ?client_id={ID}&redirect_uri=leafylog://callback&response_type=code
  ▼
사용자: Tistory 로그인 & 권한 동의
  ▼
딥링크 콜백 수신 (leafylog://callback?code=AUTH_CODE)
  ▼
POST /oauth/access_token (code + client_secret 교환)
  ▼
access_token → Hive 'settings' 박스에 AES-256 암호화 저장
```

**딥링크 설정** (`AndroidManifest.xml`):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="leafylog" android:host="callback"/>
</intent-filter>
```

### 5.2 Tistory API 규격

| API | 메서드 | 엔드포인트 | 주요 파라미터 |
|---|---|---|---|
| 포스트 작성 | POST | `/apis/post` | `blogName`, `title`, `content`, `visibility` |
| 포스트 수정 | POST | `/apis/post/modify` | `blogName`, `postId`, `content` |
| 파일 첨부 | POST | `/apis/post/attach` | `blogName`, `uploadedfile` (multipart) |
| 블로그 정보 | GET | `/apis/blog/info` | `access_token` |

**공통 요청 헤더**: `Authorization: Bearer {access_token}`, `Content-Type: application/json`

### 5.3 HTML 출력 포맷 (평어체 칼럼 스타일)

```html
<article class="leafylog-post">
  <header>
    <h1>몬스테라 관찰 일기 — 84일의 기록</h1>
    <p class="meta">2026년 4월 9일 · leafylog 자동 생성</p>
  </header>
  <section class="timeline">
    <div class="entry"><time>2026년 1월 20일</time><p>첫 물을 줬다.</p></div>
  </section>
  <section class="ai-report">
    <h2>AI 건강 진단 리포트</h2>
    <p>건강 점수: <strong>82점</strong></p>
  </section>
</article>
```

---

## 6. 마일스톤 & 개발 계획

| 단계 | 마일스톤 | 핵심 산출물 | 완료 기준 |
|---|---|---|---|
| M1 | Flutter 초기화 & UI 스캐폴딩 | 프로젝트 구조, 4개 화면, 라우팅 | 화면 전환 가능, 더미 데이터 표시 |
| M2 | 로컬 데이터 저장 | Hive 어댑터, FileSystemRepo, PhotoService | 재시작 후 데이터 유지, 사진 저장 |
| M3 | Gemini AI 연동 | GeminiApiClient, AnalyzePlantUseCase | 실 기기 사진 → AI 건강 점수 표시 |
| M4 | E2E 테스트 & 릴리즈 빌드 | 전 계층 테스트, 릴리즈 APK | 모든 테스트 통과, APK 생성 |
| M5 *(2차)* | Tistory 연동 | OAuth2, 블로그 포스트 생성 | M4 완료 후 착수 |

### M4 체크리스트 (테스트 & 릴리즈)

- [ ] Unit Tests: D-Day 계산, 파일명 생성, Gemini JSON 파서, UUID 중복 검사
- [ ] Widget Tests: PlantListPage 렌더링, PlantRegisterPage 폼 유효성, AnalysisResultPage 결과 카드
- [ ] Integration Tests: 식물 등록 → AI 분석 → history_log.json 기록 전체 플로우
- [ ] `AndroidManifest.xml` 권한 최종 점검 (CAMERA, READ_EXTERNAL_STORAGE)
- [ ] ProGuard 규칙 (`proguard-rules.pro`) 설정
- [ ] 보안 체크리스트 완료 (섹션 7 참조)
- [ ] `flutter build apk --release --obfuscate --split-debug-info=build/symbols` 성공

---

## 7. 보안 전략

### 계층적 API 키 보안

```
레벨 1: 소스코드 분리
  .env 파일에 API 키 저장 / .gitignore에 .env 등록 (절대 커밋 금지)

레벨 2: 런타임 보호
  flutter_dotenv로 런타임 로딩 / 화면 출력 금지

레벨 3: 저장소 보호
  OAuth access_token: Hive + HiveAesCipher(256-bit AES)
  암호화 키: flutter_secure_storage (Android Keystore 연동)

레벨 4: 빌드 보호
  ProGuard/R8 난독화 활성화 / APK에서 .env 리소스 추출 방지
```

**.env 파일 구조**:
```dotenv
GEMINI_API_KEY=your_gemini_api_key_here
TISTORY_CLIENT_ID=your_tistory_client_id_here
TISTORY_CLIENT_SECRET=your_tistory_client_secret_here
TISTORY_REDIRECT_URI=leafylog://callback
```

**보안 체크리스트**:
- [ ] `.env`가 `.gitignore`에 포함되어 있는가
- [ ] `flutter_secure_storage`로 토큰 암호화 저장
- [ ] 릴리즈 빌드에서 `--obfuscate --split-debug-info` 플래그 적용
- [ ] Gemini API 키에 Android Package 제한 설정

---

## 8. 테스트 전략

### 테스트 계층

```
Unit Tests (비즈니스 로직, 파서, 포매터)
  ↓
Widget Tests (UI 컴포넌트, 상태 관리)
  ↓
Integration Tests (integration_test 패키지)
  ↓
E2E 시나리오 (실제 기기/에뮬레이터)
```

### 테스트 대역(Test Double) 전략

| 테스트 대상 | 대역 방식 | 이유 |
|---|---|---|
| Gemini API | Mock (사전 정의 응답) | API 비용 절감, 일관성 보장 |
| Tistory API | Mock + WireMock | 실제 블로그 발행 방지 |
| 파일 시스템 | 실제 임시 디렉토리 | 실제 I/O 동작 검증 |
| Hive DB | 실제 인메모리 박스 | 실제 직렬화 동작 검증 |

### 핵심 E2E 시나리오 (`integration_test/plant_lifecycle_test.dart`)

```dart
testWidgets('식물 등록 → AI 분석 → history_log.json 기록 전체 흐름', (tester) async {
  // 1. 앱 시작 → 2. 식물 등록 → 3. plants.json 생성 검증
  // 4. AI 분석 요청 (Mock Gemini Client) → 5. 결과 UI 표시 검증
  // 6. history_log.json에 AI_ANALYSIS 엔트리 기록 검증
  expect(log['entries'].last['event_type'], equals('AI_ANALYSIS'));
});
```

---

## 9. 리스크 매트릭스

| # | 리스크 | 가능성 | 영향도 | 대응책 |
|---|---|---|---|---|
| R-01 | 로컬 저장소 부족 (사진 누적) | 중 | 높음 | 500MB 경보 UI, 사진 자동 압축(>1.5MB), 오래된 사진 썸네일 교체 |
| R-02 | Gemini API 실패 (네트워크/할당량) | 중 | 중간 | Exponential Backoff 3회, 오프라인 모드, Hive 캐시 TTL 24h |
| R-03 | AI 오인식 (잘못된 식물 진단) | 높음 | 높음 | Species Context 주입, Confidence < 0.7 경고, 오진 신고 버튼 |
| R-04 | Tistory OAuth 토큰 만료 *(2차)* | 중 | 낮음 | 만료 72h 전 사전 갱신, 실패 시 재인증, 미발행 포스트 로컬 임시저장 |
| R-05 | Hive 박스 데이터 손상 | 낮음 | 높음 | HiveBox.compact() 주기 실행, JSON이 진실 공급원, 초기화 실패 시 JSON 복원 |
| R-06 | UUID 중복 | 매우 낮음 | 높음 | UUID v4 (충돌 확률 1/2^122) + 등록 시 plants.json 중복 검사 |
| R-07 | API 키 유출 (APK 리버싱) | 낮음 | 매우 높음 | .env Git 제외, ProGuard 난독화, 유출 감지 시 즉시 키 폐기, IP/Package 제한 |
| R-08 | 대용량 JSON 파싱 지연 (이력 수백 건) | 중 | 낮음 | Isolate 백그라운드 파싱, 최근 30건 페이지네이션, 집계 캐시 유지 |
| R-09 | 기기 분실/파손 (데이터 전체 손실) | 중 | 매우 높음 | Android Auto Backup (Google Drive, android:allowBackup="true"), 최초 실행 시 백업 활성화 온보딩 안내 |

---

## 10. 스킬 참조

| 스킬 | 호출 방법 | 용도 |
|---|---|---|
| `flutter_qa_builder` | `/flutter_qa_builder` | 테스트 → APK 빌드 자동화 (M4) |
| `data_inspector` | `/data_inspector [plants\|history\|hive]` | 로컬 데이터 검증 (M2~M3) |
| `git_manager` | `/git_manager` | 커밋/푸시 자동화 (작업 완료 시) |
