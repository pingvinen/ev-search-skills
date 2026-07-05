---
phase: 02-detail-skill
plan: "02"
subsystem: ev-detail-skill
status: complete
tags: [skill, ev-research, web-fetch, multi-source]
dependency_graph:
  requires:
    - 02-01 (car-template.md, ev-new-project skill, ev-switch-project skill, per-project state.md schema)
  provides:
    - .claude/skills/ev-detail/SKILL.md
  affects:
    - Phase 3 (ev-search skill reads research/*.md produced by ev-detail)
    - Phase 5 (Tire Research picks up where TIRE-01 leaves off; tire size already captured)
tech_stack:
  added:
    - ev-detail Claude Code skill (context: fork, agent: Explore)
  patterns:
    - WebSearch-then-WebFetch variant discovery (avoids JS-driven ev-database.org listing)
    - backtick injection (!`cat state.md`) for active-project resolution at invocation
    - purchase-type branch (new/used/leasing) driven by BRIEF.md
    - best-effort sources with explicit gap notes (FDM, wheel-size.com)
    - mandatory-source abort guard (ev-database.org)
key_files:
  created:
    - .claude/skills/ev-detail/SKILL.md
  modified: []
decisions:
  - "D-03 enforced: ev-database.org is mandatory; skill aborts without writing any file if car not found"
  - "D-04 applied: FDM and wheel-size.com are best-effort; gap notes written on failure, not aborts"
  - "D-05/D-06: variant auto-selected per BRIEF budget/range with middle-tier tie-breaker; rationale stated in output"
  - "D-07/D-08: purchase_type branch produces tier1+tier2 DKK (new), Bilbasen Blog market range (used), or monthly range + no-residual note (leasing)"
  - "D-09: re-run guard checks for existing research file before any fetch; overwrite/skip prompt"
  - "D-10: no training data; every fact sources to URL+date; rated vs FDM-measured DC kW recorded separately; WLTP and real-world range never blended"
  - "TIRE-01 only: tire SIZE captured from wheel-size.com; pricing/scoring deferred to Phase 5 (D-01/D-02)"
  - "greengarage.dk excluded from mandatory sources (verified 404 on model pages); silent optional probe only"
metrics:
  duration_minutes: 3
  completed: "2026-06-22"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
---

# Phase 02 Plan 02: ev-detail Skill Summary

**One-liner:** Step-numbered `/ev-detail` skill with mandatory ev-database.org spec fetch, best-effort FDM/tire/pricing, purchase-type-aware DK pricing branch, and full sourcing discipline writing to car-template.md.

## What Was Built

Created `.claude/skills/ev-detail/SKILL.md` — a 328-line self-contained step-numbered skill that:

1. Resolves the active project from global `state.md` via backtick injection.
2. Reads `projects/<active>/BRIEF.md` (budget, purchase_type, must-haves) and per-project `state.md`.
3. Normalizes the filename from `$ARGUMENTS` and runs an overwrite/skip guard before any fetching.
4. Discovers ev-database.org variants via WebSearch (avoids the JS-driven listing page).
5. Selects the best variant against BRIEF budget/range, applying the middle-tier tie-breaker (D-06).
6. Mandatorily fetches the selected variant page and extracts all spec fields including EV platform.
7. Attempts FDM test discovery (2 WebSearch queries max) and fetches the most recent article; writes a gap note on failure.
8. Fetches tire size from wheel-size.com with front/rear rule; graceful 404 fallback.
9. Branches on `purchase_type`: tier1+tier2 DKK (new), Bilbasen Blog market range (used), or monthly range + no-residual note (leasing).
10. Skips greengarage.dk as a mandatory source (model pages verified 404).
11. Writes `projects/<active>/research/<filename>.md` conforming to car-template.md with full Sources table.
12. Appends a row to the per-project `state.md` Research Progress table.
13. Confirms file path, variant selected, FDM found/not-found, and any gaps.

## Requirements Implemented

| ID | Description | Status |
|----|-------------|--------|
| DETL-01 | ev-database.org live spec fetch for named car | Complete |
| DETL-02 | Per-car file written to active project's research/ | Complete |
| DETL-03 | All spec fields (WLTP, charging, battery, performance, cargo) present | Complete |
| DETL-04 | No training data — live fetch only | Complete (enforced in skill prompt) |
| DETL-05 | Every fact traces to source URL + fetch date | Complete (Sources table + assertion before write) |
| DETL-06 | FDM real-world 110 km/h range → Real-world range row | Complete |
| DETL-07 | FDM verdict, Styrker, Svagheder captured | Complete |
| DETL-08 | Missing FDM → graceful gap note | Complete |
| DETL-09 | Tier 1 and tier 2 DKK prices (new purchase_type) | Complete |
| DETL-10 | EV platform field (dedicated/adapted ICE) | Complete |
| TIRE-01 | Tire size (front, rear if different) from wheel-size.com | Complete |
| OWNR-01 | FDM reliability reputation with confidence label | Complete |
| SRCH-07 | Purchase-type branch (new/used/leasing) | Complete |

## Deviations from Plan

None — plan executed exactly as written.

Both Task 1 and Task 2 content was written in a single atomic file creation (a complete SKILL.md covering all 13 steps). This is equivalent to Task 1 writing Steps 1-6 and Task 2 appending Steps 7-13 — the content is identical; the implementation was more efficient by doing it in one Write call.

## Known Stubs

None. The skill produces procedural instructions, not data — there are no hardcoded empty values or placeholder data. All data is fetched live at skill invocation time.

## Threat Flags

No new threat surface introduced beyond what was declared in the plan's threat model. The `Bash(ls *)` restriction correctly limits shell execution to file-existence checks only (T-02-V5 mitigation in place).

## Self-Check: PASSED

- `.claude/skills/ev-detail/SKILL.md` exists: FOUND
- Commit `cc76d4d` exists: FOUND
- 328 lines (exceeds min_lines: 120): PASS
- All 13 steps present: PASS
- All automated verification commands pass: PASS
