---
phase: 01-foundation
plan: "01"
subsystem: data-contracts
tags: [template, state, data-contract, ev-research]
dependency_graph:
  requires: []
  provides:
    - car-template.md
    - state.md
  affects:
    - Phase 2 ev-detail skill (reads car-template.md)
    - ev-switch-project skill (writes state.md active_project)
tech_stack:
  added: []
  patterns:
    - YAML frontmatter for machine-readable state (backtick injection)
    - HTML comment guidance blocks inside markdown templates
key_files:
  created:
    - car-template.md
    - state.md
decisions:
  - "D-07: Template uses section headings with inline HTML guidance comments, not rigid field tables"
  - "D-08: EV platform origin and WLTP/real-world range distinction are guidance notes within Specs, not separate sections"
  - "D-05: Two-level state model — global state.md at repo root, per-project state.md in projects/<name>/"
  - "D-06: Skills read active project via backtick injection of global state.md"
metrics:
  completed: 2026-06-22
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
status: complete
---

# Phase 01 Plan 01: Data Contract Files Summary

Per-car output template and global state file created as the foundational data contract for all downstream skills.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create car-template.md | staged (committed by orchestrator) | car-template.md |
| 2 | Create global state.md | staged (committed by orchestrator) | state.md |

## What Was Built

### car-template.md

The per-car output template that Phase 2's `/ev-detail` skill will use when writing research files to `projects/<name>/research/<make-model>.md`.

Key elements:
- **Specs table** with 15 rows: WLTP range, Real-world range (mild), Real-world range (cold), Battery (usable), DC charge peak, AC charge rate, 10-80% DC charge time, 0-100 km/h, Cargo, Tow capacity, Tire size (front/rear), Price DK tier 1 and tier 2, Power output — each with Value and Source columns
- **RANGE guidance comment** explicitly requires WLTP and real-world figures reported separately with source attribution; never mixed or averaged
- **EV PLATFORM guidance comment** and `**EV platform:**` field capturing whether the car uses a dedicated EV platform or an adapted ICE platform
- **FDM Test Notes** section with handling guidance for present vs missing FDM tests
- **Tire Research** section for tire size and all-season pricing
- **Ownership Signals** section with confidence labeling guidance
- **Danish Market Context** section for registration tax and insurance tier flags
- **Sources table** requiring every fact to carry URL and fetch date

### state.md

The global state file at repo root read by all skills via backtick injection.

Key elements:
- YAML frontmatter with `active_project: none` and `last_updated:` fields (machine-readable)
- `# Global State` heading with `## Active Project` and `## Tool Notes` sections (human-readable)
- Initial state: no active project set

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Created files exist

- FOUND: /Users/user/workspace/github/car-research/car-template.md
- FOUND: /Users/user/workspace/github/car-research/state.md

### All acceptance criteria verified

**car-template.md (16/16):**
- WLTP range row present
- Real-world range (mild) row present (separate from WLTP)
- Real-world range (cold) row present
- Price DK tier 1 (from) row present
- Price DK tier 2 (best value) row present
- Power output row present
- EV PLATFORM HTML comment present
- **EV platform:** bold line present
- RANGE HTML comment present (explicitly states WLTP vs real-world distinction)
- Sources section present
- Source URL and Fetch date table headers present
- FDM Test Notes section present
- Tire Research section present
- Ownership Signals section present
- Danish Market Context section present
- Specs table header `| Field | Value | Source |` present

**state.md (7/7):**
- active_project: none in frontmatter
- last_updated: in frontmatter
- YAML frontmatter delimiters (---) present
- Global State heading present
- Active Project section present
- **Project:** none present
- Tool Notes section present

## Self-Check: PASSED

## Known Stubs

None — these are template/scaffold files; placeholder values (`[date]`, `[project name]`, `none`) are intentional and correct for their role as data contract templates.

## Threat Flags

None — no network endpoints, auth paths, or trust boundary changes introduced.
