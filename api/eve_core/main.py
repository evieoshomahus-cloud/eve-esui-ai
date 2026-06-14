from __future__ import annotations

import gzip
import mimetypes
from pathlib import Path
import re

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import FileResponse, Response

from .admissions import estimate_admission_readiness
from .assistant import generate_answer
from .attachments import list_attachments, save_attachment
from .learning import learning_profile
from .learning_sessions import get_learning_session, start_learning_session, submit_learning_answer
from .local_env import load_local_env
from .llm import openai_configured
from .progress_store import lecturer_course_learning_insights, student_progress_history
from .repository import (
    KnowledgeNotFoundError,
    KnowledgeSaveError,
    delete_knowledge_entry,
    knowledge_audit_library,
    knowledge_gap_library,
    knowledge_library,
    knowledge_summary,
    lecturer_profile,
    public_profiles,
    reload_knowledge_cache,
    record_knowledge_audit,
    save_knowledge_entry,
    student_profile,
    update_knowledge_gap,
    update_knowledge_entry,
    user_profile,
    validate_current_knowledge,
)
from .schemas import (
    AdmissionEstimateRequest,
    AdmissionEstimateResponse,
    AttachmentResponse,
    AttachmentUploadRequest,
    ChatRequest,
    ChatResponse,
    KnowledgeEntryRequest,
    KnowledgeGapUpdateRequest,
    LearningAnswerRequest,
    LearningSessionStartRequest,
    KnowledgeValidateRequest,
)
from .knowledge_validation import validate_knowledge_entries


load_local_env()

COURSE_CODE_RE = re.compile(r"\b[A-Z]{2,4}\s?\d{3}\b")
LECTURER_APPROVAL_STATUSES = {"demo", "draft", "needs_review"}

app = FastAPI(
    title="Eve ESUI AI Platform",
    description="AI system prototype for personalized learning and academic progress tracking at Edo State University Iyamho.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1024)


@app.get("/api/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "eve-esui-ai",
        "version": "1.0.0",
        "ai_mode": "openai_responses" if openai_configured() else "local_fallback",
    }


@app.get("/api/users")
def users() -> list[dict]:
    return public_profiles()


@app.post("/api/uploads", response_model=AttachmentResponse)
def upload_attachment(payload: AttachmentUploadRequest) -> dict:
    profile = user_profile(payload.user_id)
    if profile is None or profile.get("role") != payload.role:
        raise HTTPException(status_code=403, detail="Upload user does not match a valid demo account.")
    try:
        return save_attachment(
            role=payload.role,
            user_id=payload.user_id,
            filename=payload.filename,
            content_type=payload.content_type,
            base64_data=payload.base64_data,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/api/uploads", response_model=list[AttachmentResponse])
def uploaded_attachments(role: str, user_id: str) -> list[dict]:
    profile = user_profile(user_id)
    if profile is None or profile.get("role") != role:
        raise HTTPException(status_code=403, detail="Upload user does not match a valid demo account.")
    return list_attachments(role, user_id)


@app.get("/api/admin/knowledge/stats")
def admin_knowledge_stats() -> dict:
    return knowledge_summary()


@app.get("/api/admin/knowledge/validate")
def admin_validate_current_knowledge() -> dict:
    return validate_current_knowledge()


@app.post("/api/admin/knowledge/validate")
def admin_validate_supplied_knowledge(payload: KnowledgeValidateRequest) -> dict:
    return validate_knowledge_entries(payload.entries).to_dict()


@app.post("/api/admin/knowledge/reload")
def admin_reload_knowledge() -> dict:
    return reload_knowledge_cache()


def _payload_dict(payload) -> dict:
    return payload.model_dump() if hasattr(payload, "model_dump") else payload.dict()


def _payload_update_dict(payload) -> dict:
    if hasattr(payload, "model_dump"):
        return payload.model_dump(exclude_unset=True)
    return payload.dict(exclude_unset=True)


def _actor_identity(actor_role: str | None, actor_user_id: str | None) -> tuple[str, str]:
    role = (actor_role or "").strip().lower()
    user_id = (actor_user_id or "").strip()
    if role not in {"admin", "lecturer"}:
        raise HTTPException(
            status_code=403,
            detail="Only admins and lecturers can manage Eve knowledge.",
        )
    profile = user_profile(user_id)
    if profile is None or profile.get("role") != role:
        raise HTTPException(
            status_code=403,
            detail="The knowledge actor role does not match a valid demo account.",
        )
    return role, user_id


def _default_approval_status(actor_role: str, data: dict) -> str:
    tags = [str(tag).lower() for tag in data.get("tags", []) if isinstance(tag, str)]
    identifier = str(data.get("id", "")).lower()
    if identifier.startswith("demo-") or "demo" in tags:
        return "demo"
    if actor_role == "lecturer":
        return "draft"
    return "approved"


def _apply_actor_metadata(data: dict, actor_role: str, actor_user_id: str, *, creating: bool) -> dict:
    data["actor_role"] = actor_role
    data["actor_user_id"] = actor_user_id
    data["updated_by"] = actor_user_id
    data["updated_by_role"] = actor_role
    if creating:
        data.setdefault("created_by", actor_user_id)
        data.setdefault("created_by_role", actor_role)
    data["approval_status"] = str(
        data.get("approval_status") or _default_approval_status(actor_role, data)
    ).lower()
    if actor_role == "lecturer" and data["approval_status"] not in LECTURER_APPROVAL_STATUSES:
        raise HTTPException(
            status_code=403,
            detail="Lecturers can submit course knowledge as draft, demo, or needs review. Admin approval is required before an entry is marked approved.",
        )
    return data


def _normal_course_code(code: str) -> str:
    cleaned = re.sub(r"\s+", "", code.upper())
    match = re.match(r"^([A-Z]{2,4})(\d{3})$", cleaned)
    return f"{match.group(1)} {match.group(2)}" if match else code.upper()


def _assigned_courses(user_id: str) -> set[str]:
    profile = lecturer_profile(user_id) or {}
    return {_normal_course_code(course) for course in profile.get("assigned_courses", [])}


def _entry_text(entry: dict) -> str:
    parts = [
        entry.get("id", ""),
        entry.get("title", ""),
        entry.get("category", ""),
        entry.get("summary", ""),
        entry.get("content", ""),
        " ".join(str(tag) for tag in entry.get("tags", [])),
    ]
    return " ".join(str(part) for part in parts)


def _entry_course_codes(entry: dict) -> set[str]:
    return {_normal_course_code(match.group(0)) for match in COURSE_CODE_RE.finditer(_entry_text(entry).upper())}


def _gap_course_codes(gap: dict) -> set[str]:
    text = " ".join(
        str(value)
        for value in [
            gap.get("question", ""),
            gap.get("suggested_title", ""),
            gap.get("suggested_category", ""),
            " ".join(str(tag) for tag in gap.get("suggested_tags", [])),
        ]
    )
    return {_normal_course_code(match.group(0)) for match in COURSE_CODE_RE.finditer(text.upper())}


def _can_manage_entry(actor_role: str, actor_user_id: str, entry: dict) -> bool:
    if actor_role == "admin":
        return True
    if actor_role != "lecturer":
        return False
    if str(entry.get("category", "")).lower() != "learning":
        return False
    codes = _entry_course_codes(entry)
    return bool(codes and codes & _assigned_courses(actor_user_id))


def _can_manage_gap(actor_role: str, actor_user_id: str, gap: dict) -> bool:
    if actor_role == "admin":
        return True
    if actor_role != "lecturer":
        return False
    codes = _gap_course_codes(gap)
    return bool(codes and codes & _assigned_courses(actor_user_id))


def _filter_entries_for_actor(entries: list[dict], actor_role: str, actor_user_id: str) -> list[dict]:
    if actor_role == "admin":
        return entries
    return [entry for entry in entries if _can_manage_entry(actor_role, actor_user_id, entry)]


def _filter_gaps_for_actor(gaps: list[dict], actor_role: str, actor_user_id: str) -> list[dict]:
    if actor_role == "admin":
        return gaps
    return [gap for gap in gaps if _can_manage_gap(actor_role, actor_user_id, gap)]


def _knowledge_entry_or_404(entry_id: str) -> dict:
    entry = next(
        (item for item in knowledge_library()["entries"] if item.get("id") == entry_id),
        None,
    )
    if entry is None:
        raise HTTPException(status_code=404, detail=f"Knowledge entry ID '{entry_id}' was not found.")
    return entry


def _knowledge_gap_or_404(gap_id: str) -> dict:
    gap = next(
        (item for item in knowledge_gap_library()["gaps"] if item.get("id") == gap_id),
        None,
    )
    if gap is None:
        raise HTTPException(status_code=404, detail=f"Knowledge gap ID '{gap_id}' was not found.")
    return gap


def _scope_library_payload(payload: dict, actor_role: str, actor_user_id: str) -> dict:
    scoped = dict(payload)
    scoped["entries"] = _filter_entries_for_actor(payload.get("entries", []), actor_role, actor_user_id)
    scoped["actor_scope"] = {
        "role": actor_role,
        "user_id": actor_user_id,
        "managed_entry_count": len(scoped["entries"]),
    }
    return scoped


@app.post("/api/admin/knowledge/entries")
def admin_create_knowledge_entry(payload: KnowledgeEntryRequest) -> dict:
    data = _payload_dict(payload)
    actor_role, actor_user_id = _actor_identity(
        data.pop("actor_role", None),
        data.pop("actor_user_id", None),
    )
    data = _apply_actor_metadata(data, actor_role, actor_user_id, creating=True)
    if not _can_manage_entry(actor_role, actor_user_id, data):
        raise HTTPException(
            status_code=403,
            detail="Lecturers can only create learning entries for their assigned course codes. Admins handle school-wide knowledge.",
        )
    try:
        result = save_knowledge_entry(data)
    except KnowledgeSaveError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if result.get("saved") is not True:
        raise HTTPException(status_code=422, detail=result)
    event = record_knowledge_audit(
        actor_role=actor_role,
        actor_user_id=actor_user_id,
        action="create",
        entry=result.get("entry"),
        notes="Knowledge entry created.",
    )
    scoped = _scope_library_payload(result, actor_role, actor_user_id)
    scoped["audit_event"] = event
    return scoped


@app.get("/api/admin/knowledge/entries")
def admin_list_knowledge_entries(
    actor_role: str | None = Query(default=None),
    actor_user_id: str | None = Query(default=None),
) -> dict:
    payload = knowledge_library()
    if actor_role is None and actor_user_id is None:
        return payload
    role, user_id = _actor_identity(actor_role, actor_user_id)
    return _scope_library_payload(payload, role, user_id)


@app.put("/api/admin/knowledge/entries/{entry_id}")
def admin_update_knowledge_entry(entry_id: str, payload: KnowledgeEntryRequest) -> dict:
    data = _payload_dict(payload)
    actor_role, actor_user_id = _actor_identity(
        data.pop("actor_role", None),
        data.pop("actor_user_id", None),
    )
    data = _apply_actor_metadata(data, actor_role, actor_user_id, creating=False)
    existing = _knowledge_entry_or_404(entry_id)
    if not _can_manage_entry(actor_role, actor_user_id, existing) or not _can_manage_entry(actor_role, actor_user_id, data):
        raise HTTPException(
            status_code=403,
            detail="Lecturers can only update learning entries for their assigned course codes. Admins handle school-wide knowledge.",
        )
    try:
        result = update_knowledge_entry(entry_id, data)
    except KnowledgeNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except KnowledgeSaveError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if result.get("saved") is not True:
        raise HTTPException(status_code=422, detail=result)
    event = record_knowledge_audit(
        actor_role=actor_role,
        actor_user_id=actor_user_id,
        action="update",
        entry=result.get("entry"),
        notes="Knowledge entry updated.",
    )
    scoped = _scope_library_payload(result, actor_role, actor_user_id)
    scoped["audit_event"] = event
    return scoped


@app.delete("/api/admin/knowledge/entries/{entry_id}")
def admin_delete_knowledge_entry(
    entry_id: str,
    actor_role: str | None = Query(default=None),
    actor_user_id: str | None = Query(default=None),
) -> dict:
    role, user_id = _actor_identity(actor_role, actor_user_id)
    existing = _knowledge_entry_or_404(entry_id)
    if not _can_manage_entry(role, user_id, existing):
        raise HTTPException(
            status_code=403,
            detail="Lecturers can only delete learning entries for their assigned course codes. Admins handle school-wide knowledge.",
        )
    try:
        result = delete_knowledge_entry(entry_id)
    except KnowledgeNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except KnowledgeSaveError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if result.get("deleted") is not True:
        raise HTTPException(status_code=422, detail=result)
    event = record_knowledge_audit(
        actor_role=role,
        actor_user_id=user_id,
        action="delete",
        entry=existing,
        entry_id=entry_id,
        notes="Knowledge entry deleted.",
    )
    scoped = _scope_library_payload(result, role, user_id)
    scoped["audit_event"] = event
    return scoped


@app.get("/api/admin/knowledge/audit")
def admin_list_knowledge_audit(
    actor_role: str | None = Query(default=None),
    actor_user_id: str | None = Query(default=None),
    limit: int = Query(default=40, ge=1, le=200),
) -> dict:
    role, user_id = _actor_identity(actor_role, actor_user_id)
    payload = knowledge_audit_library(limit=limit)
    if role == "admin":
        payload["actor_scope"] = {"role": role, "user_id": user_id}
        return payload
    events = [
        event
        for event in payload.get("events", [])
        if event.get("actor_user_id") == user_id
    ]
    return {
        **payload,
        "events": events,
        "actor_scope": {"role": role, "user_id": user_id},
    }


@app.get("/api/admin/knowledge/gaps")
def admin_list_knowledge_gaps(
    actor_role: str | None = Query(default=None),
    actor_user_id: str | None = Query(default=None),
) -> dict:
    payload = knowledge_gap_library()
    if actor_role is None and actor_user_id is None:
        return payload
    role, user_id = _actor_identity(actor_role, actor_user_id)
    scoped = dict(payload)
    scoped["gaps"] = _filter_gaps_for_actor(payload.get("gaps", []), role, user_id)
    scoped["open_count"] = sum(1 for item in scoped["gaps"] if item.get("status") == "open")
    scoped["gap_count"] = len(scoped["gaps"])
    scoped["actor_scope"] = {"role": role, "user_id": user_id}
    return scoped


@app.patch("/api/admin/knowledge/gaps/{gap_id}")
def admin_update_knowledge_gap(gap_id: str, payload: KnowledgeGapUpdateRequest) -> dict:
    data = _payload_update_dict(payload)
    actor_role, actor_user_id = _actor_identity(
        data.pop("actor_role", None),
        data.pop("actor_user_id", None),
    )
    existing = _knowledge_gap_or_404(gap_id)
    if not _can_manage_gap(actor_role, actor_user_id, existing):
        raise HTTPException(
            status_code=403,
            detail="Lecturers can only review knowledge gaps for their assigned course codes. Admins handle school-wide gaps.",
        )
    try:
        return update_knowledge_gap(gap_id, **data)
    except KnowledgeNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except KnowledgeSaveError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/api/chat", response_model=ChatResponse)
def chat(payload: ChatRequest) -> ChatResponse:
    return generate_answer(
        payload.role,
        payload.user_id,
        payload.message,
        [{"speaker": turn.speaker, "content": turn.content} for turn in payload.history],
        payload.attachment_ids,
    )


@app.post("/api/admissions/estimate", response_model=AdmissionEstimateResponse)
def admission_estimate(payload: AdmissionEstimateRequest) -> AdmissionEstimateResponse:
    return estimate_admission_readiness(payload)


@app.get("/api/student/{user_id}/dashboard")
def student_dashboard(user_id: str) -> dict:
    profile = student_profile(user_id)
    if profile is None:
        return {"found": False, "message": "Student profile not found."}
    return {"found": True, "profile": profile}


@app.get("/api/student/{user_id}/learning-profile")
def student_learning_profile(user_id: str) -> dict:
    return learning_profile(user_id)


@app.get("/api/student/{user_id}/progress-history")
def student_learning_history(user_id: str) -> dict:
    return student_progress_history(user_id)


@app.post("/api/learning-sessions")
def create_learning_session(payload: LearningSessionStartRequest) -> dict:
    return start_learning_session(payload.user_id, payload.course_code, payload.topic)


@app.get("/api/learning-sessions/{session_id}")
def read_learning_session(session_id: str) -> dict:
    return get_learning_session(session_id)


@app.post("/api/learning-sessions/{session_id}/answer")
def answer_learning_session(session_id: str, payload: LearningAnswerRequest) -> dict:
    return submit_learning_answer(session_id, payload.answer)


@app.get("/api/lecturer/{user_id}/insights")
def lecturer_insights(user_id: str) -> dict:
    profile = lecturer_profile(user_id)
    if profile is None:
        return {"found": False, "message": "Lecturer profile not found."}
    enriched_profile = dict(profile)
    enriched_profile["learning_insights"] = lecturer_course_learning_insights(profile["assigned_courses"])
    return {"found": True, "profile": enriched_profile}


WEB_BUILD = Path(__file__).resolve().parents[2] / "eve_app" / "build" / "web"
WEB_CACHE_HEADERS = {"Cache-Control": "no-store, max-age=0"}
GZIP_STATIC_SUFFIXES = {".html", ".js", ".mjs", ".json", ".css", ".wasm"}


def _web_file_response(path: Path, request: Request | None = None) -> FileResponse | Response:
    accepts_gzip = request is not None and "gzip" in request.headers.get("accept-encoding", "").lower()
    if accepts_gzip and path.suffix.lower() in GZIP_STATIC_SUFFIXES:
        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        headers = {
            **WEB_CACHE_HEADERS,
            "Content-Encoding": "gzip",
            "Vary": "Accept-Encoding",
        }
        return Response(
            gzip.compress(path.read_bytes(), compresslevel=6),
            media_type=content_type,
            headers=headers,
        )
    return FileResponse(path, headers=WEB_CACHE_HEADERS)


@app.get("/", include_in_schema=False, response_model=None)
def web_index(request: Request) -> FileResponse | Response:
    index = WEB_BUILD / "index.html"
    if not index.exists():
        raise HTTPException(status_code=404, detail="Flutter web build not found. Run flutter build web first.")
    return _web_file_response(index, request)


@app.get("/{asset_path:path}", include_in_schema=False, response_model=None)
def web_asset(asset_path: str, request: Request) -> FileResponse | Response:
    if asset_path.startswith("api/"):
        raise HTTPException(status_code=404, detail="API route not found.")

    if asset_path == "assets/esui-logo.png":
        logo = WEB_BUILD / "assets" / "assets" / "esui-logo.png"
        if logo.exists():
            return _web_file_response(logo, request)

    root = WEB_BUILD.resolve()
    target = (WEB_BUILD / asset_path).resolve()
    try:
        target.relative_to(root)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="File not found.") from exc

    if target.is_file():
        return _web_file_response(target, request)

    index = WEB_BUILD / "index.html"
    if index.exists():
        return _web_file_response(index, request)
    raise HTTPException(status_code=404, detail="Flutter web build not found. Run flutter build web first.")
