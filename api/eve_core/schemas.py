from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


Role = Literal["guest", "student", "lecturer", "admin"]


class ChatTurn(BaseModel):
    speaker: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=4000)


class ChatRequest(BaseModel):
    role: Role
    user_id: str = Field(min_length=3)
    message: str = Field(min_length=1, max_length=4000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=12)
    attachment_ids: list[str] = Field(default_factory=list, max_length=5)


class AttachmentUploadRequest(BaseModel):
    role: Role
    user_id: str = Field(min_length=3)
    filename: str = Field(min_length=1, max_length=180)
    content_type: str = Field(min_length=3, max_length=140)
    base64_data: str = Field(min_length=1)


class AttachmentResponse(BaseModel):
    id: str
    filename: str
    content_type: str
    kind: str
    size: int
    created_at: str
    preview: str = ""


class PeerNoteCreateRequest(BaseModel):
    user_id: str = Field(min_length=3, max_length=120)
    course_code: str = Field(min_length=3, max_length=20)
    title: str = Field(min_length=4, max_length=140)
    summary: str = Field(min_length=20, max_length=500)
    content: str = Field(min_length=80, max_length=6000)


class PeerNoteReviewRequest(BaseModel):
    actor_role: Literal["lecturer", "admin"]
    actor_user_id: str = Field(min_length=3, max_length=120)
    status: Literal["pending", "approved", "rejected", "needs_revision"]
    review_notes: str | None = Field(default="", max_length=1000)


class Source(BaseModel):
    title: str
    category: str
    audience: list[str]
    source_url: str | None = None
    source_label: str = "Curated ESUI Knowledge"
    verified: bool = True
    updated: str | None = None


class ChatResponse(BaseModel):
    answer: str
    role: Role
    user_id: str
    intent: str
    blocked: bool = False
    confidence: float = 0.0
    sources: list[Source] = []
    next_actions: list[str] = []
    audit: dict[str, Any] = {}


class AdmissionEstimateRequest(BaseModel):
    course: str = Field(min_length=2)
    jamb_score: int = Field(ge=0, le=400)
    english: str
    mathematics: str
    science: str
    fourth_subject: str


class AdmissionEstimateResponse(BaseModel):
    course: str
    readiness_score: int
    band: str
    reasons: list[str]
    recommendations: list[str]


class LearningSessionStartRequest(BaseModel):
    user_id: str = Field(min_length=3)
    course_code: str = Field(min_length=3)
    topic: str | None = None


class LearningAnswerRequest(BaseModel):
    answer: str = Field(min_length=1, max_length=2000)


class KnowledgeValidateRequest(BaseModel):
    entries: list[dict[str, Any]] = Field(default_factory=list)


class KnowledgeEntryRequest(BaseModel):
    actor_role: Role | None = None
    actor_user_id: str | None = Field(default=None, max_length=120)
    id: str | None = Field(default=None, max_length=120)
    title: str = Field(min_length=4, max_length=160)
    category: str = Field(min_length=2, max_length=60)
    audience: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    summary: str = Field(min_length=20, max_length=600)
    content: str = Field(min_length=40, max_length=6000)
    source_url: str | None = Field(default=None, max_length=500)
    updated: str | None = Field(default=None, max_length=20)
    approval_status: Literal["demo", "draft", "approved", "needs_review"] | None = None
    review_notes: str | None = Field(default=None, max_length=1000)
    created_by: str | None = Field(default=None, max_length=120)
    created_by_role: str | None = Field(default=None, max_length=40)
    created_at: str | None = Field(default=None, max_length=40)
    updated_by: str | None = Field(default=None, max_length=120)
    updated_by_role: str | None = Field(default=None, max_length=40)
    reviewed_by: str | None = Field(default=None, max_length=120)
    reviewed_at: str | None = Field(default=None, max_length=40)


class KnowledgeGapUpdateRequest(BaseModel):
    actor_role: Role | None = None
    actor_user_id: str | None = Field(default=None, max_length=120)
    status: Literal["open", "reviewing", "converted", "dismissed"] | None = None
    notes: str | None = Field(default=None, max_length=1000)
    converted_entry_id: str | None = Field(default=None, max_length=120)
