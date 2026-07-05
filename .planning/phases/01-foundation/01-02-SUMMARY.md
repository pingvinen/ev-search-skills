---
phase: 01-foundation
plan: "02"
subsystem: project-management-skills
tags: [skills, project-lifecycle, state-management, ev-research]
dependency_graph:
  requires:
    - state.md (created by 01-01)
  provides:
    - .claude/skills/ev-new-project/SKILL.md
    - .claude/skills/ev-switch-project/SKILL.md
  affects:
    - Phase 2 ev-detail skill (reads active project from state.md)
    - Phase 2 ev-search skill (reads active project from state.md)
    - Phase 3 ev-compare skill (reads active project from state.md)
tech_stack:
  added: []
  patterns:
    - Claude Code skill frontmatter (name, description, allowed-tools, disable-model-invocation, argument-hint)
    - Backtick injection for reading state.md at invocation time
    - $ARGUMENTS substitution for project name parameter
    - Bash(ls *) for directory existence checks
    - disable-model-invocation: true on both write-side skills
key_files:
  created:
    - .claude/skills/ev-new-project/SKILL.md
    - .claude/skills/ev-switch-project/SKILL.md
decisions:
  - "D-09: When no active project is set, skills list existing projects and prompt user — no silent auto-creation"
  - "D-10: /ev-new-project with existing name errors and suggests /ev-switch-project — never overwrites"
  - "D-02: BRIEF.md scaffolds only ONE budget section matching the chosen purchase type"
  - "D-03: Per-brand budget overrides use percentage uplift (e.g., BMW: +50%), not absolute numbers"
  - "D-01: BRIEF.md uses markdown prose format — named sections with bullet lists, no YAML/JSON"
metrics:
  completed: 2026-06-22
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
status: complete
---

# Phase 01 Plan 02: Project Management Skills Summary

Two Claude Code skills created for project lifecycle management: /ev-new-project (scaffold + guardrails) and /ev-switch-project (state switching), both reading global state.md via backtick injection and writing to disk on completion.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create /ev-new-project skill | staged (committed by orchestrator) | .claude/skills/ev-new-project/SKILL.md |
| 2 | Create /ev-switch-project skill | staged (committed by orchestrator) | .claude/skills/ev-switch-project/SKILL.md |

## What Was Built

### .claude/skills/ev-new-project/SKILL.md

Project creation skill with embedded BRIEF.md template and guardrails.

Key elements:
- **Frontmatter:** `disable-model-invocation: true`, `allowed-tools: Write, Read, Bash(mkdir *, ls *)`, `argument-hint: [project-name]`
- **Backtick injection:** `!`cat state.md 2>/dev/null || echo "state.md not found"`` reads global state before execution
- **D-10 guardrail (Step 1):** Checks `ls projects/$ARGUMENTS/ 2>/dev/null` before creating anything. If the directory exists, stops and redirects user to `/ev-switch-project` — never overwrites existing research
- **D-02 purchase type prompt (Step 2):** Asks user for `new`, `used`, or `leasing` before creating BRIEF.md; only the matching budget subsection is scaffolded
- **Project scaffold (Step 3):** Creates `projects/$ARGUMENTS/research/` (via mkdir -p), `BRIEF.md`, per-project `state.md`, and placeholder `comparison.md`
- **Global state update (Step 4):** Updates both the YAML frontmatter `active_project:` and the markdown body `**Project:**` in global `state.md`, plus `last_updated` and `**Switched:**` dates
- **BRIEF.md template** embedded inline with: `**Purchase type:**` field, `## Context`, `## Budget` (one of three purchase-type variants), `### Per-brand overrides` (percentage uplift pattern per D-03), `## Must-Have Features` (with BEV starter bullet), `## Body Type`, `## Seats`, `## Preferred Features`, `## Brand Notes`
- **Per-project state.md template** embedded inline with: `## Research Progress` table (Car model, File, Researched, FDM found), `## Source Reliability Notes`, `## Discovered Sources`

### .claude/skills/ev-switch-project/SKILL.md

Project switching skill that updates global state.md active project field.

Key elements:
- **Frontmatter:** `disable-model-invocation: true`, `allowed-tools: Write, Read, Bash(ls *)`, `argument-hint: [project-name]`
- **Backtick injection:** Two-line pattern — `Current global state:` then `!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"``
- **D-09 no-argument handling:** If `$ARGUMENTS` is empty, lists existing projects with `ls projects/` and prompts the user to choose; if no projects exist, suggests `/ev-new-project`
- **D-09 existence check (Step 1):** Verifies `projects/$ARGUMENTS/` exists with `ls`; if not, lists available projects and suggests `/ev-new-project "$ARGUMENTS"` to create it
- **State update (Step 2):** Updates `active_project:` in YAML frontmatter and `**Project:**` in markdown body, with date fields
- **Confirmation (Step 3):** Shows previous project, new active project, and lists files in `projects/$ARGUMENTS/research/` for context

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Created files exist

- FOUND: /Users/user/workspace/github/car-research/.claude/skills/ev-new-project/SKILL.md
- FOUND: /Users/user/workspace/github/car-research/.claude/skills/ev-switch-project/SKILL.md

### Task 1 automated checks (all passed)

- `disable-model-invocation: true` present in frontmatter
- `name: ev-new-project` present in frontmatter
- `BRIEF.md` referenced (template embedded)
- "already exists" error message present (D-10 guardrail)
- "purchase type" question present (D-02)
- `ev-switch-project` suggestion in error path (D-10)
- backtick injection `cat state.md` present

### Task 2 automated checks (all passed)

- `disable-model-invocation: true` present in frontmatter
- `name: ev-switch-project` present in frontmatter
- backtick injection `cat state.md` present
- `active_project` update instruction present
- `ev-new-project` suggestion present in missing-project path

### Additional acceptance criteria

**ev-new-project:**
- `allowed-tools: Write, Read, Bash(mkdir *, ls *)` — PASS
- `argument-hint: [project-name]` — PASS
- `$ARGUMENTS` for project name substitution — PASS
- `ls projects/$ARGUMENTS` existence check — PASS
- "purchase type" options `new`, `used`, `leasing` — PASS
- `## Budget` section in BRIEF template — PASS
- `### Per-brand overrides` subsection with percentage uplift example — PASS
- `## Must-Have Features` section — PASS
- Per-project state.md template with `## Research Progress` table — PASS
- Instruction to update global `state.md` with `active_project:` — PASS
- Instruction to create `projects/$ARGUMENTS/comparison.md` — PASS
- Instruction to run `mkdir -p projects/$ARGUMENTS/research` — PASS
- Only ONE budget section scaffolded per purchase type (D-02) — PASS

**ev-switch-project:**
- `allowed-tools: Write, Read, Bash(ls *)` — PASS
- `argument-hint: [project-name]` — PASS
- `$ARGUMENTS` for project name substitution — PASS
- Existence check for `projects/$ARGUMENTS/` — PASS
- Fallback to list existing projects when target doesn't exist — PASS
- Suggestion to use `/ev-new-project` when project doesn't exist — PASS
- Instruction to update `active_project:` in state.md — PASS
- No-argument handling that lists projects and prompts user (D-09) — PASS

## Self-Check: PASSED

## Known Stubs

None — these are skill prompt files. Placeholder tokens (`$ARGUMENTS`, `[project name]`, `[date]`, `[purchase type]`) are intentional substitution markers, not stubs.

## Threat Flags

None — no network endpoints, auth paths, file access beyond `projects/` namespace, or trust boundary changes introduced.
