from __future__ import annotations

import base64
import binascii
import html
import json
import re
import uuid
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
UPLOAD_DIR = ROOT / "storage" / "uploads"
UPLOAD_INDEX = UPLOAD_DIR / "attachments.json"
MAX_UPLOAD_BYTES = 5 * 1024 * 1024
MAX_EXTRACTED_CHARS = 12000
ALLOWED_TYPES = {
    "text/plain",
    "text/markdown",
    "text/csv",
    "application/json",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "image/png",
    "image/jpeg",
    "image/webp",
}


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _safe_filename(name: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", name.strip())[:120]
    return cleaned or "upload.bin"


def _load_index() -> dict[str, Any]:
    if not UPLOAD_INDEX.exists():
        return {"attachments": []}
    try:
        return json.loads(UPLOAD_INDEX.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"attachments": []}


def _save_index(payload: dict[str, Any]) -> None:
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    UPLOAD_INDEX.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def _kind(content_type: str) -> str:
    if content_type.startswith("image/"):
        return "image"
    if content_type == "application/pdf":
        return "pdf"
    if "wordprocessingml" in content_type or content_type == "application/msword":
        return "document"
    return "text"


def _decode_text(data: bytes) -> str:
    return data.decode("utf-8", errors="replace")


def _extract_docx_text(data: bytes) -> str:
    temp = UPLOAD_DIR / f"docx_extract_{uuid.uuid4().hex}.docx"
    temp.write_bytes(data)
    try:
        with zipfile.ZipFile(temp) as archive:
            document = archive.read("word/document.xml").decode("utf-8", errors="ignore")
    except Exception:
        return "Word document uploaded. Text extraction was not available for this file."
    finally:
        temp.unlink(missing_ok=True)
    document = re.sub(r"<[^>]+>", " ", document)
    return re.sub(r"\s+", " ", html.unescape(document)).strip()


def _extract_pdf_text(data: bytes) -> str:
    strings = re.findall(rb"[\x20-\x7E]{5,}", data)
    text = " ".join(part.decode("latin-1", errors="ignore") for part in strings[:240])
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return "PDF uploaded. Full PDF text extraction is limited in this demo."
    return text


def _extract_text(filename: str, content_type: str, data: bytes) -> str:
    lower = filename.lower()
    if content_type.startswith("image/"):
        return ""
    if content_type in {"text/plain", "text/markdown", "text/csv", "application/json"} or lower.endswith(
        (".txt", ".md", ".csv", ".json")
    ):
        return _decode_text(data)
    if content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" or lower.endswith(".docx"):
        return _extract_docx_text(data)
    if content_type == "application/pdf" or lower.endswith(".pdf"):
        return _extract_pdf_text(data)
    return "File uploaded. Eve can use the filename and any extracted preview available in this demo."


def save_attachment(
    *,
    role: str,
    user_id: str,
    filename: str,
    content_type: str,
    base64_data: str,
) -> dict[str, Any]:
    normalized_type = (content_type or "application/octet-stream").split(";")[0].strip().lower()
    if normalized_type not in ALLOWED_TYPES:
        raise ValueError("Unsupported upload type. Use images, text, CSV, JSON, PDF, or DOCX files.")
    try:
        data = base64.b64decode(base64_data, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("Upload data was not valid base64.") from exc
    if not data:
        raise ValueError("The uploaded file was empty.")
    if len(data) > MAX_UPLOAD_BYTES:
        raise ValueError("Uploads are limited to 5 MB in this demo.")

    attachment_id = f"att-{uuid.uuid4().hex[:12]}"
    safe_name = _safe_filename(filename)
    user_dir = UPLOAD_DIR / _safe_filename(user_id)
    user_dir.mkdir(parents=True, exist_ok=True)
    stored_path = user_dir / f"{attachment_id}-{safe_name}"
    stored_path.write_bytes(data)

    extracted_text = _extract_text(safe_name, normalized_type, data)[:MAX_EXTRACTED_CHARS]
    preview = extracted_text[:420].strip()
    if normalized_type.startswith("image/"):
        preview = "Image uploaded for Eve vision analysis."

    record = {
        "id": attachment_id,
        "role": role,
        "user_id": user_id,
        "filename": safe_name,
        "content_type": normalized_type,
        "kind": _kind(normalized_type),
        "size": len(data),
        "stored_path": str(stored_path),
        "created_at": _now_iso(),
        "extracted_text": extracted_text,
        "preview": preview,
    }
    payload = _load_index()
    payload.setdefault("attachments", []).append(record)
    _save_index(payload)
    return _public_attachment(record)


def _public_attachment(record: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": record["id"],
        "filename": record["filename"],
        "content_type": record["content_type"],
        "kind": record["kind"],
        "size": record["size"],
        "created_at": record["created_at"],
        "preview": record.get("preview", ""),
    }


def list_attachments(role: str, user_id: str) -> list[dict[str, Any]]:
    return [
        _public_attachment(record)
        for record in reversed(_load_index().get("attachments", []))
        if record.get("role") == role and record.get("user_id") == user_id
    ]


def attachment_context(role: str, user_id: str, attachment_ids: list[str]) -> list[dict[str, Any]]:
    if not attachment_ids:
        return []
    allowed_ids = set(attachment_ids[:5])
    records = []
    for record in _load_index().get("attachments", []):
        if (
            record.get("id") in allowed_ids
            and record.get("role") == role
            and record.get("user_id") == user_id
        ):
            records.append(record)
    return records


def attachment_image_inputs(records: list[dict[str, Any]]) -> list[dict[str, str]]:
    inputs: list[dict[str, str]] = []
    for record in records:
        if record.get("kind") != "image":
            continue
        path = Path(record.get("stored_path", ""))
        if not path.exists():
            continue
        encoded = base64.b64encode(path.read_bytes()).decode("ascii")
        inputs.append(
            {
                "type": "input_image",
                "image_url": f"data:{record['content_type']};base64,{encoded}",
                "detail": "auto",
            }
        )
    return inputs[:3]


def attachment_text_context(records: list[dict[str, Any]]) -> str:
    if not records:
        return "No uploaded files are attached to this question."
    lines: list[str] = []
    for index, record in enumerate(records[:5], start=1):
        lines.append(
            "\n".join(
                [
                    f"Attachment {index}: {record['filename']}",
                    f"Type: {record['content_type']}",
                    f"Kind: {record['kind']}",
                    f"Preview/extracted text: {record.get('extracted_text') or record.get('preview') or 'No extracted text.'}",
                ]
            )
        )
    return "\n\n".join(lines)
