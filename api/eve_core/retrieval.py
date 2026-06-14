from __future__ import annotations

import math
import re
from collections import Counter
from dataclasses import dataclass
from typing import Iterable

from .repository import knowledge_items


TOKEN_RE = re.compile(r"[a-zA-Z0-9]+")


@dataclass(frozen=True)
class RetrievalHit:
    item: dict
    score: float


def tokenize(text: str) -> list[str]:
    return [token.lower() for token in TOKEN_RE.findall(text)]


def _cosine(query: Iterable[str], document: Iterable[str]) -> float:
    q = Counter(query)
    d = Counter(document)
    if not q or not d:
        return 0.0
    overlap = set(q) & set(d)
    dot = sum(q[token] * d[token] for token in overlap)
    q_norm = math.sqrt(sum(value * value for value in q.values()))
    d_norm = math.sqrt(sum(value * value for value in d.values()))
    return dot / (q_norm * d_norm)


def allowed_audiences(role: str) -> set[str]:
    if role == "guest":
        return {"public", "guest"}
    if role == "student":
        return {"public", "guest", "student"}
    if role == "admin":
        return {"public", "guest", "student", "lecturer", "admin"}
    return {"public", "lecturer"}


def retrieve(message: str, role: str, limit: int = 5) -> list[RetrievalHit]:
    query_tokens = tokenize(message)
    security_query = bool(
        {
            "security",
            "privacy",
            "private",
            "authorization",
            "authorisation",
            "guardrail",
            "prompt",
            "injection",
            "records",
        }
        & set(query_tokens)
    )
    hits: list[RetrievalHit] = []
    for item in knowledge_items():
        if not set(item["audience"]) & allowed_audiences(role):
            continue
        if item.get("category") == "security" and not security_query:
            continue
        weighted_text = " ".join(
            [
                item["title"],
                item["category"],
                item["summary"],
                item["content"],
                " ".join(item.get("tags", [])),
            ]
        )
        score = _cosine(query_tokens, tokenize(weighted_text))
        if score > 0:
            hits.append(RetrievalHit(item, score))
    return sorted(hits, key=lambda hit: hit.score, reverse=True)[:limit]
