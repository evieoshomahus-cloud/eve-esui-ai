# Eve Project Blueprint

## Recorded Project Topic

Design and implementation of an ai system for personalized learning and academic progress tracking

## Core Modules

- Personalized learning assistant
- Academic progress tracking dashboard
- Learning profile computation
- Weak-topic and priority-course detection
- Weekly personalized study plan
- Guided learning session mode
- Quiz scoring and feedback history
- SQLite learning-session persistence
- Saved progress-history endpoint
- Student academic assistant and private dashboard
- Private student learning inputs that do not publish global school knowledge
- Private file and image uploads for note review, screenshot explanation, and assignment-guidance conversations
- Lecturer course-progress analytics assistant
- Lecturer saved-session trend dashboard
- Assigned-course intervention recommendations
- Admin knowledge governance workbench for school-wide information
- Guest admission and public information assistant
- Admissions readiness estimator
- RAG knowledge retrieval
- In-app knowledge-base library with search, filters, view, add, edit, delete, validation, persistence, and reload workflow
- Role-scoped knowledge ownership: admins manage school affairs, lecturers manage assigned-course learning entries only
- Approval status and audit trail for knowledge create, update, delete, and review activity
- Knowledge-gap tracking for unanswered or low-confidence student questions
- Clearly labelled demo knowledge placeholders for unavailable school policies
- Allowlisted official ESUI website retrieval
- Prompt-injection guardrails
- Role-based access control
- Audit and explainability labels
- Visible answer source labels
- Optional OpenAI Responses API response generation
- Conversation-first Ask Eve interface backed by the OpenAI response layer when configured
- Upload-assisted Ask Eve conversations with text extraction and image input routing
- Responsive Flutter interface

## Product Suggestions Added

- Treat Eve as an institutional AI system for personalized learning and academic progress tracking, not a generic chatbot.
- Keep the product portal-first: role dashboards, progress tools, admissions guidance, and governance screens should be visible before users need the natural-language Ask Eve assistant.
- Use verified ESUI data first; avoid hallucinating live news or private records.
- Treat curated ESUI knowledge, approved departmental documents, course materials, academic calendars, and authorized student records as the primary information sources.
- Fetch public information from approved ESUI website pages only when the user asks for current/latest/website-specific information or when curated knowledge is insufficient, then clearly show the official source.
- Show source labels inside the chat so users can distinguish curated ESUI knowledge, live website snippets, and external references.
- Add an in-app knowledge-base library so approved ESUI staff can search, inspect, add, edit, delete, validate, persist, and reload curated school information before the chatbot uses it.
- Separate knowledge ownership so admins handle admissions, fees, portals, hostel guidance, calendars, and student affairs while lecturers handle only learning entries for assigned course codes.
- Add approval labels (`demo`, `draft`, `approved`, `needs_review`) and an audit log so school information changes can be traced before students rely on them.
- Add a human-in-the-loop knowledge-gap workflow so Eve records unknown questions and admin staff convert them into approved knowledge instead of allowing the AI to silently invent school policies.
- Mark unavailable school-policy examples as demo knowledge so the prototype remains useful without pretending that placeholder content is official.
- Use a ChatGPT-style response layer only after guardrails and RAG retrieval have selected safe context.
- Present Ask Eve as an assistant conversation with contextual memory and natural follow-ups, not as a rigid messaging bot.
- Let students attach learning material directly in Ask Eve so the assistant can summarize, explain, quiz from, or plan around uploaded notes and images.
- Add student-success nudges inspired by Georgia State's Pounce.
- Add departmental knowledge ownership inspired by University of Houston's Shasta.
- Add custom dataset readiness inspired by University of Michigan's Maizey.
- Add privacy and enterprise governance language inspired by ASU's ChatGPT Edu deployment.
- Design for future LMS, admissions, finance, and student-record integrations.
- Keep the student module centered on personalized learning and measurable academic progress.
- Keep student-submitted practice work and learning notes scoped to that student's dashboard unless a reviewed staff workflow deliberately promotes a fact into the official knowledge base.
- Use saved learning history to help lecturers identify course-level intervention needs.

## Current Prototype Limits

- Uses sample data, not real ESUI student records.
- Uses deterministic local RAG responses when no OpenAI API key is configured.
- OpenAI response generation works only when `OPENAI_API_KEY` is configured on the backend.
- Learning progress scores are calculated from sample academic records for demonstration.
- Learning sessions are persisted locally with SQLite for prototype progress tracking.
- Demonstrates role isolation for students, lecturers, and admins but does not yet connect to a real identity provider.
- Demonstrates approval and audit tracking locally; production deployment should move the audit log to tamper-resistant managed storage.
- Uses curated prototype knowledge, clearly labelled demo knowledge, and supplementary official website content; full production deployment needs approved data owners in admissions, departments, registry, finance, ICT, student affairs, hostel administration, library, clinic, and academic planning.

## Future Work

- Connect to ESUI AIS authentication.
- Integrate with Canvas LMS course materials.
- Use a vector database such as Qdrant, pgvector, or Chroma.
- Add an LLM provider adapter with model fallback.
- Migrate local SQLite progress storage to a managed production database.
- Add production approval workflow with real staff authentication, content-review status, and audit logs.
- Add feedback collection and analytics.
- Add human handoff for admissions, finance, and academic advising offices.
