# CHAPTER TWO

# LITERATURE REVIEW

## 2.1 Introduction to the Chapter

This chapter reviews literature related to the project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**. The review covers the major concepts, theoretical framework, empirical related works, existing systems, comparative analysis, research gap, relevant algorithms, standards, and datasets.

The chapter focuses on artificial intelligence in education, personalized learning, academic progress tracking, Retrieval-Augmented Generation, large language models, cybersecurity guardrails, and institutional AI adoption in universities.

## 2.2 Conceptual Review

### 2.2.1 Artificial Intelligence in Education

Artificial intelligence in education refers to the use of intelligent computer systems to support teaching, learning, assessment, administration, and student services. AI systems can assist students by explaining difficult topics, generating practice questions, recommending learning resources, and providing feedback. For lecturers, AI can support course analytics, weak-topic detection, assessment preparation, and teaching intervention.

In this project, AI is used to provide academic guidance through Eve, an academic companion for Edo State University Iyamho. Eve supports students, prospective candidates, and lecturers through role-specific functions.

### 2.2.2 Personalized Learning

Personalized learning is an approach in which learning support is adapted to the needs, weaknesses, goals, and progress of each student. Instead of giving every student the same guidance, a personalized system considers the student's course records, weak topics, timetable, risk level, and learning history.

For this project, personalization is achieved by analyzing student continuous assessment scores, risk levels, weak topics, saved quiz scores, and completed learning sessions. The system then recommends priority courses, study plans, and guided learning sessions.

### 2.2.3 Academic Progress Tracking

Academic progress tracking involves monitoring student learning performance over time. It may include scores, CGPA, weak topics, completed tasks, quiz attempts, feedback history, and intervention records. Academic progress tracking helps students know where they stand and helps lecturers identify where support is needed.

In Eve, academic progress is tracked using course records and saved learning-session history. The SQLite database stores learning sessions, student answers, scores, feedback, and completion status.

### 2.2.4 Large Language Models

Large language models are AI models trained on large text datasets to understand and generate natural language. They can support explanation, summarization, question answering, and tutoring. However, LLMs may hallucinate or produce unsafe responses if not constrained. Zhao et al. (2023) explain that LLMs have strong language capabilities but require careful alignment, safety controls, and domain grounding.

In this project, OpenAI response generation is optional. The system uses local fallback logic when no API key is configured. This ensures that Eve remains functional even without external AI access.

### 2.2.5 Retrieval-Augmented Generation

Retrieval-Augmented Generation combines information retrieval with language generation. Instead of relying only on model memory, the system retrieves relevant documents and uses them to ground the response. Lewis et al. (2020) introduced RAG as a method for improving knowledge-intensive natural language processing tasks. Gao et al. (2024) further reviewed RAG as a major approach for improving LLM factuality and domain relevance.

Eve uses a curated ESUI knowledge base for retrieval. This helps prevent unsupported answers about university policies, admissions, learning resources, and institutional information.

### 2.2.6 Cybersecurity Guardrails

Cybersecurity guardrails are rules and checks that protect an AI system from unsafe use. In LLM applications, prompt injection is a major threat. It occurs when a user tries to override system instructions, reveal hidden prompts, bypass authentication, or extract private data. OWASP (2025) identifies prompt injection and sensitive-information disclosure as major LLM application risks.

Eve implements a guardrail layer that checks requests before retrieval and answer generation. Suspicious or unauthorized requests are blocked.

### 2.2.7 Role-Based Access Control

Role-based access control restricts user access according to assigned roles. In Eve, the main roles are guest, student, and lecturer. Guests can access public guidance only. Students can access their own academic and fee-related sample records. Lecturers can access analytics only for assigned courses.

This design helps protect private academic data and supports institutional governance.

## 2.3 Theoretical Framework

The theoretical foundation of this project is based on constructivist learning theory, adaptive learning theory, and information retrieval theory.

### 2.3.1 Constructivist Learning Theory

Constructivism suggests that students learn better when they actively build understanding through explanation, practice, and feedback. Eve supports this by explaining topics, asking questions, scoring student answers, and providing feedback.

### 2.3.2 Adaptive Learning Theory

Adaptive learning systems adjust content and recommendations based on learner performance. Eve applies this concept by identifying weak topics, selecting priority courses, recommending study plans, and using saved quiz performance to update progress indicators.

### 2.3.3 Information Retrieval Theory

Information retrieval theory focuses on finding relevant information from a document collection. Eve uses retrieval principles to search curated ESUI knowledge and return relevant context for AI responses.

### 2.3.4 AI Risk Management

The NIST AI Risk Management Framework (2023) emphasizes governance, mapping, measuring, and managing AI risks. This supports Eve's use of role-based access, audit labels, source grounding, and guardrails.

## 2.4 Empirical Review of Related Works

### 2.4.1 Retrieval-Augmented Generation

Lewis et al. (2020) proposed Retrieval-Augmented Generation for knowledge-intensive NLP tasks. Their work showed that retrieval can improve generated responses by grounding them in external documents. This is relevant to Eve because university information changes and should be grounded in approved sources.

### 2.4.2 Survey of Large Language Models

Zhao et al. (2023) reviewed large language models and discussed their capabilities, limitations, and applications. The study supports the use of LLMs for natural language interaction while also highlighting the need for safety and domain adaptation.

### 2.4.3 RAG for Large Language Models

Gao et al. (2024) reviewed RAG systems and explained how retrieval can improve factuality, trustworthiness, and domain-specific performance. Eve adopts this approach by retrieving from a curated ESUI knowledge base before generating responses.

### 2.4.4 AI Risk Management Framework

The National Institute of Standards and Technology (2023) published the AI Risk Management Framework. The framework emphasizes trustworthy AI through governance, risk mapping, measurement, and management. Eve reflects this by including privacy controls, security checks, role-based access, and audit information.

### 2.4.5 OWASP LLM Application Risks

OWASP Foundation (2025) identified common risks in LLM applications, including prompt injection, sensitive-information disclosure, insecure output handling, and excessive agency. Eve addresses these risks through prompt-injection detection, private-record restrictions, and source-limited responses.

## 2.5 Review of Existing Systems/Tools

### 2.5.1 Arizona State University AI Systems

Arizona State University provides ChatGPT Edu and institutional AI services. The ASU example shows that universities are adopting AI tools with governance and privacy considerations. The lesson for Eve is that an institutional AI system should have approved data sources, secure access, and clear boundaries.

### 2.5.2 University of Michigan AI Services

The University of Michigan provides AI services such as U-M GPT, Maizey, and mobile AI support. Maizey allows custom datasets, which is relevant to Eve's RAG approach. The lesson is that a university AI system should support controlled datasets, feedback, accessibility, and future data integration.

### 2.5.3 Georgia State University Pounce

Georgia State University has used Pounce-related chatbot systems for student success support. A 2022 report linked course-related chatbot support with improved student performance. The lesson for Eve is that AI can support academic outcomes when it provides targeted nudges, reminders, and learning guidance.

### 2.5.4 University of Houston Shasta

The University of Houston's Shasta chatbot provides departmental website-based assistance. It shows the value of departmental content ownership and service oversight. Eve can adopt this concept by allowing future ESUI departments to manage approved knowledge content.

### 2.5.5 University of Alaska Fairbanks Ocelot Chatbot

The University of Alaska Fairbanks launched an Ocelot chatbot with preloaded office information, generative search over university pages, and planned integration with student systems. This supports Eve's phased roadmap from public information support to deeper student-record integration.

## 2.6 Comparative Analysis of Related Works

| System / Study | Main Focus | Strength | Limitation / Gap | Relevance to Eve |
| --- | --- | --- | --- | --- |
| Lewis et al. (2020) RAG | Retrieval plus generation | Improves factual grounding | Not university-specific | Supports Eve's RAG design |
| Zhao et al. (2023) LLM survey | LLM capabilities and limitations | Broad AI language review | Does not implement ESUI system | Supports OpenAI response layer |
| Gao et al. (2024) RAG survey | RAG architecture and applications | Explains modern RAG patterns | Not focused on academic progress tracking | Supports retrieval design |
| NIST AI RMF (2023) | AI governance and risk | Strong risk-management framework | General framework, not a product | Supports guardrails and governance |
| OWASP LLM Top 10 (2025) | LLM security risks | Practical threat categories | Does not provide university app | Supports prompt-injection controls |
| ASU AI systems | Institutional AI adoption | Governance and privacy focus | Not tailored to ESUI | Supports institutional AI model |
| University of Michigan AI services | Custom datasets and campus AI | Controlled university datasets | Not directly for ESUI students | Supports future dataset expansion |
| Georgia State Pounce | Student success chatbot | Evidence of academic support impact | Different institutional setting | Supports proactive learning support |
| University of Houston Shasta | Departmental chatbot | Departmental content ownership | Mainly service Q&A | Supports departmental knowledge governance |
| UAF Ocelot | Campus support chatbot | Preloaded knowledge and future integration | Not focused on personalized learning | Supports phased deployment roadmap |

## 2.7 Identified Research Gap

The reviewed systems show that AI assistants are increasingly used in universities. However, many systems focus mainly on general information, chatbot support, or institutional AI access. The identified gap is the need for a system that combines:

- ESUI-focused public knowledge;
- personalized student learning support;
- academic progress tracking;
- guided learning sessions;
- saved quiz scores and feedback history;
- lecturer assigned-course analytics;
- RAG grounding;
- prompt-injection guardrails;
- role-based privacy protection.

This project addresses the gap by designing and implementing Eve as a role-aware AI system for personalized learning and academic progress tracking.

## 2.8 Summary of the Chapter

This chapter reviewed the main concepts and related works relevant to the project. It discussed AI in education, personalized learning, academic progress tracking, LLMs, RAG, cybersecurity guardrails, role-based access, and university AI systems. The review showed that existing AI systems provide useful lessons but do not fully address the ESUI-specific need for personalized learning and progress tracking with role-aware privacy controls.

## 2.9 Review of Relevant Algorithms

### 2.9.1 Retrieval Algorithm

The retrieval algorithm searches the curated ESUI knowledge base and returns relevant documents based on the user's message and role. It filters documents by audience before scoring them.

### 2.9.2 Intent Detection Algorithm

Intent detection classifies messages into categories such as admission, exam practice, student success, fees, planning, lecturer analytics, and knowledge. This allows the backend to route requests correctly.

### 2.9.3 Learning Progress Algorithm

The learning progress algorithm calculates course progress using continuous assessment score, risk level, topic gaps, and saved session performance. It then identifies the priority course and recommends study actions.

### 2.9.4 Quiz Scoring Algorithm

The quiz scoring algorithm compares student answers with expected keywords and ideal answer direction. It returns a score, feedback, and next step.

### 2.9.5 Guardrail Algorithm

The guardrail algorithm checks whether a prompt attempts to bypass rules, reveal private records, expose hidden instructions, or access unauthorized data.

## 2.10 Review of Relevant Standards/Protocols

### 2.10.1 NIST AI Risk Management Framework

The NIST AI RMF provides guidance for trustworthy AI risk management. It supports the design of Eve's governance, transparency, and privacy controls.

### 2.10.2 ISO/IEC 42001:2023

ISO/IEC 42001:2023 provides requirements for an AI management system. It is relevant to future institutional deployment because it emphasizes governance, monitoring, accountability, and continuous improvement.

### 2.10.3 OWASP Top 10 for LLM Applications

OWASP provides security guidance for LLM applications. Eve applies this by blocking prompt injection and restricting private-data access.

### 2.10.4 REST API Communication

Eve uses REST API endpoints between the Flutter client and FastAPI backend. REST allows the client to request chat responses, learning profiles, learning sessions, progress history, admissions estimates, and lecturer insights.

## 2.11 Review of Relevant Datasets

The prototype uses curated and sample datasets rather than live institutional records.

| Dataset | Purpose |
| --- | --- |
| ESUI knowledge base | Stores curated public and role-aware university knowledge. |
| Sample student records | Demonstrates student academic progress tracking. |
| Sample lecturer records | Demonstrates assigned-course analytics. |
| Sample course analytics | Demonstrates lecturer performance insights. |
| SQLite learning-session history | Stores runtime quiz attempts, scores, feedback, and progress history. |

In production, these datasets should be replaced or extended with approved ESUI systems such as student information systems, LMS materials, admissions data, and lecturer-approved course content.
