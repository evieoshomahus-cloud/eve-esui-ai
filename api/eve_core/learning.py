from __future__ import annotations

from statistics import mean
from typing import Any

from .progress_store import student_progress_snapshot
from .repository import student_profile


RISK_BONUS = {
    "low": 14,
    "medium": 4,
    "high": -6,
}


def _course_progress(ca_score: int, risk: str, gap_count: int) -> int:
    progress = ca_score + RISK_BONUS.get(risk, 0) - (gap_count * 2)
    return max(5, min(98, round(progress)))


def _status(progress: int) -> str:
    if progress < 50:
        return "Urgent support"
    if progress < 65:
        return "Needs reinforcement"
    if progress < 78:
        return "Developing"
    return "On track"


def _next_activity(course_code: str, gaps: list[str], risk: str) -> str:
    if gaps:
        topic = gaps[0]
        return f"Revise {topic}, then complete a 5-question practice drill for {course_code}."
    if risk == "low":
        return f"Attempt a timed past-question set for {course_code} to maintain momentum."
    return f"Review lecture notes and ask Eve for a short diagnostic quiz in {course_code}."


def _study_minutes(risk: str) -> int:
    if risk == "high":
        return 60
    if risk == "medium":
        return 45
    return 30


def learning_profile(user_id: str) -> dict[str, Any]:
    profile = student_profile(user_id)
    if not profile:
        return {"found": False, "message": "Student learning profile not found."}

    progress_snapshot = student_progress_snapshot(user_id)
    course_history = {
        item["course_code"]: item
        for item in progress_snapshot["course_history"]
    }
    courses: list[dict[str, Any]] = []
    for code, info in profile["courses"].items():
        gaps = list(info["topic_gaps"])
        progress = _course_progress(int(info["ca"]), info["risk"], len(gaps))
        history = course_history.get(code, {})
        courses.append(
            {
                "course_code": code,
                "title": info["title"],
                "ca": info["ca"],
                "risk": info["risk"],
                "topic_gaps": gaps,
                "progress": progress,
                "status": _status(progress),
                "study_minutes": _study_minutes(info["risk"]),
                "next_activity": _next_activity(code, gaps, info["risk"]),
                "suggested_prompt": f"Start a personalized learning session for {code}"
                + (f" on {gaps[0]}" if gaps else ""),
                "session_count": history.get("session_count", 0),
                "completed_sessions": history.get("completed_count", 0),
                "average_session_score": history.get("average_score", 0),
                "last_session_score": history.get("last_score", 0),
                "last_studied_topic": history.get("last_topic"),
            }
        )

    courses.sort(key=lambda item: (item["progress"], item["ca"]))
    base_progress = round(mean(course["progress"] for course in courses))
    overall_progress = base_progress
    if progress_snapshot["average_session_score"]:
        overall_progress = round((base_progress * 0.75) + (progress_snapshot["average_session_score"] * 0.25))
    priority_course = courses[0]
    weak_topics = [
        {"course_code": course["course_code"], "topic": topic}
        for course in courses
        for topic in course["topic_gaps"]
    ]

    weekly_plan = []
    for index, course in enumerate(courses[:4], start=1):
        topic_text = course["topic_gaps"][0] if course["topic_gaps"] else "past-question practice"
        weekly_plan.append(
            {
                "day": ["Monday", "Tuesday", "Wednesday", "Thursday"][index - 1],
                "course_code": course["course_code"],
                "focus": topic_text,
                "duration_minutes": course["study_minutes"],
                "task": course["next_activity"],
            }
        )

    milestones = [
        {
            "title": "Close urgent gaps",
            "target": f"Raise {priority_course['course_code']} progress above 65%",
            "status": "active",
        },
        {
            "title": "Practice consistency",
            "target": "Complete at least three Eve practice sessions this week",
            "status": "complete" if progress_snapshot["completed_sessions"] >= 3 else "pending",
        },
        {
            "title": "Exam readiness",
            "target": "Score 70% or higher in two mock tests",
            "status": "active" if progress_snapshot["average_session_score"] >= 70 else "pending",
        },
    ]

    recommendations = [
        f"Start with {priority_course['course_code']} because it has the lowest progress score.",
        "Use short learning sessions: explain the topic, answer practice questions, review mistakes, then repeat.",
        "Track improvement weekly by comparing weak-topic confidence and mock-test scores.",
    ]
    if progress_snapshot["needs_revision"]:
        item = progress_snapshot["needs_revision"]
        recommendations.append(
            f"Revisit {item['topic']} in {item['course_code']} because the last tracked score was {item['average_score']}%."
        )

    return {
        "found": True,
        "profile": {
            "name": profile["name"],
            "department": profile["department"],
            "level": profile["level"],
            "cgpa": profile["cgpa"],
            "overall_progress": overall_progress,
            "base_progress": base_progress,
            "learning_status": _status(overall_progress),
            "learning_streak": max(1, min(7, round(overall_progress / 14))),
            "priority_course": priority_course,
            "weak_topic_count": len(weak_topics),
            "weak_topics": weak_topics,
            "courses": courses,
            "weekly_plan": weekly_plan,
            "milestones": milestones,
            "recommendations": recommendations,
            "progress_history": progress_snapshot,
        },
    }
