# Phase 1: Foundation - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the data contract and project scaffolding that all skills depend on: criteria file schema (`BRIEF.md`), per-car output template (`car-template.md`), project management skills (`/ev-new-project`, `/ev-switch-project`), and state tracking (`state.md` global + per-project).

Requirements in scope: SRCH-01, SRCH-04, SRCH-05, SRCH-06, PROJ-01, PROJ-02, PROJ-03, PROJ-04

</domain>

<decisions>
## Implementation Decisions

### Criteria Schema Format
- **D-01:** Keep markdown prose format for `BRIEF.md` (renamed from `search_criteria.md`). Claude reads natural language natively; no YAML/JSON parsing needed. Headings and bullet lists under clear sections.
- **D-02:** Budget section is per purchase type. Each project specifies one purchase type, and the template scaffolds only that type's budget section (not all three).
- **D-03:** Per-brand budget overrides use percentage uplift (e.g., "BMW: +50%"), not absolute numbers. This scales across purchase types automatically (new DKK, used DKK, leasing DKK/mo).
- **D-04:** The criteria file is renamed from `search_criteria.md` to `BRIEF.md` within each project folder (`projects/<name>/BRIEF.md`).

### Active Project Tracking
- **D-05:** Two-level state model: global `state.md` at repo root (tracks active project name + tool-wide state) and per-project `projects/<name>/state.md` (tracks research progress, discovered sources, fetch reliability notes).
- **D-06:** `/ev-switch-project` updates the active project name in the global `state.md`. Skills read it via backtick injection at invocation time.

### Car Template Depth
- **D-07:** Template uses section headings with inline guidance comments (HTML comments), not rigid field tables. Detail skill has flexibility to adapt per car while knowing what to capture.
- **D-08:** EV platform origin (dedicated vs adapted ICE) and WLTP/real-world range distinction are guidance notes within the Specs section, not separate sections.

### Project Skill Guardrails
- **D-09:** When no active project is set, skills list existing projects and prompt the user to choose (or create new). No silent auto-creation.
- **D-10:** `/ev-new-project` with an existing name errors and suggests `/ev-switch-project` instead. Never overwrites existing research.
- **D-11:** No dedicated `/ev-list-projects` skill. The prompt-to-choose guardrail and `ls projects/` cover this need.

### Claude's Discretion
- Template guidance comment wording and level of detail per section
- Global `state.md` format beyond active project name (what other tool-wide state to track)
- Per-project `state.md` fields and format

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Stack & Skill Patterns
- `.planning/research/STACK.md` -- Skill structure, frontmatter fields, web fetching strategy per data source, markdown output patterns
- `CLAUDE.md` -- Project conventions, technology stack, skill structure, web fetching strategy

### Requirements
- `.planning/REQUIREMENTS.md` -- Full requirement definitions (SRCH-01, SRCH-04, SRCH-05, SRCH-06, PROJ-01..04)
- `.planning/ROADMAP.md` -- Phase 1 success criteria (7 criteria that must be TRUE)

### Existing Reference Data
- `search_criteria.md` -- Current criteria file at repo root; serves as the content reference for the BRIEF.md template (will be superseded by per-project BRIEF.md files)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No `.claude/skills/` directory exists yet -- this phase creates the first skills
- `search_criteria.md` at repo root contains a working example of criteria content that informs the BRIEF.md template schema

### Established Patterns
- `.planning/research/STACK.md` documents the skill structure pattern: `.claude/skills/<name>/SKILL.md` with frontmatter (`name`, `description`, `allowed-tools`, `context: fork`, `disable-model-invocation`)
- Backtick injection (`!`cat file``) for injecting file content at skill invocation time
- `$ARGUMENTS` for passing parameters to skills

### Integration Points
- Skills register as `/slash-commands` when placed in `.claude/skills/<name>/SKILL.md`
- Global `state.md` at repo root will be read by all skills via backtick injection
- `projects/<name>/` folder structure is the namespace for all project-scoped data

</code_context>

<specifics>
## Specific Ideas

- Budget percentage overrides preview showed "[Brand]: +50% (discount arrangement)" format -- user confirmed this pattern
- Template scaffolding for `/ev-new-project` should ask for purchase type and generate only the relevant budget section
- The "prompt to choose" pattern for missing active project should show available projects with a hint to create new

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-25*
