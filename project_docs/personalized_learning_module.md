# Personalized Learning and Academic Progress Tracking Module

This module is the core of the recorded project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**.

## Purpose

The module converts student academic data into personalized learning guidance. Instead of only answering questions, Eve now evaluates course performance, identifies weak topics, recommends the next learning session, and presents a weekly study plan.

## Inputs

- Student profile
- Department and level
- CGPA
- Registered courses
- Continuous assessment scores
- Risk level per course
- Topic gaps
- Timetable data
- Saved learning sessions
- Quiz answer scores and feedback history

## Processing Logic

1. Retrieve the logged-in student's academic record.
2. Calculate a progress score per course using CA score, risk level, and topic gaps.
3. Rank courses from weakest to strongest.
4. Select the priority course for immediate intervention.
5. Generate weekly learning tasks with suggested study duration.
6. Produce academic milestones for progress tracking.
7. Send learning-session prompts to Eve for guided explanations, practice, and revision.
8. Open a structured learning session where the student answers quiz questions and receives scores.
9. Persist session and answer data in SQLite.
10. Blend saved quiz performance with calculated academic indicators for the student dashboard.

## Outputs

- Overall learning progress percentage
- Learning status
- Weak-topic count
- Priority course
- Course progress bars
- Recommended next learning session
- Weekly study plan
- Progress milestones
- Learning session quiz scores
- Feedback history
- Recent saved sessions
- Course-level session count and average score
- Completed-session count

## Endpoint

```text
GET /api/student/{user_id}/learning-profile
GET /api/student/{user_id}/progress-history
```

## Example

For `stu-csc-001`, Eve identifies `MTH 211` as the priority course and recommends focused support around eigenvalues and matrix inverse topics.

## Defense Value

This module makes the project more than a chatbot. It demonstrates personalized learning and academic progress tracking using structured student data, saved learning history, AI-guided recommendations, quiz scoring, and role-based privacy protection.

Learning Session Mode is the active teaching layer, where Eve teaches, quizzes, scores, stores results, and turns those results into progress evidence.
