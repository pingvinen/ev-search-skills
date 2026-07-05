# Phase 1: Foundation - Research

**Researched:** 2026-03-25
**Domain:** Claude Code skills architecture — data contracts, file schema, project management skills
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Keep markdown prose format for `BRIEF.md` (renamed from `search_criteria.md`). Claude reads natural language natively; no YAML/JSON parsing needed. Headings and bullet lists under clear sections.
- **D-02:** Budget section is per purchase type. Each project specifies one purchase type, and the template scaffolds only that type's budget section (not all three).
- **D-03:** Per-brand budget overrides use percentage uplift (e.g., "BMW: +50%"), not absolute numbers. This scales across purchase types automatically (new DKK, used DKK, leasing DKK/mo).
- **D-04:** The criteria file is renamed from `search_criteria.md` to `BRIEF.md` within each project folder (`projects/<name>/BRIEF.md`).
- **D-05:** Two-level state model: global `state.md` at repo root (tracks active project name + tool-wide state) and per-project `projects/<name>/state.md` (tracks research progress, discovered sources, fetch reliability notes).
- **D-06:** `/ev-switch-project` updates the active project name in the global `state.md`. Skills read it via backtick injection at invocation time.
- **D-07:** Template uses section headings with inline guidance comments (HTML comments), not rigid field tables. Detail skill has flexibility to adapt per car while knowing what to capture.
- **D-08:** EV platform origin (dedicated vs adapted ICE) and WLTP/real-world range distinction are guidance notes within the Specs section, not separate sections.
- **D-09:** When no active project is set, skills list existing projects and prompt the user to choose (or create new). No silent auto-creation.
- **D-10:** `/ev-new-project` with an existing name errors and suggests `/ev-switch-project` instead. Never overwrites existing research.
- **D-11:** No dedicated `/ev-list-projects` skill. The prompt-to-choose guardrail and `ls projects/` cover this need.

### Claude's Discretion

- Template guidance comment wording and level of detail per section
- Global `state.md` format beyond active project name (what other tool-wide state to track)
- Per-project `state.md` fields and format

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCH-01 | Skills read search parameters from the active project's `search_criteria.md` (budget, range, body type, seats, requirements, exclusions) | Backtick injection pattern confirmed: `!`cat projects/$(active-project)/BRIEF.md`` reads file at invocation time |
| SRCH-04 | Search criteria schema supports per-brand budget overrides (e.g., a higher ceiling for one brand where the user has a discount arrangement) | Locked as percentage uplift (D-03); markdown prose section handles this naturally |
| SRCH-05 | Search criteria schema supports a must-have features list (e.g., wireless Android Auto) that filters results | Markdown section "Must-Have Features" with bullet list; skills parse by reading the section |
| SRCH-06 | Search criteria schema includes a `purchase_type` field with values: `new`, `used`, or `leasing` — defaults to `new` if omitted | Markdown heading or bold field in BRIEF.md; backtick injection makes it available to skills |
| PROJ-01 | `/ev-new-project "<name>"` creates `projects/<name>/` with `search_criteria.md` (from template schema), empty `research/` subfolder, and placeholder `comparison.md` | Skill uses Write + Bash to create dirs; must also create BRIEF.md (from template), not search_criteria.md (name change D-04) |
| PROJ-02 | `/ev-switch-project "<name>"` sets active project context; subsequent skill invocations operate within that project's folder | Writes project name to global `state.md`; other skills inject it via backtick |
| PROJ-03 | Each project is a self-contained silo — skills never read or compare across project boundaries | Enforced by always constructing paths via `projects/$(active-project)/`; no cross-project glob patterns |
| PROJ-04 | Active project context persists across skill invocations within a session (no need to re-switch) | Global `state.md` persists to disk; each skill reads it fresh via backtick injection |
</phase_requirements>

---

## Summary

Phase 1 creates the data contract and project scaffolding that all downstream skills depend on. It is a pure authoring phase — no web fetching, no per-car research. The deliverables are: the `BRIEF.md` criteria file schema, the `car-template.md` per-car output template, two project management skills (`/ev-new-project`, `/ev-switch-project`), and two state files (`state.md` global and per-project).

The technical domain is Claude Code skill authoring: SKILL.md frontmatter, backtick injection for dynamic file reading, `$ARGUMENTS` substitution, and the `allowed-tools` permission model. All patterns are verified against the current Claude Code docs (fetched 2026-03-25). No runtime beyond Claude itself is involved — no npm, no Python, no build step.

The key constraint driving every design decision is that Claude reads markdown natively. Schema enforcement comes from well-named sections and inline HTML comments that guide the detail skill, not from parsing rules. The WLTP/real-world range distinction is enforced by labeling in the template, not by code.

**Primary recommendation:** Author all four deliverables (BRIEF.md template, car-template.md, ev-new-project skill, ev-switch-project skill) as markdown files. Use backtick injection to read state.md at invocation time. This phase produces no runnable code — it produces the corpus that subsequent phases consume.

---

## Standard Stack

### Core Technologies

| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| Claude Code skills | Current | Skill definition via SKILL.md in `.claude/skills/` | Native to environment; no runtime needed; files become `/slash-commands` automatically |
| Markdown files | Plain text | BRIEF.md (criteria schema), car-template.md (output template), state.md (project state) | Zero dependencies; Claude reads natively; diffs cleanly in git |
| Bash (minimal) | macOS built-in | `mkdir -p` inside `/ev-new-project` to create project folder structure | Only needed for directory creation; no external tools |

### Supporting Patterns

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| Backtick injection `!`cat file`` | Read file content at skill invocation time before Claude sees the prompt | Every skill that reads `state.md` or `BRIEF.md` |
| `$ARGUMENTS` substitution | Pass project name to `/ev-new-project` and `/ev-switch-project` | Both project management skills |
| HTML comments in templates | Inline guidance notes inside template sections | `car-template.md` — guides detail skill without appearing in output |
| `allowed-tools: Write, Bash, Read` | Scope tool permissions | `/ev-new-project` needs Write (create files) + Bash (mkdir) + Read (verify); `/ev-switch-project` needs Write + Read |
| `disable-model-invocation: true` | Prevent auto-triggering of file-creating skills | Both project management skills — should only run on explicit user invocation |

### Installation

No installation needed. All deliverables are markdown files committed to the repo.

---

## Architecture Patterns

### Project Directory Structure (outcome of this phase)

```
.claude/skills/
├── ev-new-project/
│   └── SKILL.md          # Creates projects/<name>/ scaffolding
└── ev-switch-project/
    └── SKILL.md          # Updates state.md active project

projects/                 # Created by /ev-new-project at runtime
└── <name>/
    ├── BRIEF.md          # Criteria file (from template schema)
    ├── state.md          # Per-project state
    ├── research/         # Empty at creation; populated by ev-detail
    └── comparison.md     # Placeholder at creation

state.md                  # Global state file at repo root
car-template.md           # Per-car output template (reference for ev-detail)
```

Note: `car-template.md` lives at repo root (or `.claude/skills/ev-detail/output-template.md` when the detail skill is built in Phase 2). For this phase, root placement is fine.

### Pattern 1: Backtick Injection for Active Project

Skills discover the active project by injecting `state.md` content before Claude executes.

```yaml
---
name: ev-switch-project
description: Switch the active EV research project. Use when the user asks to switch projects or change context to a different project.
allowed-tools: Write, Read, Bash
disable-model-invocation: true
argument-hint: [project-name]
---

Current global state:
!`cat state.md`

The user wants to switch to project: $ARGUMENTS

1. Verify that `projects/$ARGUMENTS/` exists. If not, list existing projects with `ls projects/` and tell the user to create it first with `/ev-new-project`.
2. Update `state.md` — change the `active_project:` value to `$ARGUMENTS`.
3. Confirm the switch to the user.
```

**What happens:** `!`cat state.md`` runs before Claude sees anything. Claude receives the rendered content with actual state values, then follows the instructions with that knowledge.

### Pattern 2: Active Project Path Construction

Every skill that operates within a project constructs its file paths from the active project name read via backtick injection:

```
Current state:
!`cat state.md`

Active project directory: projects/[active_project from state.md]/
Criteria file: projects/[active_project]/BRIEF.md
Research files: projects/[active_project]/research/
```

This pattern ensures PROJ-03 (project silos) — skills never hardcode project names.

### Pattern 3: ev-new-project Guardrails

```yaml
---
name: ev-new-project
description: Create a new EV research project. Use when the user wants to start researching a new set of cars with different criteria.
allowed-tools: Write, Read, Bash
disable-model-invocation: true
argument-hint: [project-name]
---

!`cat state.md 2>/dev/null || echo "state.md not found"`

Project name requested: $ARGUMENTS

Before creating anything:
1. Check if `projects/$ARGUMENTS/` already exists using Bash(`ls projects/$ARGUMENTS/ 2>/dev/null`).
   - If it EXISTS: stop, tell the user the project already exists, suggest `/ev-switch-project "$ARGUMENTS"` instead. Never overwrite.
2. Ask the user: what is the purchase type for this project? Options: `new`, `used`, or `leasing`. Default `new` if they don't specify.
3. Create the project scaffold:
   - `mkdir -p projects/$ARGUMENTS/research`
   - Write `projects/$ARGUMENTS/BRIEF.md` using the BRIEF template (see below)
   - Write `projects/$ARGUMENTS/state.md` with initial per-project state
   - Write `projects/$ARGUMENTS/comparison.md` as placeholder
4. Update global `state.md` to set `active_project: $ARGUMENTS`
5. Confirm creation to the user

[BRIEF template embedded or referenced here]
```

### Pattern 4: BRIEF.md Schema (Prose Markdown)

The criteria file uses named sections with bullet lists — no YAML, no JSON. This is the schema all skills expect to read.

```markdown
# Project Brief: [Project Name]

**Purchase type:** new

## Context
[Why this search, what's being replaced, key constraints]

## Budget
**Preferred range:** 200,000 – 300,000 DKK
**Maximum:** 400,000 DKK

### Per-brand overrides
- [Brand]: +50% (discount arrangement)

## Must-Have Features
- Electric only (BEV)
- Minimum 300 km WLTP range
- Tow hitch available (factory or aftermarket)
- Wireless Android Auto

## Body Type
[SUV / small crossover preferred; open to hatchbacks]

## Seats
[4–5 seats]

## Preferred Features
- Heated steering wheel
- Matrix headlights
- Heated front and rear seats

## Brand Notes
- [Brand]: EXCLUDED
- French brands (Peugeot, Citroen, Renault, DS): research quality thoroughly
- Chinese brands: note data privacy stance and DK service network
```

**Key design points:**
- `**Purchase type:**` on a named line so skills can extract it with natural language reasoning
- "Per-brand overrides" subsection uses percentage uplift (D-03)
- "Must-Have Features" is the filter list for SRCH-05
- Section names are stable — skills reference them by heading name

### Pattern 5: car-template.md with HTML Guidance Comments

```markdown
# [Make Model Variant]

**Researched:** [date]
**Project:** [project name]

## Quick Verdict
<!-- 2-3 sentences: does it meet the BRIEF criteria, what stands out -->

## Specs

<!-- RANGE: Always report WLTP range AND real-world range separately. Never mix or average them.
     WLTP = manufacturer-claimed standardized test figure
     Real-world = FDM measured at 110 km/h, or ev-database.org "mild weather" figure
     If only one is available, state which and note the other is missing. -->

| Field | Value | Source |
|-------|-------|--------|
| WLTP range | km | |
| Real-world range (mild) | km | |
| Real-world range (cold) | km | |
| Battery (usable) | kWh | |
| DC charge peak | kW | |
| AC charge rate | kW | |
| 10–80% DC charge time | min | |
| 0–100 km/h | s | |
| Cargo | L | |
| Tow capacity | kg | |
| Tire size (front) | | |
| Tire size (rear) | | |
| Price DK tier 1 (from) | DKK | |
| Price DK tier 2 (best value) | DKK | |
| Power output | kW | |

<!-- EV PLATFORM: Note whether this car is built on a dedicated EV platform or an adapted ICE platform.
     Example: "Dedicated EV platform (MEB)" or "Adapted ICE platform (PF1)" -->
**EV platform:** [dedicated / adapted ICE + platform name]

## FDM Test Notes
<!-- If FDM test found: extract measured range, charging performance, verdict, pros/cons
     If no FDM test found: write "No FDM test found as of [date]" -->

## Tire Research
<!-- Capture tire size and current price estimate for a quality all-season set (Michelin/Goodyear tier) -->

## Ownership Signals
<!-- Reliability reputation, known issues, brand quality signals. Label each with confidence and source. -->

## Danish Market Context
<!-- Registration tax note, insurance tier flag if power >150 kW, DK-specific pricing -->

## Pros
-

## Cons
-

## Sources
<!-- Every fact above must trace to a URL and fetch date here -->
| Claim | Source URL | Fetch date |
|-------|-----------|------------|
| | | |
```

**Key enforcement points:**
- WLTP and real-world range are separate rows with separate Source columns — cannot be silently mixed (success criterion 3)
- HTML comments are invisible in rendered markdown, guide the skill author without polluting output
- Sources section is mandatory with URL + fetch date fields (DETL-05 readiness)

### Pattern 6: Global state.md Format

```markdown
---
active_project: family-ev
last_updated: 2026-03-25
---

# Global State

## Active Project
**Project:** family-ev
**Switched:** 2026-03-25

## Tool Notes
<!-- Any cross-project observations, source reliability notes -->
```

**Design choices (Claude's discretion):**
- YAML frontmatter at top for machine-readable `active_project` field (backtick injection can extract it)
- Markdown body for human-readable context
- `last_updated` tracks when active project was last switched
- Tool Notes section for cross-project fetch observations (e.g., "ev-database.org returned 403 on 2026-03-20, resolved 2026-03-21")

### Pattern 7: Per-Project state.md Format

```markdown
# Project State: [project name]

**Created:** [date]
**Purchase type:** [new / used / leasing]
**Status:** [active / archived]

## Research Progress
| Car model | File | Researched | FDM found |
|-----------|------|------------|-----------|
| | | | |

## Source Reliability Notes
<!-- Fetch-time observations for this project's research session -->

## Discovered Sources
<!-- Useful URLs found during research that weren't in the initial brief -->
```

**Design choices (Claude's discretion):**
- Research Progress table gives a quick inventory of what's been done
- Source Reliability Notes keeps fetch-time observations close to the project that generated them
- Separated from global state.md so per-project noise doesn't accumulate in the global file

### Anti-Patterns to Avoid

- **YAML/JSON schema for BRIEF.md:** Claude reads prose; structured formats require parsing logic that adds fragility. Markdown sections are sufficient.
- **Hardcoding project names in skills:** Always read from `state.md` via backtick injection. Hardcoded names break the active-project pattern.
- **Rigid field tables in car-template.md:** Use HTML comment guidance instead. The detail skill needs flexibility to note missing fields or add car-specific context.
- **Auto-creating project when active project is missing:** D-09 locks this — list existing projects and ask. Silent creation pollutes the projects directory.
- **Omitting `disable-model-invocation: true` on write-side skills:** Without it, Claude may auto-trigger `/ev-new-project` when discussing project setup, creating unintended project scaffolding.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reading criteria at invocation time | Custom parsing script | Backtick injection `!`cat file`` | Built into Claude Code; zero maintenance; output goes directly into prompt |
| Project name in every skill invocation | `$ARGUMENTS` for project context | Read from `state.md` via backtick | User shouldn't have to name the project every time; state.md persists across calls |
| Schema validation for BRIEF.md | YAML parser or JSON schema checker | Named markdown sections + Claude reading | Claude parses natural language; validation overhead adds no value here |
| Directory existence check | Python or node script | `Bash(ls projects/$NAME 2>/dev/null)` | One shell command in the skill body; no external script needed |

**Key insight:** Every "infrastructure" need in this phase (file reading, directory checking, state persistence) is already solved by Claude Code's native tools and markdown files. Building custom solutions would add maintenance cost with no benefit.

---

## Common Pitfalls

### Pitfall 1: state.md Not Found on First Run

**What goes wrong:** The first time any skill is invoked, `state.md` doesn't exist. Backtick injection of `!`cat state.md`` fails silently or errors, and Claude has no active project context.

**Why it happens:** The file is only created after `/ev-new-project` runs for the first time.

**How to avoid:** Use `!`cat state.md 2>/dev/null || echo "No active project set"`` in backtick injection. Skills should handle the "no active project" state by listing `projects/` and prompting the user to create or switch.

**Warning signs:** Skill starts with no project context and Claude invents a project name.

### Pitfall 2: WLTP and Real-World Range Conflation

**What goes wrong:** The detail skill (Phase 2) writes a single "range" figure that mixes WLTP and real-world measurements, making the comparison table misleading.

**Why it happens:** If the template doesn't clearly separate the two, the writing skill takes the path of least resistance.

**How to avoid:** The car-template.md has separate table rows for WLTP range and real-world range, each with its own Source column. The HTML comment in the Specs section explicitly forbids mixing. The comparison skill (Phase 3) labels range methodology per column.

**Warning signs:** A per-car file has a single "Range" field without a methodology label.

### Pitfall 3: ev-new-project Overwrites Existing Research

**What goes wrong:** Running `/ev-new-project "family-ev"` when `projects/family-ev/` already has research files — skill recreates the directory and erases all research.

**Why it happens:** Skill uses `mkdir -p` without checking for existing content first.

**How to avoid:** D-10 locks this behavior. The skill must check `ls projects/$ARGUMENTS/ 2>/dev/null` before creating anything. If the directory exists (even empty), stop and redirect to `/ev-switch-project`.

**Warning signs:** Research files in `projects/` are newer than the project's creation date but shorter than expected.

### Pitfall 4: Purchase Type Not Scaffolded in BRIEF.md

**What goes wrong:** `/ev-new-project` creates BRIEF.md with all three budget sections (new, used, leasing), and the search skill is confused about which price fields to prioritize.

**Why it happens:** If the skill uses a static BRIEF.md template, it includes all variants.

**How to avoid:** D-02 locks this — the skill asks the user for purchase type during creation and generates only the relevant budget section. The BRIEF.md template embedded in the skill should have a placeholder that gets filled with the right section.

**Warning signs:** BRIEF.md contains "Monthly payment (leasing)" in a new-purchase project.

### Pitfall 5: Skills Trigger Automatically on Setup Conversation

**What goes wrong:** User discusses project setup with Claude, and Claude auto-invokes `/ev-new-project` based on the conversation context, creating an unintended project.

**Why it happens:** Without `disable-model-invocation: true`, Claude matches the skill's description to the conversation and invokes it.

**How to avoid:** Both `/ev-new-project` and `/ev-switch-project` must have `disable-model-invocation: true`. These are explicit user-controlled operations.

**Warning signs:** A `projects/` directory appears that the user didn't explicitly create.

---

## Code Examples

### Verified: Minimal SKILL.md with backtick injection

Source: code.claude.com/docs/en/slash-commands (fetched 2026-03-25)

```yaml
---
name: ev-switch-project
description: Switch the active EV research project. Use when the user says "switch to project X" or "change project".
allowed-tools: Write, Read, Bash
disable-model-invocation: true
argument-hint: [project-name]
---

Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found — no active project"`

Switch to project: $ARGUMENTS
```

### Verified: Frontmatter Fields Available

Source: code.claude.com/docs/en/slash-commands (fetched 2026-03-25)

All confirmed fields for this phase:

| Field | Value in This Phase |
|-------|---------------------|
| `name` | `ev-new-project` / `ev-switch-project` |
| `description` | Natural language trigger description |
| `allowed-tools` | `Write, Read, Bash` |
| `disable-model-invocation` | `true` (both skills) |
| `argument-hint` | `[project-name]` |
| `context` | NOT used (no fork needed; these are simple write operations) |

### Verified: $ARGUMENTS Behavior

Source: code.claude.com/docs/en/slash-commands (fetched 2026-03-25)

- `/ev-new-project "family-ev"` → `$ARGUMENTS` = `family-ev`
- If skill content doesn't include `$ARGUMENTS`, Claude Code appends `ARGUMENTS: family-ev` to the end automatically
- `$ARGUMENTS[0]` for first positional argument (not needed here — single project name)

### Verified: Shell Command in Bash Tool

For directory existence check inside a skill:

```bash
# Check if project exists — safe with 2>/dev/null
ls projects/family-ev/ 2>/dev/null
```

Claude's `Bash` tool is available when `Bash` or `Bash(ls *)` is in `allowed-tools`. For this phase, `Bash` (unrestricted) is acceptable since the skills are user-invoked only (`disable-model-invocation: true`).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.claude/commands/` for skills | `.claude/skills/<name>/SKILL.md` preferred | Skills format introduced; commands still work | Skills support supporting files directory; use skills for new work |
| Single global `car_search.md` | Per-project `projects/<name>/BRIEF.md` | Design decision (this phase) | Enables multiple independent research contexts |

**Deprecated/outdated:**
- `car_search.md` at repo root: Superseded by `projects/<name>/BRIEF.md`. The existing `search_criteria.md` at repo root remains as content reference during this phase but is not the target schema.
- `.claude/commands/`: Still works, but `.claude/skills/` is preferred per current docs. Do not create new commands files.

---

## Open Questions

1. **BRIEF.md embedded in skill vs. referenced as supporting file**
   - What we know: SKILL.md can reference supporting files (`template.md`, etc.) in the skill directory
   - What's unclear: Whether to embed the BRIEF.md template inline in the ev-new-project SKILL.md or store it as a supporting file (`.claude/skills/ev-new-project/brief-template.md`)
   - Recommendation: Start with inline embedding (simpler, one file to edit). Extract to supporting file if SKILL.md exceeds 500 lines.

2. **Bash tool scope for ev-new-project**
   - What we know: `allowed-tools: Bash` grants unrestricted bash; `Bash(mkdir *)` restricts to mkdir only
   - What's unclear: Whether restricting to `Bash(mkdir *, ls *)` is worth the specificity
   - Recommendation: Use `Bash(mkdir *, ls *)` for the principle of least privilege, since this skill is user-invoked only.

3. **car-template.md location**
   - What we know: Phase 2 will build ev-detail, which uses this template. STACK.md shows it at `.claude/skills/ev-detail/output-template.md`
   - What's unclear: Whether to place it at repo root now (Phase 1 deliverable) or in the future ev-detail skill directory
   - Recommendation: Place at repo root as `car-template.md` for Phase 1. Phase 2 will move or reference it from the ev-detail skill directory.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — this phase creates markdown files and Claude Code skills only; no web fetching, no external services, no CLI tools beyond macOS built-in Bash)

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in config.json).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test runner — skills are prompt files) |
| Config file | none — skill testing is live invocation |
| Quick run command | `/ev-new-project "test-project"` in a Claude Code session |
| Full suite command | Run all success criteria checks manually against a live session |

Skills are not code — they cannot be unit tested with pytest or jest. Validation is behavioral: invoke the skill, observe output, verify the file system result.

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | Exists? |
|--------|----------|-----------|-------------------|---------|
| SRCH-01 | Skill reads active project's BRIEF.md at invocation | Manual smoke | `/ev-switch-project "family-ev"` then verify skills read correct BRIEF | Wave 0 gap |
| SRCH-04 | Per-brand budget override in BRIEF.md schema | Manual inspection | Read `projects/family-ev/BRIEF.md`, verify "Per-brand overrides" section present | Wave 0 gap |
| SRCH-05 | Must-have features list in BRIEF.md schema | Manual inspection | Read `projects/family-ev/BRIEF.md`, verify "Must-Have Features" section present | Wave 0 gap |
| SRCH-06 | `purchase_type` field in BRIEF.md | Manual inspection | Read `projects/family-ev/BRIEF.md`, verify `**Purchase type:**` line present | Wave 0 gap |
| PROJ-01 | `/ev-new-project "family-ev"` creates correct structure | Manual smoke | Check `projects/family-ev/BRIEF.md`, `projects/family-ev/research/`, `projects/family-ev/comparison.md` exist | Wave 0 gap |
| PROJ-02 | `/ev-switch-project "family-ev"` updates state.md | Manual smoke | Read `state.md` after switch, verify `active_project: family-ev` | Wave 0 gap |
| PROJ-03 | Skills never cross project boundaries | Manual inspection | Review skill content for any cross-project glob patterns | Wave 0 gap |
| PROJ-04 | Active project persists within session | Manual smoke | Switch project, invoke another skill, verify it uses the switched project | Wave 0 gap |

All tests are manual — this is inherent to the skill domain, not a gap. Skills are prompt files; behavioral testing requires a live Claude Code session.

### Sampling Rate

- **Per task commit:** Manually check that created files exist and contain expected sections
- **Per wave merge:** Run the full success criteria checklist from ROADMAP.md Phase 1 (7 criteria)
- **Phase gate:** All 7 success criteria TRUE before `/gsd:verify-work`

### Wave 0 Gaps

No automated test infrastructure to set up. Phase 1 is purely file creation. Validation is:
- [ ] `projects/test-project/` — created by running `/ev-new-project "test-project"`
- [ ] `state.md` — verify `active_project:` updates correctly after `/ev-switch-project`
- [ ] `car-template.md` — inspect for all required sections (WLTP range row, real-world range row, Sources table)
- [ ] `BRIEF.md` in test project — inspect for all required sections (purchase type, budget, must-have features, per-brand overrides)

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on This Phase |
|-----------|---------------------|
| Skills live at `.claude/skills/<name>/SKILL.md` | Both project management skills go here |
| Input from `car_search.md` (now BRIEF.md) — no hardcoded parameters | BRIEF.md content injected via backtick at runtime |
| Data freshness: skills must fetch live data | Not applicable to Phase 1 (no fetching in this phase) |
| Output as per-car files in `research/`, comparison in `research/` | car-template.md establishes this structure; actual files created in Phase 2 |
| `context: fork` only for detail skill (multi-URL fetch) | NOT used in Phase 1 skills; project management skills are simple writes |
| `disable-model-invocation: true` on file-writing skills | Required on both `/ev-new-project` and `/ev-switch-project` |
| No git commit/push from subagents | Not applicable (Phase 1 has no subagent skills) |
| Use GSD workflow entry points for file changes | Respected — this research is produced via `/gsd:plan-phase` |

---

## Sources

### Primary (HIGH confidence)

- `https://code.claude.com/docs/en/slash-commands` — Skill frontmatter fields, backtick injection, `$ARGUMENTS`, `disable-model-invocation`, `allowed-tools`, `context: fork`, file location hierarchy, supporting files pattern (fetched 2026-03-25)
- `.planning/research/STACK.md` — Project-specific skill structure, fetch strategy, output patterns, verified against official docs 2026-03-22
- `CLAUDE.md` in this repo — Project technology stack, conventions, skill structure requirements, web fetching strategy (authoritative project document)
- `.planning/phases/01-foundation/01-CONTEXT.md` — Locked implementation decisions D-01 through D-11 (user decisions from /gsd:discuss-phase)

### Secondary (MEDIUM confidence)

- `search_criteria.md` at repo root — Content reference for BRIEF.md schema; shows what a working criteria file looks like in practice for this user

### Tertiary (LOW confidence)

None for this phase — all findings are either from official docs or locked decisions.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against current Claude Code docs (2026-03-25)
- Architecture patterns: HIGH — derived directly from locked decisions and verified skill patterns
- Pitfalls: HIGH — derived from locked decisions (D-09, D-10) and known Claude Code skill behavior
- Schema designs: MEDIUM — designed to spec; will be validated during Phase 2 when ev-detail consumes the template

**Research date:** 2026-03-25
**Valid until:** 2026-04-25 (Claude Code skill format is stable; unlikely to change in 30 days)
