# Defense PowerPoint Content

Project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**

Use this content with `UNDERGRADUATE POWERPOINT TEMPLATE (2).pptx`. It follows the 21-slide structure extracted from the school template.

## Slide 1: Title

**Design and implementation of an ai system for personalized learning and academic progress tracking**

Presented by:

- Name of Student
- Matriculation Number
- Department of Computer Science
- Faculty of Science
- Edo State University Iyamho
- Supervisor: __________________

## Slide 2: Background of the Study

- Universities increasingly use digital platforms for learning, advising, and student support.
- Students need personalized help with weak topics, study planning, mock tests, and academic progress.
- Lecturers need timely insights into course performance and weak-topic trends.
- Generic AI tools are not designed around ESUI data, privacy, or role-based access.
- Eve was developed as an AI academic companion for Edo State University Iyamho.

## Slide 3: Statement of the Problem

- Academic support information is spread across websites, portals, offices, and course materials.
- Students may know their scores but may not receive continuous personalized improvement guidance.
- Lecturers may not have fast access to learning-session evidence for intervention planning.
- Generic AI chatbots can hallucinate, expose private data, or ignore institutional rules.
- There is a need for a role-aware AI system for personalized learning and academic progress tracking.

## Slide 4: Aim and Objectives

Aim:

- To design and implement an ai system for personalized learning and academic progress tracking.

Objectives:

- Design a responsive AI academic-support interface.
- Implement personalized student learning progress tracking.
- Identify weak topics and recommend learning sessions.
- Implement guided learning sessions with quiz scoring and feedback.
- Store learning history using SQLite.
- Provide lecturer assigned-course analytics.
- Add RAG, role-based access, and prompt-injection guardrails.

## Slide 5: Significance of the Study

- Students receive personalized academic guidance and weak-topic support.
- Lecturers receive course-level insights for teaching intervention.
- Prospective candidates receive admission-readiness and public guidance.
- The university gains a prototype for a future institutional AI platform.
- The system improves academic support while enforcing privacy and cybersecurity controls.

## Slide 6: Literature Review

- RAG improves factual grounding by combining retrieval with generation.
- LLMs can support explanation, summarization, and tutoring when properly constrained.
- AI risk frameworks emphasize governance, privacy, safety, and accountability.
- Universities such as ASU, University of Michigan, Georgia State, and University of Houston show growing institutional AI adoption.
- The identified gap is the need for an ESUI-focused AI system with personalized learning and academic progress tracking.

## Slide 7: Analysis of the Existing System

- Students currently rely on separate sources for guidance.
- Public information, course materials, academic records, and lecturer feedback are not unified.
- Existing support may not provide continuous personalized learning recommendations.
- Lecturers may not easily connect student practice activity to teaching intervention.
- Existing generic AI tools lack ESUI-specific governance and privacy controls.

## Slide 8: Architecture of the Existing System

Existing flow:

- Student or candidate asks office, website, lecturer, or peers.
- Information is manually searched or requested.
- Progress tracking depends on isolated scores and manual interpretation.
- Lecturer intervention depends on delayed or fragmented data.

Weaknesses:

- slow feedback;
- scattered data;
- limited personalization;
- privacy risk if informal channels are used.

## Slide 9: Analysis of the Proposed System

Proposed system: Eve.

- Guest mode for public and admission guidance.
- Student mode for personalized learning and progress tracking.
- Lecturer mode for assigned-course analytics.
- RAG for verified ESUI knowledge.
- Guardrails for prompt injection and private-data protection.
- SQLite persistence for learning-session history.
- Optional OpenAI mode for natural ChatGPT-style responses.

## Slide 10: Design Methodology

- Design and implementation research approach.
- Iterative prototyping model.
- Requirement analysis from project description and ESUI context.
- Backend implemented with Python FastAPI.
- Client implemented with Flutter.
- Testing through API checks, Flutter analysis, widget tests, and security scenarios.

## Slide 11: Architecture of the Proposed System

Main architecture:

- Flutter Web/Mobile Client
- FastAPI Backend
- Guardrail Layer
- Role-Based Access Layer
- RAG Retrieval Layer
- Academic Services
- SQLite Progress Database
- Optional OpenAI Responses API

Suggested diagram:

```text
User -> Flutter Client -> FastAPI Backend
                 -> Guardrails -> Role Access
                 -> RAG -> ESUI Knowledge Base
                 -> Academic Services -> SQLite
                 -> Optional OpenAI API
```

## Slide 12: System Requirements

Hardware:

- Laptop or desktop computer.
- Internet connection for OpenAI mode.

Software:

- Windows OS.
- Flutter SDK.
- Python and FastAPI.
- Uvicorn server.
- SQLite database.
- Browser for web demonstration.
- Optional OpenAI API key.

## Slide 13: Diagrams of the System

Recommended diagrams for defense:

- Use Case Diagram.
- Data Flow Diagram.
- Entity Relationship Diagram.
- Learning Session Sequence Diagram.

Key entities:

- `learning_sessions`
- `learning_answers`

Key actors:

- Guest
- Student
- Lecturer

## Slide 14: Overview of Implementation

Implemented modules:

- Entry and role selection screen.
- AI chat interface.
- Admission readiness estimator.
- Student learning progress dashboard.
- Guided learning session mode.
- SQLite progress history.
- Lecturer teaching workbench.
- Prompt-injection guardrails.
- OpenAI response generation with local fallback.

## Slide 15: Implementation Procedures

1. Created curated ESUI knowledge and sample academic records.
2. Built FastAPI backend routes.
3. Implemented role-based access and security checks.
4. Implemented RAG retrieval and OpenAI response layer.
5. Built Flutter responsive interface.
6. Added learning profile computation.
7. Added guided learning sessions and answer scoring.
8. Added SQLite persistence.
9. Added lecturer saved-session analytics.
10. Tested backend, UI, and security behavior.

## Slide 16: Programming Language and Tools Used

- Flutter: responsive client and future Android deployment.
- Dart: Flutter application logic.
- Python: backend and AI orchestration.
- FastAPI: REST API server.
- SQLite: persistent progress tracking.
- JSON: prototype knowledge and academic records.
- OpenAI Responses API: optional natural language generation.
- PowerShell: local development and testing commands.

## Slide 17: System Interface / Screenshots

Screenshots to show:

- Entry screen.
- Student learning progress dashboard.
- Guided learning session screen.
- Feedback history and quiz score.
- Lecturer teaching workbench.
- Admission readiness estimator.
- Chat response with OpenAI mode.

## Slide 18: Discussion of Results / Evaluation

Evaluation results:

- Backend compile check passed.
- Flutter analysis passed with no issues.
- Flutter widget test passed.
- Backend health endpoint returned `ok`.
- Student learning profile endpoint returned personalized progress.
- Progress history endpoint returned saved SQLite history.
- Lecturer endpoint returned assigned-course trends.
- Chat handled casual and academic prompts naturally.
- Guardrails blocked unsafe requests.

## Slide 19: Conclusion and Recommendations

Conclusion:

- The project successfully implemented an AI system for personalized learning and academic progress tracking.
- Eve supports students, lecturers, and guests through role-based modules.
- The system demonstrates RAG, guardrails, guided learning, saved progress, and lecturer analytics.

Recommendations:

- Integrate with official ESUI student records.
- Connect to Canvas LMS and approved course materials.
- Use managed database storage in production.
- Add admin content-approval dashboard.
- Expand datasets across departments.

## Slide 20: Selected References

- Lewis et al. (2020), Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks.
- NIST (2023), Artificial Intelligence Risk Management Framework.
- ISO/IEC (2023), ISO/IEC 42001 AI Management System.
- Zhao et al. (2023), A Survey of Large Language Models.
- Gao et al. (2024), Retrieval-Augmented Generation for Large Language Models: A Survey.
- OWASP (2025), Top 10 for Large Language Model Applications.

## Slide 21: Thank You

Thank you.

Questions and contributions are welcome.
