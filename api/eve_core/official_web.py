from __future__ import annotations

import html
import re
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from html.parser import HTMLParser
from typing import Any

from .retrieval import RetrievalHit, tokenize


ALLOWED_PAGES = [
    {
        "title": "ESUI Official Website",
        "url": "https://edouniversity.edu.ng/",
        "tags": ["home", "news", "announcement", "calendar", "latest", "school"],
    },
    {
        "title": "About Edo State University Iyamho",
        "url": "https://edouniversity.edu.ng/home/about",
        "tags": ["about", "history", "vision", "mission", "university"],
    },
    {
        "title": "ESUI Programmes and Study Options",
        "url": "https://edouniversity.edu.ng/home/programs",
        "tags": ["programme", "programmes", "courses", "admission", "undergraduate", "postgraduate", "jupeb"],
    },
    {
        "title": "ESUI Undergraduate Admission Application",
        "url": "https://edouniversity.edu.ng/admissions/undergraduate",
        "tags": ["admission", "undergraduate", "utme", "direct entry", "transfer", "requirements", "computer science"],
    },
    {
        "title": "ESUI Academic Calendar",
        "url": "https://edouniversity.edu.ng/academic-calender",
        "tags": ["academic calendar", "semester", "resumption", "revision", "examination", "convocation", "dates"],
    },
    {
        "title": "ESUI Undergraduate Fee Description",
        "url": "https://edouniversity.edu.ng/ug-fee-description",
        "tags": ["fees", "school fees", "undergraduate", "payment", "accommodation", "fee description"],
    },
    {
        "title": "ESUI Quick Pay",
        "url": "https://edouniversity.edu.ng/quickpay",
        "tags": ["quick pay", "payment", "transaction", "receipt", "certificate", "transcript", "verify payment"],
    },
    {
        "title": "ESUI AIS Login",
        "url": "https://edouniversity.edu.ng/Identity/Account/Login",
        "tags": ["ais", "student portal", "login", "school fees", "student account", "payment"],
    },
]

CACHE_SECONDS = 15 * 60
MAX_PAGE_TEXT = 4500


@dataclass
class CachedPage:
    fetched_at: float
    text: str
    ok: bool
    error: str | None = None


class _TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._skip_depth = 0
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in {"script", "style", "noscript", "svg"}:
            self._skip_depth += 1
        if tag in {"p", "br", "li", "h1", "h2", "h3", "h4", "section", "article"}:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "noscript", "svg"} and self._skip_depth:
            self._skip_depth -= 1
        if tag in {"p", "li", "h1", "h2", "h3", "h4"}:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if self._skip_depth:
            return
        cleaned = data.strip()
        if cleaned:
            self.parts.append(cleaned)

    def text(self) -> str:
        joined = html.unescape(" ".join(self.parts))
        joined = re.sub(r"\s+", " ", joined)
        return joined.strip()


_CACHE: dict[str, CachedPage] = {}


def _fetch_page(url: str) -> CachedPage:
    cached = _CACHE.get(url)
    now = time.time()
    if cached and now - cached.fetched_at < CACHE_SECONDS:
        return cached

    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Eve ESUI academic assistant prototype/1.0",
            "Accept": "text/html,application/xhtml+xml",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            content_type = response.headers.get("Content-Type", "")
            if "text/html" not in content_type and "application/xhtml+xml" not in content_type:
                page = CachedPage(now, "", False, f"Unsupported content type: {content_type}")
            else:
                raw = response.read(800_000).decode("utf-8", errors="ignore")
                parser = _TextExtractor()
                parser.feed(raw)
                page = CachedPage(now, parser.text()[:MAX_PAGE_TEXT], True)
    except urllib.error.URLError as error:
        page = CachedPage(now, "", False, str(error))
    except Exception as error:  # noqa: BLE001 - live website lookup must fail safely.
        page = CachedPage(now, "", False, str(error))

    _CACHE[url] = page
    return page


def _score(query_tokens: list[str], page: dict[str, Any], text: str) -> float:
    searchable = " ".join([page["title"], " ".join(page["tags"]), text]).lower()
    if not query_tokens or not searchable:
        return 0.0
    matches = sum(1 for token in set(query_tokens) if token in searchable)
    tag_bonus = sum(1 for token in set(query_tokens) if token in page["tags"]) * 0.25
    return min(1.0, (matches / max(4, len(set(query_tokens)))) + tag_bonus)


def official_website_hits(message: str, role: str, limit: int = 3) -> list[RetrievalHit]:
    if role not in {"guest", "student", "lecturer", "admin"}:
        return []

    query_tokens = tokenize(message)
    hits: list[RetrievalHit] = []
    for page in ALLOWED_PAGES:
        fetched = _fetch_page(page["url"])
        if not fetched.ok or not fetched.text:
            continue
        score = _score(query_tokens, page, fetched.text)
        if score <= 0:
            continue
        hits.append(
            RetrievalHit(
                item={
                    "title": f"Official ESUI Website - {page['title']}",
                    "category": "official_web",
                    "audience": ["public", "guest", "student", "lecturer", "admin"],
                    "summary": fetched.text[:420],
                    "content": fetched.text,
                    "source_url": page["url"],
                    "tags": page["tags"],
                },
                score=score,
            )
        )
    return sorted(hits, key=lambda hit: hit.score, reverse=True)[:limit]
