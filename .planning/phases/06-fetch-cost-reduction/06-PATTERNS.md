# Phase 6: Fetch-Cost Reduction - Pattern Map

**Mapped:** 2026-06-22
**Files analyzed:** 3 (1 new skill, 1 new supporting file, 1 modified skill)
**Analogs found:** 3 / 3

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.claude/skills/ev-research/SKILL.md` | skill / orchestrator | event-driven (fan-out N forks, collect status) | `.claude/skills/ev-new-project/SKILL.md` (frontmatter + `$ARGUMENTS`); `.claude/skills/ev-detail/SKILL.md` (fork pattern to mirror but NOT repeat) | role-match |
| `.claude/skills/ev-detail/sites.md` | config / supporting file | reference (read-only by SKILL.md at fetch time) | No exact analog in repo. Named in CLAUDE.md as a first-class pattern. | pattern-doc only |
| `.claude/skills/ev-detail/SKILL.md` | skill / fetch consumer | request-response (WebFetch per known site, Steps 6-9) | Self — this is the file being modified. Analog for step structure: existing Steps 6-9 show the exact shape to extend. | self-analog (modify in place) |

---

## Pattern Assignments

### `.claude/skills/ev-research/SKILL.md` (orchestrator skill, inline — no fork)

**Primary analog:** `.claude/skills/ev-new-project/SKILL.md` (frontmatter block + backtick state injection + `$ARGUMENTS`)
**Secondary analog:** `.claude/skills/ev-detail/SKILL.md` (the fork pattern this skill dispatches TO — do not replicate it here)

---

**Frontmatter pattern** — copy from `ev-new-project/SKILL.md` lines 1-7, adapt fields:

```yaml
---
name: ev-new-project
description: Create a new EV research project. Use when the user wants to start researching a new set of cars with different criteria.
allowed-tools: Write, Read, Bash(mkdir *, ls *)
disable-model-invocation: true
argument-hint: [project-name]
---
```

For `/ev-research`, adapt as:
- `name: ev-research`
- `description:` — batch orchestrator phrasing (see RESEARCH.md Pattern 1 example)
- `allowed-tools: Read, Bash(ls *)` — orchestrator never writes files; only reads state and lists
- `disable-model-invocation: true` — batch runner should only run when explicitly invoked
- NO `context: fork` — orchestrator must be inline to accumulate status lines across iterations
- `argument-hint: ["car1" "car2" ...]`

---

**Backtick state injection pattern** — copy from `ev-switch-project/SKILL.md` lines 9-10 (exact form used in both existing inline skills):

```
Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`
```

The `ev-new-project/SKILL.md` uses the same pattern (lines 9-10):
```
!`cat state.md 2>/dev/null || echo "state.md not found"`
```

Use this verbatim in `/ev-research`. The orchestrator needs to know the active project so it can confirm forks will write to the right project path.

---

**`$ARGUMENTS` injection pattern** — copy from `ev-new-project/SKILL.md` line 11 and `ev-switch-project/SKILL.md` line 12:

```
Project name requested: $ARGUMENTS
```
```
Switch to project: $ARGUMENTS
```

For `/ev-research`, the equivalent is:
```
Cars to research: $ARGUMENTS
```

The SKILL.md prose then instructs Claude to parse `$ARGUMENTS` as a shell-quoted list of car names (`$ARGUMENTS[0]`, `$ARGUMENTS[1]`, etc.).

---

**Step structure pattern** — copy from `ev-new-project/SKILL.md` lines 13-15 (step preamble):

```
Follow these steps in order:
```

For the orchestrator steps, the pattern is:
1. Parse `$ARGUMENTS` into a list of car names (split on shell-quoted tokens).
2. For each car: instruct Claude to invoke `/ev-detail "<car>"` and wait for the fork to complete.
3. After each fork: record ONLY the status line + file path from the fork's Step 13 output. Do NOT use the Read tool on the research file.
4. After all forks: print final summary table (car | status | path).

**Critical prose to include verbatim** (from RESEARCH.md "Fork boundary guarantee"):
> "After each `/ev-detail` invocation completes, record only the status line and file path from the fork's output. Do NOT use the Read tool on the research file. The research file is for Phase 3's `/ev-compare` skill, not for this orchestrator's context."

---

**No-argument handling pattern** — copy from `ev-switch-project/SKILL.md` lines 17-24:

```
**No-argument handling (D-09)**

If `$ARGUMENTS` is empty or not provided:
- Run `Bash(ls projects/ 2>/dev/null || echo "No projects found")` to list existing projects.
- ...
- Stop here and wait for user input.
```

For `/ev-research`, adapt: if `$ARGUMENTS` is empty, tell the user the expected invocation format and stop.

---

**Step 13 confirmation shape** (what the fork returns; what the orchestrator collects) — copy from `ev-detail/SKILL.md` lines 321-329:

```
**Step 13 — Confirm to user**

Report:
- File written: `projects/<active_project>/research/<filename>.md`
- Variant selected: `<name>` (reason: `<brief rationale>`)
- FDM: found (article date: `<date>`) / not found
- Tire size: confirmed from wheel-size.com / unconfirmed (check spec sheet)
- Gaps (if any): ...
```

The orchestrator captures the "File written: ..." and status lines from this report. The per-car row in the orchestrator's summary table maps directly to this output.

---

### `.claude/skills/ev-detail/sites.md` (supporting config file, no execution)

**Analog:** No existing file in this repo. Pattern is documented in CLAUDE.md and RESEARCH.md.

**Structure pattern** (from RESEARCH.md Pattern 3 and Pattern 2 examples):

```markdown
## ev-database.org
URL pattern: https://ev-database.org/[uk/]car/{ID}/{Make-Model-Variant}
Region prompt: Return only the spec-table container — the section containing technical
specification rows for range (WLTP, real-world), battery, charging power (AC/DC, 10-80%
time), performance (0-100 km/h), dimensions, cargo, tow capacity, power output, and EV
platform. Discard navigation, footer, related cars section, and any advertisement blocks.
max_content_tokens: [Claude's Discretion — see RESEARCH.md Open Question #1]

## fdm.dk
URL pattern: https://fdm.dk/tests/biltest/[slug]
Region prompt: Return only the article body — the editorial content including measured range
at 110 km/h 20°C, measured range at 0°C, FDM-measured DC charge rate, overall verdict,
Styrker/Fordele, Svagheder/Ulemper, DKK prices (base and tested trim), and publication date.
Discard navigation, header, footer, sidebar, related articles, cookie/consent banners.
max_content_tokens: [Claude's Discretion]

## wheel-size.com
URL pattern: https://www.wheel-size.com/size/<make>/<model>/<year>/
Region prompt: Return only the tire size block — the table or list showing OEM tire
specifications. Include front and rear tire sizes (marked 'OE' or 'OEM'). Discard
navigation, advertisements, and unrelated size listings.
max_content_tokens: [Claude's Discretion]

## Bilbasen Blog (used branch)
URL pattern: https://blog.bilbasen.dk/...
Region prompt: Return only the article body containing the used-market price range analysis —
low, typical, and high DKK figures and article publication date. Discard navigation,
unrelated articles, and comments.
max_content_tokens: [Claude's Discretion]

## Manufacturer DK site (new branch)
URL pattern: varies by make (e.g., volvocars.com/da, renault.dk)
Region prompt: Return only the pricing section showing tier 1 (base/from) and tier 2
(best-value mid-tier) DKK prices. Discard configurator, accessories, and unrelated sections.
max_content_tokens: [Claude's Discretion]

## Fallback (unknown site or missing region)
If the URL does not match any site entry above: perform a bounded full fetch
(max_content_tokens backstop only, no region prompt). Never abort.
```

**Field coverage requirement:** The spec-table region for ev-database.org MUST cover all fields in `ev-detail/SKILL.md` Step 6's extraction table (lines 124-141) — verified against VALIDATION-CHECKLIST.md. See RESEARCH.md "Per-site region prompts" section for the exhaustive field list per site.

---

### `.claude/skills/ev-detail/SKILL.md` — Steps 6-9 (modified, Lever B)

**Analog:** Self. Steps 6-9 are the existing fetch steps; the modification adds a sites.md Read instruction and per-site region prompt reference before each WebFetch call.

---

**Current Step 6 shape** (lines 120-151 of ev-detail/SKILL.md — the pattern to extend):

```markdown
**Step 6 — Fetch mandatory ev-database.org specs (DETL-01, DETL-03, DETL-10, D-03)**

WebFetch the selected variant's URL from Step 5.

Extract the following fields (all are present on ev-database.org car pages):
...
```

**Modified Step 6 shape** — add a preamble before the WebFetch instruction:

```markdown
**Step 6 — Fetch mandatory ev-database.org specs (DETL-01, DETL-03, DETL-10, D-03)**

Read `.claude/skills/ev-detail/sites.md` to get the per-site region prompts and URL
patterns. Apply the region prompt for ev-database.org in the WebFetch instruction below.

WebFetch the selected variant's URL from Step 5.
Region to extract (from sites.md ev-database.org entry): [paste region prompt at write time]
max_content_tokens backstop: [value from sites.md]

Graceful degradation: if the region prompt yields no content or the site layout has changed,
fall back to a bounded full fetch (max_content_tokens backstop only). Never abort.

Extract the following fields...
```

**Same extension pattern applies to Steps 7, 8, 9** — each step gets the same "Read sites.md, apply region prompt, WebFetch with backstop, graceful degradation" preamble before its existing WebFetch instruction.

**Existing token-ceiling note in Step 4** (lines 93-95 of ev-detail/SKILL.md) — this is the prior art for the max_content_tokens pattern already in the file:

```markdown
**Important:** Do NOT fetch multiple variant pages to compare specs. Token budget is limited
in this fork context — fetching 3–5 pages before selecting would exhaust it (each page is
~10–15k tokens). All selection reasoning must happen from the URL slugs alone in this step.
```

The Lever B backstop formalizes this concern from a warning into a structural parameter.

---

**sites.md Read instruction placement** — two options per RESEARCH.md Open Question #3:

Option A (backtick injection at invocation time — test first):
```
!`cat ${CLAUDE_SKILL_DIR}/sites.md`
```
Add as a third backtick injection line after the state injection, before Step 1. Loads once, free to all steps.

Option B (Read tool at Step 6 preamble — fallback if Option A fails):
```
Read `.claude/skills/ev-detail/sites.md` to get the per-site region prompts.
```
Add as first line of the Step 6-9 preamble.

**Planner note:** Implementation task must test Option A first (Wave 1). If it works, use it and remove per-step Read instructions.

---

## Shared Patterns

### Backtick State Injection
**Source:** `.claude/skills/ev-switch-project/SKILL.md` lines 9-10; `.claude/skills/ev-new-project/SKILL.md` lines 9-10
**Apply to:** `.claude/skills/ev-research/SKILL.md`
```
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`
```

### `$ARGUMENTS` Reference Line
**Source:** `.claude/skills/ev-new-project/SKILL.md` line 11; `.claude/skills/ev-switch-project/SKILL.md` line 12
**Apply to:** `.claude/skills/ev-research/SKILL.md`
Pattern: `<Action noun>: $ARGUMENTS` immediately after the backtick injection block.

### `disable-model-invocation: true` Frontmatter
**Source:** `.claude/skills/ev-new-project/SKILL.md` line 6; `.claude/skills/ev-switch-project/SKILL.md` line 6
**Apply to:** `.claude/skills/ev-research/SKILL.md`
Prevents auto-trigger on any mention of batch research. Only explicit invocation should run the orchestrator.

### Graceful Degradation (never abort) Pattern
**Source:** `.claude/skills/ev-detail/SKILL.md` lines 162-164, 200-203, 213-215
**Apply to:** `.claude/skills/ev-detail/SKILL.md` Steps 6-9 (Lever B additions); `ev-detail/sites.md` fallback entry
```markdown
If the page cannot be fetched or the car is not found: ABORT immediately — write NO file.
[Step 7:] If both attempts return no results: write "No FDM test found..." and proceed. Do NOT abort — FDM is best-effort.
[Step 8:] If the page returns 404 or fails to load: write "Tire size: unconfirmed..." Do NOT abort.
```
Pattern: mandatory sources abort on failure; best-effort sources degrade to a gap note and continue.
Apply the same abort/degrade split to the Lever B region prompt: if ev-database.org region yields nothing → abort. If fdm.dk/wheel-size/Bilbasen region yields nothing → log gap note and continue.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.claude/skills/ev-detail/sites.md` | config / supporting file | reference | No existing `sites.md` or equivalent per-site config file in this repo. Pattern is named in CLAUDE.md but not yet instantiated. Planner should use the structure examples in RESEARCH.md Pattern 2 and Pattern 3 as the template. |

---

## Metadata

**Analog search scope:** `.claude/skills/` (all 4 existing skill SKILL.md files)
**Files scanned:** 4 (`ev-detail/SKILL.md`, `ev-new-project/SKILL.md`, `ev-switch-project/SKILL.md`, and by reference `ev-search` if it existed — it does not)
**Pattern extraction date:** 2026-06-22
