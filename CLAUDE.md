# leafylog 프로젝트 헌법 (Project Constitution)

작업 시작 전 항상 이 파일을 읽고 아래 전역 규칙을 엄격히 준수하라.

## 1. Coding Constraints (코딩 컨벤션)
- 상태 관리: 예외 없이 `flutter_riverpod`만 사용한다. 비즈니스 로직은 철저히 Provider로 분리하라.
- 데이터 모델: Hive 스토리지 기반 직렬화 모델을 사용하며, 핵심 로직은 DartDoc 주석을 작성한다.

## 2. Tone & Manner (어조 및 로깅)
- 코드 주석, UI 안내, AI 생성 텍스트 등 모든 문구는 담백한 **평어체(Plain tone)**로 작성한다. (예: "~했다", "~이다")

## 3. Agent Communication & QA (행동 지침)
- No Yapping: 불필요한 사과나 변명을 생략하고, 오류 발생 시 수정된 코드만 즉시 제시하라.
- Token Efficiency: 파일 수정 시 전체 코드를 쏟아내지 말고, 변경 부분만 타겟팅하여 패치(Patch)하라.
- Smart QA: UI 위젯 테스트는 생략하고, 순수 비즈니스 로직(날짜 계산, 파싱 등) 단위 테스트만 최소한으로 작성한다. 마일스톤 완료 시에만 전체 통합 빌드를 검증하라.
- Task Sync: 세부 작업이 완료되면 스스로 `git_manager` 스킬을 호출하여 버전을 기록하라.
