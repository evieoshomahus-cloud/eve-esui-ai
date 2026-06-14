from __future__ import annotations

import html
import re
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "project_docs"
MARKDOWN_OUTPUT = DOCS / "full_project_report_draft.md"
DOCX_OUTPUT = DOCS / "Eve_Full_Project_Report_Draft.docx"

TOPIC = "Design and implementation of an ai system for personalized learning and academic progress tracking"

CHAPTER_FILES = [
    DOCS / "chapter_one_draft.md",
    DOCS / "chapter_two_draft.md",
    DOCS / "chapter_three_draft.md",
    DOCS / "chapter_four_draft.md",
    DOCS / "chapter_five_draft.md",
    DOCS / "references_2020_forward.md",
]


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

This project focused on the design and implementation of an AI system for personalized learning and academic progress tracking. The system, named Eve, was developed as a role-aware academic companion for Edo State University Iyamho. It supports guest users, students, and lecturers through a responsive Flutter interface connected to a Python FastAPI backend. The system provides admission guidance, student learning progress tracking, guided learning sessions, quiz scoring, saved progress history, lecturer assigned-course analytics, Retrieval-Augmented Generation, prompt-injection guardrails, and optional OpenAI response generation. SQLite was used to persist learning sessions, answers, scores, feedback, and completion status. The system was evaluated using backend compilation, Flutter analysis, widget tests, API endpoint tests, learning-session persistence checks, lecturer analytics checks, and security behavior tests. The results showed that Eve can support personalized academic guidance, track student progress over time, and provide lecturers with course-level learning evidence while enforcing role-based privacy controls.

# TABLE OF CONTENTS

Use Microsoft Word to update the automatic table of contents after final formatting.

# LIST OF FIGURES

Figure 4.1 Entry screen

Figure 4.2 Student home screen

Figure 4.3 Chat interface

Figure 4.4 Student learning progress dashboard

Figure 4.5 Guided learning session screen

Figure 4.6 Feedback history screen

Figure 4.7 Lecturer teaching workbench

Figure 4.8 Admission readiness estimator

Figure 4.9 Profile/account switcher
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
            in_code = not in_code
            continue
        if in_code:
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
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>"""


def rels_xml() -> str:
    return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""


def document_rels_xml() -> str:
    return """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>"""


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
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    {body_xml}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>"""


def build_docx(markdown: str) -> None:
    body_xml = markdown_to_body(markdown)
    with zipfile.ZipFile(DOCX_OUTPUT, "w", zipfile.ZIP_DEFLATED) as docx:
        docx.writestr("[Content_Types].xml", content_types_xml())
        docx.writestr("_rels/.rels", rels_xml())
        docx.writestr("word/_rels/document.xml.rels", document_rels_xml())
        docx.writestr("word/styles.xml", styles_xml())
        docx.writestr("word/document.xml", document_xml(body_xml))


def main() -> None:
    DOCS.mkdir(exist_ok=True)
    markdown = assemble_markdown()
    build_docx(markdown)
    print(MARKDOWN_OUTPUT)
    print(DOCX_OUTPUT)


if __name__ == "__main__":
    main()
