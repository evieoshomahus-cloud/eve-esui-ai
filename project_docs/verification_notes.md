# Verification Notes

Date verified: 2026-06-11

## Backend Checks

- `python -c "from api.eve_core.main import app; print(app.title)"` passed.
- `python -m compileall -q api` passed.
- RAG chat endpoint returned sourced ESUI LMS guidance.
- Prompt-injection smoke test was blocked.
- Admission readiness endpoint returned a valid readiness score and recommendations.
- Backend health now reports `ai_mode` as either `local_fallback` or `openai_responses`.
- OpenAI-aware backend path falls back safely when `OPENAI_API_KEY` is not configured.

## Flutter Checks

- `flutter analyze` passed with no issues.
- `flutter test` passed.
- Flutter web server returned HTTP 200 on `http://127.0.0.1:8011`.
- Flutter UI was redesigned into an entry screen, personalized home, full chat, role tools, admission estimator, and profile/account switcher.

## Personalized Learning Module Checks

- `GET /api/student/stu-csc-001/learning-profile` returned a full learning profile.
- The profile includes overall progress, learning status, priority course, weak topics, course progress, weekly plan, and milestones.
- The profile now includes saved progress history, completed session count, quiz average, recent sessions, and course-level session statistics.
- `GET /api/student/stu-csc-001/progress-history` returned persisted SQLite learning history.
- Flutter student tools now read from the learning-profile endpoint.
- Flutter web server was restarted on `http://127.0.0.1:8011` after the UI update.

## Learning Session Mode Checks

- `POST /api/learning-sessions` creates a guided session for a registered student course.
- Session payload includes explanation, example, question, progress counters, average score, and history.
- Backend answer scoring works with concept keywords and feedback.
- Backend stores learning sessions and answer records in local SQLite.
- Persistence smoke test completed one `MTH 211` eigenvalues session and returned a saved average score.
- Flutter analysis passed after adding the Learning Session screen.

## Lecturer Learning Analytics Checks

- `GET /api/lecturer/lec-mth-002/insights` returned assigned-course learning insights for `MTH 211`.
- The lecturer payload includes total saved sessions, completed sessions, tracked student count, average quiz score, topic performance, weakest saved topic, and an intervention suggestion.
- Lecturer chat for `MTH 211` used saved learning-session trends and returned no unrelated retrieval sources.
- Flutter lecturer tools now show saved-session trend metrics and assigned-course intervention cards.

## Running Services

- Backend: `http://127.0.0.1:8010`
- Flutter web: `http://127.0.0.1:8011`

## Important Note

The previous test prototype on port `8001` was stopped. The rebuilt system now runs through the Flutter client and the new backend.
