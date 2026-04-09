# Skill: git_manager
이 스킬은 단위 Task가 완료되었을 때 버전 관리와 티켓 동기화를 위해 호출된다.

1. Micro-Commits: Task 검증 완료 시 즉시 `git add`와 `git commit`을 실행한다.
2. Convention: Conventional Commits(feat, fix 등)를 따르며, 메시지 끝에 이슈/티켓 번호를 포함한다. (예: `feat: Hive 어댑터 구현 (#12)`)
3. Auto-Push: 커밋 직후 `git push`로 원격 저장소에 동기화한다.
4. Ticket Sync: `gh issue close <번호> -c "요약"` 명령어를 통해 GitHub 티켓 상태를 업데이트한다.
