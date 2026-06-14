# Defense Package Checklist

Project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**

## Files Created

- `project_docs/chapter_three_draft.md`
- `project_docs/chapter_four_draft.md`
- `project_docs/chapter_two_draft.md`
- `project_docs/chapter_five_draft.md`
- `project_docs/full_project_report_draft.md`
- `project_docs/Eve_Full_Project_Report_Draft.docx`
- `project_docs/defense_powerpoint_content.md`
- `project_docs/Eve_Defense_Presentation.pptx`

## Personal Details to Replace

In the PowerPoint title slide and final report front matter, replace:

- `NAME OF STUDENT`
- `MATRICULATION NUMBER`
- `SUPERVISOR: ______________`
- date/month if your department requires a specific submission month
- acknowledgement wording if you want it to be more personal
- dedication wording if you want it to mention specific people

## Screenshots to Capture

Run the app at `http://127.0.0.1:8011` and capture:

- Entry screen
- Student home screen
- Chat interface with a natural Eve response
- Student Learning Progress screen
- Guided Learning Session screen
- Feedback History after answering quiz questions
- Lecturer Teaching Workbench
- Admission Readiness Estimator
- Profile/account switcher

## Word Report Final Formatting

- Open `Eve_Full_Project_Report_Draft.docx` in Microsoft Word.
- Replace all personal placeholders.
- Insert screenshots under Chapter Four.
- Update the table of contents.
- Check page numbering and line spacing against the department guide.
- Convert to PDF only after your supervisor has reviewed the Word version.

## Demo Flow for Defense

1. Start with the project topic and problem statement.
2. Explain why the system is not just a chatbot.
3. Show Guest Mode for admissions guidance.
4. Show Student Mode for learning progress and weak topics.
5. Start a guided learning session and submit an answer.
6. Show saved progress history.
7. Switch to Lecturer Mode and show assigned-course learning trends.
8. Explain RAG, guardrails, role-based access, and SQLite persistence.
9. Mention that OpenAI mode improves natural responses while local fallback remains available.

## Strong Talking Points

- Eve personalizes learning using course scores, risk level, weak topics, and saved quiz performance.
- Eve tracks academic progress over time using SQLite learning-session history.
- Eve protects privacy through role-based access and prompt-injection guardrails.
- Lecturers only see assigned-course analytics.
- The system can be extended to official ESUI records, Canvas LMS, and a managed production database.
