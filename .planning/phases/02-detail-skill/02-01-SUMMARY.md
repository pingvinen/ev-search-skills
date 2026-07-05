---
phase: 02-detail-skill
plan: "01"
subsystem: validation-fixtures
status: complete
tags:
  - validation
  - fixtures
  - test-projects
  - checklist
dependency_graph:
  requires:
    - .claude/skills/ev-new-project/SKILL.md
    - .planning/phases/02-detail-skill/02-VALIDATION.md
    - car-template.md
  provides:
    - projects/ev-detail-test-new/BRIEF.md
    - projects/ev-detail-test-used/BRIEF.md
    - projects/ev-detail-test-leasing/BRIEF.md
    - .planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md
  affects:
    - .planning/phases/02-detail-skill/02-02-PLAN.md
tech_stack:
  added: []
  patterns:
    - ev-new-project BRIEF.md schema (purchase_type + budget subsection per type)
    - per-project state.md template (Research Progress table, empty header only)
key_files:
  created:
    - projects/ev-detail-test-new/BRIEF.md
    - projects/ev-detail-test-new/state.md
    - projects/ev-detail-test-new/comparison.md
    - projects/ev-detail-test-used/BRIEF.md
    - projects/ev-detail-test-used/state.md
    - projects/ev-detail-test-used/comparison.md
    - projects/ev-detail-test-leasing/BRIEF.md
    - projects/ev-detail-test-leasing/state.md
    - projects/ev-detail-test-leasing/comparison.md
    - .planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md
  modified: []
decisions:
  - "Test fixtures use exact ev-new-project BRIEF.md and state.md templates — no invented fields"
  - "Global state.md left at active_project: none — Plan 03 switches per golden-run scenario"
  - "Validation checklist maps all 5 golden-run scenarios from 02-VALIDATION.md with per-checkbox requirement IDs"
metrics:
  duration: "7 minutes"
  completed: 2026-06-22
  tasks_completed: 2
  tasks_total: 2
  files_created: 10
  files_modified: 0
requirements:
  - DETL-02
  - SRCH-07
---

# Phase 02 Plan 01: Validation Fixtures Summary

Wave 0 test-project scaffolds (three purchase types) and a traceable golden-run checklist for Phase 2 `/ev-detail` validation.

## What Was Built

### Task 1 — Three test-project scaffolds (new / used / leasing)

Three project directories under `projects/` were created, each mirroring the exact schema produced by `/ev-new-project` (PROJ-01 schema). Each contains BRIEF.md, state.md, and comparison.md.

**ev-detail-test-new** (purchase_type: new)
- Budget: Preferred 300,000 DKK / Maximum 350,000 DKK
- Must-haves: Electric only (BEV), Wireless Android Auto
- Body: SUV / crossover, 4-5 seats
- Purpose: drives the Volvo EX30 happy-path golden run (DETL-01..10, TIRE-01, OWNR-01)

**ev-detail-test-used** (purchase_type: used)
- Budget: Preferred 220,000 DKK / Maximum 260,000 DKK, Max age 3 years, Max km 60,000
- Same must-haves/body/seats
- Purpose: drives the Bilbasen market-range branch golden run (SRCH-07 used)

**ev-detail-test-leasing** (purchase_type: leasing)
- Budget: Monthly 4,500 DKK/mo, Max upfront 25,000 DKK, Lease term 36 months
- Same must-haves/body/seats
- Purpose: drives the leasing monthly-payment-range branch golden run (SRCH-07 leasing)

Each per-project state.md has the Research Progress table with the header row only — the skill appends rows at golden-run time. Global repo-root state.md left unchanged (active_project: none).

### Task 2 — Golden-run validation checklist

`.planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md` written with:
- "How to Run" preamble (switch project → run skill → inspect output against car-template.md)
- 5 Golden-Run scenarios, each specifying: test project, switch command, exact `/ev-detail` invocation, and checkbox pass conditions
- Every checkbox traceable to one or more requirement/decision IDs (DETL-01..10, TIRE-01, OWNR-01, SRCH-07, D-05/D-06/D-07/D-08/D-09)
- Requirement coverage summary table mapping all req IDs to their scenarios
- Final sign-off block with 6 checkboxes and instruction to set `nyquist_compliant: true` in 02-VALIDATION.md

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 46fee4b | feat(02-01): create three purchase-type test-project fixtures |
| Task 2 | 7ee217e | feat(02-01): write golden-run validation checklist for Phase 2 |

## Self-Check: PASSED

- [x] projects/ev-detail-test-new/BRIEF.md exists
- [x] projects/ev-detail-test-used/BRIEF.md exists
- [x] projects/ev-detail-test-leasing/BRIEF.md exists
- [x] All state.md files have Research Progress table header
- [x] Global state.md unchanged (active_project: none)
- [x] VALIDATION-CHECKLIST.md exists with Golden-Run section and DETL-0x requirement IDs
- [x] Commit 46fee4b exists in git log
- [x] Commit 7ee217e exists in git log
