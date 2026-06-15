from __future__ import annotations

import copy
import html
import os
import re
import struct
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "project_docs"
MARKDOWN_OUTPUT = DOCS / "full_project_report_draft.md"
DOCX_OUTPUT = Path(os.environ.get("EVE_REPORT_OUTPUT", DOCS / "Eve_Full_Project_Report_Draft.docx"))
TEMPLATE_DOCX = ROOT / "PROJECT TEMPLATE THE EXTRACTED VERSION (1).docx"

TOPIC = "Design and implementation of an ai system for personalized learning and academic progress tracking"

CHAPTER_FILES = [
    DOCS / "chapter_one_draft.md",
    DOCS / "chapter_two_draft.md",
    DOCS / "chapter_three_draft.md",
    DOCS / "chapter_four_draft.md",
    DOCS / "chapter_five_draft.md",
    DOCS / "references_2020_forward.md",
]

DOCX_IMAGES: list[dict[str, object]] = []
MAX_DOCX_IMAGE_WIDTH = 5_800_000
MAX_DOCX_IMAGE_HEIGHT = 4_600_000


def front_matter() -> str:
    return f"""# {TOPIC.upper()}

BY

NAME OF STUDENT

MATRICULATION NUMBER

DEPARTMENT OF COMPUTER SCIENCE

FACULTY OF SCIENCE

EDO STATE UNIVERSITY, IYAMHO,

EDO STATE

JUNE, 2026

# {TOPIC.upper()}

BY

SURNAME, OTHER NAMES

MATRICULATION NUMBER

A PROJECT SUBMITTED IN PARTIAL FULFILLMENT OF THE REQUIREMENTS FOR THE AWARD OF THE DEGREE OF BACHELOR OF SCIENCE (B.Sc.) IN COMPUTER SCIENCE, EDO STATE UNIVERSITY, IYAMHO

JUNE, 2026

# DECLARATION

This project is my original work and has not been presented for a degree at any other university or similar institution. I also declare that I have not taken any material from any source without proper acknowledgement, and no part of this project may be reproduced without the prior written permission of the author and/or Edo State University, Iyamho.

Name of Student: ______________________________

Matriculation Number: _________________________

Date: ________________________________________

# CERTIFICATION

This is to certify that NAME OF STUDENT with Matriculation Number: MATRICULATION NUMBER undertook this project titled: {TOPIC}, and that it meets the requirements for submission to the Department of Computer Science, Edo State University Iyamho, in partial fulfillment for the award of the degree of Bachelor of Science (B.Sc.) in Computer Science.

Project Supervisor: ___________________________

Signature: __________________ Date: ___________

Lecturer-in-Charge: ___________________________

Signature: __________________ Date: ___________

External Examiner: ____________________________

Signature: __________________ Date: ___________

# DEDICATION

This project is dedicated to God Almighty, whose grace, strength, and guidance made the successful completion of this work possible.

# ACKNOWLEDGEMENT

I acknowledge God Almighty for wisdom, strength, and protection throughout this project. I also appreciate my supervisor, lecturers in the Department of Computer Science, my family, and everyone whose support contributed to the successful completion of this work.

# ABSTRACT

This project focused on the design and implementation of an AI system for personalized learning and academic progress tracking. The system, named Eve, was developed as a role-aware academic companion for Edo State University Iyamho. It supports guest users, students, and lecturers through a responsive Flutter interface connected to a Python FastAPI backend. The system provides admission guidance, student learning progress tracking, guided learning sessions, quiz scoring, saved progress history, upload-assisted questions, moderated peer notes, lecturer assigned-course analytics, Retrieval-Augmented Generation, prompt-injection guardrails, knowledge governance, and optional OpenAI response generation. SQLite was used to persist learning sessions, answers, scores, feedback, completion status, and peer-note review records. The system was evaluated using backend compilation, Flutter analysis, widget tests, API endpoint tests, learning-session persistence checks, lecturer analytics checks, moderation checks, and security behavior tests. The results showed that Eve can support personalized academic guidance, track student progress over time, manage reviewed student contributions, and provide lecturers with course-level learning evidence while enforcing role-based privacy controls.

# TABLE OF CONTENTS

CHAPTER ONE

INTRODUCTION

1.1 Background to the Study

1.2 Statement of the Problem

1.3 Aim of the Study

1.4 Objectives of the Study

1.5 Research Questions

1.6 Research Hypotheses

1.7 Significance of the Study

1.8 Scope of the Study

1.9 Limitations of the Study

1.10 Definition of Terms

1.11 Organisation of the Report

CHAPTER TWO

LITERATURE REVIEW

CHAPTER THREE

SYSTEM ANALYSIS AND DESIGN

CHAPTER FOUR

IMPLEMENTATION

CHAPTER FIVE

SUMMARY, CONCLUSION AND RECOMMENDATIONS

REFERENCES

# LIST OF FIGURES

Figure 3.1 Architecture of the existing system

Figure 3.2 Architecture of the proposed Eve system

Figure 3.3 Data flow diagram

Figure 3.4 Database and storage design

Figure 4.1 Entry screen

Figure 4.2 Personalized student dashboard

Figure 4.3 Mobile responsive dashboard

Figure 4.4 Ask Eve conversation

Figure 4.5 Upload-assisted Ask Eve

Figure 4.6 Guided learning session

Figure 4.7 Peer-note submission

Figure 4.8 Lecturer peer-note review

Figure 4.9 Lecturer analytics

Figure 4.10 Admission readiness estimator

Figure 4.11 Admin knowledge library

Figure 4.12 Backend health endpoint
"""


def assemble_markdown() -> str:
    sections = [front_matter()]
    for path in CHAPTER_FILES:
        sections.append(path.read_text(encoding="utf-8").strip())
    content = "\n\n".join(sections).replace("Eve ESUI", "Eve ESUI")
    MARKDOWN_OUTPUT.write_text(content + "\n", encoding="utf-8")
    return content


def esc(text: str) -> str:
    return html.escape(text, quote=False)


def esc_attr(text: str) -> str:
    return html.escape(text, quote=True)


def paragraph_xml(text: str, style: str = "Normal", bold: bool = False) -> str:
    text = text.strip()
    if not text:
        return '<w:p/>'
    run_props = "<w:b/>" if bold else ""
    style_xml = f'<w:pPr><w:pStyle w:val="{style}"/></w:pPr>' if style != "Normal" else ""
    return (
        "<w:p>"
        f"{style_xml}"
        "<w:r>"
        f"<w:rPr>{run_props}<w:rFonts w:ascii=\"Times New Roman\" w:hAnsi=\"Times New Roman\"/><w:sz w:val=\"24\"/></w:rPr>"
        f"<w:t xml:space=\"preserve\">{esc(text)}</w:t>"
        "</w:r>"
        "</w:p>"
    )


def resolve_image_path(source: str) -> Path | None:
    raw = source.strip().replace("\\", "/")
    path = Path(raw)
    candidates = [path] if path.is_absolute() else [DOCS / raw, ROOT / raw]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


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


def fitted_emu_size(path: Path) -> tuple[int, int]:
    width, height = image_dimensions(path)
    scale = min(MAX_DOCX_IMAGE_WIDTH / width, MAX_DOCX_IMAGE_HEIGHT / height)
    return int(width * scale), int(height * scale)


def image_paragraph_xml(source: str, caption: str) -> str:
    path = resolve_image_path(source)
    if path is None:
        return paragraph_xml(f"[Missing screenshot: {source}]")

    image_index = len(DOCX_IMAGES) + 1
    rel_id = f"rIdEveImage{image_index}"
    target_name = f"eve_report_image{image_index}{path.suffix.lower()}"
    cx, cy = fitted_emu_size(path)
    DOCX_IMAGES.append({"rel_id": rel_id, "target": target_name, "path": path})

    return f"""
<w:p>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="{cx}" cy="{cy}"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="{image_index}" name="Figure {image_index}" descr="{esc_attr(caption)}"/>
        <wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>
        <a:graphic>
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic>
              <pic:nvPicPr>
                <pic:cNvPr id="0" name="{esc_attr(target_name)}"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="{rel_id}"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm>
                  <a:off x="0" y="0"/>
                  <a:ext cx="{cx}" cy="{cy}"/>
                </a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
{paragraph_xml(caption, bold=True)}
"""


def table_line_xml(line: str) -> str:
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    row = ["<w:tr>"]
    for cell in cells:
        row.append(
            "<w:tc><w:tcPr><w:tcW w:w=\"2400\" w:type=\"dxa\"/></w:tcPr>"
            + paragraph_xml(cell)
            + "</w:tc>"
        )
    row.append("</w:tr>")
    return "".join(row)


def markdown_to_body(markdown: str) -> str:
    body: list[str] = []
    in_code = False
    code_language = ""
    in_table = False
    table_rows: list[str] = []

    def flush_table() -> None:
        nonlocal table_rows, in_table
        if table_rows:
            body.append("<w:tbl>")
            body.append(
                "<w:tblPr><w:tblW w:w=\"0\" w:type=\"auto\"/>"
                "<w:tblBorders><w:top w:val=\"single\" w:sz=\"4\"/>"
                "<w:left w:val=\"single\" w:sz=\"4\"/><w:bottom w:val=\"single\" w:sz=\"4\"/>"
                "<w:right w:val=\"single\" w:sz=\"4\"/><w:insideH w:val=\"single\" w:sz=\"4\"/>"
                "<w:insideV w:val=\"single\" w:sz=\"4\"/></w:tblBorders></w:tblPr>"
            )
            for row in table_rows:
                if re.fullmatch(r"\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?", row):
                    continue
                body.append(table_line_xml(row))
            body.append("</w:tbl>")
        table_rows = []
        in_table = False

    for raw_line in markdown.splitlines():
        line = raw_line.rstrip()
        if line.startswith("```"):
            flush_table()
            if in_code:
                in_code = False
                code_language = ""
            else:
                in_code = True
                code_language = line.strip("`").strip().lower()
            continue
        image_match = re.fullmatch(r"!\[(.*?)\]\((.*?)\)", line.strip())
        if image_match and not in_code:
            flush_table()
            body.append(image_paragraph_xml(image_match.group(2), image_match.group(1)))
            continue
        if in_code:
            if code_language == "mermaid":
                continue
            body.append(paragraph_xml(line, "Code"))
            continue
        if line.startswith("|") and line.endswith("|"):
            in_table = True
            table_rows.append(line)
            continue
        if in_table:
            flush_table()
        if not line.strip():
            body.append("<w:p/>")
            continue
        if line.startswith("# "):
            body.append(paragraph_xml(line[2:], "Heading1", True))
        elif line.startswith("## "):
            body.append(paragraph_xml(line[3:], "Heading2", True))
        elif line.startswith("### "):
            body.append(paragraph_xml(line[4:], "Heading3", True))
        elif line.startswith("- "):
            body.append(paragraph_xml("• " + line[2:]))
        elif re.match(r"^\d+\.\s+", line):
            body.append(paragraph_xml(line))
        else:
            clean = re.sub(r"\*\*(.*?)\*\*", r"\1", line)
            clean = clean.replace("`", "")
            body.append(paragraph_xml(clean))
    flush_table()
    return "\n".join(body)


def content_types_xml() -> str:
    return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Default Extension="jpg" ContentType="image/jpeg"/>
  <Default Extension="jpeg" ContentType="image/jpeg"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>"""


def rels_xml() -> str:
    return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""


def document_rels_xml() -> str:
    image_rels = "\n".join(
        f'  <Relationship Id="{item["rel_id"]}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{item["target"]}"/>'
        for item in DOCX_IMAGES
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
{image_rels}
</Relationships>"""


def styles_xml() -> str:
    return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="24"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:rPr><w:b/><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="28"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:rPr><w:b/><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="26"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:basedOn w:val="Normal"/>
    <w:rPr><w:b/><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="24"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Code">
    <w:name w:val="Code"/>
    <w:basedOn w:val="Normal"/>
    <w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/><w:sz w:val="20"/></w:rPr>
  </w:style>
</w:styles>"""


def document_xml(body_xml: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:body>
    {body_xml}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>"""


def add_image_content_types(content_xml: str) -> str:
    additions = []
    defaults = {
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
    }
    for extension, content_type in defaults.items():
        if f'Extension="{extension}"' not in content_xml:
            additions.append(f'  <Default Extension="{extension}" ContentType="{content_type}"/>')
    if not additions:
        return content_xml
    return content_xml.replace("</Types>", "\n".join(additions) + "\n</Types>")


def document_rels_from_template(rels_xml_text: str) -> str:
    image_rels = "\n".join(
        f'  <Relationship Id="{item["rel_id"]}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{item["target"]}"/>'
        for item in DOCX_IMAGES
    )
    if not image_rels:
        return rels_xml_text
    return rels_xml_text.replace("</Relationships>", image_rels + "\n</Relationships>")


def document_xml_from_template(template_xml: str, body_xml: str) -> str:
    namespace_additions = {
        "xmlns:a": "http://schemas.openxmlformats.org/drawingml/2006/main",
        "xmlns:pic": "http://schemas.openxmlformats.org/drawingml/2006/picture",
    }
    document_tag_start = template_xml.find("<w:document")
    document_tag_end = template_xml.find(">", document_tag_start)
    if document_tag_end != -1:
        insertions = []
        for prefix, uri in namespace_additions.items():
            if f"{prefix}=" not in template_xml[document_tag_start:document_tag_end]:
                insertions.append(f' {prefix}="{uri}"')
        if insertions:
            template_xml = template_xml[:document_tag_end] + "".join(insertions) + template_xml[document_tag_end:]

    body_start = template_xml.find("<w:body>")
    body_end = template_xml.rfind("</w:body>")
    if body_start == -1 or body_end == -1:
        return document_xml(body_xml)

    body_content_start = body_start + len("<w:body>")
    existing_body = template_xml[body_content_start:body_end]
    sect_start = existing_body.rfind("<w:sectPr")
    sect_pr = ""
    if sect_start != -1:
        sect_pr = existing_body[sect_start:]

    return template_xml[:body_content_start] + "\n" + body_xml + "\n" + sect_pr + "\n" + template_xml[body_end:]


def copy_zip_info(item: zipfile.ZipInfo) -> zipfile.ZipInfo:
    return copy.copy(item)


def build_docx(markdown: str) -> None:
    DOCX_IMAGES.clear()
    body_xml = markdown_to_body(markdown)
    if TEMPLATE_DOCX.exists():
        with zipfile.ZipFile(TEMPLATE_DOCX, "r") as source, zipfile.ZipFile(DOCX_OUTPUT, "w", zipfile.ZIP_DEFLATED) as docx:
            for item in source.infolist():
                data = source.read(item.filename)
                if item.filename == "[Content_Types].xml":
                    text = data.decode("utf-8")
                    data = add_image_content_types(text).encode("utf-8")
                elif item.filename == "word/document.xml":
                    text = data.decode("utf-8")
                    data = document_xml_from_template(text, body_xml).encode("utf-8")
                elif item.filename == "word/_rels/document.xml.rels":
                    text = data.decode("utf-8")
                    data = document_rels_from_template(text).encode("utf-8")
                docx.writestr(copy_zip_info(item), data)
            for item in DOCX_IMAGES:
                path = item["path"]
                target = item["target"]
                if isinstance(path, Path) and isinstance(target, str):
                    docx.writestr(f"word/media/{target}", path.read_bytes())
        return

    with zipfile.ZipFile(DOCX_OUTPUT, "w", zipfile.ZIP_DEFLATED) as docx:
        docx.writestr("[Content_Types].xml", content_types_xml())
        docx.writestr("_rels/.rels", rels_xml())
        docx.writestr("word/_rels/document.xml.rels", document_rels_xml())
        docx.writestr("word/styles.xml", styles_xml())
        docx.writestr("word/document.xml", document_xml(body_xml))
        for item in DOCX_IMAGES:
            path = item["path"]
            target = item["target"]
            if isinstance(path, Path) and isinstance(target, str):
                docx.writestr(f"word/media/{target}", path.read_bytes())


def main() -> None:
    DOCS.mkdir(exist_ok=True)
    markdown = assemble_markdown()
    build_docx(markdown)
    print(MARKDOWN_OUTPUT)
    print(DOCX_OUTPUT)


if __name__ == "__main__":
    main()
