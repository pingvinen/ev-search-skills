---
phase: 03-search-and-compare
plan: "01"
subsystem: ev-search-skill
tags: [skill, ev-search, curl, python3, ev-database, dk-price-band, search-candidates]
dependency_graph:
  requires: []
  provides: [/ev-search skill, Search Candidates section in state.md]
  affects: [projects/<active>/state.md]
tech_stack:
  added: [Bash(curl), Bash(python3), ev-search skill]
  patterns: [Mozilla-UA curl fetch, python3 jplist HTML extraction, DK price WebSearch band, state.md read-modify-write]
key_files:
  created: [.claude/skills/ev-search/SKILL.md]
  modified: []
decisions:
  - "D-01 resolved: curl + python3 on the 8.9 MB server-rendered root listing is the discovery mechanism (live probe confirmed)"
  - "D-05 enforced: no EUR->DKK conversion; DK price comes exclusively from per-candidate WebSearch"
  - "D-12 enforced: borderline near-misses always surfaced in grouped output, never silently dropped"
  - "Candidate cap set at 20 with EUR pre-filter (brief_max_DKK / 6) to keep DK price WebSearch cost bounded"
  - "Skill runs inline (no context:fork) so user can ask follow-up questions after search"
metrics:
  duration: "~15 min"
  completed: "2026-06-28"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 0
status: complete
---

# Phase 03 Plan 01: ev-search Skill Summary

**One-liner:** `/ev-search` skill using curl + python3 HTML extraction on ev-database.org root listing, with per-candidate DK price WebSearch bands and Search Candidates section written to state.md.

## What Was Built

The `/ev-search` Claude Code skill at `.claude/skills/ev-search/SKILL.md` delivers SRCH-02 and SRCH-03: reads the active project's `brief.md`, discovers matching EV models from ev-database.org via the confirmed D-01 mechanism, attaches a DK price band per candidate, persists results to `state.md`, and ends with a `/ev-research "A" "B"` handoff command.

### Key implementation decisions

- **Discovery:** `curl -s -A "Mozilla/5.0"` downloads the 8.9 MB root listing to `/tmp/evdb_listing.html`; a 100 KB sanity abort prevents silently parsing the 64 KB 404 bot-detection page (Pitfall 1).
- **Filtering:** python3 script maps brief body type text to `shape-*` CSS classes, filters by seats/range/battery, applies EUR pre-filter cap (`brief_max_DKK / 6`), caps at 20 candidates sorted by EUR price ascending.
- **DK price band:** one WebSearch per candidate (`"<make> <model> pris DKK"`); buckets as `within budget` / `slight stretch` / `over budget` / `price unknown` relative to brief preferred+maximum; per-brand overrides applied as a multiplier on maximum.
- **state.md write:** read-modify-write of only the `## Search Candidates` section; EVDB Range column label (not WLTP) per Pitfall 2 and D-16; dated `_Last updated_` snapshot per D-13.
- **Handoff:** grouped chat output (match / borderline / excluded) ending with `/ev-research "A" "B"` listing match + borderline candidates.

## Tasks

| # | Task | Status | Commit | Files |
|---|------|--------|--------|-------|
| 1 | Author the ev-search SKILL.md | Complete | 506b009 | `.claude/skills/ev-search/SKILL.md` (created, 256 lines) |
| 2 | Live discovery smoke test | Complete | — (verification only, no file changes) | `.claude/skills/ev-search/SKILL.md` |

## Verification Results

### Task 1 gate (structural checks)
All acceptance criteria passed:
- `name: ev-search` ✓
- `allowed-tools:` includes `Bash(curl`, `WebSearch`, `Write` ✓
- No `context: fork` ✓
- `!`cat state.md`` backtick injection present, no `$ARGUMENTS` ✓
- `Mozilla/5.0` in curl step with 100 KB sanity abort ✓
- `EVDB Range` column label ✓
- `## Search Candidates` section heading ✓
- `/ev-research` handoff command ✓

### Task 2 gate (live smoke test, 2026-06-28)
```
File size:   8,915,558 bytes  (>100 KB — real listing, not 404)
list-item blocks:  1,367       (all cars present)
shape-suv spans:     672       (>0 — structure confirmed)
erange_real fields:  1,367
battery hidden fields: 817
Gate result: PASS
```

ev-database.org HTML structure (shape-*, erange_real, battery hidden spans) is exactly as documented in Phase 3 research. The embedded python3 script in the skill matches live HTML. No SKILL.md correction was needed.

## Deviations from Plan

None — plan executed exactly as written. The smoke test confirmed the research assumptions; no correction to the embedded script was required.

## Known Stubs

None. The skill's python3 script contains the full runnable extraction logic. The DK price band step, state.md section schema, and handoff format are all specified inline — no placeholder content.

## Threat Surface Scan

No new network endpoints or auth paths introduced. The skill fetches one hardcoded URL (`https://ev-database.org`) via curl and performs WebSearch queries — both are read-only fetch patterns already covered by the plan's threat model (T-03-01 through T-03-SC). The state.md write path is bounded to `projects/<active_project>/state.md` per T-03-02. No new threat surface beyond what the threat model registers.

## Self-Check: PASSED

- `.claude/skills/ev-search/SKILL.md` exists: FOUND
- Commit 506b009 exists: FOUND
- SUMMARY.md written to `.planning/phases/03-search-and-compare/03-01-SUMMARY.md`: FOUND
