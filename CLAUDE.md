# leafylog 프로젝트 헌법 (Project Constitution)

## 1. Coding Constraints
- 상태 관리: `flutter_riverpod` 단독 사용. 비즈니스 로직은 Provider로 분리.
- 데이터 모델: Hive 직렬화 기반. 핵심 로직은 DartDoc 주석 작성.

## 2. Tone & Manner
- 코드 주석·UI 문구 모두 **평어체** ("~했다", "~이다").

## 3. Agent Rules
- No Yapping: 사과·변명 생략. 오류 시 수정 코드만 제시.
- Token Efficiency: 변경 부분만 패치. 전체 코드 덤프 금지.
- Smart QA: UI 테스트 생략. 순수 비즈니스 로직 단위 테스트만.
- Task Sync: 작업 완료 시 `git_manager` 스킬로 커밋/푸시.
