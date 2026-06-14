from __future__ import annotations

import copy
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "UNDERGRADUATE POWERPOINT TEMPLATE (2).pptx"
OUTPUT = ROOT / "project_docs" / "Eve_Defense_Presentation.pptx"

P_NS = "http://schemas.openxmlformats.org/presentationml/2006/main"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

ET.register_namespace("p", P_NS)
ET.register_namespace("a", A_NS)
ET.register_namespace("r", R_NS)

NS = {"p": P_NS, "a": A_NS}


TITLE_REPLACEMENTS = {
    1: [
        "Design and implementation of an ai system for personalized learning and academic progress tracking",
        "PRESENTED BY",
        "NAME OF STUDENT",
        "MATRICULATION NUMBER",
        "DEPARTMENT OF COMPUTER SCIENCE",
        "FACULTY OF SCIENCE",
        "EDO STATE UNIVERSITY IYAMHO",
        "SUPERVISOR: ______________",
    ],
    2: ["BACKGROUND OF THE STUDY"],
    3: ["STATEMENT OF THE PROBLEM"],
    4: ["AIM AND OBJECTIVES"],
    5: ["SIGNIFICANCE OF THE STUDY"],
    6: ["LITERATURE REVIEW"],
    7: ["ANALYSIS OF THE EXISTING SYSTEM"],
    8: ["ARCHITECTURE OF THE EXISTING SYSTEM"],
    9: ["ANALYSIS OF THE PROPOSED SYSTEM"],
    10: ["DESIGN METHODOLOGY"],
    11: ["ARCHITECTURE OF THE PROPOSED SYSTEM"],
    12: ["SYSTEM REQUIREMENTS"],
    13: ["SYSTEM DIAGRAMS"],
    14: ["OVERVIEW OF IMPLEMENTATION"],
    15: ["IMPLEMENTATION PROCEDURES"],
    16: ["PROGRAMMING LANGUAGE AND TOOLS USED"],
    17: ["SYSTEM INTERFACE / SCREENSHOTS"],
    18: ["DISCUSSION OF RESULTS / EVALUATION"],
    19: ["CONCLUSION AND RECOMMENDATIONS"],
    20: ["SELECTED REFERENCES"],
    21: ["THANK YOU"],
}


SLIDE_BODIES = {
    2: [
        "Universities increasingly use digital platforms for learning and student support.",
        "Students need personalized help with weak topics, study planning, and mock tests.",
        "Lecturers need timely insight into course performance and intervention needs.",
        "Generic AI tools are not designed around ESUI data, privacy, or role-based access.",
        "Eve was developed as an AI academic companion for Edo State University Iyamho.",
    ],
    3: [
        "Academic guidance is spread across portals, offices, websites, and course materials.",
        "Students may know their scores but lack continuous improvement guidance.",
        "Lecturers may not easily connect student practice activity to teaching intervention.",
        "Generic chatbots can hallucinate or expose private data if poorly governed.",
        "A role-aware AI system is needed for personalized learning and progress tracking.",
    ],
    4: [
        "Aim: To design and implement an ai system for personalized learning and academic progress tracking.",
        "Design a responsive academic-support interface.",
        "Implement personalized student learning progress tracking.",
        "Identify weak topics and recommend learning sessions.",
        "Implement guided sessions with quiz scoring, feedback, and SQLite history.",
        "Provide lecturer assigned-course analytics with guardrails and RAG.",
    ],
    5: [
        "Students receive personalized academic guidance and weak-topic support.",
        "Lecturers receive course-level evidence for teaching intervention.",
        "Prospective candidates receive admission-readiness and public guidance.",
        "The university gains a prototype for a future institutional AI platform.",
        "The system improves support while enforcing privacy and cybersecurity controls.",
    ],
    6: [
        "RAG improves factual grounding by combining retrieval with generation.",
        "LLMs can support explanation, tutoring, and summarization when constrained.",
        "AI risk frameworks emphasize governance, privacy, safety, and accountability.",
        "Universities such as ASU, University of Michigan, Georgia State, and University of Houston show growing AI adoption.",
        "Identified gap: an ESUI-focused system for personalized learning and progress tracking.",
    ],
    7: [
        "Students rely on separate sources for guidance and course support.",
        "Public information, course materials, and academic records are not unified.",
        "Existing support may not provide continuous personalized recommendations.",
        "Lecturer intervention can depend on delayed or fragmented data.",
        "Generic AI tools lack ESUI-specific governance and privacy controls.",
    ],
    8: [
        "Student or candidate asks office, website, lecturer, or peers.",
        "Information is manually searched or requested.",
        "Progress tracking depends on isolated scores and manual interpretation.",
        "Lecturer intervention depends on delayed or fragmented data.",
        "Weaknesses: slow feedback, scattered data, limited personalization, privacy risk.",
    ],
    9: [
        "Proposed system: Eve.",
        "Guest mode for public and admission guidance.",
        "Student mode for personalized learning and progress tracking.",
        "Lecturer mode for assigned-course analytics.",
        "RAG for verified ESUI knowledge and guardrails for privacy protection.",
        "SQLite persistence and optional OpenAI mode for natural responses.",
    ],
    10: [
        "Design and implementation research approach.",
        "Iterative prototyping model.",
        "Requirement analysis from project description and ESUI context.",
        "Backend implemented with Python FastAPI.",
        "Client implemented with Flutter.",
        "Testing through API checks, Flutter analysis, widget tests, and security scenarios.",
    ],
    11: [
        "User -> Flutter Client -> FastAPI Backend.",
        "Backend -> Guardrails -> Role-Based Access.",
        "Backend -> RAG -> ESUI Knowledge Base.",
        "Academic services -> SQLite progress database.",
        "Optional OpenAI Responses API improves response naturalness.",
        "Local fallback keeps the system usable without OpenAI mode.",
    ],
    12: [
        "Hardware: laptop or desktop computer with internet for OpenAI mode.",
        "Software: Windows, Flutter SDK, Python, FastAPI, Uvicorn, SQLite, browser.",
        "Backend URL: http://127.0.0.1:8010.",
        "Flutter web URL: http://127.0.0.1:8011.",
        "API key is stored privately in .env and never hard-coded.",
    ],
    13: [
        "Use Case Diagram: Guest, Student, Lecturer, Eve AI System.",
        "Data Flow Diagram: Flutter client, API, guardrails, RAG, academic services, SQLite.",
        "ERD: learning_sessions and learning_answers.",
        "Sequence Diagram: start session, submit answer, score answer, save progress.",
        "These diagrams are documented in Chapter Three.",
    ],
    14: [
        "Entry and role selection screen.",
        "AI chat interface.",
        "Admission readiness estimator.",
        "Student learning progress dashboard.",
        "Guided learning session mode with feedback history.",
        "Lecturer teaching workbench and OpenAI response layer.",
    ],
    15: [
        "Created curated ESUI knowledge and sample academic records.",
        "Built FastAPI backend routes and Flutter screens.",
        "Implemented role-based access and prompt-injection checks.",
        "Added RAG retrieval and OpenAI response mode.",
        "Added learning profile, guided sessions, quiz scoring, and SQLite persistence.",
        "Added lecturer saved-session analytics and tested the system.",
    ],
    16: [
        "Flutter and Dart: responsive client and future Android deployment.",
        "Python: backend and AI orchestration.",
        "FastAPI: REST API server.",
        "SQLite: persistent progress tracking.",
        "JSON: prototype knowledge and academic records.",
        "OpenAI Responses API: optional natural language generation.",
    ],
    17: [
        "Entry screen.",
        "Student learning progress dashboard.",
        "Guided learning session screen.",
        "Feedback history and quiz score.",
        "Lecturer teaching workbench.",
        "Admission readiness estimator and ChatGPT-style chat interface.",
    ],
    18: [
        "python -m compileall -q api: passed.",
        "flutter analyze: no issues found.",
        "flutter test: all tests passed.",
        "Backend health endpoint returned ok.",
        "Student progress and progress-history endpoints returned saved data.",
        "Lecturer endpoint returned assigned-course learning trends.",
        "Guardrails blocked unsafe requests.",
    ],
    19: [
        "The project successfully implemented an AI system for personalized learning and academic progress tracking.",
        "Eve supports guest, student, and lecturer modes.",
        "The system demonstrates RAG, guardrails, guided learning, saved progress, and lecturer analytics.",
        "Recommendations: integrate official ESUI records, Canvas LMS, managed database storage, and admin content approval.",
    ],
    20: [
        "Lewis et al. (2020) - Retrieval-Augmented Generation.",
        "NIST (2023) - AI Risk Management Framework.",
        "ISO/IEC (2023) - AI Management System.",
        "Zhao et al. (2023) - Survey of Large Language Models.",
        "Gao et al. (2024) - RAG Survey.",
        "OWASP (2025) - Top 10 for LLM Applications.",
    ],
    21: [
        "Thank you.",
        "Questions and contributions are welcome.",
    ],
}


def qn(namespace: str, tag: str) -> str:
    return f"{{{namespace}}}{tag}"


def slide_number(name: str) -> int | None:
    match = re.fullmatch(r"ppt/slides/slide(\d+)\.xml", name)
    return int(match.group(1)) if match else None


def replace_existing_text(root: ET.Element, replacements: list[str]) -> None:
    text_nodes = root.findall(".//a:t", NS)
    for index, node in enumerate(text_nodes):
        if index < len(replacements):
            node.text = replacements[index]
        elif index > 0:
            node.text = ""


def max_shape_id(root: ET.Element) -> int:
    values = []
    for node in root.findall(".//p:cNvPr", NS):
        raw = node.attrib.get("id")
        if raw and raw.isdigit():
            values.append(int(raw))
    return max(values, default=100)


def paragraph(text: str, font_size: int = 2050) -> ET.Element:
    p = ET.Element(qn(A_NS, "p"))
    r = ET.SubElement(p, qn(A_NS, "r"))
    r_pr = ET.SubElement(r, qn(A_NS, "rPr"))
    r_pr.set("lang", "en-US")
    r_pr.set("sz", str(font_size))
    t = ET.SubElement(r, qn(A_NS, "t"))
    t.text = text
    return p


def add_textbox(root: ET.Element, slide_index: int, lines: list[str]) -> None:
    if not lines:
        return
    sp_tree = root.find(".//p:cSld/p:spTree", NS)
    if sp_tree is None:
        return

    shape_id = max_shape_id(root) + 100 + slide_index
    sp = ET.Element(qn(P_NS, "sp"))

    nv_sp_pr = ET.SubElement(sp, qn(P_NS, "nvSpPr"))
    c_nv_pr = ET.SubElement(nv_sp_pr, qn(P_NS, "cNvPr"))
    c_nv_pr.set("id", str(shape_id))
    c_nv_pr.set("name", f"Eve Content {slide_index}")
    c_nv_sp_pr = ET.SubElement(nv_sp_pr, qn(P_NS, "cNvSpPr"))
    c_nv_sp_pr.set("txBox", "1")
    ET.SubElement(nv_sp_pr, qn(P_NS, "nvPr"))

    sp_pr = ET.SubElement(sp, qn(P_NS, "spPr"))
    xfrm = ET.SubElement(sp_pr, qn(A_NS, "xfrm"))
    off = ET.SubElement(xfrm, qn(A_NS, "off"))
    off.set("x", "760000")
    off.set("y", "1480000" if slide_index != 1 else "2100000")
    ext = ET.SubElement(xfrm, qn(A_NS, "ext"))
    ext.set("cx", "11380000")
    ext.set("cy", "5000000" if slide_index != 1 else "3300000")
    prst = ET.SubElement(sp_pr, qn(A_NS, "prstGeom"))
    prst.set("prst", "rect")
    ET.SubElement(prst, qn(A_NS, "avLst"))
    ET.SubElement(sp_pr, qn(A_NS, "noFill"))
    ln = ET.SubElement(sp_pr, qn(A_NS, "ln"))
    ET.SubElement(ln, qn(A_NS, "noFill"))

    tx_body = ET.SubElement(sp, qn(P_NS, "txBody"))
    body_pr = ET.SubElement(tx_body, qn(A_NS, "bodyPr"))
    body_pr.set("wrap", "square")
    ET.SubElement(body_pr, qn(A_NS, "spAutoFit"))
    ET.SubElement(tx_body, qn(A_NS, "lstStyle"))
    for line in lines:
        add_line = line if slide_index == 21 else f"- {line}"
        tx_body.append(paragraph(add_line, 2100 if slide_index != 20 else 1750))

    sp_tree.append(sp)


def build() -> None:
    OUTPUT.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(TEMPLATE, "r") as source, zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as target:
        for item in source.infolist():
            data = source.read(item.filename)
            number = slide_number(item.filename)
            if number is not None:
                root = ET.fromstring(data)
                if number in TITLE_REPLACEMENTS:
                    replace_existing_text(root, TITLE_REPLACEMENTS[number])
                if number in SLIDE_BODIES:
                    add_textbox(root, number, SLIDE_BODIES[number])
                data = ET.tostring(root, encoding="utf-8", xml_declaration=True)
            new_item = copy.copy(item)
            target.writestr(new_item, data)


if __name__ == "__main__":
    build()
    print(OUTPUT)
