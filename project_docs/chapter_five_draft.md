# CHAPTER FIVE

# SUMMARY, CONCLUSION AND RECOMMENDATIONS

## 5.1 Introduction to the Chapter

This chapter presents the summary, conclusion, recommendations, limitations, future work, and AI-use disclosure for the project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**.

The chapter reviews what was achieved in the study and explains how the implemented system addresses the identified problem.

## 5.2 Summary of the Study

The study focused on the design and implementation of an AI system that supports personalized learning and academic progress tracking for Edo State University Iyamho. The system, named Eve, was developed as a role-aware academic companion for prospective candidates, current students, and lecturers.

The project began with the problem that academic guidance, course support, admission information, and progress tracking are often spread across different sources. Students may need support with weak topics, study planning, mock tests, and academic improvement, while lecturers may need course-level insights for teaching intervention. Generic AI chatbots are not sufficient because they may lack institutional grounding, privacy controls, and role-based access.

To address the problem, Eve was built with a Flutter frontend and a Python FastAPI backend. The backend includes RAG retrieval, prompt-injection guardrails, role-based access control, student learning-profile computation, guided learning sessions, quiz scoring, SQLite progress persistence, lecturer assigned-course analytics, admission readiness estimation, and optional OpenAI response generation.

The implemented system demonstrates that AI can be used as an institutional academic-support layer when combined with verified knowledge, structured academic data, saved progress history, and privacy-aware controls.

## 5.3 Achievement of Objectives

The project objectives were achieved as follows:

| Objective | Achievement |
| --- | --- |
| Design a responsive AI system interface | A Flutter web/mobile interface was implemented with guest, student, lecturer, chat, tools, admission, and profile screens. |
| Implement personalized academic support for students | The student module analyzes course records, weak topics, risk levels, timetable data, and saved quiz performance. |
| Implement academic progress tracking | Eve tracks overall progress, priority course, weak topics, completed learning sessions, quiz scores, and feedback history. |
| Generate personalized learning plans | The system recommends weekly learning tasks, priority-course sessions, and study milestones. |
| Implement RAG with ESUI knowledge | The backend retrieves from a curated ESUI knowledge base and grounds public responses in approved context. |
| Implement role-based access control | Guests, students, and lecturers receive different authorized data access. |
| Add cybersecurity guardrails | Prompt injection, private-record extraction, and unauthorized requests are blocked. |
| Provide student academic advising and mock assessment support | Eve supports course explanations, mock questions, guided sessions, scoring, and feedback. |
| Provide lecturer analytics | Lecturers can view assigned-course analytics and saved learning-session trends. |
| Include admission readiness guidance | The guest module includes a readiness estimator based on JAMB and O-Level details. |
| Evaluate the system | Backend, Flutter, API, learning-session, lecturer, and security tests were performed. |

## 5.4 Contributions to Knowledge/Practice

This project contributes to academic practice in the following ways:

- It demonstrates how AI can be used for personalized learning and academic progress tracking in a university context.
- It shows how RAG can reduce hallucination by grounding answers in curated institutional knowledge.
- It demonstrates the importance of role-based access control in academic AI systems.
- It provides a model for saving learning-session history and using it as progress evidence.
- It extends academic support beyond students by giving lecturers course-level learning trends.
- It shows how prompt-injection guardrails can be included in an educational AI prototype.
- It provides a practical foundation for a future ESUI institutional AI platform.

## 5.5 Conclusion

The project successfully achieved its aim of designing and implementing an AI system for personalized learning and academic progress tracking. Eve provides a working prototype that supports guests, students, and lecturers through role-based AI assistance.

The student module identifies weak topics, recommends study tasks, starts guided learning sessions, scores answers, provides feedback, and saves progress history. The lecturer module provides assigned-course analytics and uses saved learning-session data to suggest teaching interventions. The guest module supports admissions guidance and public inquiries. The system also includes RAG, OpenAI response generation, local fallback logic, prompt-injection guardrails, and SQLite persistence.

The results show that Eve is more than a general chatbot. It is a structured academic-support system that combines AI conversation, institutional knowledge, academic records, learning analytics, and security controls.

## 5.6 Limitations of the Study

The study has the following limitations:

- The prototype uses sample student and lecturer records, not live ESUI records.
- The ESUI knowledge base is curated for demonstration and does not yet include all departments.
- The SQLite database is suitable for local demonstration but should be replaced with managed production storage.
- The system does not yet connect to Canvas LMS, official payment systems, or student information systems.
- The guided quiz scoring uses keyword-based logic and should be improved with richer assessment methods in production.
- OpenAI response quality depends on API availability and configuration.
- The system has not yet been evaluated with a large group of real ESUI students and lecturers.

## 5.7 Recommendations

Based on the study, the following recommendations are made:

- Edo State University should consider a governed institutional AI assistant for academic support.
- Official data owners should review and approve knowledge content before production deployment.
- The system should be integrated with secure university authentication.
- Student records should only be accessed through approved APIs and role-based permissions.
- Lecturers should be given analytics only for assigned courses.
- Course materials should be added through lecturer-approved LMS integration.
- AI outputs should include source grounding, uncertainty handling, and audit logs.
- The system should be tested with real users before deployment.

## 5.8 Suggestions for Future Work

Future work may include:

- integration with ESUI student information systems;
- integration with Canvas LMS course materials;
- managed database deployment using PostgreSQL or another production database;
- vector database support using pgvector, Qdrant, or Chroma;
- lecturer content-upload and approval dashboard;
- push notifications for study reminders and academic nudges;
- richer quiz generation and grading using lecturer-approved marking schemes;
- mobile Android release through Google Play Store;
- real-time human handoff to admissions, finance, or academic advising units;
- institutional analytics dashboard for administrators;
- evaluation with real student and lecturer participants.

## 5.9 AI Use Disclosure

AI tools were used to support the planning, drafting, coding, debugging, and documentation of this project. The final project remains the student's responsibility. All AI-assisted content should be reviewed, edited, and verified by the student before submission. Sensitive information such as API keys, private student data, and institutional credentials should not be placed in public documents or shared chats.

The implemented system also uses optional AI response generation through an API key stored locally in a private `.env` file. The project does not hard-code or publicly expose the API key.
