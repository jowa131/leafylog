# leafylog 프로젝트 헌법 (Project Constitution)

이 파일은 Claude가 leafylog 프로젝트를 작업할 때 반드시 준수해야 할 규칙 문서다.
작업 시작 전 항상 이 파일을 읽고 아래 규칙에 따라 행동하라.

---

## 1. Auto-Provisioning & DevOps Rules (자동 프로비저닝 3원칙)

- **Pre-flight Check**: 새로운 프레임워크나 도구 설치 전 `uname -a`, `cat /etc/os-release` 등을 통해 시스템 환경을 파악하고, 필요한 기본 패키지(git, curl, unzip 등)가 있는지 사전 검사하라. 없다면 `sudo apt-get install`을 통한 설치를 계획하라.
- **Deterministic Source**: 다운로드 URL에 `x.x` 같은 가짜 버전(Placeholder)을 절대 사용하지 마라. 버전을 명확히 알 수 없다면 `git clone -b stable` 방식을 최우선으로 사용하라.
- **Auto-Troubleshooting**: 권한 문제(Permission denied)나 패키지 누락으로 명령이 실패할 경우 바로 질문하지 마라. 스스로 에러 로그를 분석해 필요한 `sudo` 명령이나 해결책을 찾고, "이러한 이유로 다음 명령을 실행하겠습니다"라고 승인(Approve)만 요청하라.

---

## 2. Coding Constraints (코딩 컨벤션)

- **상태 관리**: 예외 없이 `flutter_riverpod`만 사용한다. UI 위젯 내부에 비즈니스 로직을 직접 구현하지 말고, 철저히 Provider로 분리하라.
- **데이터 모델**: 데이터는 로컬 Hive 스토리지와 직렬화/역직렬화가 용이하도록 구성하며, 모든 핵심 함수와 클래스에는 DartDoc 표준에 맞춘 주석을 작성한다.

---

## 3. Tone & Manner (어조 및 로깅)

- 코드 내 주석, 앱 UI의 안내 문구, Gemini AI가 분석하여 저장하는 모든 텍스트(예: `ai_status_report`)는 반드시 담백한 **평어체(Plain tone)**로 작성한다.
  - 올바른 예: "~했다", "~이다", "~한다"
  - 잘못된 예: "~했습니다", "~입니다", "~합니다"

---

## 4. Agent Communication Rules (토큰 절약 및 행동 지침)

- **No Yapping**: 불필요한 사과, 변명, 긴 인사말을 절대 하지 마라. 오류 수정 시 "죄송합니다" 등의 감정적 표현 없이 수정된 코드와 이유만 즉시 제시하라.
- **Token Efficiency**: 기존 파일 수정 시 터미널에 파일 전체 코드를 출력하지 마라. 변경이 필요한 부분만 정확히 타겟팅하여 수정(Edit 도구의 특정 블록 교체)하라.
- **Smart QA & Token Saving**:
  1. 과도한 Mocking이 필요한 UI 위젯 테스트 코드는 작성하지 마라.
  2. 테스트 코드는 입력과 출력이 명확한 순수 비즈니스 로직(예: D-Day 계산, JSON 파싱 유틸리티 등)에 대해서만 최소한으로 작성한다.
  3. 세부 Task 단위마다 테스트를 실행하지 마라. 각 마일스톤(예: M2 전체) 개발이 완전히 종료되는 시점에만 `flutter_qa_builder` 스킬을 한 번 호출하여 전체 통합 빌드 안정성을 검증하라.

---

## 5. Version Control & Issue Tracking (버전 관리 및 티켓 동기화)
- **Micro-Commits**: 마일스톤 전체가 끝나기를 기다리지 마라. 하나의 의미 있는 기능, 모듈, 또는 세부 Task 개발이 완료되고 검증되면 **즉시 `git add`와 `git commit`을 실행**하라.
- **Commit Convention**: 커밋 메시지는 Conventional Commits 규약(feat, fix, refactor, chore 등)을 따르며, 메시지 끝에 반드시 관련된 **이슈/티켓 번호**를 포함하라. (예: `feat: Hive 로컬 스토리지 어댑터 구현 (#12)`)
- **Auto-Push**: 커밋을 완료한 직후에는 반드시 **`git push`**를 실행하여 원격 저장소(Remote Repository)에 코드를 동기화하라.
- **Ticket Management**: 코드 푸시 후, GitHub CLI(`gh`)를 사용하여 해당 Task와 관련된 이슈(Issue)를 업데이트하라. Task가 완전히 종료되었다면 `gh issue close <번호> -c "해결 내용 요약"` 명령어를 통해 코멘트를 남기고 티켓을 닫아라.
