# Eve ESUI AI Platform

Recorded project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**.

Eve is the system prototype for this topic. It provides personalized learning support, academic progress tracking, student academic guidance, lecturer course analytics, RAG-backed answers, role-based access control, and cybersecurity guardrails. The interface is designed as an academic portal first, with a conversation-first AI assistant embedded as one support tool inside guest, student, lecturer, and admin workflows.

## Architecture

- `eve_app/` - Flutter Android/Web client
- `api/` - Python FastAPI AI backend
- `knowledge/` - curated ESUI knowledge, sample records, and research notes
- `project_docs/` - project documentation and report material
- `assets/` - official ESUI logo asset captured from the school website
- `storage/` - local runtime SQLite database for saved learning progress

## Core Student Module

The personalized learning module calculates:

- Overall learning progress
- Priority course
- Weak topics
- Recommended next learning session
- Weekly study plan
- Academic milestones
- Guided learning sessions
- Quiz scoring and feedback
- Persistent SQLite learning history
- Saved session progress dashboard
- File and image uploads inside Ask Eve for notes, screenshots, assignment briefs, and study material

Student practice answers, weak-topic history, and learning-session scores remain inside the student's private progress workspace. They do not publish school-wide information. Official knowledge that Eve uses for general answers is handled through the admin-reviewed knowledge workflow.

Uploaded chat files are treated as private session material for the signed-in demo account. Text, markdown, CSV, JSON, PDF, DOCX, and common image uploads are accepted up to the demo size limit. Text-like files are extracted into temporary context; images are routed to the OpenAI vision-capable response layer when configured.

## Lecturer Analytics Module

The lecturer module shows assigned-course analytics and saved learning-session trends:

- Assigned-course performance indicators
- Tracked student count from saved sessions
- Completed Eve learning-session count
- Average quiz score by assigned course
- Weak-topic trend detection
- Suggested teaching interventions

## Run Backend

```powershell
python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload
```

## Run Flutter Web

```powershell
cd eve_app
flutter run -d chrome --web-port 8011
```

## Deploy Demo Online

Eve is deployment-ready as a single Docker web service. The deployment builds the Flutter web client first, then serves it from the FastAPI backend so reviewers can open one stable public URL instead of an ngrok tunnel.

Recommended path:

1. Push this folder to a private GitHub repository.
2. Create a Render Blueprint from the repository.
3. Add `OPENAI_API_KEY` as a private Render environment variable.
4. Deploy and test `/api/health`.

See `project_docs/deployment_guide.md` for the full checklist.

## Demo Accounts

- Guest: `guest-001`
- Student: `stu-csc-001`
- Student: `stu-acc-002`
- Lecturer: `lec-csc-001`
- Lecturer: `lec-mth-002`
- Admin: `adm-knowledge-001`

## Manage Eve Knowledge

Eve uses scoped knowledge governance. Admin users manage school-wide information such as admissions, fees, portals, hostel guidance, calendars, student affairs, and payment links. Lecturer users can manage only `learning` entries that include one of their assigned course codes, such as `CSC 201`, `CSC 305`, or `MTH 211`.

Open the Admin account, go to Tools, choose Knowledge base, then use the library to search, filter, view, edit, delete, or add entries. Open a Lecturer account to manage assigned-course learning entries only. Eve validates each saved entry, writes approved changes to `knowledge/esui_knowledge.json`, and reloads the backend knowledge cache when validation passes.

Because the prototype does not have every official school policy, some entries are clearly marked as demo placeholders. Replace those demo entries with approved ESUI policies before production.

Eve also tracks knowledge gaps. When a student asks a question Eve cannot answer confidently from approved/demo knowledge, the question is stored in `storage/knowledge_gaps.json` for admin review. Admin staff can draft a new knowledge entry from the gap, edit it, save it, and mark the gap as converted.

Each knowledge entry carries an approval status: `demo`, `draft`, `approved`, or `needs_review`. Admin users can approve entries; lecturers can submit course entries as draft/demo/needs-review only. Eve records create, update, and delete events in `storage/knowledge_audit_log.json`, and the Admin Knowledge Base screen shows the recent audit trail.

Manual editing is still available for bulk updates. Use `knowledge/knowledge_entry_template.json` as the format for new entries.

Validate entries before using them:

```powershell
python tools\validate_knowledge.py
```

Reload the backend knowledge cache after editing:

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8010/api/admin/knowledge/reload -Method Post
```

Useful admin checks:

```powershell
Invoke-RestMethod http://127.0.0.1:8010/api/admin/knowledge/stats
Invoke-RestMethod http://127.0.0.1:8010/api/admin/knowledge/validate
Invoke-RestMethod http://127.0.0.1:8010/api/admin/knowledge/entries
Invoke-RestMethod http://127.0.0.1:8010/api/admin/knowledge/gaps
Invoke-RestMethod "http://127.0.0.1:8010/api/admin/knowledge/audit?actor_role=admin&actor_user_id=adm-knowledge-001"
Invoke-RestMethod -Uri http://127.0.0.1:8010/api/admin/knowledge/entries -Method Post -ContentType 'application/json' -Body $body
```

Useful scoped check:

```powershell
Invoke-RestMethod "http://127.0.0.1:8010/api/admin/knowledge/entries?actor_role=lecturer&actor_user_id=lec-csc-001"
```

## Main Defense Points

- Comparable universities are already deploying governed AI systems for student support, learning guidance, and campus knowledge.
- Eve uses Flutter because the target product is mobile-first and Play Store-ready.
- Eve uses Python FastAPI because AI/RAG and future model integration are stronger in Python.
- The current system demonstrates personalized learning support, academic progress tracking, role-aware access, RAG retrieval, admission guidance, student success support, lecturer analytics, and prompt-injection blocking.
- Learning sessions are saved locally in SQLite so quiz history and progress scores survive backend restarts during demonstration.
- Lecturer dashboards use saved learning-session history to support course intervention decisions.
- Eve separates knowledge ownership: admins govern school affairs while lecturers manage assigned-course learning entries only.
- Eve includes approval status and audit tracking so school information can be reviewed before students rely on it.
- Eve is not only a chatbot; it includes role dashboards, admission tools, learning-progress views, lecturer analytics, and admin governance screens, while Ask Eve supports the user when natural-language help is needed.
- Eve uses the OpenAI response layer for natural conversation when the API key is configured, while the local RAG and role checks still control what institutional or private context the model may use.
- Eve supports upload-assisted conversations, allowing a student to attach a note, screenshot, or assignment material and ask for summaries, explanations, study plans, or feedback.
- Eve uses curated ESUI knowledge as its primary school-information source. The official ESUI website is used only as a supplementary live source for current/latest/website-specific questions, because live websites can be unavailable during a demonstration.
- Chat answers expose source labels such as Curated ESUI Knowledge, Demo Curated Knowledge, Live ESUI Website, and External Reference so users can see where Eve grounded the response.
- Eve does not silently invent and permanently save new school facts; it records knowledge gaps for human review.

## Optional OpenAI Mode

To make Eve respond more naturally, configure the backend with an OpenAI API key.

Recommended local setup:

1. Copy `.env.example` to `.env`.
2. Paste your real key into `.env`.
3. Keep `.env` private.

The `.env` file should look like:

```text
OPENAI_API_KEY=your_key_here
EVE_OPENAI_MODEL=gpt-5.4-mini
```

Then run:

```powershell
python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload
```

Without a key, Eve runs in local fallback mode.
