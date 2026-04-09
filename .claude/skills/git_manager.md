# git_manager 스킬

세부 작업 완료 시 Conventional Commits 규약에 따라 커밋하고 원격 저장소에 푸시한다.

## 실행 절차

1. `git status --short` 로 변경 파일 목록을 확인한다.
2. 변경 내용을 분석해 적절한 커밋 타입을 선택한다. (feat / fix / refactor / chore / docs / test)
3. 관련 이슈 번호를 포함한 커밋 메시지를 작성한다. (예: `feat: 기능 설명 (#이슈번호)`)
4. `git add <관련 파일>` → `git commit -m "..."` → `git push` 를 순서대로 실행한다.
5. 푸시 성공 시 해당 GitHub 이슈가 열려 있다면 `gh issue close <번호> -c "해결 내용"` 으로 닫는다.

## 커밋 타입 기준

| 타입 | 사용 시점 |
|------|-----------|
| feat | 새 기능 추가 |
| fix | 버그 수정 |
| refactor | 동작 변경 없는 코드 개선 |
| chore | 빌드·설정·의존성 변경 |
| docs | 문서·주석 수정 |
| test | 테스트 코드 추가·수정 |

## 주의사항
- `.env` 파일은 절대 스테이징하지 않는다.
- APK 바이너리(`*.apk`)는 `.gitignore`에 등록되어 있으므로 자동 제외된다.
- 커밋 메시지 끝에 항상 `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` 를 추가한다.
