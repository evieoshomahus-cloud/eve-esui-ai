# CHAPTER FOUR

# IMPLEMENTATION

## 4.1 Introduction to the Chapter

This chapter presents the implementation of the project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**. It describes the implementation environment, system modules, interface design, API endpoints, testing process, results, and discussion of findings.

The implemented system is named Eve. Eve was built as a responsive Flutter client connected to a Python FastAPI backend. The backend provides AI orchestration, RAG, role-based access control, learning-session scoring, SQLite persistence, admission readiness estimation, student progress tracking, and lecturer analytics.

## 4.2 Implementation Environment

The system was implemented and tested in the following environment:

| Item | Description |
| --- | --- |
| Operating system | Windows |
| Client framework | Flutter |
| Backend framework | FastAPI |
| Backend language | Python |
| Local database | SQLite |
| API server | Uvicorn |
| AI response mode | Optional OpenAI Responses API with local fallback |
| Browser test URL | `http://127.0.0.1:8011` |
| Backend test URL | `http://127.0.0.1:8010` |

The local backend is started with:

```powershell
python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload
```

The Flutter web client is started with:

```powershell
cd eve_app
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8011
```

## 4.3 System Implementation

### 4.3.1 Backend Implementation

The backend was implemented using FastAPI. It is organized into modules for admissions, AI assistance, learning profiles, learning sessions, persistence, retrieval, repository access, schemas, and security.

Major backend files include:

| File | Purpose |
| --- | --- |
| `api/eve_core/main.py` | Defines API routes and application setup. |
| `api/eve_core/assistant.py` | Handles intent detection, authorization, retrieval, and answer generation. |
| `api/eve_core/learning.py` | Computes student learning profile and progress dashboard data. |
| `api/eve_core/learning_sessions.py` | Starts guided sessions, scores answers, and returns feedback. |
| `api/eve_core/progress_store.py` | Stores and retrieves SQLite learning-session history. |
| `api/eve_core/retrieval.py` | Implements RAG-style knowledge retrieval. |
| `api/eve_core/security.py` | Blocks prompt injection and unauthorized private-record access. |
| `api/eve_core/llm.py` | Connects to optional OpenAI response generation. |

### 4.3.2 Frontend Implementation

The frontend was implemented using Flutter. It provides a responsive interface for guest, student, and lecturer users. The interface includes login mode selection, chat, tools, admissions estimator, student learning progress dashboard, guided learning session screen, upload-assisted Ask Eve, peer-note contribution, lecturer workbench, knowledge governance views, and profile/account switcher.

Major frontend files include:

| File | Purpose |
| --- | --- |
| `eve_app/lib/main.dart` | Main Flutter interface and screens. |
| `eve_app/lib/eve_api.dart` | API client for backend communication. |
| `eve_app/lib/eve_models.dart` | Data models for users and chat responses. |

### 4.3.3 RAG and AI Response Implementation

The system uses a curated ESUI knowledge base. When a user asks a knowledge-based question, Eve retrieves relevant entries according to the user's role. The retrieved information is used to ground the answer. If OpenAI is configured, Eve uses the OpenAI Responses API to make the answer more natural while respecting the authorized context. If OpenAI is not configured, Eve returns a local fallback answer.

### 4.3.4 Prompt-Injection Guardrail Implementation

Before answering a request, Eve checks whether the prompt attempts to bypass rules, reveal hidden instructions, extract private records, or impersonate another user. Suspicious requests are blocked before retrieval or generation.

### 4.3.5 Personalized Learning Implementation

The personalized learning module computes:

- overall progress;
- learning status;
- weak topics;
- priority course;
- weekly learning plan;
- milestones;
- saved session history;
- quiz average;
- course-level session statistics.

For the demo student `stu-csc-001`, Eve identifies `MTH 211` as a priority course because it has a high risk level and topic gaps such as eigenvalues and matrix inverse.

### 4.3.6 Guided Learning Session Implementation

A student can start a guided learning session from a weak course. Eve returns a concept explanation, worked example, and practice questions. The student submits answers, and the backend scores them using expected concepts and keywords. The answer, score, feedback, and ideal answer direction are saved in SQLite.

### 4.3.7 Lecturer Analytics Implementation

Lecturers can view analytics only for their assigned courses. The lecturer workbench shows:

- assigned course count;
- tracked students;
- completed Eve learning sessions;
- average quiz score;
- topic performance;
- weakest saved topic;
- intervention recommendation.

For example, `lec-mth-002` can view `MTH 211` insights because the course is assigned to that lecturer.

### 4.3.8 Upload-Assisted Ask Eve Implementation

The Ask Eve module supports file-assisted academic questions. A student can upload a supported note file and ask Eve to summarize, explain, or turn the content into a study plan. This makes the assistant more useful for personalized learning because it can respond to a student's own learning material instead of only answering from general knowledge.

For the prototype, uploaded content is treated as private session context. Eve uses it to support the student's current question, but it is not automatically published to the shared knowledge base. This design prevents unverified notes from becoming official institutional content.

### 4.3.9 Moderated Peer Notes and Knowledge Governance Implementation

The project also includes a moderated peer-note workflow. Students can submit helpful course notes, summaries, and explanations, but those notes do not become shared learning material until they are reviewed. Lecturers can review submissions only for courses assigned to them, while administrators can review wider institutional knowledge entries.

The moderation process supports three outcomes:

- approve useful and accurate notes;
- request revision when a note needs correction;
- reject unsuitable or inaccurate notes.

Approved peer notes can be retrieved as learning support, while pending and rejected notes remain separate from the official knowledge base. This protects students from misinformation and supports academic governance.

## 4.4 System Interface / Screenshots

The following screenshots were captured from the running system and are included as implementation evidence:

| Figure | Screenshot | Description |
| --- | --- | --- |
| Figure 4.1 | Entry screen | Shows guest, student, and lecturer entry modes. |
| Figure 4.2 | Personalized student dashboard | Shows today's focus, weak topic, progress, and peer-note activity. |
| Figure 4.3 | Mobile responsive dashboard | Shows the same student dashboard adapted to a phone screen. |
| Figure 4.4 | Ask Eve conversation | Shows Eve giving personalized academic guidance. |
| Figure 4.5 | Upload-assisted Ask Eve | Shows Eve using an uploaded CSC note to support a student's question. |
| Figure 4.6 | Guided learning session | Shows concept explanation and practice question support. |
| Figure 4.7 | Peer-note submission | Shows the student contribution form. |
| Figure 4.8 | Lecturer peer-note review | Shows approve, reject, and revise moderation actions. |
| Figure 4.9 | Lecturer analytics | Shows assigned-course analytics and intervention insight. |
| Figure 4.10 | Admission readiness estimator | Shows public guidance for Computer Science admission readiness. |
| Figure 4.11 | Admin knowledge library | Shows curated institutional knowledge entries and governance controls. |
| Figure 4.12 | Backend health endpoint | Shows the deployed backend running in OpenAI Responses API mode. |

![Figure 4.1: Eve role selection and login screen.](screenshots/login_screen.png)

![Figure 4.2: Personalized student dashboard showing today's focus, weak topic, progress, and peer-note activity.](screenshots/student_personalized_home_desktop.png)

![Figure 4.3: Mobile responsive view of the personalized student dashboard.](screenshots/student_personalized_home_mobile.jpeg)

![Figure 4.4: Ask Eve conversation showing personalized academic guidance.](screenshots/ask_eve_conversation.png)

![Figure 4.5: Upload-assisted Ask Eve conversation using a CSC 201 note.](screenshots/upload_assisted_ask_eve.png)

![Figure 4.6: Guided CSC 201 learning session with concept explanation and practice question.](screenshots/learning_session_page.png)

![Figure 4.7: Student peer-note submission form.](screenshots/peer_notes_submission_form.png)

![Figure 4.8: Lecturer peer-note review queue with approve, reject, and revise actions.](screenshots/lecturer_peer_note_review.png)

![Figure 4.9: Lecturer workbench with assigned-course analytics.](screenshots/lecturer_analytics_page.png)

![Figure 4.10: Admission readiness estimator result for Computer Science.](screenshots/admission_readiness_result.png)

![Figure 4.11: Admin curated knowledge library with approved entries.](screenshots/admin_knowledge_library.png)

![Figure 4.12: Backend health endpoint showing OpenAI Responses API mode.](screenshots/openai_responses.png)

## 4.5 Test Plan

The system was tested using functional tests, API endpoint tests, UI tests, and security behavior checks.

| Test Area | Purpose |
| --- | --- |
| Backend compilation | Confirm Python modules compile successfully. |
| Flutter analysis | Detect Dart and Flutter code issues. |
| Flutter widget test | Confirm the app renders the entry screen. |
| API health test | Confirm backend service is running. |
| Student learning profile test | Confirm personalized progress data is returned. |
| Learning session test | Confirm session creation, answer scoring, and persistence. |
| Lecturer insight test | Confirm assigned-course analytics and saved learning trends. |
| Chat test | Confirm natural responses and role-aware answers. |
| Guardrail test | Confirm prompt-injection attempts are blocked. |
| Upload-assisted chat test | Confirm Eve can use an uploaded note as private question context. |
| Peer-note moderation test | Confirm student notes require review before shared use. |
| Knowledge governance test | Confirm admin knowledge entries and audit labels are available. |

## 4.6 Test Cases and Test Results

### 4.6.1 Backend Compilation Test

| Test | Command | Expected Result | Actual Result |
| --- | --- | --- | --- |
| Compile backend | `python -m compileall -q api` | No syntax errors | Passed |

### 4.6.2 Flutter Analysis Test

| Test | Command | Expected Result | Actual Result |
| --- | --- | --- | --- |
| Analyze Flutter app | `flutter analyze` | No issues found | Passed |

### 4.6.3 Flutter Widget Test

| Test | Command | Expected Result | Actual Result |
| --- | --- | --- | --- |
| Render entry screen | `flutter test` | All tests passed | Passed |

### 4.6.4 API Health Test

| Endpoint | Expected Result | Actual Result |
| --- | --- | --- |
| `GET /api/health` | Backend status is `ok` | Passed |

Example response:

```json
{
  "status": "ok",
  "service": "eve-esui-ai",
  "version": "1.0.0",
  "ai_mode": "openai_responses"
}
```

### 4.6.5 Student Learning Profile Test

| Endpoint | Expected Result | Actual Result |
| --- | --- | --- |
| `GET /api/student/stu-csc-001/learning-profile` | Return personalized learning profile | Passed |

The response includes overall progress, weak topics, priority course, weekly plan, saved session history, completed sessions, and quiz average.

### 4.6.6 Learning Session Persistence Test

| Endpoint | Expected Result | Actual Result |
| --- | --- | --- |
| `POST /api/learning-sessions` | Create guided learning session | Passed |
| `POST /api/learning-sessions/{session_id}/answer` | Score answer and save feedback | Passed |
| `GET /api/student/stu-csc-001/progress-history` | Return saved SQLite progress history | Passed |

One demo `MTH 211` eigenvalues session returned a saved average score of `93%`.

### 4.6.7 Lecturer Analytics Test

| Endpoint | Expected Result | Actual Result |
| --- | --- | --- |
| `GET /api/lecturer/lec-mth-002/insights` | Return assigned-course trends for `MTH 211` | Passed |

The response includes total sessions, completed sessions, tracked student count, average quiz score, topic performance, weakest saved topic, and an intervention suggestion.

### 4.6.8 Chat Response Test

| Input | Expected Result | Actual Result |
| --- | --- | --- |
| `hello` | Natural greeting response | Passed |
| `how are you` | Natural check-in response | Passed |
| `Show lecturer analytics for MTH 211` | Lecturer analytics with saved session trends | Passed |

### 4.6.9 Security Test

| Test | Expected Result | Actual Result |
| --- | --- | --- |
| Prompt-injection attempt | Request should be blocked | Passed |
| Student tries to access another student's private record | Request should be denied | Passed |
| Lecturer requests unassigned course analytics | Access should be denied | Passed |

### 4.6.10 Upload-Assisted Ask Eve Test

| Test | Expected Result | Actual Result |
| --- | --- | --- |
| Upload a CSC note and ask Eve for explanation | Eve should use the uploaded note as context for the current question | Passed |

### 4.6.11 Peer-Note Moderation Test

| Test | Expected Result | Actual Result |
| --- | --- | --- |
| Student submits course note | Note should appear as pending review | Passed |
| Lecturer reviews assigned-course note | Lecturer should approve, reject, or request revision | Passed |
| Approved note is retrieved by Eve | Approved note should be available as reviewed peer learning context | Passed |

### 4.6.12 Knowledge Governance Test

| Test | Expected Result | Actual Result |
| --- | --- | --- |
| Admin adds knowledge entry | Entry should be saved with governance metadata | Passed |
| Ask Eve about knowledge gaps | Eve should explain uncertainty and avoid unsupported claims | Passed |

## 4.7 Model Training and Evaluation

The prototype does not train a new large language model from scratch. Instead, it uses:

- a curated ESUI knowledge base;
- deterministic local academic logic;
- RAG-style retrieval;
- optional OpenAI response generation;
- scoring logic for guided learning sessions.

This approach is appropriate for the prototype because training a large model would require large datasets, high computing resources, and institutional governance. RAG allows the system to use verified knowledge while reducing hallucination.

Evaluation was performed through functional testing, response quality checks, role-based access tests, and guardrail tests.

## 4.8 Experimental Results and Analysis

The implemented prototype successfully demonstrated the main project goal. It was able to:

- support role-based guest, student, and lecturer modes;
- provide public ESUI guidance;
- estimate admission readiness;
- identify student weak topics;
- recommend personalized study tasks;
- start guided learning sessions;
- score quiz answers;
- store learning progress in SQLite;
- show saved progress history;
- provide lecturer course-level learning trends;
- support upload-assisted questions using student-provided notes;
- allow moderated peer-note contribution and lecturer review;
- provide admin knowledge governance for curated information;
- generate natural AI responses when OpenAI mode is configured;
- block unsafe or unauthorized requests.

The saved `MTH 211` session showed how a student's activity can become progress evidence. The lecturer dashboard then reused that saved learning history as course-level teaching insight.

## 4.9 Performance Evaluation

The system ran successfully in a local development environment. Flutter web returned HTTP `200` on `http://127.0.0.1:8011`, and the backend responded on `http://127.0.0.1:8010`.

The system uses lightweight JSON and SQLite storage, which is suitable for prototype demonstration. In production, performance can be improved by using a managed database, caching, vector search, asynchronous workers, and institution-hosted infrastructure.

## 4.10 Discussion of Results

The results show that Eve is more than a chatbot. It implements the core requirements of personalized learning and academic progress tracking. The student module identifies weak topics and tracks improvement through saved quiz sessions. The lecturer module converts saved student learning activity into course-level intervention insight. The guest module supports admissions and public inquiry functions.

The use of guardrails and role-based access control addresses privacy and cybersecurity concerns. The OpenAI integration improves response quality, while local fallback logic ensures that the system can still operate when external AI access is unavailable.

The prototype is limited by its use of sample data. However, its architecture can be extended to real university systems through secure APIs, identity management, approved course materials, and managed database storage.

## 4.11 Summary of the Chapter

This chapter presented the implementation and testing of Eve. It described the development environment, backend and frontend modules, interface screens, test plan, test results, AI evaluation approach, and discussion of results. The implementation confirms that the project topic was achieved through a working system for personalized learning, academic progress tracking, guided learning sessions, upload-assisted learning support, moderated peer notes, knowledge governance, and lecturer analytics.
