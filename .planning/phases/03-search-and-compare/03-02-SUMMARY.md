---
phase: 03-search-and-compare
plan: "02"
subsystem: ev-compare-skill
tags: [skill, comparison, write-side, ev-research]
dependency_graph:
  requires:
    - projects/<active>/research/*.md (written by /ev-detail or /ev-research)
    - state.md (global active_project resolution)
    - projects/<active>/brief.md (brief-aware verdict in Step 5)
  provides:
    - .claude/skills/ev-compare/SKILL.md (/ev-compare skill)
    - projects/<active>/comparison.md (at runtime)
  affects: []
tech_stack:
  added:
    - Claude Code skill: ev-compare (write-side, Glob+Read+Write)
  patterns:
    - backtick injection for active project resolution (state.md)
    - project-scoped Glob (projects/<active>/research/*.md)
    - disable-model-invocation: true (write-side guard)
    - unconditional single-Write output (comparison.md)
    - three separate labelled range rows (WLTP/mild/cold — D-16)
    - explicit gap text rendering (D-17)
    - best-in-class bold marking per row
    - brief-aware verdict from brief.md (D-14/D-15)
key_files:
  created:
    - .claude/skills/ev-compare/SKILL.md
  modified: []
decisions:
  - "disable-model-invocation: true required — write-side skill must never auto-trigger (D-18, Pitfall 4)"
  - "Glob path built from resolved active_project — never hardcoded (D-18/PROJ-03/Pitfall 5)"
  - "Three separate range rows mandatory: WLTP (manufacturer rated), real-world mild (FDM or EVDB), real-world cold (FDM or EVDB) — D-16 locked"
  - "Gap text explicit, never blank: no FDM test / unconfirmed / not available (<type>) — D-17 locked"
  - "Single Write call unconditional overwrite — explicit-invoke-only skill, no overwrite guard needed"
metrics:
  duration_seconds: 420
  completed_date: "2026-06-28"
  tasks_total: 2
  tasks_completed: 2
  files_created: 1
  files_modified: 0
status: complete
---

# Phase 03 Plan 02: ev-compare skill Summary

**One-liner:** Write-side `/ev-compare` skill — project-scoped Glob of `research/*.md` → side-by-side `comparison.md` with three separate labelled range rows (WLTP/mild/cold), best-in-class bold per row, and brief-aware verdict.

## What Was Built

The `/ev-compare` Claude Code skill at `.claude/skills/ev-compare/SKILL.md`.

At runtime, the skill:
1. Resolves the active project from the backtick-injected `state.md`
2. Globs `projects/<active_project>/research/*.md` (project-scoped, not cross-project)
3. Reads each per-car file and extracts 15 Specs rows + EV platform + FDM qualitative fields
4. Builds a side-by-side Markdown comparison table with one column per car
5. Keeps WLTP range, real-world mild, real-world cold as three separate rows each with methodology labels
6. Marks best-in-class per row (bold) and renders all gaps as explicit text
7. Reads `projects/<active>/brief.md` to write a 2-3 sentence brief-aware verdict
8. Writes `projects/<active_project>/comparison.md` in a single unconditional Write call

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author the ev-compare SKILL.md | 7c35e28 | .claude/skills/ev-compare/SKILL.md (created, 167 lines) |
| 2 | Verify range-methodology + gap-rendering contract | — | No changes needed; gate PASS on Task 1 output |

## Verification Gates

Both automated gates printed PASS without any fixes needed:

**Task 1 gate:**
- `name: ev-compare` present in frontmatter ✓
- `disable-model-invocation: true` present ✓
- `allowed-tools: Read, Write, Glob` present ✓
- `research/*.md` pattern present ✓
- `comparison.md` output present ✓
- WLTP range row present ✓
- Real-world range (mild) row present ✓
- Real-world range (cold) row present ✓
- No `$ARGUMENTS` line ✓

**Task 2 gate:**
- All three range rows present as separate labelled rows ✓
- `no FDM test` gap text present ✓
- Best-in-class marking (`bold the`) specified ✓
- `active_project` variable used in Glob path ✓

## Requirements Delivered

| Req | Description | Status |
|-----|-------------|--------|
| COMP-01 | /ev-compare reads all active-project research/*.md | Satisfied — Step 2 Globs project-scoped path, Step 3 reads all files |
| COMP-02 | WLTP range and FDM real-world range appear as separate labelled rows | Satisfied — Step 4 defines three distinct rows with methodology labels |
| COMP-03 | Writes projects/<active>/comparison.md with one column per car | Satisfied — Step 6 single Write to project-scoped path |

## Decisions Made

1. **`disable-model-invocation: true` is mandatory.** The skill overwrites `comparison.md` unconditionally on every run. Without this flag Claude would auto-trigger it on any "compare" utterance, silently clobbering the file (Pitfall 4, D-18).

2. **Glob path built from resolved `active_project`.** Never hardcode `research/*.md` — this would read across project boundaries, violating PROJ-03 isolation (Pitfall 5, D-18).

3. **Three separate range rows are a locked decision (D-16).** WLTP and real-world ranges measure different things and must never be merged or averaged. Each row carries its methodology in parentheses so the figures are unambiguous without any additional context.

4. **Explicit gap text, never blank (D-17).** Blank cells in a comparison table look like "equal" or "unavailable" — they are ambiguous. Explicit text (`no FDM test`, `unconfirmed`) makes the data quality visible.

5. **Single unconditional Write.** The skill is explicit-invoke-only (protected by `disable-model-invocation: true`), so no overwrite prompt or guard is needed. Write once, overwrite cleanly.

## Deviations from Plan

None. Plan executed exactly as written. Both gates passed without requiring any fixes.

## Known Stubs

None. The skill is fully specified with no placeholder values, hardcoded data, or TODO markers. Output is generated at runtime from live research files.

## Threat Surface

| Flag | File | Description |
|------|------|-------------|
| T-03-04 handled | .claude/skills/ev-compare/SKILL.md | research/*.md content is echoed into comparison.md as table cells only; gaps rendered as fixed explicit strings; no execution of file content |
| T-03-05 handled | .claude/skills/ev-compare/SKILL.md | Glob path built solely from resolved active_project; never a bare research/ glob |
| T-03-06 handled | .claude/skills/ev-compare/SKILL.md | disable-model-invocation: true in frontmatter prevents accidental auto-invocation |

## Self-Check: PASSED

- FOUND: .claude/skills/ev-compare/SKILL.md
- FOUND: .planning/phases/03-search-and-compare/03-02-SUMMARY.md
- FOUND commit: 7c35e28 (feat(03-02): author ev-compare SKILL.md)
