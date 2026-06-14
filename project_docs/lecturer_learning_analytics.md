# Lecturer Learning Analytics Module

This module supports the recorded project topic: **Design and implementation of an ai system for personalized learning and academic progress tracking**.

## Purpose

The lecturer module helps assigned lecturers monitor course-level learning trends from saved Eve learning sessions. It turns student quiz activity into teaching signals while keeping access limited to assigned courses.

## Inputs

- Lecturer profile
- Assigned courses
- Existing course analytics
- Saved learning sessions
- Saved quiz scores and topic history

## Processing Logic

1. Verify the lecturer account and assigned courses.
2. Retrieve only learning sessions linked to assigned courses.
3. Group sessions by course and topic.
4. Calculate completed sessions, tracked student count, average quiz score, and topic performance.
5. Identify the weakest saved topic when scores show a learning gap.
6. Generate a teaching intervention suggestion for the assigned course.

## Outputs

- Assigned-course dashboard
- Tracked student count
- Completed learning-session count
- Average Eve quiz score
- Topic-performance summary
- Weak-topic trend
- Intervention recommendation

## Endpoint

```text
GET /api/lecturer/{user_id}/insights
```

## Defense Value

This module shows that academic progress tracking is useful beyond the student screen. Students receive personalized learning support, while lecturers receive course-level evidence that can guide revision classes, practice drills, and intervention planning.
