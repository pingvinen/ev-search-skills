---
phase: 06-fetch-cost-reduction
plan: "01"
subsystem: ev-research-skill
tags: [lever-a, orchestrator, batch-research, context-isolation]
dependency_graph:
  requires: []
  provides: ["/ev-research skill", "multi-car batch orchestration"]
  affects: [".claude/skills/ev-research/SKILL.md"]
tech_stack:
  added: ["ev-research/SKILL.md — new orchestrator skill"]
  patterns: ["inline skill (no context:fork)", "disable-model-invocation: true", "sequential fork dispatch", "$ARGUMENTS shell-quoted list"]
key_files:
  created:
    - .claude/skills/ev-research/SKILL.md
  modified: []
decisions:
  - "Sequential foreground dispatch chosen as default (avoids rate-limit risk and foreground fork overwrite-prompt surfaces to user — Pitfall 3)"
  - "disable-model-invocation: true prevents auto-trigger on any mention of batch research"
  - "Fork boundary prohibition expressed as verbatim prose per SC#7 design"
metrics:
  duration: "2m"
  completed: "2026-06-22"
  tasks_completed: 1
  files_changed: 1
status: complete
---

# Phase 06 Plan 01: /ev-research Orchestrator Skill Summary

**One-liner:** New `/ev-research` inline orchestrator that fans out one isolated `/ev-detail` fork per car and returns only status + file path per car, structurally preventing multi-car context overflow (Lever A, D-02).

## What Was Built

A new skill at `.claude/skills/ev-research/SKILL.md` — the Lever A batch orchestrator for multi-car EV research. The skill:

- Parses `$ARGUMENTS` as a shell-quoted list of car names (`/ev-research "Volvo EX30" "Renault 5" "BMW iX1"`)
- Confirms an active project exists before dispatching any forks
- Invokes `/ev-detail "<car>"` sequentially (foreground, one at a time) for each car in the list
- Records ONLY the status line + file path from each fork's Step 13 output — never page content or file bodies
- Prints a final summary table: car | status | path
- Is inline (no `context: fork`) so it can accumulate per-car status across all iterations

## Commits

| Hash | Type | Description |
|------|------|-------------|
| a4a1b96 | feat | feat(06-01): add /ev-research batch orchestrator skill (Lever A) |

## Tasks

| # | Name | Status | Commit |
|---|------|--------|--------|
| 1 | Author the /ev-research orchestrator skill | DONE | a4a1b96 |

## Acceptance Criteria — All Passed

| Criterion | Result |
|-----------|--------|
| `.claude/skills/ev-research/SKILL.md` exists | PASS |
| `name: ev-research` in frontmatter | PASS |
| `disable-model-invocation: true` in frontmatter | PASS |
| `allowed-tools: Read, Bash(ls *)` in frontmatter | PASS |
| `argument-hint` in frontmatter | PASS |
| NO `context: fork` in frontmatter | PASS |
| Backtick `cat state.md` injection in body | PASS |
| `Cars to research: $ARGUMENTS` line in body | PASS |
| `/ev-detail "<car>"` dispatch instruction in body | PASS |
| Verbatim fork-boundary prohibition (Do NOT use the Read tool on the research file) | PASS |
| Sequential dispatch default documented | PASS |
| Parallel dispatch caveat documented (Pitfall 3 / overwrite auto-deny) | PASS |
| File line count: 95 lines (>40 min, <500 max) | PASS |

## Deviations from Plan

None — plan executed exactly as written.

## Decisions Made

1. **Sequential foreground dispatch as default** — The plan listed this as Claude's Discretion (D-04). Chosen because: (a) avoids rate-limit risk from simultaneous fetches to ev-database.org and fdm.dk, (b) foreground mode surfaces the Step 3 overwrite prompt to the user, which is critical for re-run workflows. Parallel dispatch documented as an opt-in with its caveats per Pitfall 3.

2. **No additional guards on $ARGUMENTS count** — The plan specified documenting the 2-6 car suitability note. This is in the skill description (frontmatter) and in the Step 3 dispatch note. No hard limit enforced — user discretion.

## Known Stubs

None. This plan produces a skill file (prompt text), not a data-driven UI. No stubs or placeholders exist.

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| T-06-01 (mitigated) | .claude/skills/ev-research/SKILL.md | Verbatim fork-boundary prohibition in Step 4 ensures orchestrator context never holds raw page content or research file bodies (SC#7 structural guarantee confirmed) |

No new unplanned threat surface introduced. The skill delegates all live fetching to `/ev-detail` forks.

## Self-Check

### Files Created
- `.claude/skills/ev-research/SKILL.md` — FOUND

### Commits
- `a4a1b96` — FOUND (git log confirmed)

## Self-Check: PASSED
