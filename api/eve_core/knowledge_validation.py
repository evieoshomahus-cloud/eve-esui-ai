from __future__ import annotations

import json
from collections import Counter
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


REQUIRED_FIELDS = {
    "id",
    "title",
    "category",
    "audience",
    "tags",
    "summary",
    "content",
    "source_url",
    "updated",
}
VALID_AUDIENCES = {"public", "guest", "student", "lecturer"}
VALID_APPROVAL_STATUSES = {"demo", "draft", "approved", "needs_review"}
OFFICIAL_DOMAIN = "edouniversity.edu.ng"


@dataclass(frozen=True)
class KnowledgeIssue:
    severity: str
    entry_id: str
    field: str
    message: str

    def to_dict(self) -> dict[str, str]:
        return {
            "severity": self.severity,
            "entry_id": self.entry_id,
            "field": self.field,
            "message": self.message,
        }


@dataclass(frozen=True)
class KnowledgeValidationResult:
    ok: bool
    entry_count: int
    errors: list[KnowledgeIssue]
    warnings: list[KnowledgeIssue]

    def to_dict(self) -> dict[str, Any]:
        return {
            "ok": self.ok,
            "entry_count": self.entry_count,
            "errors": [issue.to_dict() for issue in self.errors],
            "warnings": [issue.to_dict() for issue in self.warnings],
        }


def load_knowledge_file(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise ValueError("Knowledge file must contain a JSON list of entries.")
    return payload


def knowledge_stats(entries: list[dict[str, Any]]) -> dict[str, Any]:
    categories = Counter(str(entry.get("category", "unknown")) for entry in entries)
    approval_statuses = Counter(_approval_status(entry) for entry in entries)
    audiences = Counter(
        audience
        for entry in entries
        for audience in entry.get("audience", [])
        if isinstance(entry.get("audience"), list)
    )
    official_sources = sum(
        1
        for entry in entries
        if isinstance(entry.get("source_url"), str) and OFFICIAL_DOMAIN in entry["source_url"]
    )
    return {
        "entry_count": len(entries),
        "categories": dict(sorted(categories.items())),
        "approval_statuses": dict(sorted(approval_statuses.items())),
        "audiences": dict(sorted(audiences.items())),
        "official_source_count": official_sources,
        "curated_internal_count": sum(1 for entry in entries if entry.get("source_url") is None),
    }


def validate_knowledge_file(path: Path) -> KnowledgeValidationResult:
    return validate_knowledge_entries(load_knowledge_file(path))


def validate_knowledge_entries(entries: list[dict[str, Any]]) -> KnowledgeValidationResult:
    errors: list[KnowledgeIssue] = []
    warnings: list[KnowledgeIssue] = []
    seen_ids: set[str] = set()

    if not isinstance(entries, list):
        return KnowledgeValidationResult(
            ok=False,
            entry_count=0,
            errors=[KnowledgeIssue("error", "file", "root", "Knowledge payload must be a JSON list.")],
            warnings=[],
        )

    for index, entry in enumerate(entries):
        entry_id = str(entry.get("id", f"entry-{index}")) if isinstance(entry, dict) else f"entry-{index}"
        if not isinstance(entry, dict):
            errors.append(KnowledgeIssue("error", entry_id, "entry", "Entry must be a JSON object."))
            continue

        missing = REQUIRED_FIELDS - set(entry)
        for field in sorted(missing):
            errors.append(KnowledgeIssue("error", entry_id, field, "Required field is missing."))

        _validate_id(entry, entry_id, seen_ids, errors)
        _validate_text(entry, entry_id, "title", 4, errors)
        _validate_text(entry, entry_id, "category", 2, errors)
        _validate_text(entry, entry_id, "summary", 20, errors)
        _validate_text(entry, entry_id, "content", 40, errors)
        _validate_list(entry, entry_id, "tags", errors)
        _validate_audience(entry, entry_id, errors)
        _validate_updated(entry, entry_id, errors, warnings)
        _validate_source_url(entry, entry_id, errors, warnings)
        _validate_approval_status(entry, entry_id, errors)
        _validate_payment_safety(entry, entry_id, errors, warnings)

    return KnowledgeValidationResult(
        ok=not errors,
        entry_count=len(entries),
        errors=errors,
        warnings=warnings,
    )


def _validate_id(entry: dict[str, Any], entry_id: str, seen_ids: set[str], errors: list[KnowledgeIssue]) -> None:
    value = entry.get("id")
    if not isinstance(value, str) or len(value.strip()) < 4:
        errors.append(KnowledgeIssue("error", entry_id, "id", "ID must be a non-empty string of at least 4 characters."))
        return
    if value in seen_ids:
        errors.append(KnowledgeIssue("error", entry_id, "id", "Duplicate knowledge entry ID."))
    seen_ids.add(value)


def _validate_text(
    entry: dict[str, Any],
    entry_id: str,
    field: str,
    min_length: int,
    errors: list[KnowledgeIssue],
) -> None:
    value = entry.get(field)
    if not isinstance(value, str) or len(value.strip()) < min_length:
        errors.append(KnowledgeIssue("error", entry_id, field, f"Must be a string of at least {min_length} characters."))


def _validate_list(entry: dict[str, Any], entry_id: str, field: str, errors: list[KnowledgeIssue]) -> None:
    value = entry.get(field)
    if not isinstance(value, list) or not value:
        errors.append(KnowledgeIssue("error", entry_id, field, "Must be a non-empty list."))
        return
    if not all(isinstance(item, str) and item.strip() for item in value):
        errors.append(KnowledgeIssue("error", entry_id, field, "All list items must be non-empty strings."))


def _validate_audience(entry: dict[str, Any], entry_id: str, errors: list[KnowledgeIssue]) -> None:
    value = entry.get("audience")
    if not isinstance(value, list) or not value:
        errors.append(KnowledgeIssue("error", entry_id, "audience", "Audience must be a non-empty list."))
        return
    invalid = sorted(set(value) - VALID_AUDIENCES)
    if invalid:
        errors.append(KnowledgeIssue("error", entry_id, "audience", f"Invalid audience values: {', '.join(invalid)}."))


def _validate_updated(
    entry: dict[str, Any],
    entry_id: str,
    errors: list[KnowledgeIssue],
    warnings: list[KnowledgeIssue],
) -> None:
    value = entry.get("updated")
    if not isinstance(value, str):
        errors.append(KnowledgeIssue("error", entry_id, "updated", "Updated date must be in YYYY-MM-DD format."))
        return
    try:
        parsed = date.fromisoformat(value)
    except ValueError:
        errors.append(KnowledgeIssue("error", entry_id, "updated", "Updated date must be in YYYY-MM-DD format."))
        return
    if parsed > date.today():
        warnings.append(KnowledgeIssue("warning", entry_id, "updated", "Updated date is in the future."))


def _approval_status(entry: dict[str, Any]) -> str:
    value = str(entry.get("approval_status", "")).strip().lower()
    if value in VALID_APPROVAL_STATUSES:
        return value
    tags = entry.get("tags", []) if isinstance(entry.get("tags"), list) else []
    identifier = str(entry.get("id", "")).lower()
    if identifier.startswith("demo-") or any(str(tag).lower() == "demo" for tag in tags):
        return "demo"
    return "approved"


def _validate_approval_status(entry: dict[str, Any], entry_id: str, errors: list[KnowledgeIssue]) -> None:
    if "approval_status" not in entry or entry.get("approval_status") in (None, ""):
        return
    value = str(entry.get("approval_status")).strip().lower()
    if value not in VALID_APPROVAL_STATUSES:
        errors.append(
            KnowledgeIssue(
                "error",
                entry_id,
                "approval_status",
                "Approval status must be demo, draft, approved, or needs_review.",
            )
        )


def _validate_source_url(
    entry: dict[str, Any],
    entry_id: str,
    errors: list[KnowledgeIssue],
    warnings: list[KnowledgeIssue],
) -> None:
    value = entry.get("source_url")
    if value is None:
        warnings.append(KnowledgeIssue("warning", entry_id, "source_url", "No URL supplied; treat as curated internal knowledge."))
        return
    if not isinstance(value, str) or not value.strip():
        errors.append(KnowledgeIssue("error", entry_id, "source_url", "Source URL must be null or a non-empty HTTPS URL."))
        return
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.netloc:
        errors.append(KnowledgeIssue("error", entry_id, "source_url", "Source URL must use HTTPS."))
    if OFFICIAL_DOMAIN not in parsed.netloc:
        warnings.append(KnowledgeIssue("warning", entry_id, "source_url", "Source is not on the official ESUI domain."))


def _validate_payment_safety(
    entry: dict[str, Any],
    entry_id: str,
    errors: list[KnowledgeIssue],
    warnings: list[KnowledgeIssue],
) -> None:
    tags = entry.get("tags", []) if isinstance(entry.get("tags"), list) else []
    category = str(entry.get("category", "")).lower()
    title_and_tags = " ".join(
        [
            str(entry.get("title", "")),
            " ".join(tags),
        ]
    ).lower()
    is_payment_entry = category == "fees" or any(
        term in title_and_tags for term in ["payment", "payments", "payment portal", "quick pay", "receipt"]
    )
    if not is_payment_entry:
        return

    searchable = " ".join(
        [
            category,
            str(entry.get("title", "")),
            str(entry.get("summary", "")),
            str(entry.get("content", "")),
            " ".join(tags),
        ]
    ).lower()
    content = str(entry.get("content", ""))
    if "https://edouniversity.edu.ng/" not in content and OFFICIAL_DOMAIN not in str(entry.get("source_url", "")):
        errors.append(
            KnowledgeIssue(
                "error",
                entry_id,
                "content",
                "Payment-related entries must include an official edouniversity.edu.ng URL.",
            )
        )
    if "unofficial" not in searchable and "safety" not in searchable:
        warnings.append(
            KnowledgeIssue(
                "warning",
                entry_id,
                "content",
                "Payment-related entry should warn users against unofficial payment links.",
            )
        )
