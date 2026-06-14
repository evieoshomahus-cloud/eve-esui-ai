from __future__ import annotations

import json
import re
import uuid
from datetime import date, datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any

from .knowledge_validation import knowledge_stats, validate_knowledge_entries, validate_knowledge_file


ROOT = Path(__file__).resolve().parents[2]
KNOWLEDGE_PATH = ROOT / "knowledge" / "esui_knowledge.json"
RECORDS_PATH = ROOT / "knowledge" / "sample_records.json"
GAPS_PATH = ROOT / "storage" / "knowledge_gaps.json"
AUDIT_PATH = ROOT / "storage" / "knowledge_audit_log.json"
VALID_APPROVAL_STATUSES = {"demo", "draft", "approved", "needs_review"}


class KnowledgeSaveError(ValueError):
    """Raised when a knowledge entry cannot be persisted safely."""


class KnowledgeNotFoundError(KnowledgeSaveError):
    """Raised when a requested knowledge entry ID does not exist."""


@lru_cache(maxsize=1)
def knowledge_items() -> list[dict[str, Any]]:
    with KNOWLEDGE_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


@lru_cache(maxsize=1)
def records() -> dict[str, Any]:
    with RECORDS_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def user_profile(user_id: str) -> dict[str, Any] | None:
    return records()["users"].get(user_id)


def student_profile(user_id: str) -> dict[str, Any] | None:
    return records()["students"].get(user_id)


def lecturer_profile(user_id: str) -> dict[str, Any] | None:
    return records()["lecturers"].get(user_id)


def course_analytics(course_code: str) -> dict[str, Any] | None:
    return records()["course_analytics"].get(course_code.upper())


def public_profiles() -> list[dict[str, Any]]:
    return list(records()["users"].values())


def knowledge_summary() -> dict[str, Any]:
    entries = knowledge_items()
    validation = validate_knowledge_entries(entries).to_dict()
    return {
        **knowledge_stats(entries),
        "validation": {
            "ok": validation["ok"],
            "error_count": len(validation["errors"]),
            "warning_count": len(validation["warnings"]),
        },
    }


def validate_current_knowledge() -> dict[str, Any]:
    return validate_knowledge_file(KNOWLEDGE_PATH).to_dict()


def reload_knowledge_cache() -> dict[str, Any]:
    knowledge_items.cache_clear()
    entries = knowledge_items()
    return {
        "reloaded": True,
        **knowledge_stats(entries),
        "entries": _clone_entries(entries),
        "validation": validate_knowledge_entries(entries).to_dict(),
    }


def knowledge_library() -> dict[str, Any]:
    entries = knowledge_items()
    return {
        **knowledge_stats(entries),
        "entries": _clone_entries(entries),
        "validation": validate_knowledge_entries(entries).to_dict(),
    }


def save_knowledge_entry(entry: dict[str, Any]) -> dict[str, Any]:
    entries = _read_knowledge_entries()
    normalized = _normalize_knowledge_entry(entry)
    duplicate_index = next(
        (index for index, item in enumerate(entries) if item.get("id") == normalized["id"]),
        None,
    )
    if duplicate_index is not None:
        raise KnowledgeSaveError(
            f"Knowledge entry ID '{normalized['id']}' already exists. Choose a unique ID for new information."
        )

    candidate_entries = [*entries, normalized]
    validation = validate_knowledge_entries(candidate_entries)
    if not validation.ok:
        return {
            "saved": False,
            "entry": normalized,
            "validation": validation.to_dict(),
        }

    _write_knowledge_entries(candidate_entries)
    knowledge_items.cache_clear()
    current_entries = knowledge_items()
    return {
        "saved": True,
        "created": True,
        "entry": normalized,
        **knowledge_stats(current_entries),
        "entries": _clone_entries(current_entries),
        "validation": validate_knowledge_entries(current_entries).to_dict(),
    }


def update_knowledge_entry(entry_id: str, entry: dict[str, Any]) -> dict[str, Any]:
    entries = _read_knowledge_entries()
    index = _find_knowledge_index(entries, entry_id)
    normalized = _normalize_knowledge_entry({**entries[index], **entry, "id": entry.get("id") or entry_id})
    if normalized["id"] != entry_id and any(
        item.get("id") == normalized["id"] for position, item in enumerate(entries) if position != index
    ):
        raise KnowledgeSaveError(f"Knowledge entry ID '{normalized['id']}' already exists.")

    candidate_entries = [*entries]
    candidate_entries[index] = normalized
    validation = validate_knowledge_entries(candidate_entries)
    if not validation.ok:
        return {
            "saved": False,
            "updated": False,
            "entry": normalized,
            "validation": validation.to_dict(),
        }

    _write_knowledge_entries(candidate_entries)
    knowledge_items.cache_clear()
    current_entries = knowledge_items()
    return {
        "saved": True,
        "updated": True,
        "entry": normalized,
        **knowledge_stats(current_entries),
        "entries": _clone_entries(current_entries),
        "validation": validate_knowledge_entries(current_entries).to_dict(),
    }


def delete_knowledge_entry(entry_id: str) -> dict[str, Any]:
    entries = _read_knowledge_entries()
    index = _find_knowledge_index(entries, entry_id)
    removed = entries[index]
    candidate_entries = [item for position, item in enumerate(entries) if position != index]
    validation = validate_knowledge_entries(candidate_entries)
    if not validation.ok:
        return {
            "deleted": False,
            "entry_id": entry_id,
            "validation": validation.to_dict(),
        }

    _write_knowledge_entries(candidate_entries)
    knowledge_items.cache_clear()
    current_entries = knowledge_items()
    return {
        "deleted": True,
        "entry_id": entry_id,
        "entry": removed,
        **knowledge_stats(current_entries),
        "entries": _clone_entries(current_entries),
        "validation": validate_knowledge_entries(current_entries).to_dict(),
    }


def knowledge_gap_library() -> dict[str, Any]:
    gaps = _read_knowledge_gaps()
    sorted_gaps = sorted(gaps, key=lambda item: str(item.get("last_seen", "")), reverse=True)
    open_count = sum(1 for item in gaps if item.get("status") == "open")
    return {
        "gap_count": len(gaps),
        "open_count": open_count,
        "gaps": sorted_gaps,
    }


def knowledge_audit_library(limit: int = 40) -> dict[str, Any]:
    events = _read_knowledge_audit()
    sorted_events = sorted(events, key=lambda item: str(item.get("timestamp", "")), reverse=True)
    visible = sorted_events[: max(1, min(limit, 200))]
    return {
        "event_count": len(events),
        "events": visible,
    }


def record_knowledge_audit(
    *,
    actor_role: str,
    actor_user_id: str,
    action: str,
    entry: dict[str, Any] | None = None,
    entry_id: str | None = None,
    notes: str = "",
) -> dict[str, Any]:
    event = {
        "id": f"audit-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6]}",
        "timestamp": _utc_now(),
        "actor_role": _clean_text(actor_role),
        "actor_user_id": _clean_text(actor_user_id),
        "action": _clean_text(action),
        "entry_id": _clean_text(entry_id or (entry or {}).get("id")),
        "entry_title": _clean_text((entry or {}).get("title")),
        "approval_status": _approval_status(entry or {}),
        "notes": _clean_text(notes)[:600],
    }
    events = _read_knowledge_audit()
    events.append(event)
    _write_knowledge_audit(events[-500:])
    return event


def record_knowledge_gap(
    *,
    role: str,
    user_id: str,
    message: str,
    intent: str,
    confidence: float,
    retrieved_documents: int,
) -> dict[str, Any]:
    question = _redact_sensitive_text(_clean_text(message))[:800]
    if len(question) < 4:
        return {}
    gaps = _read_knowledge_gaps()
    now = _utc_now()
    signature = _gap_signature(question, role)
    existing = next((item for item in gaps if item.get("signature") == signature), None)
    if existing:
        existing["count"] = int(existing.get("count", 1)) + 1
        existing["last_seen"] = now
        existing["status"] = "open" if existing.get("status") == "dismissed" else existing.get("status", "open")
        existing["confidence"] = round(confidence, 2)
        existing["retrieved_documents"] = retrieved_documents
        if user_id not in existing.get("sample_user_ids", []):
            existing.setdefault("sample_user_ids", []).append(user_id)
    else:
        existing = {
            "id": f"gap-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6]}",
            "signature": signature,
            "question": question,
            "role": role,
            "intent": intent,
            "status": "open",
            "count": 1,
            "first_seen": now,
            "last_seen": now,
            "confidence": round(confidence, 2),
            "retrieved_documents": retrieved_documents,
            "sample_user_ids": [user_id],
            "suggested_title": _suggest_gap_title(question),
            "suggested_category": _suggest_gap_category(question),
            "suggested_tags": _suggest_gap_tags(question),
            "notes": "",
            "converted_entry_id": None,
        }
        gaps.append(existing)
    _write_knowledge_gaps(gaps)
    return dict(existing)


def update_knowledge_gap(
    gap_id: str,
    *,
    status: str | None = None,
    notes: str | None = None,
    converted_entry_id: str | None = None,
) -> dict[str, Any]:
    gaps = _read_knowledge_gaps()
    gap = next((item for item in gaps if item.get("id") == gap_id), None)
    if gap is None:
        raise KnowledgeNotFoundError(f"Knowledge gap ID '{gap_id}' was not found.")
    if status is not None:
        if status not in {"open", "reviewing", "converted", "dismissed"}:
            raise KnowledgeSaveError("Knowledge gap status must be open, reviewing, converted, or dismissed.")
        gap["status"] = status
    if notes is not None:
        gap["notes"] = _clean_text(notes)[:1000]
    if converted_entry_id is not None:
        gap["converted_entry_id"] = _clean_text(converted_entry_id) or None
    gap["updated"] = _utc_now()
    _write_knowledge_gaps(gaps)
    return gap


def _read_knowledge_entries() -> list[dict[str, Any]]:
    with KNOWLEDGE_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise KnowledgeSaveError("Knowledge file must contain a JSON list of entries.")
    return payload


def _write_knowledge_entries(entries: list[dict[str, Any]]) -> None:
    with KNOWLEDGE_PATH.open("w", encoding="utf-8") as handle:
        json.dump(entries, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def _read_knowledge_gaps() -> list[dict[str, Any]]:
    if not GAPS_PATH.exists():
        return []
    with GAPS_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise KnowledgeSaveError("Knowledge gap file must contain a JSON list.")
    return payload


def _write_knowledge_gaps(gaps: list[dict[str, Any]]) -> None:
    GAPS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with GAPS_PATH.open("w", encoding="utf-8") as handle:
        json.dump(gaps, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def _read_knowledge_audit() -> list[dict[str, Any]]:
    if not AUDIT_PATH.exists():
        return []
    with AUDIT_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise KnowledgeSaveError("Knowledge audit log file must contain a JSON list.")
    return payload


def _write_knowledge_audit(events: list[dict[str, Any]]) -> None:
    AUDIT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with AUDIT_PATH.open("w", encoding="utf-8") as handle:
        json.dump(events, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def _normalize_knowledge_entry(entry: dict[str, Any]) -> dict[str, Any]:
    category = _clean_text(entry.get("category")).lower().replace(" ", "_")
    title = _clean_text(entry.get("title"))
    entry_id = _clean_text(entry.get("id")) or f"esui-{category}-{_slugify(title)}"
    source_url = _clean_text(entry.get("source_url")) or None
    updated = _clean_text(entry.get("updated")) or date.today().isoformat()
    actor_role = _clean_text(entry.get("actor_role"))
    actor_user_id = _clean_text(entry.get("actor_user_id"))
    tags = _clean_list(entry.get("tags"), lowercase=True)
    status = _approval_status({**entry, "id": entry_id, "tags": tags})
    now = _utc_now()
    created_by = _clean_text(entry.get("created_by")) or actor_user_id or "system"
    created_by_role = _clean_text(entry.get("created_by_role")) or actor_role or "system"
    updated_by = _clean_text(entry.get("updated_by")) or actor_user_id or created_by
    updated_by_role = _clean_text(entry.get("updated_by_role")) or actor_role or created_by_role
    reviewed_by = _clean_text(entry.get("reviewed_by"))
    reviewed_at = _clean_text(entry.get("reviewed_at")) or None
    if status == "approved":
        reviewed_by = reviewed_by or updated_by
        reviewed_at = reviewed_at or now
    return {
        "id": entry_id,
        "title": title,
        "category": category,
        "audience": _clean_list(entry.get("audience"), lowercase=True),
        "tags": tags,
        "summary": _clean_text(entry.get("summary")),
        "content": _clean_text(entry.get("content")),
        "source_url": source_url,
        "updated": updated,
        "approval_status": status,
        "review_notes": _clean_text(entry.get("review_notes"))[:1000],
        "created_by": created_by,
        "created_by_role": created_by_role,
        "created_at": _clean_text(entry.get("created_at")) or now,
        "updated_by": updated_by,
        "updated_by_role": updated_by_role,
        "updated_at": now,
        "reviewed_by": reviewed_by or None,
        "reviewed_at": reviewed_at,
    }


def _approval_status(entry: dict[str, Any]) -> str:
    value = _clean_text(entry.get("approval_status")).lower()
    if value in VALID_APPROVAL_STATUSES:
        return value
    tags = entry.get("tags", []) if isinstance(entry.get("tags"), list) else []
    identifier = _clean_text(entry.get("id")).lower()
    if identifier.startswith("demo-") or any(_clean_text(tag).lower() == "demo" for tag in tags):
        return "demo"
    actor_role = _clean_text(entry.get("actor_role")).lower()
    if actor_role == "lecturer":
        return "draft"
    return "approved"


def _find_knowledge_index(entries: list[dict[str, Any]], entry_id: str) -> int:
    for index, entry in enumerate(entries):
        if entry.get("id") == entry_id:
            return index
    raise KnowledgeNotFoundError(f"Knowledge entry ID '{entry_id}' was not found.")


def _clone_entries(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return json.loads(json.dumps(entries))


def _clean_text(value: Any) -> str:
    return str(value or "").strip()


def _clean_list(value: Any, *, lowercase: bool = False) -> list[str]:
    if isinstance(value, str):
        raw_items = value.split(",")
    elif isinstance(value, list):
        raw_items = value
    else:
        raw_items = []
    cleaned: list[str] = []
    for item in raw_items:
        text = _clean_text(item)
        if not text:
            continue
        cleaned.append(text.lower() if lowercase else text)
    return list(dict.fromkeys(cleaned))


def _slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug[:64] or "entry"


def _utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _gap_signature(question: str, role: str) -> str:
    normalized = re.sub(r"[^a-z0-9 ]+", " ", question.lower())
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return f"{role}:{normalized[:220]}"


def _redact_sensitive_text(value: str) -> str:
    redacted = re.sub(r"\b\d{10,16}\b", "[number-redacted]", value)
    redacted = re.sub(r"(?i)(password|otp|pin|token)\s*[:=]\s*\S+", r"\1=[redacted]", redacted)
    return redacted


def _suggest_gap_title(question: str) -> str:
    words = re.sub(r"[^a-zA-Z0-9 ]+", " ", question).split()
    title = " ".join(words[:8]) or "Knowledge Gap"
    return f"Demo Knowledge: {title}".strip()


def _suggest_gap_category(question: str) -> str:
    text = question.lower()
    if _has_any(text, ["hostel", "appliance", "room", "accommodation"]):
        return "student_life"
    if _has_any(text, ["fee", "dues", "payment", "receipt"]):
        return "fees"
    if _has_any(text, ["portal", "password", "login", "email", "ict"]):
        return "portal"
    if _has_any(text, ["course", "lecture", "exam", "registration", "calendar"]):
        return "planning"
    if _has_any(text, ["clinic", "medical", "health"]):
        return "student_life"
    return "governance"


def _suggest_gap_tags(question: str) -> list[str]:
    text = question.lower()
    candidates = [
        "demo",
        "knowledge gap",
        "hostel",
        "appliances",
        "fees",
        "portal",
        "library",
        "clinic",
        "course registration",
        "exam clearance",
        "student support",
    ]
    tags = [tag for tag in candidates if tag in text or tag in {"demo", "knowledge gap"}]
    return list(dict.fromkeys(tags))[:8]


def _has_any(text: str, terms: list[str]) -> bool:
    return any(term in text for term in terms)
