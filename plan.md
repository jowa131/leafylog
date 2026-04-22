# leafylog — Development Plan

## Completed Milestones

- [x] M1: Project setup — Flutter environment, Riverpod, Hive, go_router, flutter_dotenv
- [x] M2: Plant CRUD — `plants.json` as source of truth, `FileSystemRepository`, UUID v4 IDs
- [x] M3: Photo management — camera capture, file path convention, photo gallery per plant
- [x] M4: AI analysis — Gemini API integration (image + context), `history_log.json` persistence

## Backlog / Future Work

- [ ] M5 (2nd phase): Tistory blog integration via OAuth2 + REST API v1
- [ ] Crash log server integration — wire app to `leafylog-log-server` in `web_dist/`
- [ ] Notification / reminder system for plant care schedules
- [ ] Widget — home screen plant status widget (Android)
- [ ] Export — backup/restore `plants.json` and photos to external storage
- [ ] Multi-device sync (future consideration — breaks local-first constraint)
