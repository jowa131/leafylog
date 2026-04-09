# Skill: release_manager
이 스킬은 새로운 기능 개발이나 버그 수정이 완료되어, 사용자에게 새로운 앱 버전을 배포(Release)해야 할 때 호출된다. 이 스킬이 실행되면 반드시 아래 5단계를 순차적으로 자동 수행하라.

1. Version Bump: `pubspec.yaml`을 읽고 앱 버전을 올린다. (예: 1.2.0+3 -> 1.2.1+4 등 상황에 맞게)
2. Build: 터미널에서 `flutter build apk --release` 명령을 실행하여 릴리즈 APK를 추출한다.
3. Artifact Copy: 빌드된 APK(`build/app/outputs/flutter-apk/app-release.apk`)를 웹 배포 폴더로 복사하되, 파일명에 새 버전을 포함시킨다. (명령어: `cp build/app/outputs/flutter-apk/app-release.apk web_dist/html/leafylog/leafylog-v{새버전}.apk`)
4. Web Update: `web_dist/html/leafylog/index.html` 파일을 수정하여 다운로드 링크(href)가 방금 복사한 새 버전의 APK를 가리키도록 업데이트하고, 페이지 내 버전 표기 텍스트도 변경한다.
5. Deploy: 터미널에서 `cd web_dist && docker-compose up -d --build`를 실행하여 웹 서버 컨테이너를 재시작하고 배포를 완료한다.
