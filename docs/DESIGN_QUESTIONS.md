# Progress Tracker — Open Design Questions

> **Status**: Awaiting answers before implementation begins.
> These questions shape the architecture, data model, and UI decisions.

---

## Platform & Scope

1. **Target phones**: iOS, Android, or both? Native app vs. installable web app (PWA)?
2. **Audience**: Personal tool, or multi-user with accounts?

---

## The Tasks

3. **Task recurrence**: Same daily tasks every day (e.g. "3 LeetCode problems"), or different tasks added ad-hoc each day?
4. **Task targets**: Does each task have a measurable target (number of problems, minutes, pages), or simple done/not-done?
5. **Categories**: Should tasks have categories like "DSA", "Reading", "Workout"?

---

## The Green Grid

6. **Green threshold**: What makes a day green? All tasks done, at least one, or a percentage?
7. **Shading**: Shades of green for different completion levels (GitHub/LeetCode style), or binary green/grey?
8. **Time range**: Grid shows a week, a month, or a full year?

---

## The Grafana-Style Dashboard

9. **Priority charts**: Which matter most?
   - Completion rate over time
   - Current and longest streak
   - Weekly totals
   - Per-task breakdown
   - Something else?
10. **Time filters**: Filter by 7, 30, or 90 days?

---

## LeetCode Integration

11. **Auto-sync**: Read actual LeetCode account and mark problems done automatically, or just copy the visual style?
12. **Manual tracker**: If manual, should adding a task also create a LeetCode-style entry for that day?
