---
name: data_inspector
description: leafylog 로컬 데이터(plants.json, history_log.json, Hive 박스)를 읽어 터미널에 포매팅해서 출력한다. 개발 중 데이터 상태 검증용.
---

leafylog 로컬 데이터를 검사하라.
앱 데이터 기본 경로: Android 에뮬레이터/기기의 경우 `adb shell`로 접근하거나,
로컬 테스트 시 `getApplicationDocumentsDirectory()` 결과 경로를 사용한다.

사용자가 제공한 인수(args)에 따라 아래 모드 중 하나를 실행하라.

## 모드 1: `plants` — 전체 식물 목록 조회

**호출**: `/data_inspector plants`

1. `[AppDocDir]/leafylog/plants.json` 파일을 Read 도구로 읽어라
2. 파일이 없으면: "plants.json 없음 — 아직 등록된 식물이 없습니다." 출력
3. 있으면 아래 형식으로 출력하라:

```
# plants.json 현황 ({last_updated} 기준)

| # | ID (앞8자리) | 표시명 | 종명 | 등록일 | D-Day | 물주기 | 상태 |
|---|---|---|---|---|---|---|---|
| 1 | a1b2c3d4 | 몬스테라 | Monstera deliciosa | 2026-01-15 | D+84 | 7일 | 활성 |

총 {n}개 식물 ({m}개 아카이브 포함)
```

- D-Day: 오늘 날짜 기준 `dday_anchor`로부터 경과일 계산
- 상태: `is_archived: true`이면 "아카이브", 아니면 "활성"

## 모드 2: `history <plant_id>` — 식물 이력 타임라인 조회

**호출**: `/data_inspector history a1b2c3d4` (UUID 앞 8자리 또는 전체)

1. `plants.json`에서 plant_id 매칭 (앞 8자리로도 매칭 허용)
2. `[AppDocDir]/leafylog/plants/{FULL_UUID}/history_log.json` 읽기
3. 없으면: "해당 식물의 이력 로그가 없습니다." 출력
4. 있으면 타임라인 형식으로 출력:

```
# {표시명} ({종명}) 이력 타임라인
# UUID: {full_uuid} | 총 {n}개 항목

날짜        시간     이벤트 타입      내용
----------  -------  ---------------  ------------------------------------------
2026-01-15  09:00    WATERING         첫 물주기
2026-02-10  14:30    REPOTTING        새 흙으로 분갈이
2026-04-09  14:30    AI_ANALYSIS      건강점수: 82 | 신뢰도: 0.91
                                      이슈: 하엽 황화, 과습 의심
                                      권장: 물주기 10일로 조정, 직사광선 회피
```

- `AI_ANALYSIS` 엔트리는 `health_score`, `detected_issues`, `recommendations` 추가 표시
- `user_note`가 있으면 내용란에 함께 표시

## 모드 3: `hive <box_name>` — Hive 박스 상태 확인

**호출**: `/data_inspector hive settings` 또는 `/data_inspector hive cache`

Hive 박스는 바이너리 형식이므로 직접 파싱 대신 아래를 수행하라:

1. Hive 박스 파일 예상 경로를 출력:
   ```
   [AppDocDir]/leafylog_hive/{box_name}.hive
   ```
2. 박스별 저장 내용 안내:

| 박스명 | 저장 내용 | 비고 |
|---|---|---|
| `settings` | 테마, 알림 설정, OAuth 토큰 | `flutter_secure_storage`로 토큰 암호화 |
| `cache` | Gemini 최근 응답 캐시 | TTL 24h |
| `notification_schedule` | 물주기 알림 예약 | 앱 재시작 후 복원용 |

3. 개발 중 Hive 내용 직접 확인이 필요하면 Unit Test에서 `Hive.openBox()`로 읽는 방법을 제안하라

## 인수 없이 호출 시

`/data_inspector` (인수 없음) → 사용법 안내 출력:

```
## data_inspector 사용법

- /data_inspector plants               전체 식물 목록 조회
- /data_inspector history <plant_id>   특정 식물 이력 타임라인 조회
- /data_inspector hive <box_name>      Hive 박스 상태 확인
```
