from __future__ import annotations

from typing import Any
from uuid import uuid4

from .progress_store import add_answer, load_session, save_session, update_session
from .repository import student_profile


SESSIONS: dict[str, dict[str, Any]] = {}


TOPIC_LIBRARY: dict[str, dict[str, Any]] = {
    "eigenvalues": {
        "explanation": "Eigenvalues are special scalar values that show how a matrix stretches or compresses a vector without changing the vector's direction.",
        "example": "If A is a matrix and Ax = lambda x, then lambda is an eigenvalue and x is the corresponding eigenvector.",
        "questions": [
            {
                "prompt": "In your own words, what does an eigenvalue represent?",
                "keywords": ["matrix", "vector", "scale", "stretch", "direction"],
                "ideal": "An eigenvalue is a scalar that tells how much a matrix scales an eigenvector without changing its direction.",
            },
            {
                "prompt": "What equation is commonly used to describe an eigenvalue and eigenvector?",
                "keywords": ["ax", "lambda", "x", "eigenvector"],
                "ideal": "The common equation is Ax = lambda x, where A is the matrix, x is the eigenvector, and lambda is the eigenvalue.",
            },
            {
                "prompt": "Why are eigenvalues useful in linear algebra?",
                "keywords": ["transform", "matrix", "system", "simplify", "behavior"],
                "ideal": "They help explain the behaviour of matrix transformations and simplify the analysis of linear systems.",
            },
        ],
    },
    "matrix inverse": {
        "explanation": "A matrix inverse reverses the effect of a square matrix. If A has an inverse, multiplying A by A inverse gives the identity matrix.",
        "example": "For a matrix A, A x A^-1 = I, where I is the identity matrix.",
        "questions": [
            {
                "prompt": "What is the result of multiplying a matrix by its inverse?",
                "keywords": ["identity", "matrix"],
                "ideal": "The result is the identity matrix.",
            },
            {
                "prompt": "Can every matrix have an inverse? Explain briefly.",
                "keywords": ["no", "square", "determinant", "zero", "singular"],
                "ideal": "No. A matrix must be square and non-singular; if its determinant is zero, it has no inverse.",
            },
        ],
    },
    "linked lists": {
        "explanation": "A linked list is a data structure made of nodes. Each node stores data and a reference to the next node.",
        "example": "A simple linked list node may contain a student record and a pointer to the next student record.",
        "questions": [
            {
                "prompt": "What two main things does a linked list node usually contain?",
                "keywords": ["data", "next", "pointer", "reference"],
                "ideal": "It contains data and a pointer or reference to the next node.",
            },
            {
                "prompt": "Mention one advantage of linked lists over arrays.",
                "keywords": ["dynamic", "insert", "delete", "memory"],
                "ideal": "Linked lists can grow dynamically and make insertion or deletion easier in some positions.",
            },
        ],
    },
    "recursion": {
        "explanation": "Recursion is a programming technique where a function solves a problem by calling itself with a smaller version of the problem.",
        "example": "Factorial can be solved recursively: factorial(n) = n * factorial(n - 1), with factorial(1) as the base case.",
        "questions": [
            {
                "prompt": "What is the purpose of a base case in recursion?",
                "keywords": ["stop", "end", "infinite", "condition"],
                "ideal": "The base case stops the recursive calls and prevents infinite recursion.",
            },
            {
                "prompt": "Give one example of a problem that can be solved recursively.",
                "keywords": ["factorial", "fibonacci", "tree", "search"],
                "ideal": "Examples include factorial, Fibonacci sequence, tree traversal, and recursive search.",
            },
        ],
    },
    "algorithm tracing": {
        "explanation": "Algorithm tracing means manually following each step of an algorithm to understand how values change over time.",
        "example": "Tracing a sorting algorithm involves writing down the array after each comparison or swap.",
        "questions": [
            {
                "prompt": "Why is algorithm tracing useful?",
                "keywords": ["understand", "debug", "steps", "values", "errors"],
                "ideal": "It helps students understand program flow, detect errors, and see how values change step by step.",
            }
        ],
    },
    "normalization": {
        "explanation": "Database normalization organizes data to reduce redundancy and improve data integrity.",
        "example": "A student table and a course table should be separated instead of repeating course details for every student row.",
        "questions": [
            {
                "prompt": "What is one major reason for database normalization?",
                "keywords": ["reduce", "redundancy", "integrity", "duplicate"],
                "ideal": "Normalization reduces data redundancy and improves data integrity.",
            }
        ],
    },
}


def _fallback_topic(topic: str) -> dict[str, Any]:
    readable = topic or "the selected topic"
    return {
        "explanation": f"{readable.title()} is an important concept in this course. Start by understanding the definition, then practise with examples and past-question style problems.",
        "example": f"Apply {readable} to a simple classroom scenario, then explain each step in your own words.",
        "questions": [
            {
                "prompt": f"Explain {readable} in your own words and give one example.",
                "keywords": [word for word in readable.lower().split() if len(word) > 2],
                "ideal": f"A good answer should define {readable}, give an example, and explain why it matters.",
            },
            {
                "prompt": f"State one common mistake students make when learning {readable}.",
                "keywords": ["mistake", "confuse", "wrong", "error"],
                "ideal": "A good answer identifies a realistic mistake and explains how to avoid it.",
            },
        ],
    }


def _topic_from_course(profile: dict[str, Any], course_code: str, topic: str | None) -> str:
    if topic and topic.strip():
        return topic.strip().lower()
    course = profile["courses"].get(course_code)
    if course and course["topic_gaps"]:
        return course["topic_gaps"][0].lower()
    return "past-question practice"


def _score_answer(answer: str, keywords: list[str]) -> tuple[int, list[str]]:
    normalized = answer.lower()
    if not keywords:
        return (70 if len(normalized.split()) >= 8 else 45, [])
    matched = [keyword for keyword in keywords if keyword.lower() in normalized]
    ratio = len(matched) / len(keywords)
    score = round(35 + (ratio * 55))
    if len(normalized.split()) >= 18:
        score += 10
    return min(100, score), matched


def _feedback(score: int, matched: list[str], ideal: str) -> str:
    if score >= 80:
        return f"Strong answer. You covered the key idea well. Matched concepts: {', '.join(matched) or 'clear explanation'}."
    if score >= 60:
        return f"Good attempt. You are close, but make the explanation more complete. Ideal direction: {ideal}"
    return f"Needs revision. Compare your answer with this: {ideal}"


def _session_payload(session: dict[str, Any]) -> dict[str, Any]:
    questions = session["questions"]
    index = session["current_question_index"]
    completed = index >= len(questions)
    question = None if completed else questions[index]["prompt"]
    average = round(sum(item["score"] for item in session["history"]) / len(session["history"])) if session["history"] else 0
    return {
        "found": True,
        "session_id": session["session_id"],
        "user_id": session["user_id"],
        "course_code": session["course_code"],
        "course_title": session["course_title"],
        "topic": session["topic"],
        "explanation": session["explanation"],
        "example": session["example"],
        "current_question_index": min(index + 1, len(questions)),
        "total_questions": len(questions),
        "question": question,
        "completed": completed,
        "average_score": average,
        "history": session["history"],
        "summary": session.get("summary"),
        "created_at": session.get("created_at"),
        "updated_at": session.get("updated_at"),
        "completed_at": session.get("completed_at"),
    }


def _find_session(session_id: str) -> dict[str, Any] | None:
    session = SESSIONS.get(session_id)
    if session:
        return session
    session = load_session(session_id)
    if session:
        SESSIONS[session_id] = session
    return session


def start_learning_session(user_id: str, course_code: str, topic: str | None = None) -> dict[str, Any]:
    profile = student_profile(user_id)
    if not profile:
        return {"found": False, "message": "Student profile not found."}

    normalized_course = course_code.upper()
    course = profile["courses"].get(normalized_course)
    if not course:
        return {"found": False, "message": f"{normalized_course} is not registered for this student."}

    selected_topic = _topic_from_course(profile, normalized_course, topic)
    content = TOPIC_LIBRARY.get(selected_topic, _fallback_topic(selected_topic))
    session_id = str(uuid4())
    session = {
        "session_id": session_id,
        "user_id": user_id,
        "course_code": normalized_course,
        "course_title": course["title"],
        "topic": selected_topic,
        "explanation": content["explanation"],
        "example": content["example"],
        "questions": content["questions"],
        "current_question_index": 0,
        "history": [],
        "summary": None,
    }
    SESSIONS[session_id] = session
    save_session(session)
    return _session_payload(session)


def submit_learning_answer(session_id: str, answer: str) -> dict[str, Any]:
    session = _find_session(session_id)
    if not session:
        return {"found": False, "message": "Learning session not found."}

    index = session["current_question_index"]
    questions = session["questions"]
    if index >= len(questions):
        return _session_payload(session)

    question = questions[index]
    score, matched = _score_answer(answer, question.get("keywords", []))
    answer_item = {
        "question": question["prompt"],
        "answer": answer,
        "score": score,
        "feedback": _feedback(score, matched, question["ideal"]),
        "ideal_answer": question["ideal"],
    }
    session["history"].append(answer_item)
    add_answer(session_id, index, answer_item)
    session["current_question_index"] += 1

    if session["current_question_index"] >= len(questions):
        average = round(sum(item["score"] for item in session["history"]) / len(session["history"]))
        if average >= 75:
            next_step = "Move to a timed mock question and maintain the topic with revision twice this week."
        elif average >= 55:
            next_step = "Repeat the explanation, correct weak points, and attempt another practice drill tomorrow."
        else:
            next_step = "Restart this topic from the concept explanation and ask Eve for simpler examples."
        session["summary"] = {
            "average_score": average,
            "progress_delta": max(1, round(average / 20)),
            "next_step": next_step,
        }

    update_session(session)
    return _session_payload(session)


def get_learning_session(session_id: str) -> dict[str, Any]:
    session = _find_session(session_id)
    if not session:
        return {"found": False, "message": "Learning session not found."}
    return _session_payload(session)
