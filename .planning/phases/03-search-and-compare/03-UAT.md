---
status: complete
phase: 03-search-and-compare
source: [03-VERIFICATION.md]
started: 2026-06-28T17:17:14Z
updated: 2026-07-02T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. /ev-search golden run
expected: Run /ev-search in an active project with a filled-out brief.md (e.g. projects/test-ev-detail-new). Confirm it (a) reads brief.md, (b) fetches ev-database.org via curl with Mozilla UA and prints a file size >100 KB, (c) outputs a candidate table grouped as Matches / Borderline / Excluded with EVDB range, battery, body type, and a DK price band per car, (d) writes a dated ## Search Candidates section to projects/<active>/state.md without truncating other sections, (e) ends with a /ev-research "..." "..." handoff command.
result: pass

### 2. /ev-compare golden run
expected: Run /ev-compare in the same active project after at least two cars have been researched (research/*.md present). Confirm it (a) Globs only that project's research/*.md, (b) writes projects/<active>/comparison.md, (c) one column per car, (d) WLTP range / Real-world range (mild) / Real-world range (cold) are three separate rows each methodology-labelled, (e) best-in-class values bolded per row, (f) gaps render as explicit text (no FDM test, unconfirmed, not available) — never blank, (g) a ## Brief-Aware Verdict heads the file.
result: pass
note: "User verified e2e by creating a real example-2026 project — worked as expected"

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
