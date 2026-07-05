# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-03-25
**Phase:** 01-foundation
**Areas discussed:** Criteria schema format, Active project tracking, Car template depth, Project skill guardrails

---

## Criteria Schema Format

### Schema style

| Option | Description | Selected |
|--------|-------------|----------|
| Keep markdown prose | Current style works -- Claude reads natural language natively. Low friction to edit. | ✓ |
| YAML-like frontmatter + prose | Structured fields at top, prose below. Hybrid approach. | |
| Pure structured (YAML/JSON) | Fully machine-readable. Less natural to write/read. | |

**User's choice:** Keep markdown prose
**Notes:** User added that budget must have a section for each purchase type, which suggests per-brand overrides should be percentage-based rather than absolute to handle both used/new and leasing.

### Per-brand budget overrides

| Option | Description | Selected |
|--------|-------------|----------|
| Percentage uplift | One override per brand (e.g., BMW: +50%). Applied to active purchase type's budget ceiling. | ✓ |
| Absolute per purchase type | Separate budget override per brand per purchase type. More precise but more to maintain. | |

**User's choice:** Percentage uplift

### Template purchase type sections

| Option | Description | Selected |
|--------|-------------|----------|
| Only active purchase type | /ev-new-project asks for purchase type and scaffolds only that budget section. | ✓ |
| All three with blanks | Template always has New/Used/Leasing sections. | |

**User's choice:** Only active purchase type

### File naming

| Option | Description | Selected |
|--------|-------------|----------|
| PROJECT.md | Paths are distinct from .planning/PROJECT.md. Name fits content well. | |
| BRIEF.md | Distinct name, conveys 'project brief'. | ✓ |
| CRITERIA.md | More specific, clearly signals search criteria. | |

**User's choice:** BRIEF.md
**Notes:** User suggested renaming from search_criteria.md to something better. Chose BRIEF.md to avoid confusion with .planning/PROJECT.md.

---

## Active Project Tracking

### State architecture

**User's choice:** Two-level state model (user-initiated, not from options)
**Notes:** User proposed a global state file for the tool and per-project state files. This was not from a presented option -- user directed the architecture.

### Global state location

| Option | Description | Selected |
|--------|-------------|----------|
| state.md at repo root | Visible, easy for skills to read via backtick injection. | ✓ |
| Inside projects/ directory | Groups all project-related state together. | |

**User's choice:** state.md at repo root

---

## Car Template Depth

### Template detail level

| Option | Description | Selected |
|--------|-------------|----------|
| Section headings + field table | Prescriptive specs table with every expected field. | |
| Section headings + guidance notes | Headings with inline comments explaining what to capture. | ✓ |
| Minimal headings only | Just section names. Maximum flexibility, least consistency. | |

**User's choice:** Section headings + guidance notes

### EV platform and range distinction

| Option | Description | Selected |
|--------|-------------|----------|
| Guidance in Specs | Keep in Specs guidance comment. Avoids over-fragmenting sections. | ✓ |
| Separate sections | Dedicated Platform section and explicit range split. | |

**User's choice:** Guidance in Specs

---

## Project Skill Guardrails

### No active project behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Error with hint | Stop and tell user to set project. | |
| Auto-create default | Auto-create 'default' project. | |
| Prompt to choose | List existing projects and ask which to use. | ✓ |

**User's choice:** Prompt to choose

### Duplicate project name

| Option | Description | Selected |
|--------|-------------|----------|
| Error and suggest switch | Tell user project exists, suggest /ev-switch-project. | ✓ |
| Switch to it silently | Treat as implicit switch. | |
| Ask what to do | Prompt with options. | |

**User's choice:** Error and suggest switch

### /ev-list-projects skill

| Option | Description | Selected |
|--------|-------------|----------|
| No dedicated skill | Prompt-to-choose guardrail already lists projects. | ✓ |
| Yes, add skill | Dedicated skill showing all projects with details. | |

**User's choice:** No dedicated skill

---

## Claude's Discretion

- Template guidance comment wording and detail level
- Global state.md format beyond active project name
- Per-project state.md fields and format

## Deferred Ideas

None -- discussion stayed within phase scope
