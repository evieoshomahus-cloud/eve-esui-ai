from __future__ import annotations

import re
from dataclasses import dataclass

from .repository import lecturer_profile, student_profile, user_profile


PROMPT_ATTACK_PATTERNS = [
    r"ignore (all )?(previous|prior|above) instructions",
    r"reveal (the )?(system|developer|hidden) prompt",
    r"bypass (security|guardrails|authentication|authorization)",
    r"act as (an )?(admin|root|developer|lecturer)",
    r"jailbreak",
    r"dump .*data",
    r"show .*database",
    r"print .*environment",
]

SENSITIVE_DATA_PATTERNS = [
    r"\ball students\b",
    r"\banother student\b",
    r"\bother student\b",
    r"\bstu-[a-z]{3}-\d{3}\b",
    r"\blec-[a-z]{3}-\d{3}\b",
]


@dataclass(frozen=True)
class SecurityDecision:
    allowed: bool
    label: str
    reason: str


def inspect_prompt(message: str) -> SecurityDecision:
    normalized = message.lower()
    for pattern in PROMPT_ATTACK_PATTERNS:
        if re.search(pattern, normalized):
            return SecurityDecision(
                allowed=False,
                label="prompt_injection",
                reason="The request tries to override instructions, expose hidden data, or bypass authorization.",
            )
    return SecurityDecision(True, "safe_prompt", "No prompt attack pattern detected.")


def enforce_role(role: str, user_id: str) -> SecurityDecision:
    profile = user_profile(user_id)
    if profile is None:
        return SecurityDecision(False, "unknown_user", "The selected demo account does not exist.")
    if profile["role"] != role:
        return SecurityDecision(False, "role_mismatch", "The selected role does not match the signed-in account.")
    return SecurityDecision(True, "role_verified", "Role and account match.")


def enforce_scope(role: str, user_id: str, message: str) -> SecurityDecision:
    normalized = message.lower()

    if role == "guest" and any(term in normalized for term in ["my cgpa", "my scores", "my fees", "my record"]):
        return SecurityDecision(False, "guest_private_data", "Guest mode can only access public information.")

    if role == "student":
        mentioned_ids = set(re.findall(r"\bstu-[a-z]{3}-\d{3}\b", normalized))
        mentioned_ids.discard(user_id)
        asks_for_others = any(re.search(pattern, normalized) for pattern in SENSITIVE_DATA_PATTERNS[:3])
        if mentioned_ids or asks_for_others:
            return SecurityDecision(False, "student_scope_violation", "Students can only access their own records.")
        if student_profile(user_id) is None:
            return SecurityDecision(False, "student_record_missing", "No student record is linked to this account.")

    if role == "lecturer":
        profile = lecturer_profile(user_id)
        if profile is None:
            return SecurityDecision(False, "lecturer_record_missing", "No lecturer record is linked to this account.")

    return SecurityDecision(True, "scope_verified", "Request is within the user's allowed scope.")


def authorize(role: str, user_id: str, message: str) -> SecurityDecision:
    for decision in (inspect_prompt(message), enforce_role(role, user_id), enforce_scope(role, user_id, message)):
        if not decision.allowed:
            return decision
    return SecurityDecision(True, "authorized", "All security checks passed.")

