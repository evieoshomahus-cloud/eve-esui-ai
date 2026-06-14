# Eve Knowledge Base Guide

Eve's primary school-information source is `knowledge/esui_knowledge.json`.

Some prototype entries are tagged `demo`. These entries are included so Eve can answer realistic student-life questions during defense when official ESUI policies are not yet available. Replace demo entries with approved ESUI documents before production use.

## Add A New Entry

Preferred workflow:

1. Start the backend and Flutter app.
2. Sign in as Admin for school-wide information or as a Lecturer for assigned-course learning entries.
3. Open Tools, then Knowledge base.
4. Search or filter existing entries before adding duplicate information.
5. Use View to inspect source, audience, tags, summary, and full content.
6. Use Edit to correct approved information.
7. Use Delete only when an entry is wrong, duplicated, or no longer approved.
8. Complete the Add knowledge entry form for new information, then save.

Eve validates saved changes, writes them to `esui_knowledge.json`, and reloads the backend knowledge cache when validation passes.

## Role Ownership

- Admin users manage school-wide knowledge: admissions, fees, payment links, portals, calendars, hostel guidance, student affairs, governance, and support services.
- Lecturer users manage only `learning` entries tied to their assigned course codes.
- A lecturer entry must include a course code such as `CSC 201`, `CSC 305`, or `MTH 211`; the backend rejects entries outside the lecturer's assigned courses.
- Knowledge gaps for school affairs stay in the admin review queue.

## Approval And Audit Tracking

- Use `demo` for placeholder information that is useful during defense but not official school policy.
- Use `draft` for staff-entered information that still needs review.
- Use `needs_review` for knowledge drafted from unanswered student questions or uncertain information.
- Use `approved` only when an admin has reviewed the entry.
- Eve stores create, update, and delete events in `storage/knowledge_audit_log.json`.
- The Admin Knowledge Base screen shows recent audit events with actor, action, entry, status, and timestamp.

## Knowledge Gap Review

When Eve cannot answer confidently from approved or demo knowledge, it stores the question in `storage/knowledge_gaps.json`.

Preferred workflow:

1. Sign in as Admin.
2. Open Tools, then Knowledge base.
3. Review the Knowledge gaps section.
4. Use Draft entry to prefill the knowledge-entry form.
5. Replace the draft with approved ESUI information.
6. Save the entry.
7. Eve marks the gap as converted and can answer similar questions next time.

Manual bulk-update workflow:

1. Copy `knowledge_entry_template.json`.
2. Edit the fields with approved ESUI information.
3. Paste the completed object into `esui_knowledge.json`.
4. Validate the file:

```powershell
python tools\validate_knowledge.py
```

5. Reload Eve's knowledge cache:

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8010/api/admin/knowledge/reload -Method Post
```

## Required Fields

- `id`: unique lowercase identifier, such as `esui-csc-course-outline-001`
- `title`: clear title shown in Eve's source panel
- `category`: topic group, such as `admission`, `fees`, `learning`, `portal`, `planning`, or `governance`
- `audience`: one or more of `public`, `guest`, `student`, `lecturer`
- `tags`: searchable keywords
- `summary`: short grounding sentence
- `content`: approved details Eve can use in answers
- `source_url`: official URL or `null` for internally curated knowledge
- `updated`: date in `YYYY-MM-DD` format

## Safety Rules

- Do not add exact fees, deadlines, or policies unless they come from an approved ESUI source.
- Payment-related entries must include an official `https://edouniversity.edu.ng/` link.
- Do not add student passwords, private records, API keys, or unofficial payment instructions.
- Use the live ESUI website only as supplementary context; curated knowledge remains the primary source.
- Demo entries must stay clearly tagged as `demo` and must not be presented as final ESUI policy.
