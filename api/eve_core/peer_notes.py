from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .repository import lecturer_profile, student_profile, user_profile


ROOT = Path(__file__).resolve().parents[2]
PEER_NOTES_PATH = ROOT / "storage" / "peer_notes.json"
VALID_REVIEW_STATUSES = {"pending", "approved", "rejected", "needs_revision"}
COURSE_CODE_RE = re.compile(r"^([A-Z]{2,4})\s?(\d{3})$")


class PeerNoteError(ValueError):
    """Raised when a peer note cannot be created or reviewed."""


def _now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _clean_text(value: Any, *, limit: int | None = None) -> str:
    text = re.sub(r"\s+", " ", str(value or "").strip())
    return text[:limit] if limit else text


def _normal_course_code(value: str) -> str:
    cleaned = re.sub(r"\s+", "", value.upper())
    match = COURSE_CODE_RE.match(cleaned)
    if not match:
        raise PeerNoteError("Use a course code like CSC 201 or MTH 211.")
    return f"{match.group(1)} {match.group(2)}"


def _read_notes() -> list[dict[str, Any]]:
    if not PEER_NOTES_PATH.exists():
        return []
    with PEER_NOTES_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise PeerNoteError("Peer notes storage must contain a JSON list.")
    return payload


def _write_notes(notes: list[dict[str, Any]]) -> None:
    PEER_NOTES_PATH.parent.mkdir(parents=True, exist_ok=True)
    with PEER_NOTES_PATH.open("w", encoding="utf-8") as handle:
        json.dump(notes, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def _public_note(note: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": note["id"],
        "course_code": note["course_code"],
        "course_title": note.get("course_title", note["course_code"]),
        "title": note["title"],
        "summary": note["summary"],
        "content": note["content"],
        "status": note["status"],
        "student_name": note.get("student_name", "Student"),
        "student_user_id": note.get("student_user_id"),
        "department": note.get("department"),
        "level": note.get("level"),
        "created_at": note["created_at"],
        "updated_at": note["updated_at"],
        "reviewed_by": note.get("reviewed_by"),
        "reviewed_by_role": note.get("reviewed_by_role"),
        "reviewed_at": note.get("reviewed_at"),
        "review_notes": note.get("review_notes", ""),
    }


def submit_peer_note(
    *,
    user_id: str,
    course_code: str,
    title: str,
    summary: str,
    content: str,
) -> dict[str, Any]:
    profile = student_profile(user_id)
    if not profile:
        raise PeerNoteError("Only signed-in student demo accounts can submit peer notes.")
    normalized_course = _normal_course_code(course_code)
    if normalized_course not in profile.get("courses", {}):
        raise PeerNoteError("Students can only submit peer notes for their registered demo courses.")

    cleaned_title = _clean_text(title, limit=140)
    cleaned_summary = _clean_text(summary, limit=500)
    cleaned_content = str(content or "").strip()
    cleaned_content = re.sub(r"\n{3,}", "\n\n", cleaned_content)[:6000]
    if len(cleaned_title) < 4:
        raise PeerNoteError("Peer note title is too short.")
    if len(cleaned_summary) < 20:
        raise PeerNoteError("Add a short summary of what the note explains.")
    if len(cleaned_content) < 80:
        raise PeerNoteError("Add more detail so reviewers can understand the note.")

    course = profile["courses"][normalized_course]
    timestamp = _now()
    note = {
        "id": f"peer-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6]}",
        "student_user_id": user_id,
        "student_name": profile["name"],
        "department": profile["department"],
        "level": profile["level"],
        "course_code": normalized_course,
        "course_title": course.get("title", normalized_course),
        "title": cleaned_title,
        "summary": cleaned_summary,
        "content": cleaned_content,
        "status": "pending",
        "created_at": timestamp,
        "updated_at": timestamp,
        "reviewed_by": None,
        "reviewed_by_role": None,
        "reviewed_at": None,
        "review_notes": "",
    }
    notes = _read_notes()
    notes.append(note)
    _write_notes(notes)
    return _public_note(note)


def student_peer_notes(user_id: str) -> dict[str, Any]:
    profile = student_profile(user_id)
    if not profile:
        raise PeerNoteError("Student profile not found.")
    registered_courses = set(profile.get("courses", {}))
    notes = _read_notes()
    own_notes = [
        _public_note(note)
        for note in notes
        if note.get("student_user_id") == user_id
    ]
    approved_shared = [
        _public_note(note)
        for note in notes
        if note.get("status") == "approved"
        and note.get("course_code") in registered_courses
        and note.get("student_user_id") != user_id
    ]
    return {
        "found": True,
        "user_id": user_id,
        "own_notes": sorted(own_notes, key=lambda item: item["updated_at"], reverse=True),
        "approved_peer_notes": sorted(approved_shared, key=lambda item: item["updated_at"], reverse=True),
    }


def _assigned_courses(actor_user_id: str) -> set[str]:
    profile = lecturer_profile(actor_user_id) or {}
    return {_normal_course_code(course) for course in profile.get("assigned_courses", [])}


def _can_review_note(actor_role: str, actor_user_id: str, note: dict[str, Any]) -> bool:
    if actor_role == "admin":
        profile = user_profile(actor_user_id)
        return bool(profile and profile.get("role") == "admin")
    if actor_role == "lecturer":
        profile = user_profile(actor_user_id)
        return bool(
            profile
            and profile.get("role") == "lecturer"
            and note.get("course_code") in _assigned_courses(actor_user_id)
        )
    return False


def peer_note_review_queue(actor_role: str, actor_user_id: str) -> dict[str, Any]:
    profile = user_profile(actor_user_id)
    if not profile or profile.get("role") != actor_role:
        raise PeerNoteError("Reviewer role does not match a valid demo account.")
    notes = [
        _public_note(note)
        for note in _read_notes()
        if _can_review_note(actor_role, actor_user_id, note)
    ]
    return {
        "reviewer_role": actor_role,
        "reviewer_user_id": actor_user_id,
        "pending_count": sum(1 for note in notes if note["status"] == "pending"),
        "notes": sorted(notes, key=lambda item: item["updated_at"], reverse=True),
    }


def update_peer_note_review(
    *,
    note_id: str,
    actor_role: str,
    actor_user_id: str,
    status: str,
    review_notes: str = "",
) -> dict[str, Any]:
    if status not in VALID_REVIEW_STATUSES:
        raise PeerNoteError("Peer note status must be pending, approved, rejected, or needs_revision.")
    notes = _read_notes()
    note = next((item for item in notes if item.get("id") == note_id), None)
    if note is None:
        raise PeerNoteError(f"Peer note '{note_id}' was not found.")
    if not _can_review_note(actor_role, actor_user_id, note):
        raise PeerNoteError("This reviewer cannot manage the selected peer note.")

    timestamp = _now()
    note["status"] = status
    note["updated_at"] = timestamp
    note["reviewed_by"] = actor_user_id
    note["reviewed_by_role"] = actor_role
    note["reviewed_at"] = timestamp
    note["review_notes"] = _clean_text(review_notes, limit=1000)
    _write_notes(notes)
    return _public_note(note)


def approved_peer_note_items() -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for note in _read_notes():
        if note.get("status") != "approved":
            continue
        items.append(
            {
                "id": note["id"],
                "title": f"Peer Note: {note['course_code']} - {note['title']}",
                "category": "learning",
                "audience": ["student", "lecturer"],
                "tags": [
                    "peer note",
                    "student contribution",
                    "reviewed",
                    note["course_code"].lower(),
                ],
                "summary": note["summary"],
                "content": (
                    f"Reviewed peer-learning note for {note['course_code']} ({note.get('course_title', '')}). "
                    "This is student-contributed learning support, not official school policy.\n\n"
                    f"{note['content']}"
                ),
                "source_url": None,
                "updated": note["updated_at"][:10],
                "approval_status": "approved",
                "source_type": "reviewed_peer_note",
            }
        )
    return items
