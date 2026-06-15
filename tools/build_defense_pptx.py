from __future__ import annotations

import copy
import re
import struct
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "UNDERGRADUATE POWERPOINT TEMPLATE (2).pptx"
OUTPUT = ROOT / "project_docs" / "Eve_Defense_Presentation.pptx"
SCREENSHOTS = ROOT / "project_docs" / "screenshots"
DIAGRAMS = ROOT / "project_docs" / "diagrams"

P_NS = "http://schemas.openxmlformats.org/presentationml/2006/main"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

ET.register_namespace("p", P_NS)
ET.register_namespace("a", A_NS)
ET.register_namespace("r", R_NS)

NS = {"p": P_NS, "a": A_NS}

CONTENT_TYPES_NS = "http://schemas.openxmlformats.org/package/2006/content-types"
RELS_NS = "http://schemas.openxmlformats.org/package/2006/relationships"

SLIDE_IMAGES = {
    8: [
        {
            "source": DIAGRAMS / "existing_system_architecture.png",
            "media": "eve_slide8_existing_architecture.png",
            "rel_id": "rIdEveExistingArchitecture",
            "name": "Architecture of the existing system",
            "box": (5200000, 1750000, 6500000, 3900000),
        }
    ],
    11: [
        {
            "source": DIAGRAMS / "proposed_system_architecture.png",
            "media": "eve_slide11_proposed_architecture.png",
            "rel_id": "rIdEveProposedArchitecture",
            "name": "Architecture of the proposed Eve system",
            "box": (5200000, 1750000, 6500000, 3900000),
        }
    ],
    13: [
        {
            "source": DIAGRAMS / "data_flow_diagram.png",
            "media": "eve_slide13_data_flow.png",
            "rel_id": "rIdEveDataFlow",
            "name": "Eve data flow diagram",
            "box": (5100000, 1500000, 6600000, 2200000),
        },
        {
            "source": DIAGRAMS / "database_erd.png",
            "media": "eve_slide13_database_erd.png",
            "rel_id": "rIdEveDatabaseErd",
            "name": "Eve database and storage design",
            "box": (5100000, 4050000, 6600000, 2200000),
        },
    ],
    17: [
        {
            "source": SCREENSHOTS / "student_personalized_home_desktop.png",
            "media": "eve_slide17_dashboard.png",
            "rel_id": "rIdEveDashboard",
            "name": "Personalized student dashboard",
            "box": (720000, 1850000, 5200000, 2050000),
        },
        {
            "source": SCREENSHOTS / "ask_eve_conversation.png",
            "media": "eve_slide17_chat.png",
            "rel_id": "rIdEveChat",
            "name": "Ask Eve conversation",
            "box": (6500000, 1850000, 5200000, 2050000),
        },
        {
            "source": SCREENSHOTS / "lecturer_peer_note_review.png",
            "media": "eve_slide17_review.png",
            "rel_id": "rIdEveReview",
            "name": "Lecturer peer-note review",
            "box": (720000, 4250000, 5200000, 2050000),
        },
        {
            "source": SCREENSHOTS / "admin_knowledge_library.png",
            "media": "eve_slide17_admin.png",
            "rel_id": "rIdEveAdmin",
            "name": "Admin knowledge library",
            "box": (6500000, 4250000, 5200000, 2050000),
        },
    ]
}


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
        "Support upload-assisted learning questions and moderated peer notes.",
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
        "Information is scattered across website, portal, offices, lecturers, course materials, and peers.",
        "The student must manually search across several sources.",
        "There is limited personalization, delayed feedback, and no continuous progress tracking.",
    ],
    9: [
        "Proposed system: Eve.",
        "Guest mode for public and admission guidance.",
        "Student mode for personalized learning and progress tracking.",
        "Lecturer mode for assigned-course analytics.",
        "Upload-assisted Ask Eve support for student notes.",
        "Moderated peer notes and admin knowledge governance.",
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
        "Flutter connects guest, student, and lecturer users to a FastAPI backend.",
        "Guardrails and role-based access control protect private academic data.",
        "RAG, academic services, SQLite, peer-note review, and OpenAI mode work together.",
    ],
    12: [
        "Hardware: laptop or desktop computer with internet for OpenAI mode.",
        "Software: Windows, Flutter SDK, Python, FastAPI, Uvicorn, SQLite, browser.",
        "Backend URL: http://127.0.0.1:8010.",
        "Flutter web URL: http://127.0.0.1:8011.",
        "API key is stored privately in .env and never hard-coded.",
    ],
    13: [
        "Data flow shows how a request becomes a grounded Eve response.",
        "Storage design separates learning progress from moderated peer-note review.",
        "Use case, sequence, and ERD details are documented in Chapter Three.",
    ],
    14: [
        "Entry and role selection screen.",
        "AI chat interface.",
        "Admission readiness estimator.",
        "Student learning progress dashboard.",
        "Guided learning session mode with feedback history.",
        "Upload-assisted Ask Eve questions.",
        "Moderated peer-note contribution and lecturer review.",
        "Lecturer teaching workbench, admin governance, and OpenAI response layer.",
    ],
    15: [
        "Created curated ESUI knowledge and sample academic records.",
        "Built FastAPI backend routes and Flutter screens.",
        "Implemented role-based access and prompt-injection checks.",
        "Added RAG retrieval and OpenAI response mode.",
        "Added learning profile, guided sessions, quiz scoring, and SQLite persistence.",
        "Added upload-assisted questions and moderated peer notes.",
        "Added lecturer saved-session analytics and tested the system.",
    ],
    16: [
        "Flutter and Dart: responsive client and future Android deployment.",
        "Python: backend and AI orchestration.",
        "FastAPI: REST API server.",
        "SQLite: persistent progress tracking.",
        "JSON: prototype knowledge and academic records.",
        "OpenAI Responses API: optional natural language generation.",
        "Render: public deployment for user review.",
    ],
    17: [
        "Personalized dashboard, Ask Eve conversation, lecturer review, and knowledge governance are shown below.",
    ],
    18: [
        "python -m compileall -q api: passed.",
        "flutter analyze: no issues found.",
        "flutter test: all tests passed.",
        "Backend health endpoint returned ok.",
        "Student progress and progress-history endpoints returned saved data.",
        "Lecturer endpoint returned assigned-course learning trends.",
        "Upload-assisted Ask Eve used a CSC note as private context.",
        "Peer-note workflow kept student submissions pending until review.",
        "Guardrails blocked unsafe requests.",
    ],
    19: [
        "The project successfully implemented an AI system for personalized learning and academic progress tracking.",
        "Eve supports guest, student, and lecturer modes.",
        "The system demonstrates RAG, guardrails, guided learning, saved progress, uploads, moderated peer notes, knowledge governance, and lecturer analytics.",
        "Recommendations: integrate official ESUI records, Canvas LMS, managed database storage, official lecturer accounts, and admin content approval.",
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


def image_dimensions(path: Path) -> tuple[int, int]:
    suffix = path.suffix.lower()
    data = path.read_bytes()
    if suffix == ".png" and len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", data[16:24])
    if suffix in {".jpg", ".jpeg"} and data[:2] == b"\xff\xd8":
        index = 2
        while index + 9 < len(data):
            if data[index] != 0xFF:
                index += 1
                continue
            marker = data[index + 1]
            index += 2
            if marker in {0xD8, 0xD9}:
                continue
            if index + 2 > len(data):
                break
            length = int.from_bytes(data[index:index + 2], "big")
            if 0xC0 <= marker <= 0xCF and marker not in {0xC4, 0xC8, 0xCC}:
                height = int.from_bytes(data[index + 3:index + 5], "big")
                width = int.from_bytes(data[index + 5:index + 7], "big")
                return width, height
            index += length
    return (1200, 800)


def fit_to_box(path: Path, box: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    x, y, box_w, box_h = box
    width, height = image_dimensions(path)
    scale = min(box_w / width, box_h / height)
    cx = int(width * scale)
    cy = int(height * scale)
    return x + ((box_w - cx) // 2), y + ((box_h - cy) // 2), cx, cy


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
    if slide_index in {8, 11, 13}:
        off.set("x", "650000")
        off.set("y", "1700000")
    else:
        off.set("x", "760000")
        off.set("y", "1250000" if slide_index == 17 else ("1480000" if slide_index != 1 else "2100000"))
    ext = ET.SubElement(xfrm, qn(A_NS, "ext"))
    if slide_index in {8, 11, 13}:
        ext.set("cx", "4000000")
        ext.set("cy", "4300000")
    else:
        ext.set("cx", "11380000")
        ext.set("cy", "500000" if slide_index == 17 else ("5000000" if slide_index != 1 else "3300000"))
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
        if slide_index in {8, 11, 13}:
            font_size = 1550
        else:
            font_size = 1450 if slide_index == 17 else (2100 if slide_index != 20 else 1750)
        tx_body.append(paragraph(add_line, font_size))

    sp_tree.append(sp)


def add_picture(root: ET.Element, shape_id: int, spec: dict[str, object]) -> None:
    sp_tree = root.find(".//p:cSld/p:spTree", NS)
    if sp_tree is None:
        return

    path = spec["source"]
    box = spec["box"]
    if not isinstance(path, Path) or not isinstance(box, tuple):
        return

    x, y, cx, cy = fit_to_box(path, box)
    pic = ET.Element(qn(P_NS, "pic"))

    nv_pic_pr = ET.SubElement(pic, qn(P_NS, "nvPicPr"))
    c_nv_pr = ET.SubElement(nv_pic_pr, qn(P_NS, "cNvPr"))
    c_nv_pr.set("id", str(shape_id))
    c_nv_pr.set("name", str(spec["name"]))
    ET.SubElement(nv_pic_pr, qn(P_NS, "cNvPicPr"))
    ET.SubElement(nv_pic_pr, qn(P_NS, "nvPr"))

    blip_fill = ET.SubElement(pic, qn(P_NS, "blipFill"))
    blip = ET.SubElement(blip_fill, qn(A_NS, "blip"))
    blip.set(qn(R_NS, "embed"), str(spec["rel_id"]))
    stretch = ET.SubElement(blip_fill, qn(A_NS, "stretch"))
    ET.SubElement(stretch, qn(A_NS, "fillRect"))

    sp_pr = ET.SubElement(pic, qn(P_NS, "spPr"))
    xfrm = ET.SubElement(sp_pr, qn(A_NS, "xfrm"))
    off = ET.SubElement(xfrm, qn(A_NS, "off"))
    off.set("x", str(x))
    off.set("y", str(y))
    ext = ET.SubElement(xfrm, qn(A_NS, "ext"))
    ext.set("cx", str(cx))
    ext.set("cy", str(cy))
    prst = ET.SubElement(sp_pr, qn(A_NS, "prstGeom"))
    prst.set("prst", "rect")
    ET.SubElement(prst, qn(A_NS, "avLst"))

    sp_tree.append(pic)


def add_slide_images(root: ET.Element, slide_index: int) -> None:
    specs = SLIDE_IMAGES.get(slide_index, [])
    shape_id = max_shape_id(root) + 1
    for spec in specs:
        add_picture(root, shape_id, spec)
        shape_id += 1


def slide_rels_number(name: str) -> int | None:
    match = re.fullmatch(r"ppt/slides/_rels/slide(\d+)\.xml\.rels", name)
    return int(match.group(1)) if match else None


def add_image_relationships(data: bytes, slide_index: int) -> bytes:
    specs = SLIDE_IMAGES.get(slide_index, [])
    if not specs:
        return data

    root = ET.fromstring(data)
    existing_ids = {node.attrib.get("Id") for node in root}
    for spec in specs:
        rel_id = str(spec["rel_id"])
        if rel_id in existing_ids:
            continue
        rel = ET.SubElement(root, qn(RELS_NS, "Relationship"))
        rel.set("Id", rel_id)
        rel.set("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image")
        rel.set("Target", f"../media/{spec['media']}")
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def add_content_type_defaults(data: bytes) -> bytes:
    root = ET.fromstring(data)
    existing = {node.attrib.get("Extension") for node in root.findall(f"{{{CONTENT_TYPES_NS}}}Default")}
    defaults = {
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
    }
    for extension, content_type in defaults.items():
        if extension not in existing:
            node = ET.SubElement(root, f"{{{CONTENT_TYPES_NS}}}Default")
            node.set("Extension", extension)
            node.set("ContentType", content_type)
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def image_media_items() -> list[tuple[str, Path]]:
    items: list[tuple[str, Path]] = []
    for specs in SLIDE_IMAGES.values():
        for spec in specs:
            media = spec["media"]
            path = spec["source"]
            if isinstance(media, str) and isinstance(path, Path):
                items.append((media, path))
    return items


def build() -> None:
    OUTPUT.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(TEMPLATE, "r") as source, zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as target:
        written_rels: set[int] = set()
        for item in source.infolist():
            data = source.read(item.filename)
            if item.filename == "[Content_Types].xml":
                data = add_content_type_defaults(data)
            number = slide_number(item.filename)
            if number is not None:
                root = ET.fromstring(data)
                if number in TITLE_REPLACEMENTS:
                    replace_existing_text(root, TITLE_REPLACEMENTS[number])
                if number in SLIDE_BODIES:
                    add_textbox(root, number, SLIDE_BODIES[number])
                if number in SLIDE_IMAGES:
                    add_slide_images(root, number)
                data = ET.tostring(root, encoding="utf-8", xml_declaration=True)
            rel_number = slide_rels_number(item.filename)
            if rel_number is not None and rel_number in SLIDE_IMAGES:
                data = add_image_relationships(data, rel_number)
                written_rels.add(rel_number)
            new_item = copy.copy(item)
            target.writestr(new_item, data)
        for slide_index in SLIDE_IMAGES:
            if slide_index not in written_rels:
                rels = add_image_relationships(
                    b'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>',
                    slide_index,
                )
                target.writestr(f"ppt/slides/_rels/slide{slide_index}.xml.rels", rels)
        for media, path in image_media_items():
            target.writestr(f"ppt/media/{media}", path.read_bytes())


if __name__ == "__main__":
    build()
    print(OUTPUT)
