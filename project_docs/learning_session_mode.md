# Learning Session Mode and Quiz Scoring

Learning Session Mode turns Eve from a dashboard assistant into an active personalized learning system.

## Purpose

The feature allows a student to start a guided session from a weak course or topic. Eve explains the concept, gives an example, asks practice questions, scores the student's answers, provides feedback, and recommends the next step.

## Flow

1. Student opens the Learning Progress screen.
2. Student selects `Start session` on a priority course or weekly learning task.
3. Backend creates a session with:
   - course code
   - course title
   - weak topic
   - explanation
   - worked example
   - quiz questions
4. Student submits answers.
5. Backend scores answers using expected concepts and keywords.
6. Backend stores the session and answer records in SQLite.
7. Eve returns feedback, ideal answer direction, average score, and completion summary.

## Endpoints

```text
POST /api/learning-sessions
GET /api/learning-sessions/{session_id}
POST /api/learning-sessions/{session_id}/answer
GET /api/student/{user_id}/progress-history
```

## Progress Tracking Value

The module records:

- questions attempted
- student answers
- score per answer
- feedback per answer
- average session score
- recommended next step
- progress delta
- saved session history
- course-level session averages

## Current Prototype Scope

The prototype now persists learning sessions in a local SQLite database at runtime. This is suitable for defense demonstration because progress survives backend restarts without requiring an external database server.

A production version should migrate this persistence layer to a managed database, connect it to the university's approved student-record system, and enforce institutional backup, retention, and access policies.
