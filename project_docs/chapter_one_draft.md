# CHAPTER ONE

# INTRODUCTION

## 1.1 Background to the Study

Universities increasingly rely on digital platforms to support teaching, learning, administration, academic advising, and student success. Edo State University Iyamho already provides digital services such as online admissions information, student-facing web resources, and Canvas LMS-supported learning. However, students still need a more unified, intelligent, and always-available system that can support personalized learning, monitor academic progress, identify weak areas, and provide guidance based on their academic needs.

Artificial intelligence systems can support personalized learning by explaining topics, generating practice questions, recommending study plans, and tracking academic performance indicators such as course scores, weak topics, fee status, and timetable commitments. When supported by Retrieval-Augmented Generation, role-based access control, and cybersecurity guardrails, such a system can provide useful academic support while protecting private student records.

This project proposes Eve, an AI system for personalized learning and academic progress tracking at Edo State University Iyamho. Eve is designed to support student academic guidance, weak-topic identification, mock assessment generation, progress monitoring, timetable planning, and lecturer course-progress analytics. The system also includes prompt-injection detection, privacy enforcement, and audit labels to reduce the risk of unauthorized data disclosure.

## 1.2 Statement of the Problem

Current students need academic guidance, timetable planning, course explanations, practice questions, fee-status guidance, and support based on their academic records. Lecturers also need insight into student performance for their assigned courses so they can identify weak topics and improve teaching strategies. In many institutions, this information is spread across websites, portals, offices, course materials, and informal communication channels.

Generic AI chatbots can answer questions, but they may hallucinate, expose private data if poorly designed, or fail to follow institutional policies. Therefore, Edo State University needs a role-aware AI system that supports personalized learning and academic progress tracking while retrieving from verified school knowledge, limiting users to authorized data, and blocking prompt-injection attempts.

## 1.3 Aim of the Study

The aim of this study is to design and implement an ai system for personalized learning and academic progress tracking.

## 1.4 Objectives of the Study

- To design a responsive AI system interface for personalized learning and academic progress tracking.
- To implement personalized academic support for students using course records, weak-topic analysis, and timetable data.
- To implement academic progress tracking using CGPA, course scores, risk levels, and study recommendations.
- To generate personalized learning plans, priority-course recommendations, and academic progress milestones.
- To implement a Retrieval-Augmented Generation workflow using curated ESUI knowledge.
- To implement role-based access control for public, student, and lecturer information.
- To add guardrails against prompt injection and unauthorized private-record access.
- To provide student academic advising, mock assessment generation, and fee guidance.
- To provide lecturer analytics for assigned courses.
- To include admission readiness guidance as an additional public-support feature.
- To evaluate the system using representative user scenarios and security tests.

## 1.5 Research Questions

The study is guided by the following research questions:

- How can an AI system be designed to support personalized learning and academic progress tracking for students?
- How can student weak topics and learning progress be identified and presented in a useful way?
- How can lecturers receive assigned-course analytics without exposing unauthorized student information?
- How can RAG and role-based access control reduce unsupported answers and privacy risks?
- How can the system remain useful for demonstration while using sample academic records instead of live university data?

## 1.6 Research Hypotheses

This project is a design and implementation study; therefore, formal statistical hypotheses are not required. The work is evaluated through system functionality, user scenarios, API tests, interface review, and security behavior checks rather than hypothesis testing.

## 1.7 Significance of the Study

The project is significant to students, lecturers, prospective candidates, and the university administration. Students can receive personalized academic support, practice assistance, weak-topic guidance, and progress tracking. Lecturers can access course-specific analytics for teaching improvement. Candidates can receive faster admission guidance as a supporting feature. The university can use the system as a foundation for a future institutional AI platform that improves academic support while protecting privacy.

## 1.8 Scope of the Study

The scope covers a prototype AI system for personalized learning and academic progress tracking at Edo State University Iyamho with guest, student, and lecturer modes. The prototype uses curated public ESUI knowledge and sample academic records. It demonstrates personalized student advising, weak-topic identification, saved learning-session progress, quiz scoring, mock assessment generation, lecturer analytics, admission guidance, RAG retrieval, prompt-injection blocking, and responsive Flutter-based user interaction.

## 1.9 Limitations of the Study

The prototype does not connect to live ESUI student databases, payment systems, or Canvas LMS. It uses sample data for demonstration, local SQLite storage for learning-session history, and optional OpenAI response generation when an API key is configured. In production, official data access approval, identity integration, server infrastructure, managed database deployment, and continuous content review would be required.

## 1.10 Definition of Terms

Artificial Intelligence: The use of computer systems to perform tasks that normally require human intelligence, such as answering questions, generating explanations, and recommending study plans.

Personalized Learning: A learning approach where academic support is adapted to the needs, weaknesses, and progress of each student.

Academic Progress Tracking: The monitoring of student learning performance using indicators such as course scores, weak topics, quiz results, completed sessions, and feedback history.

Retrieval-Augmented Generation: An AI approach where relevant information is retrieved from a knowledge base before an answer is generated.

Role-Based Access Control: A security method that limits what a user can see or do based on their role, such as guest, student, lecturer, or administrator.

Prompt Injection: An attempt to manipulate an AI system into ignoring its rules, revealing hidden instructions, or exposing private data.

## 1.11 Organisation of the Report

Chapter One introduces the study, problem statement, aim, objectives, significance, scope, limitations, and key terms. Chapter Two reviews related literature, existing AI systems, standards, algorithms, and datasets. Chapter Three presents the system analysis and design. Chapter Four describes implementation, screenshots, tests, and evaluation results. Chapter Five presents the summary, conclusion, recommendations, future work, and AI-use disclosure.
