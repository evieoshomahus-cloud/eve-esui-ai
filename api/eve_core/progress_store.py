from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
STORAGE_DIR = ROOT / "storage"
DB_PATH = STORAGE_DIR / "eve_progress.db"


def _now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _connect() -> sqlite3.Connection:
    STORAGE_DIR.mkdir(exist_ok=True)
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def init_db() -> None:
    with _connect() as connection:
        connection.executescript(
            """
            CREATE TABLE IF NOT EXISTS learning_sessions (
                session_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                course_code TEXT NOT NULL,
                course_title TEXT NOT NULL,
                topic TEXT NOT NULL,
                explanation TEXT NOT NULL,
                example TEXT NOT NULL,
                questions_json TEXT NOT NULL,
                current_question_index INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                completed_at TEXT,
                summary_json TEXT
            );

            CREATE TABLE IF NOT EXISTS learning_answers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL REFERENCES learning_sessions(session_id) ON DELETE CASCADE,
                question_index INTEGER NOT NULL,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                score INTEGER NOT NULL,
                feedback TEXT NOT NULL,
                ideal_answer TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_learning_sessions_user
                ON learning_sessions(user_id, updated_at DESC);

            CREATE INDEX IF NOT EXISTS idx_learning_sessions_course
                ON learning_sessions(user_id, course_code, updated_at DESC);

            CREATE INDEX IF NOT EXISTS idx_learning_answers_session
                ON learning_answers(session_id, question_index);
            """
        )


def save_session(session: dict[str, Any]) -> None:
    init_db()
    timestamp = _now()
    with _connect() as connection:
        connection.execute(
            """
            INSERT OR REPLACE INTO learning_sessions (
                session_id,
                user_id,
                course_code,
                course_title,
                topic,
                explanation,
                example,
                questions_json,
                current_question_index,
                created_at,
                updated_at,
                completed_at,
                summary_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                session["session_id"],
                session["user_id"],
                session["course_code"],
                session["course_title"],
                session["topic"],
                session["explanation"],
                session["example"],
                json.dumps(session["questions"]),
                session["current_question_index"],
                session.get("created_at", timestamp),
                timestamp,
                session.get("completed_at"),
                json.dumps(session["summary"]) if session.get("summary") else None,
            ),
        )


def add_answer(session_id: str, question_index: int, answer_item: dict[str, Any]) -> None:
    init_db()
    with _connect() as connection:
        connection.execute(
            """
            INSERT INTO learning_answers (
                session_id,
                question_index,
                question,
                answer,
                score,
                feedback,
                ideal_answer,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                session_id,
                question_index,
                answer_item["question"],
                answer_item["answer"],
                int(answer_item["score"]),
                answer_item["feedback"],
                answer_item["ideal_answer"],
                _now(),
            ),
        )


def update_session(session: dict[str, Any]) -> None:
    init_db()
    completed = session["current_question_index"] >= len(session["questions"])
    completed_at = session.get("completed_at")
    if completed and not completed_at:
        completed_at = _now()
        session["completed_at"] = completed_at
    with _connect() as connection:
        connection.execute(
            """
            UPDATE learning_sessions
            SET current_question_index = ?,
                updated_at = ?,
                completed_at = ?,
                summary_json = ?
            WHERE session_id = ?
            """,
            (
                session["current_question_index"],
                _now(),
                completed_at,
                json.dumps(session["summary"]) if session.get("summary") else None,
                session["session_id"],
            ),
        )


def load_session(session_id: str) -> dict[str, Any] | None:
    init_db()
    with _connect() as connection:
        session_row = connection.execute(
            "SELECT * FROM learning_sessions WHERE session_id = ?",
            (session_id,),
        ).fetchone()
        if not session_row:
            return None
        answer_rows = connection.execute(
            """
            SELECT question, answer, score, feedback, ideal_answer
            FROM learning_answers
            WHERE session_id = ?
            ORDER BY question_index ASC, id ASC
            """,
            (session_id,),
        ).fetchall()

    session = dict(session_row)
    return {
        "session_id": session["session_id"],
        "user_id": session["user_id"],
        "course_code": session["course_code"],
        "course_title": session["course_title"],
        "topic": session["topic"],
        "explanation": session["explanation"],
        "example": session["example"],
        "questions": json.loads(session["questions_json"]),
        "current_question_index": int(session["current_question_index"]),
        "history": [dict(row) for row in answer_rows],
        "summary": json.loads(session["summary_json"]) if session["summary_json"] else None,
        "created_at": session["created_at"],
        "updated_at": session["updated_at"],
        "completed_at": session["completed_at"],
    }


def _session_summaries(user_id: str, limit: int = 8) -> list[dict[str, Any]]:
    init_db()
    with _connect() as connection:
        rows = connection.execute(
            """
            SELECT
                s.session_id,
                s.user_id,
                s.course_code,
                s.course_title,
                s.topic,
                s.current_question_index,
                s.questions_json,
                s.created_at,
                s.updated_at,
                s.completed_at,
                COUNT(a.id) AS answered_count,
                COALESCE(ROUND(AVG(a.score)), 0) AS average_score
            FROM learning_sessions s
            LEFT JOIN learning_answers a ON a.session_id = s.session_id
            WHERE s.user_id = ?
            GROUP BY s.session_id
            ORDER BY s.updated_at DESC
            LIMIT ?
            """,
            (user_id, limit),
        ).fetchall()

    summaries: list[dict[str, Any]] = []
    for row in rows:
        questions = json.loads(row["questions_json"])
        total_questions = len(questions)
        current_index = int(row["current_question_index"])
        summaries.append(
            {
                "session_id": row["session_id"],
                "course_code": row["course_code"],
                "course_title": row["course_title"],
                "topic": row["topic"],
                "answered_count": int(row["answered_count"]),
                "total_questions": total_questions,
                "average_score": int(row["average_score"]),
                "completed": bool(row["completed_at"]) or current_index >= total_questions,
                "created_at": row["created_at"],
                "updated_at": row["updated_at"],
                "completed_at": row["completed_at"],
            }
        )
    return summaries


def student_progress_snapshot(user_id: str) -> dict[str, Any]:
    sessions = _session_summaries(user_id, limit=50)
    scored_sessions = [session for session in sessions if session["answered_count"] > 0]
    completed_sessions = [session for session in sessions if session["completed"]]
    average_score = round(mean(session["average_score"] for session in scored_sessions)) if scored_sessions else 0

    course_groups: dict[str, list[dict[str, Any]]] = {}
    for session in sessions:
        course_groups.setdefault(session["course_code"], []).append(session)

    course_history: list[dict[str, Any]] = []
    for course_code, items in course_groups.items():
        scored = [item for item in items if item["answered_count"] > 0]
        latest = items[0]
        course_history.append(
            {
                "course_code": course_code,
                "course_title": latest["course_title"],
                "session_count": len(items),
                "completed_count": sum(1 for item in items if item["completed"]),
                "average_score": round(mean(item["average_score"] for item in scored)) if scored else 0,
                "last_topic": latest["topic"],
                "last_score": latest["average_score"],
                "updated_at": latest["updated_at"],
            }
        )
    course_history.sort(key=lambda item: (item["average_score"], -item["session_count"]))

    topic_scores = [session for session in scored_sessions if session["completed"]]
    strongest = max(topic_scores, key=lambda item: item["average_score"], default=None)
    needs_revision = next(
        (session for session in scored_sessions if session["average_score"] < 60),
        None,
    )

    return {
        "total_sessions": len(sessions),
        "completed_sessions": len(completed_sessions),
        "average_session_score": average_score,
        "recent_sessions": sessions[:6],
        "course_history": course_history,
        "strongest_topic": strongest,
        "needs_revision": needs_revision,
        "database_path": str(DB_PATH),
    }


def student_progress_history(user_id: str) -> dict[str, Any]:
    return {
        "found": True,
        "user_id": user_id,
        "progress": student_progress_snapshot(user_id),
    }


def lecturer_course_learning_insights(course_codes: list[str]) -> dict[str, Any]:
    init_db()
    normalized_courses = [course.upper() for course in course_codes]
    if not normalized_courses:
        return {
            "total_sessions": 0,
            "completed_sessions": 0,
            "average_score": 0,
            "student_count": 0,
            "courses": [],
        }

    placeholders = ", ".join("?" for _ in normalized_courses)
    with _connect() as connection:
        rows = connection.execute(
            f"""
            SELECT
                s.session_id,
                s.user_id,
                s.course_code,
                s.course_title,
                s.topic,
                s.current_question_index,
                s.questions_json,
                s.updated_at,
                s.completed_at,
                COUNT(a.id) AS answered_count,
                COALESCE(ROUND(AVG(a.score)), 0) AS average_score
            FROM learning_sessions s
            LEFT JOIN learning_answers a ON a.session_id = s.session_id
            WHERE s.course_code IN ({placeholders})
            GROUP BY s.session_id
            ORDER BY s.updated_at DESC
            """,
            normalized_courses,
        ).fetchall()

    sessions: list[dict[str, Any]] = []
    for row in rows:
        questions = json.loads(row["questions_json"])
        total_questions = len(questions)
        current_index = int(row["current_question_index"])
        sessions.append(
            {
                "session_id": row["session_id"],
                "user_id": row["user_id"],
                "course_code": row["course_code"],
                "course_title": row["course_title"],
                "topic": row["topic"],
                "answered_count": int(row["answered_count"]),
                "total_questions": total_questions,
                "average_score": int(row["average_score"]),
                "completed": bool(row["completed_at"]) or current_index >= total_questions,
                "updated_at": row["updated_at"],
            }
        )

    course_summaries: list[dict[str, Any]] = []
    for course_code in normalized_courses:
        course_sessions = [session for session in sessions if session["course_code"] == course_code]
        scored = [session for session in course_sessions if session["answered_count"] > 0]
        completed = [session for session in course_sessions if session["completed"]]
        student_count = len({session["user_id"] for session in course_sessions})
        topic_groups: dict[str, list[dict[str, Any]]] = {}
        for session in scored:
            topic_groups.setdefault(session["topic"], []).append(session)

        topic_performance = []
        for topic, items in topic_groups.items():
            average_score = round(mean(item["average_score"] for item in items))
            topic_performance.append(
                {
                    "topic": topic,
                    "session_count": len(items),
                    "student_count": len({item["user_id"] for item in items}),
                    "average_score": average_score,
                    "completed_count": sum(1 for item in items if item["completed"]),
                }
            )
        topic_performance.sort(key=lambda item: item["average_score"])

        if not course_sessions:
            intervention = "No saved learning sessions yet. Ask students to complete a short diagnostic session before the next class."
        elif topic_performance and topic_performance[0]["average_score"] < 60:
            weakest = topic_performance[0]
            intervention = f"Reteach {weakest['topic']} with worked examples, then assign another Eve practice session."
        else:
            intervention = "Maintain practice momentum with timed questions and use Eve feedback to identify the next weak topic."

        title = course_sessions[0]["course_title"] if course_sessions else course_code
        course_summaries.append(
            {
                "course_code": course_code,
                "course_title": title,
                "total_sessions": len(course_sessions),
                "completed_sessions": len(completed),
                "student_count": student_count,
                "average_score": round(mean(item["average_score"] for item in scored)) if scored else 0,
                "topic_performance": topic_performance,
                "weakest_topic": topic_performance[0] if topic_performance else None,
                "recent_sessions": course_sessions[:4],
                "intervention": intervention,
            }
        )

    scored_sessions = [session for session in sessions if session["answered_count"] > 0]
    return {
        "total_sessions": len(sessions),
        "completed_sessions": sum(1 for session in sessions if session["completed"]),
        "average_score": round(mean(session["average_score"] for session in scored_sessions)) if scored_sessions else 0,
        "student_count": len({session["user_id"] for session in sessions}),
        "courses": course_summaries,
    }
