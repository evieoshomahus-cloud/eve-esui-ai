from __future__ import annotations

import re
from typing import Any

from .attachments import attachment_context, attachment_image_inputs, attachment_text_context
from .llm import generate_with_openai, openai_configured
from .official_web import official_website_hits
from .progress_store import lecturer_course_learning_insights
from .repository import course_analytics, lecturer_profile, record_knowledge_gap, student_profile
from .retrieval import RetrievalHit, retrieve
from .schemas import ChatResponse, Source
from .security import authorize


def _has_terms(text: str, terms: list[str]) -> bool:
    for term in terms:
        if " " in term or "-" in term:
            if term in text:
                return True
            continue
        if re.search(rf"\b{re.escape(term)}s?\b", text):
            return True
    return False


def detect_intent(message: str) -> str:
    text = message.lower().strip()
    compact = re.sub(r"[^a-z0-9 ]+", "", text).strip()
    check_in_patterns = [
        "how are you",
        "how are u",
        "howre you",
        "how are you doing",
        "how are u doing",
        "how far",
        "whats up",
        "what is up",
        "sup",
    ]
    if compact in {"hi", "hello", "hey", "good morning", "good afternoon", "good evening"}:
        return "greeting"
    if compact in check_in_patterns or any(pattern in compact for pattern in check_in_patterns[:5]):
        return "check_in"
    if compact in {"thanks", "thank you", "okay", "ok", "alright"}:
        return "courtesy"
    if any(term in compact for term in ["who are you", "what can you do", "help me", "how can you help"]):
        return "capabilities"
    if _has_terms(text, ["admission", "jamb", "o-level", "olevel", "apply", "requirement"]):
        return "admission"
    if _has_terms(text, ["mock", "exam", "test", "question", "quiz", "past question"]):
        return "exam_practice"
    if _has_terms(text, ["academic calendar", "calendar", "resumption", "semester", "convocation", "deadline"]):
        return "calendar"
    if _has_terms(text, ["study plan", "revision plan", "reading plan", "3 day", "three day", "day plan"]) or (
        "plan" in text and _has_terms(text, ["weak", "topic", "course", "study", "revision"])
    ):
        return "study_plan"
    if _has_terms(text, ["cgpa", "weak", "carryover", "improve", "performance", "score"]):
        return "student_success"
    if _has_terms(text, ["fee", "dues", "payment", "pay"]):
        return "fees"
    if _has_terms(text, ["analytics", "insight", "best performing", "attendance", "assignment"]):
        return "lecturer_analytics"
    if _has_terms(text, ["timetable", "schedule", "plan my week", "calendar"]):
        return "planning"
    return "knowledge"


def _sources(hits: list[RetrievalHit]) -> list[Source]:
    def source_label(item: dict[str, Any]) -> str:
        if item.get("category") == "official_web":
            return "Live ESUI Website"
        tags = [str(tag).lower() for tag in item.get("tags", [])]
        if "demo" in tags or str(item.get("title", "")).lower().startswith("demo"):
            return "Demo Curated Knowledge"
        source_url = item.get("source_url")
        if not source_url or "edouniversity.edu.ng" in source_url:
            return "Curated ESUI Knowledge"
        return "External Reference"

    return [
        Source(
            title=hit.item["title"],
            category=hit.item["category"],
            audience=hit.item["audience"],
            source_url=hit.item.get("source_url"),
            source_label=source_label(hit.item),
            verified=hit.item.get("category") != "official_web" or bool(hit.item.get("source_url")),
            updated=hit.item.get("updated"),
        )
        for hit in hits
    ]


def _next_actions(role: str, intent: str) -> list[str]:
    if role == "guest":
        return [
            "Estimate admission readiness.",
            "Ask for a department requirement.",
            "Ask for the application roadmap.",
        ]
    if role == "student":
        return [
            "Generate a mock test for a registered course.",
            "Ask for a revision plan from your weak topics.",
            "Review fee and departmental-dues status.",
        ]
    if role == "admin":
        return [
            "Review unanswered knowledge gaps.",
            "Audit payment and portal guidance.",
            "Add approved school-wide information.",
        ]
    return [
        "Review analytics for an assigned course.",
        "Generate exam questions by topic and difficulty.",
        "Ask for teaching intervention suggestions.",
    ]


def _knowledge_answer(hits: list[RetrievalHit]) -> tuple[str, float]:
    if not hits:
        return (
            "I do not have enough verified ESUI context to answer that confidently yet. Try asking with a department, admission, fee, LMS, timetable, or course keyword, and I will ground the answer in the knowledge base.",
            0.18,
        )
    lines = ["I found a few verified ESUI notes that help here:"]
    for hit in hits[:3]:
        lines.append(f"- {hit.item['summary']}")
    lines.append("For anything involving current fees, dates, or final admission decisions, confirm through the official ESUI channel.")
    return "\n".join(lines), round(min(0.96, 0.58 + hits[0].score), 2)


def _wants_live_school_info(message: str) -> bool:
    text = message.lower()
    return _has_terms(
        text,
        [
            "latest",
            "current",
            "currently",
            "recent",
            "today",
            "now",
            "news",
            "announcement",
            "update",
            "deadline",
            "date",
            "calendar",
            "convocation",
            "website",
            "site",
            "portal",
            "official",
            "application form",
            "admission form",
            "closing date",
            "2025",
            "2026",
        ],
    )


def _public_info_hits(message: str, role: str, intent: str, local_hits: list[RetrievalHit]) -> list[RetrievalHit]:
    if intent not in {"knowledge", "admission", "calendar"}:
        return []
    local_match_is_weak = not local_hits or local_hits[0].score < 0.18
    if not _wants_live_school_info(message) and not local_match_is_weak:
        return []
    hits = official_website_hits(message, role)
    if intent == "calendar":
        calendar_hits = [
            hit
            for hit in hits
            if "calendar" in f"{hit.item.get('title', '')} {' '.join(hit.item.get('tags', []))}".lower()
        ]
        return calendar_hits or hits
    return hits


def _merge_hits(*hit_groups: list[RetrievalHit]) -> list[RetrievalHit]:
    merged: list[RetrievalHit] = []
    seen: set[str] = set()
    for group in hit_groups:
        for hit in group:
            key = hit.item.get("source_url") or hit.item.get("title")
            if key in seen:
                continue
            seen.add(key)
            merged.append(hit)
    return sorted(merged, key=lambda item: item.score, reverse=True)[:6]


def _intent_scoped_hits(intent: str, message: str, hits: list[RetrievalHit]) -> list[RetrievalHit]:
    if intent == "calendar":
        scoped = [
            hit
            for hit in hits
            if hit.item.get("category") == "planning"
            or "calendar" in f"{hit.item.get('title', '')} {' '.join(hit.item.get('tags', []))}".lower()
        ]
        return scoped or hits
    if intent == "study_plan":
        scoped = [
            hit
            for hit in hits
            if hit.item.get("category") == "learning"
        ]
        return scoped or hits
    if intent == "knowledge" and _has_terms(message.lower(), ["hostel", "appliance", "air fryer", "cooker", "room"]):
        scoped = [
            hit
            for hit in hits
            if hit.item.get("category") in {"student_life", "fees"}
            and _has_terms(
                f"{hit.item.get('title', '')} {' '.join(hit.item.get('tags', []))} {hit.item.get('summary', '')}".lower(),
                ["hostel", "appliance", "accommodation", "student affairs", "residence"],
            )
        ]
        return scoped or hits
    return hits


def _small_talk_answer(intent: str, role: str) -> tuple[str, float]:
    if intent == "greeting":
        if role == "guest":
            return (
                "Hello. I am Eve, ESUI's AI academic companion. You can ask me about admissions, programmes, requirements, fees, or how to prepare for your course of interest.",
                0.96,
            )
        if role == "student":
            return (
                "Hello. I am here with you. You can ask me to explain a topic, create a mock test, plan your week, review weak courses, or check your payment guidance.",
                0.96,
            )
        if role == "admin":
            return (
                "Hello. I am ready to help review school-wide knowledge, payment guidance, knowledge gaps, and source quality for Eve.",
                0.96,
            )
        return (
            "Hello. I am ready to help with course analytics, weak-topic review, assessment ideas, and teaching intervention suggestions.",
            0.96,
        )
    if intent == "check_in":
        if role == "guest":
            return (
                "I am doing well, thank you for asking. I am ready to help you explore ESUI admissions, programmes, requirements, fees, or course preparation.",
                0.96,
            )
        if role == "student":
            return (
                "I am doing well, and I am ready to help you make today a productive one. We can review your weak courses, generate a mock test, explain a topic, or plan your study time.",
                0.96,
            )
        if role == "admin":
            return (
                "I am doing well, thank you. I can help you review knowledge gaps, source coverage, payment links, and school-wide guidance before students rely on it.",
                0.96,
            )
        return (
            "I am doing well, thank you. I am ready to help you review course performance, generate assessment ideas, or plan a teaching intervention.",
            0.96,
        )
    if intent == "courtesy":
        return ("You are welcome. What would you like Eve to help you with next?", 0.94)
    return (
        "I can help with ESUI admissions, student academic support, mock exams, fee guidance, timetable planning, lecturer analytics, and secure role-based answers.",
        0.94,
    )


def _student_success(user_id: str) -> str:
    profile = student_profile(user_id)
    if not profile:
        return "No student dashboard is linked to this account."
    weak = [
        (code, info)
        for code, info in profile["courses"].items()
        if info["risk"] in {"medium", "high"}
    ]
    lines = [f"Academic pulse for {profile['name']}: CGPA {profile['cgpa']}."]
    if not weak:
        lines.append("No urgent risk area is visible. Keep using weekly retrieval practice and timed past-question drills.")
    else:
        lines.append("Priority intervention areas:")
        for code, info in weak:
            gaps = ", ".join(info["topic_gaps"]) or "general revision"
            lines.append(f"- {code}: CA {info['ca']}%, risk {info['risk']}; focus on {gaps}.")
    lines.append("Recommended Eve routine: 25 minutes concept review, 20 minutes past questions, 10 minutes error correction, four days per week.")
    return "\n".join(lines)


def _study_plan(message: str, user_id: str, role: str) -> str:
    if role != "student":
        return "Personalized study plans are available for signed-in student accounts."
    profile = student_profile(user_id)
    if not profile:
        return "No student learning profile is linked to this account."

    day_match = re.search(r"\b(\d{1,2})\s*-?\s*day\b", message.lower())
    days = int(day_match.group(1)) if day_match else 3
    days = max(1, min(days, 14))
    requested_course = _course_from_message(message)
    course_items = list(profile["courses"].items())
    if requested_course and requested_course in profile["courses"]:
        course_items = [(requested_course, profile["courses"][requested_course])]
    weak_courses = [
        (code, info)
        for code, info in course_items
        if info.get("risk") in {"medium", "high"} or info.get("topic_gaps")
    ]
    if not weak_courses:
        weak_courses = course_items[:2]

    lines = [f"{days}-day personalized study plan for {profile['name']}:"]
    lines.append("Goal: focus on weak topics, practise recall, and correct mistakes before moving on.")
    for index in range(days):
        code, info = weak_courses[index % len(weak_courses)]
        gaps = info.get("topic_gaps") or ["general revision"]
        topic = gaps[index % len(gaps)]
        lines.extend(
            [
                f"Day {index + 1}: {code} - {topic}",
                "- 25 minutes: review the concept from your note or lecturer material.",
                "- 20 minutes: solve two practice questions without checking answers first.",
                "- 10 minutes: write down mistakes and ask Eve to explain the weakest step.",
            ]
        )
    lines.append("After the plan, generate a short mock test for the weakest topic and compare your score with the previous attempt.")
    return "\n".join(lines)


def _student_context(user_id: str) -> str:
    profile = student_profile(user_id)
    if not profile:
        return ""
    course_lines = []
    for code, info in profile["courses"].items():
        gaps = ", ".join(info["topic_gaps"]) or "none recorded"
        course_lines.append(f"{code} ({info['title']}): CA {info['ca']}%, risk {info['risk']}, topic gaps: {gaps}")
    fees = ", ".join(f"{name}: {status}" for name, status in profile["fees"].items())
    timetable = "; ".join(f"{item['day']} {item['time']} {item['course']}" for item in profile["timetable"])
    return "\n".join(
        [
            f"Student name: {profile['name']}",
            f"Department: {profile['department']}",
            f"Level: {profile['level']}",
            f"CGPA: {profile['cgpa']}",
            f"Fees: {fees}",
            "Courses:",
            *course_lines,
            f"Timetable: {timetable}",
        ]
    )


def _lecturer_context(user_id: str, message: str) -> str:
    profile = lecturer_profile(user_id)
    if not profile:
        return ""
    lines = [
        f"Lecturer name: {profile['name']}",
        f"Department: {profile['department']}",
        f"Assigned courses: {', '.join(profile['assigned_courses'])}",
    ]
    course = _course_from_message(message)
    relevant_courses = [course] if course and course in profile["assigned_courses"] else profile["assigned_courses"]
    learning_insights = {
        item["course_code"]: item
        for item in lecturer_course_learning_insights(relevant_courses)["courses"]
    }
    for code in relevant_courses:
        analytics = course_analytics(code)
        if analytics:
            lines.append(
                f"{code}: current average {analytics['current_average']}%, previous average {analytics['previous_average']}%, "
                f"attendance {analytics['attendance_average']}%, assignment submission {analytics['assignment_submission_rate']}%, "
                f"weak topics {', '.join(analytics['weak_topics'])}, best students {', '.join(analytics['best_students'])}."
            )
        insight = learning_insights.get(code)
        if insight:
            weakest = insight["weakest_topic"]
            weakest_text = f"; weakest saved topic {weakest['topic']} at {weakest['average_score']}%" if weakest else ""
            lines.append(
                f"{code} saved Eve sessions: {insight['completed_sessions']}/{insight['total_sessions']} completed, "
                f"{insight['student_count']} tracked student(s), average quiz score {insight['average_score']}%{weakest_text}. "
                f"Suggested intervention: {insight['intervention']}"
            )
    return "\n".join(lines)


def _authorized_context(role: str, user_id: str, message: str) -> str:
    if role == "student":
        return _student_context(user_id)
    if role == "lecturer":
        return _lecturer_context(user_id, message)
    if role == "admin":
        return "Administrative demo session. Provide school-wide guidance only from curated or official sources. Do not expose private student records unless a production admin authorization layer is present."
    return "Public guest session. Do not include private student, lecturer, fee, or internal records."


def _fees(user_id: str, role: str) -> str:
    official_links = [
        "- AIS / student login for account-based student access: https://edouniversity.edu.ng/Identity/Account/Login",
        "- Undergraduate fee description: https://edouniversity.edu.ng/ug-fee-description",
        "- Quick Pay for certificate, transcript, entrepreneurship, and other listed payment items: https://edouniversity.edu.ng/quickpay",
    ]
    if role != "student":
        return "\n".join(
            [
                "Fee guidance is public, but personal fee status is only available to signed-in students.",
                "",
                "Official ESUI payment links:",
                *official_links,
                "",
                "Payment safety: only enter personal or payment details on pages that begin with https://edouniversity.edu.ng/ and keep your receipt/reference number.",
            ]
        )
    profile = student_profile(user_id)
    if not profile:
        return "No fee dashboard is linked to this account."
    lines = ["Fee and dues status:"]
    for key, value in profile["fees"].items():
        lines.append(f"- {key.replace('_', ' ').title()}: {value}")
    lines.extend(
        [
            "",
            "Official ESUI payment links:",
            *official_links,
            "",
            "Use only official ESUI payment channels, do not share your password, and retain receipts/reference numbers for clearance.",
        ]
    )
    return "\n".join(lines)


def _course_from_message(message: str) -> str | None:
    match = re.search(r"\b[A-Z]{2,4}\s?\d{3}\b", message.upper())
    return match.group(0).replace(" ", " ") if match else None


def _mock_exam(message: str, user_id: str, role: str) -> str:
    course = _course_from_message(message)
    if role == "student":
        profile = student_profile(user_id)
        if course and profile and course not in profile["courses"]:
            return f"{course} is not in your registered course list, so Eve will not generate private-course practice for it."
    label = course or "the selected course"
    return (
        f"Mock assessment for {label}\n"
        "1. Define the core concept and provide one ESUI-relevant example.\n"
        "2. Solve a scenario-based question and explain each step.\n"
        "3. Compare two methods, including one advantage and one limitation each.\n"
        "4. Identify a common misconception and correct it.\n"
        "5. Write a short applied answer that connects the topic to a real workplace problem.\n\n"
        "Marking guide: 40% correctness, 30% explanation, 20% application, 10% clarity."
    )


def _lecturer_analytics(message: str, user_id: str) -> str:
    profile = lecturer_profile(user_id)
    if not profile:
        return "No lecturer analytics profile is linked to this account."
    course = _course_from_message(message) or profile["assigned_courses"][0]
    if course not in profile["assigned_courses"]:
        return f"Access denied for {course}. This lecturer account is limited to {', '.join(profile['assigned_courses'])}."
    analytics = course_analytics(course)
    if not analytics:
        return f"No analytics are available for {course}."
    lines = [f"Lecturer insight for {course}:"]
    lines.append(f"- Current class average: {analytics['current_average']}%.")
    lines.append(f"- Previous cohort average: {analytics['previous_average']}%.")
    lines.append(f"- Attendance average: {analytics['attendance_average']}%.")
    lines.append(f"- Assignment submission: {analytics['assignment_submission_rate']}%.")
    lines.append(f"- Weak topics: {', '.join(analytics['weak_topics'])}.")
    lines.append(f"- Best-performing students: {', '.join(analytics['best_students'])}.")
    learning_insights = lecturer_course_learning_insights([course])["courses"]
    if learning_insights:
        insight = learning_insights[0]
        lines.append(f"- Saved Eve sessions: {insight['completed_sessions']}/{insight['total_sessions']} completed.")
        lines.append(f"- Average Eve quiz score: {insight['average_score']}%.")
        weakest = insight["weakest_topic"]
        if weakest:
            lines.append(f"- Weakest saved session topic: {weakest['topic']} at {weakest['average_score']}%.")
        lines.append(f"Suggested intervention: {insight['intervention']}")
    else:
        lines.append("Suggested intervention: run a short diagnostic quiz, then reteach the two weakest topics with worked examples.")
    return "\n".join(lines)


def _planning(user_id: str, role: str) -> str:
    if role != "student":
        return "Planning support is currently personalized for students with timetable data."
    profile = student_profile(user_id)
    if not profile:
        return "No timetable is linked to this account."
    lines = ["Suggested weekly academic plan:"]
    for item in profile["timetable"]:
        lines.append(f"- {item['day']} {item['time']}: {item['course']}; revise within 8 hours after class.")
    lines.append("- Friday: one mock quiz from Eve. Saturday: correct missed questions and summarize weak topics.")
    return "\n".join(lines)


def _attachment_fallback(records: list[dict[str, Any]]) -> str:
    names = ", ".join(record["filename"] for record in records[:5])
    lines = [
        f"I received the uploaded file{'s' if len(records) != 1 else ''}: {names}.",
        "OpenAI vision/conversation mode is needed for full image understanding, but I can still use any extracted text available in this demo.",
    ]
    for record in records[:3]:
        preview = (record.get("extracted_text") or record.get("preview") or "").strip()
        if preview:
            lines.append(f"\n{record['filename']} preview:\n{preview[:700]}")
    lines.append("\nAsk a specific question about the upload, such as what to summarize, explain, or turn into a study plan.")
    return "\n".join(lines)


def generate_answer(
    role: str,
    user_id: str,
    message: str,
    history: list[dict[str, str]] | None = None,
    attachment_ids: list[str] | None = None,
) -> ChatResponse:
    decision = authorize(role, user_id, message)
    if not decision.allowed:
        return ChatResponse(
            answer=f"I cannot help with that request. {decision.reason}",
            role=role,
            user_id=user_id,
            intent=decision.label,
            blocked=True,
            confidence=1.0,
            next_actions=_next_actions(role, decision.label),
            audit={"security": decision.label},
        )

    intent = detect_intent(message)
    casual_intents = {"greeting", "check_in", "courtesy", "capabilities"}
    structured_intents = {"student_success", "study_plan", "fees", "exam_practice", "lecturer_analytics", "planning"}
    hits = []
    website_hits: list[RetrievalHit] = []
    if intent not in casual_intents | structured_intents:
        local_hits = retrieve(message, role)
        website_hits = _public_info_hits(message, role, intent, local_hits)
        hits = _merge_hits(local_hits, website_hits)
    elif intent == "fees":
        hits = retrieve(f"{message} official ESUI payment portal quick pay AIS fee description", role)
    elif intent in {"student_success", "study_plan", "planning"}:
        retrieval_prompt = {
            "student_success": f"{message} personalized academic progress weak topics intervention tracking",
            "study_plan": f"{message} personalized academic progress weak topics course materials revision plan",
            "planning": f"{message} timetable study schedule academic planning weekly plan",
        }[intent]
        hits = retrieve(
            retrieval_prompt,
            role,
        )
    hits = _intent_scoped_hits(intent, message, hits)
    attached_records = attachment_context(role, user_id, attachment_ids or [])
    uploaded_context = attachment_text_context(attached_records)
    uploaded_images = attachment_image_inputs(attached_records)
    should_record_gap = intent in {"knowledge", "admission", "calendar"} and (
        not hits or hits[0].score < 0.12
    )

    if intent in casual_intents:
        answer, confidence = _small_talk_answer(intent, role)
    elif intent == "student_success" and role == "student":
        answer = _student_success(user_id)
        confidence = 0.91
    elif intent == "study_plan":
        answer = _study_plan(message, user_id, role)
        confidence = 0.9
    elif intent == "fees":
        answer = _fees(user_id, role)
        confidence = 0.86
    elif intent == "exam_practice":
        answer = _mock_exam(message, user_id, role)
        confidence = 0.82
    elif intent == "lecturer_analytics" and role == "lecturer":
        answer = _lecturer_analytics(message, user_id)
        confidence = 0.9
    elif intent == "planning":
        answer = _planning(user_id, role)
        confidence = 0.84
    else:
        answer, confidence = _knowledge_answer(hits)

    gap_record: dict[str, Any] = {}
    if should_record_gap:
        gap_record = record_knowledge_gap(
            role=role,
            user_id=user_id,
            message=message,
            intent=intent,
            confidence=confidence,
            retrieved_documents=len(hits),
        )

    llm_result = generate_with_openai(
        role=role,
        user_id=user_id,
        message=message,
        intent=intent,
        hits=hits,
        authorized_context="\n\n".join(
            part
            for part in [
                "" if intent in casual_intents else _authorized_context(role, user_id, message),
                f"Uploaded file context:\n{uploaded_context}" if attached_records else "",
            ]
            if part
        ),
        fallback_answer=answer,
        history=history or [],
        image_inputs=uploaded_images,
    )
    if llm_result.ok:
        answer = llm_result.text
        confidence = max(confidence, 0.9)
        model_mode = f"openai_responses:{llm_result.model}"
    else:
        if attached_records:
            answer = _attachment_fallback(attached_records)
            confidence = max(confidence, 0.72)
        model_mode = "local_rag_orchestrator"

    return ChatResponse(
        answer=answer,
        role=role,
        user_id=user_id,
        intent=intent,
        blocked=False,
        confidence=confidence,
        sources=_sources(hits),
        next_actions=_next_actions(role, intent),
        audit={
            "security": "authorized",
            "retrieved_documents": len(hits),
            "attached_files": len(attached_records),
            "attached_images": len(uploaded_images),
            "live_website_documents": len(website_hits),
            "source_policy": "curated_esui_first_live_website_when_needed",
            "model_mode": model_mode,
            "openai_configured": openai_configured(),
            "openai_error": llm_result.error,
            "knowledge_gap_id": gap_record.get("id"),
        },
    )
