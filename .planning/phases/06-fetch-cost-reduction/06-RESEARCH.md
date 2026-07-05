# Phase 6: Fetch-Cost Reduction - Research

**Researched:** 2026-06-22
**Domain:** Claude Code skill orchestration + WebFetch section isolation
**Confidence:** HIGH (core mechanics verified against live official docs)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The 02-03 overflow was a batching failure. The executor ran all 5 golden cars in one context; `/ev-detail` is already `context: fork, agent: Explore`. The gap is the multi-car / validation layer.
- **D-02:** Build a thin batch orchestrator skill (`/ev-research "car1" "car2" ...`) that spawns one isolated `/ev-detail` fork per car and collects back only each car's status + result-file path — never raw fetches or file bodies.
- **D-03:** The validation harness (and any future multi-car run) goes through this orchestrator rather than running cars sequentially in one context.
- **D-04:** Sequencing — isolation (Lever A) lands first.
- **D-05:** Trim each known page with a per-site region prompt + a `max_content_tokens` backstop. Return the section verbatim, never pre-parsed values.
- **D-06:** Per-site region selectors + URL patterns live in a shared `sites.md` supporting file, referenced by `/ev-detail` (and later `/ev-search`, `/ev-compare`). Adding or adjusting a site = one localized edit.
- **D-07:** Graceful degradation (SC#4): on unknown site or missing region, fall back to a bounded full fetch, never abort.
- **D-08:** Validation: (a) per-site before/after page-content token counts for ~80% claim (SC#1); (b) re-run 5 golden scenarios through `/ev-research` to confirm no field dropped (SC#3) and run completes without overflow (Lever A criterion).
- **D-09:** Dynamic filtering (web_fetch region prompt) trims BEFORE content reaches context; `max_content_tokens` truncates ingested content. Both reduce the same token sink.
- **D-10:** In an agentic fork, a fetched page is re-billed as input on every subsequent turn until the fork ends — so an ~80% per-page cut multiplies across turns.

### Claude's Discretion

- Parallel vs sequential fan-out of per-car forks in `/ev-research` (rate-limit / throughput tradeoff).
- The exact `max_content_tokens` value per site.
- The precise region-prompt wording per site.
- The orchestrator's user-facing end-of-run summary format (N cars: status + path each).
- `/ev-detail` is unversioned (`allowed-tools: WebFetch`); it auto-uses whatever web-fetch version the harness ships — no version to pin or maintain.

### Deferred Ideas (OUT OF SCOPE)

- MCP "sections server" (ROADMAP candidate solution #3) — deferred. Only build if in-skill Lever A + Lever B fail.
- Structured value extraction — remains rejected (brittle; fights the living-tool requirement). Firecrawl stays reserved for bot-blocking only, not token reduction.
</user_constraints>

---

## Summary

Phase 6 reduces context cost for multi-car research runs via two complementary levers. Lever A fixes the 02-03 overflow root cause structurally: the new `/ev-research` orchestrator skill fans out one isolated `/ev-detail` fork per car and collects back only per-car status + file paths — the orchestrator's own context never holds page content. Lever B reduces the per-page weight inside each fork: a `sites.md` supporting file carries per-site region prompts (e.g., "return only the spec-table container" for ev-database.org) that the `web_fetch` dynamic-filtering mechanism uses to trim before content reaches context, backed by a `max_content_tokens` ceiling as a guaranteed floor.

The key mechanics are well-established in this project's existing patterns. `/ev-detail` is already `context: fork, agent: Explore` — this is the exact isolation pattern that Lever A scales to N cars. The `$ARGUMENTS` substitution in Claude Code skills supports multi-word quoted strings (`/ev-research "EX30" "Renault 5" "iX1"` delivers `$ARGUMENTS` = `"EX30" "Renault 5" "iX1"` verbatim; individual positional access is via `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, etc.). The `sites.md` supporting-file pattern is already named in CLAUDE.md and the STACK.md research doc.

The key open question is the orchestrator dispatch mechanism: Claude Code skills cannot programmatically invoke another `/skill-name` command from within a SKILL.md body. The orchestrator must instruct Claude (in prose) to spawn `/ev-detail "<car>"` for each car argument, one at a time or in parallel. This is the established agentic-delegation model — not a technical gap, but a constraint the planner must account for when writing task instructions.

**Primary recommendation:** Build Lever A first (new `ev-research` skill directory + SKILL.md). Then add `sites.md` to the `ev-detail` skill directory and update `ev-detail/SKILL.md` Steps 6-9 to reference per-site region prompts from `sites.md`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Multi-car batch orchestration | Orchestrator skill (`/ev-research`) | — | Owns the fan-out loop, collects only paths + status, never page content |
| Per-car research + fetch | Fork skill (`/ev-detail`) | — | Already `context: fork`; all live fetches happen here in isolation |
| Per-site region selection | `ev-detail/sites.md` | `ev-detail/SKILL.md` | Single localized edit per site per D-06; SKILL.md reads instructions from it |
| WebFetch section trimming | `web_fetch` dynamic filter (region prompt) | `max_content_tokens` ceiling | Filter trims before context (D-09); ceiling is a safety backstop |
| Validation baseline | Re-run harness via `/ev-research` | VALIDATION-CHECKLIST.md | Orchestrator drives 5 golden cars; checklist certifies no fields dropped |
| Fork boundary enforcement | Claude Code `context: fork` isolation | SKILL.md prose instruction | Structural isolation: fork context never merges back into orchestrator |

---

## Standard Stack

This phase has no npm/pip packages. The stack is Claude Code skills + native tools only.

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code skill (`context: fork`) | Current harness | Isolated subagent execution | Established pattern — `/ev-detail` already uses this; prevents page content crossing context boundaries |
| `web_fetch` dynamic filtering | `web_fetch_20260209` or later (auto-selected by harness) | Region prompt trims content before it reaches context | Official Anthropic tool; CLAUDE.md notes `web_fetch_20260209` is current; harness auto-upgrades |
| `max_content_tokens` | Tool parameter (no version constraint) | Hard token ceiling per fetch | Available on all `web_fetch_20250910` and later versions |
| Supporting file (`sites.md`) | Markdown | Per-site region selectors + URL patterns in one localized file | Named pattern in CLAUDE.md; keeps SKILL.md under 500 lines |
| `$ARGUMENTS` substitution | Claude Code skills standard | Pass multiple quoted car names to `/ev-research` | Verified in official docs: multi-word args with shell-style quoting; `$ARGUMENTS[N]` for indexed access |

### No New External Dependencies

No packages to install. All components are either:
- Native Claude Code tool primitives (`WebFetch`, `WebSearch`, `Read`, `Write`, `Bash`)
- Skill frontmatter fields (`context: fork`, `agent: Explore`, `allowed-tools`)
- Markdown files (`sites.md`, updated `SKILL.md`)

### Package Legitimacy Audit

Not applicable — this phase installs no external packages.

---

## Architecture Patterns

### System Architecture Diagram

```
User: /ev-research "EX30" "Renault 5" "iX1"
          │
          ▼
┌─────────────────────────────────────┐
│  /ev-research (inline, main context) │
│  - Parses $ARGUMENTS into car list   │
│  - For each car: instructs Claude    │
│    to invoke /ev-detail "<car>"      │
│  - Waits for fork to return          │
│  - Collects: status + file path only │
│  - Never receives page content       │
└────────┬────────────────────────────┘
         │ (one fork per car, sequential or parallel)
         ▼
┌─────────────────────────────────────────────────────────────┐
│  /ev-detail "EX30" (context: fork, agent: Explore)          │
│  Steps 1-3: resolve project, read BRIEF, normalize filename  │
│  Step 4: WebSearch for ev-database.org variants              │
│  Step 5: select variant from slugs                           │
│  Step 6: WebFetch ev-database.org                            │
│    ├─ region prompt: "spec-table container only"             │
│    └─ max_content_tokens: N (backstop)                       │
│  Step 7: WebSearch → WebFetch fdm.dk article                 │
│    ├─ region prompt: "article body only"                     │
│    └─ max_content_tokens: N (backstop)                       │
│  Step 8: WebFetch wheel-size.com                             │
│    ├─ region prompt: "size block only"                       │
│    └─ max_content_tokens: N (backstop)                       │
│  Step 9: WebFetch/WebSearch pricing source                   │
│    ├─ region prompt: "listing/price region" (Bilbasen)       │
│    └─ max_content_tokens: N (backstop)                       │
│  Steps 11-13: Write file, update state, confirm              │
└──────────────────┬──────────────────────────────────────────┘
                   │ Returns to /ev-research:
                   │  "EX30: OK → projects/family-ev/research/volvo-ex30.md"
                   ▼
┌─────────────────────────────────────┐
│  /ev-research collects results       │
│  Prints summary:                     │
│    EX30: OK → research/volvo-ex30.md │
│    Renault 5: OK → research/...      │
│    iX1: OK → research/...            │
└─────────────────────────────────────┘
```

Sites region data flows through:
```
ev-detail/sites.md  ──read by──►  ev-detail/SKILL.md Steps 6-9
                                   └─ region prompt injected into WebFetch instruction
```

### Recommended Project Structure

```
.claude/skills/
├── ev-research/          # NEW — Lever A orchestrator
│   └── SKILL.md          # Frontmatter: inline (no fork), parses $ARGUMENTS, dispatches
├── ev-detail/
│   ├── SKILL.md          # MODIFIED — Steps 6-9 reference sites.md for region prompts
│   └── sites.md          # NEW — Lever B per-site region selectors + URL patterns
├── ev-new-project/
│   └── SKILL.md          # Unchanged
└── ev-switch-project/
    └── SKILL.md          # Unchanged
```

### Pattern 1: Orchestrator Skill Dispatching N Forks

**What:** An inline skill (no `context: fork`) that parses `$ARGUMENTS` into a list of car names and instructs Claude to invoke `/ev-detail "<car>"` for each one, collecting only the status line and file path returned by each fork.

**When to use:** Any multi-car research run. The validation harness runs through this instead of calling `/ev-detail` directly in a single context.

**Example frontmatter:**
```yaml
# Source: code.claude.com/docs/en/slash-commands (verified 2026-06-22)
---
name: ev-research
description: Research one or more EV models in depth. Use when the user wants to research multiple cars or run a batch research session. Spawns one isolated /ev-detail fork per car.
allowed-tools: Read, Bash(ls *)
disable-model-invocation: true
argument-hint: ["car1" "car2" ...]
---
```

**Why no `context: fork`:** The orchestrator runs inline so it can accumulate results from each fork sequentially. It never fetches pages itself — it delegates entirely to `/ev-detail` forks.

**Critical isolation constraint (SC#7):** The SKILL.md prose must explicitly state: after each `/ev-detail` fork returns, record only the returned status line and file path. Do NOT read the research file body back into this context.

### Pattern 2: Per-Site Region Prompt in WebFetch Instruction

**What:** A WebFetch call where the instruction (the prose surrounding the URL in the skill body) names a content region. The `web_fetch_20260209` dynamic filtering executes code server-side to filter before content reaches context.

**When to use:** Every WebFetch call in `ev-detail/SKILL.md` for a known site (Steps 6, 7, 8, 9).

**How `web_fetch` dynamic filtering works (verified 2026-06-22):**
[VERIFIED: platform.claude.com/docs/en/docs/agents-and-tools/tool-use/web-fetch-tool]
- `web_fetch_20260209` and later support dynamic filtering. Claude writes and executes code server-side to filter fetched content BEFORE loading into context.
- Dynamic filtering requires the code execution tool to be enabled. In Claude Code sessions, the harness manages tool availability — the skill does not configure this.
- The filter is expressed as a prose instruction to Claude (e.g., "return only the spec-table container") — Claude then writes the filter code. The instruction lives in the SKILL.md step text or in `sites.md`.
- `max_content_tokens` is a separate hard ceiling: if content after filtering still exceeds the limit, it is truncated. The two mechanisms are complementary, not redundant.
- `max_content_tokens` approximation note: "The actual number of input tokens used can vary by a small amount." Use round numbers; don't rely on exact boundaries.

**Example: ev-database.org step instruction with region prompt:**
```markdown
# In ev-detail/SKILL.md Step 6 (after sites.md integration):
WebFetch the selected variant's URL from Step 5.
Region to extract (from sites.md): return only the spec-table container section — the area
containing technical specification rows (range, battery, charging, performance, dimensions).
Discard navigation, header, footer, related cars, and advertisement blocks.
max_content_tokens backstop: [value from Claude's Discretion].
```

**Example: sites.md entry for ev-database.org:**
```markdown
# In ev-detail/sites.md:
## ev-database.org
URL pattern: https://ev-database.org/[uk/]car/{ID}/{Make-Model-Variant}
Region prompt: Return only the spec-table container — the section containing technical
specification rows for range (WLTP, real-world), battery, charging power (AC/DC, 10-80%
time), performance (0-100 km/h), dimensions, cargo, tow capacity, power output, and EV
platform. Discard navigation, footer, related cars section, and any advertisement blocks.
max_content_tokens: [Claude's Discretion]
```

### Pattern 3: `sites.md` Supporting File

**What:** A markdown file in `.claude/skills/ev-detail/` that centralizes per-site URL patterns and region selectors. Referenced from `SKILL.md` steps via a Read instruction.

**How supporting files work (verified 2026-06-22):**
[VERIFIED: code.claude.com/docs/en/slash-commands]
- Files in a skill directory are optional supporting assets. They are NOT auto-loaded; SKILL.md must explicitly reference them.
- Reference pattern in SKILL.md: "For per-site region prompts and URL patterns, see the `sites.md` file in this skill's directory." Claude uses the Read tool to load it when the step runs.
- Adding a new site = add one section to `sites.md`. No changes to `SKILL.md` required (satisfies D-06 and SC#5).
- Keep `SKILL.md` under 500 lines per project guidelines.

**Sites to cover in `sites.md` (the four "known sites" per CONTEXT.md):**

| Site | Step in ev-detail | Region to extract |
|------|------------------|-------------------|
| ev-database.org | Step 6 (mandatory) | Spec-table container — all technical rows |
| fdm.dk | Step 7 (best-effort) | Article body — main editorial content, excluding nav/footer/related |
| wheel-size.com | Step 8 (best-effort) | Size block — OEM tire size table rows |
| Bilbasen Blog / manufacturer DK | Step 9 (purchase-type branch) | Price/listing region — DKK figures and article date |

**Unknown site / missing region (D-07, SC#4):** `sites.md` must include a fallback instruction: "If the URL does not match any site entry above, perform a bounded full fetch (max_content_tokens backstop only). Never abort."

### Pattern 4: `$ARGUMENTS` with Multiple Quoted Car Names

**What:** `/ev-research "EX30" "Renault 5" "iX1"` passes the full argument string to `$ARGUMENTS`. Individual cars are accessed by shell-style quoting and positional index.

**Verified behavior (verified 2026-06-22):**
[VERIFIED: code.claude.com/docs/en/slash-commands]
- `$ARGUMENTS` = full argument string as typed: `"EX30" "Renault 5" "iX1"`
- `$ARGUMENTS[0]` = `EX30`, `$ARGUMENTS[1]` = `Renault 5`, `$ARGUMENTS[2]` = `iX1` (shell-style quoting respected)
- The skill body instructs Claude to parse the argument string into a list of cars (by splitting on quoted tokens), then process each.
- If `$ARGUMENTS` is absent from the skill body, Claude Code appends `ARGUMENTS: <value>` to the end — use explicit `$ARGUMENTS` reference.

### Anti-Patterns to Avoid

- **Orchestrator reading the research file back:** After each fork, the orchestrator MUST NOT use the Read tool on the produced `.md` file. Only the status line ("OK" / "FAILED") and file path cross the fork boundary. Reading the file negates the isolation benefit and re-introduces page-weight into the orchestrator context (violates SC#7).
- **Running /ev-detail directly in the validation executor:** The 02-03 failure was the executor running all 5 golden cars sequentially in one context. Phase 6 fix: all multi-car runs go through `/ev-research`.
- **`context: fork` on the orchestrator:** The orchestrator must be inline (no fork) so it can loop over cars and accumulate status lines. Forking the orchestrator itself breaks the accumulation loop.
- **Omitting `max_content_tokens` backstop:** Dynamic filtering alone is not sufficient — a region prompt may silently match too much if a site changes layout. The backstop guarantees a ceiling even on unexpected layouts.
- **Firecrawl for token reduction:** Explicitly rejected in CLAUDE.md. Reserve Firecrawl for bot-blocking only.
- **Pre-parsing values in `sites.md`:** The region must return prose/table text verbatim (D-05). `sites.md` describes WHERE the content is, not WHAT values to extract.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-fork dispatch | Custom subprocess spawner | Claude Code `context: fork` + orchestrator prose instructions | Already the established pattern; forks are native Claude Code primitives |
| Per-site content extraction | CSS selectors, DOM parsers, regex extractors | `web_fetch` dynamic filtering + region prompt | Selectors rot on layout change; dynamic filtering uses semantic matching (robust to wording drift) |
| Token counting for before/after measurement | Custom token counter | Note conversation token counts from Claude Code's status bar / context indicator before and after, or compare file sizes of fetched content | No API for measuring mid-fork token usage; approximate comparison is sufficient for D-08 |
| Sites registry with structured schema | JSON config, YAML with typed fields | Plain markdown `sites.md` | Markdown is natively readable in Claude's context; no parsing step needed |

**Key insight:** This phase is almost entirely a configuration and prose-instruction change, not a code change. The "code" is SKILL.md content and a new markdown file. Don't over-engineer what is fundamentally a prompting problem.

---

## Lever A — Multi-Fork Orchestrator: Detailed Mechanics

### What `/ev-research` does

The orchestrator skill is an inline (no `context: fork`) skill that:
1. Injects `state.md` via backtick at invocation time (same pattern as existing skills)
2. Receives `$ARGUMENTS` = space-separated quoted car names
3. Instructs Claude to parse the argument string into a list
4. For each car in the list: instruct Claude to invoke `/ev-detail "<car>"` and wait for the fork to complete
5. After each fork: record only the returned "File written: ..." and "Status: OK / FAILED" confirmation from the fork's Step 13 output
6. After all forks complete: print a final summary table (car | status | path)

### Fork dispatch — what the docs confirm

[VERIFIED: code.claude.com/docs/en/sub-agents]

- `context: fork` in a skill runs the SKILL.md content as the prompt driving a forked subagent.
- The fork inherits the parent conversation's current context at spawn time — but the fork's own tool calls (WebFetch, WebSearch, Write) stay in the fork's context and do NOT return to the parent.
- Only the fork's FINAL RESULT (the text the fork returns when it finishes) comes back to the parent.
- The Explore agent (`agent: Explore`) uses: Haiku model (fast, low-latency), read-only tools, skips CLAUDE.md. For `/ev-detail`, Explore is the correct agent because it is read-heavy with a single Write at the end. The Write permission is granted via `allowed-tools: Write` in the SKILL.md frontmatter — Explore skips CLAUDE.md but respects the skill's `allowed-tools`.

**Critical clarification (confirmed from docs):** The orchestrator does NOT spawn forks directly. The orchestrator SKILL.md instructs Claude (in prose) to "invoke `/ev-detail '<car>'` for each car." Claude then uses the Skill tool to invoke `/ev-detail` — which has `context: fork` in its own frontmatter — so each invocation automatically runs in a fork. The orchestrator does not need `context: fork` itself.

### Parallel vs sequential fan-out (Claude's Discretion)

[ASSUMED — no definitive documentation on rate-limit behavior for parallel fork dispatch]

**Sequential (recommended default):**
- Invoke one `/ev-detail` fork per car, wait for completion, then dispatch the next.
- Pros: no rate-limit risk; simpler orchestrator prose; easier to attribute any failure to a specific car.
- Cons: total wall-clock time = sum of individual car times (~3-5 min per car).

**Parallel:**
- Instruct Claude to invoke all `/ev-detail` forks concurrently ("in parallel, without waiting for each to complete").
- Pros: total time ~= slowest single car.
- Cons: multiple simultaneous live fetches may hit site rate limits (ev-database.org, fdm.dk); requires the orchestrator to handle partial results gracefully; background subagents auto-deny permission prompts that would otherwise surface (an interactive overwrite prompt in `/ev-detail` Step 3 would be auto-denied in a background fork, potentially silently skipping a re-run).

**Planner recommendation surface:** Research the tradeoffs above. The planner should document the default choice in the plan and note the user can override.

### Fork boundary guarantee (SC#7)

The structural guarantee: a Claude Code fork's internal tool calls (WebFetch results, page content) are never appended to the parent conversation history. The fork's result is a summary/confirmation string, not the raw tool outputs. This is built into the fork mechanism — not a convention the SKILL.md needs to enforce.

However, the SKILL.md prose must explicitly prohibit the orchestrator from reading the research file after the fork:

> "After each `/ev-detail` invocation completes, record only the status line and file path from the fork's output. Do NOT use the Read tool on the research file. The research file is for Phase 3's `/ev-compare` skill, not for this orchestrator's context."

---

## Lever B — Per-Fetch Section Isolation: Detailed Mechanics

### WebFetch dynamic filtering — how it actually works in a Claude Code session

[VERIFIED: platform.claude.com/docs/en/docs/agents-and-tools/tool-use/web-fetch-tool]

The CLAUDE.md states the tool is `web_fetch_20260209`. The official docs confirm:
- `web_fetch_20260209` supports dynamic filtering.
- Dynamic filtering: Claude writes and executes code server-side to filter fetched content BEFORE it loads into context.
- The trigger for filtering is the fetch instruction prose — Claude reads "return only the spec-table container" and writes filter code to select that region.
- In a Claude Code session (as opposed to the Anthropic API), the harness configures the tool version automatically. The skill does not need to declare a tool version.
- `max_content_tokens` is a tool parameter that limits context contribution. It truncates after filtering. Both work together: filter reduces to the relevant section, ceiling prevents unexpected layout changes from blowing the budget.

**Important caveat for Claude Code skills (ASSUMED — not explicitly documented for the session tool vs API tool):** The `max_content_tokens` and `allowed_domains` parameters documented in the API tool definition (JSON schema) are configured at the API level, not in SKILL.md prose. In a Claude Code session, the skill's prose instruction is the lever available to the model for controlling fetch behavior. `max_content_tokens` may need to be communicated as a prompt instruction ("limit the content you ingest to approximately N tokens from this fetch") rather than as a tool parameter — unless the Claude Code harness exposes tool configuration in SKILL.md frontmatter.

**Planner action required:** The implementation task must test whether `max_content_tokens` is settable via SKILL.md instruction or requires harness configuration. If prompt-only, the skill prose must carry an explicit "ingest at most ~X tokens from this fetch" instruction per site.

### Per-site region prompts — concrete wording

The following region prompts are starting points. Final wording is Claude's Discretion (D-05). These are grounded in known page structures from Phase 2 validation runs.

**ev-database.org (Step 6 — mandatory):**
> "Fetch the URL and return ONLY the technical specifications section — the rows covering range (WLTP, real-world mild and cold), battery capacity, charging (AC max, DC max, 10-80% time), performance (0-100 km/h), dimensions, cargo, tow capacity, power output, and EV platform type. Discard the page header, navigation, footer, related cars listings, pricing section, and any advertising blocks."

Fields this region must contain to satisfy SC#3 / VALIDATION-CHECKLIST.md:
- Range (WLTP), EVDB Real Range, Real Range (Cold)
- Useable Battery Capacity
- Rapid Charging (DC max), Home Charging (AC max), 10-80% charge time
- 0-62 mph (= 0-100 km/h), Boot space, Towing Capacity
- Max Power, EV Dedicated Platform

**fdm.dk (Step 7 — best-effort):**
> "Fetch the URL and return ONLY the article body — the editorial content of the test article including the measured range figures at 110 km/h (20°C) and at 0°C, FDM-measured DC charge rate, the overall verdict, the strengths (Styrker/Fordele) section, the weaknesses (Svagheder/Ulemper) section, and the DKK prices. Discard navigation, header, footer, sidebar, related articles, and any cookie/consent banners."

Fields this region must contain to satisfy SC#3:
- Measured range at 110 km/h 20°C (real-world Danish motorway range)
- Measured range at 0°C (cold range)
- FDM-measured DC peak kW (for FDM Test Notes only)
- Verdict narrative, Styrker, Svagheder
- DKK prices (base and tested trim)
- Article publication date

**wheel-size.com (Step 8 — best-effort):**
> "Fetch the URL and return ONLY the tire size block — the table or list showing OEM tire specifications for this specific make, model, and year. Include front and rear tire sizes (marked 'OE' or 'OEM'). Discard all navigation, advertisements, and unrelated size listings."

Fields this region must contain to satisfy SC#3:
- Front OEM tire size
- Rear OEM tire size (if different from front)

**Bilbasen Blog / manufacturer DK (Step 9 — purchase-type branch):**
- For `used` (Bilbasen Blog): "Return only the article body containing the used-market price range analysis — the low, typical, and high DKK figures and the article publication date. Discard navigation, unrelated articles, and comments."
- For `new` (manufacturer DK site): "Return only the pricing section showing tier 1 (base/from) and tier 2 (best-value mid-tier) DKK prices. Discard configurator, accessories, and unrelated page sections."
- For `leasing` (editorial articles): "Return only the section describing monthly payment ranges in DKK/month for this model. Discard unrelated articles and navigation."

### Token reduction estimate mechanics (D-08, SC#1)

The claim is ~80% reduction per page. To validate per D-08(a):

1. Run `/ev-detail "Volvo EX30"` with Lever B OFF (existing SKILL.md, no region prompt). Note the total context tokens consumed during the fork (approximate from Claude Code's context indicator or session summary).
2. Run `/ev-detail "Volvo EX30"` with Lever B ON (updated SKILL.md + `sites.md` with region prompts). Note the total context tokens.
3. Compare the per-fetch content weight (the difference attributable to fetched page content).

Per the API docs: "Average web page (10 kB): ~2,500 tokens; Large documentation page (100 kB): ~25,000 tokens." ev-database.org car pages are large — observed to consume ~10-15k tokens in Phase 2 (per SKILL.md Step 4 note). The spec-table region alone is a small fraction of the full page.

Practical baseline proxy: compare the character count of the full ev-database.org page text (from a Phase 2 golden run output) vs the spec-table section alone. The spec table is ~20-30 rows × ~3 columns — approximately 200-300 words vs the full page's several thousand words.

---

## Common Pitfalls

### Pitfall 1: Orchestrator reads the research file after the fork

**What goes wrong:** After `/ev-detail` returns, the SKILL.md orchestrator instructs Claude to read `research/<car>.md` to confirm the output. This loads the full research file (including all sourced spec data) into the orchestrator's context, defeating the fork isolation.

**Why it happens:** Understandable instinct to verify the output. But the fork's Step 13 confirmation ("File written: ...") is the verification signal.

**How to avoid:** SKILL.md Step in the orchestrator explicitly prohibits Read on research files: "Record the status line and file path. Do NOT read the file content."

**Warning signs:** Orchestrator context grows proportionally to number of cars researched.

### Pitfall 2: Region prompt silently drops a required field

**What goes wrong:** The region prompt selects the spec-table container but the page layout has the EV platform field outside the spec table (e.g., in a separate "About" section). The field is silently absent from the filtered output. The research file is written with the EV platform row blank, which fails SC#3 (VALIDATION-CHECKLIST requirement).

**Why it happens:** Region prompts are semantic, not structural. The model's interpretation of "spec-table container" depends on the page layout at fetch time.

**How to avoid:** Region prompts should explicitly name every required field group, not just the container. "Return the spec-table container AND the EV platform / dedicated platform section." Validate against VALIDATION-CHECKLIST.md field list before marking Lever B complete.

**Warning signs:** Research file has blank rows for fields that should always be present (EV platform, WLTP range).

### Pitfall 3: Interactive overwrite prompt auto-denied in background fork

**What goes wrong:** `/ev-detail` Step 3 checks if the file already exists and asks the user "overwrite or skip?" During a `/ev-research` validation re-run, if `/ev-detail` forks are dispatched as background subagents, this prompt is auto-denied (per docs: "background subagents auto-deny any tool call that would otherwise prompt"). Result: the second run silently skips the car.

**Why it happens:** Background subagent permission model (documented behavior).

**How to avoid:** For validation re-runs of the 5 golden scenarios (which reuse existing test projects), delete the existing research files before re-running through `/ev-research`. Or run `/ev-research` with sequential foreground forks (not background). The orchestrator SKILL.md should note: "If a car already has a research file, the /ev-detail fork will ask whether to overwrite. In foreground mode, this prompt surfaces to you. In parallel/background mode, it may be auto-denied — delete existing files before batch re-runs."

**Warning signs:** `/ev-research` reports fewer files written than cars requested.

### Pitfall 4: `sites.md` not referenced in SKILL.md steps

**What goes wrong:** `sites.md` is created in the skill directory but `ev-detail/SKILL.md` doesn't include a Read instruction for it. The file exists but the fork never loads it, so region prompts are never applied.

**Why it happens:** Supporting files must be explicitly referenced from SKILL.md. They are NOT auto-loaded.

**How to avoid:** Add a Read instruction at the start of Step 6 (or a preamble): "Before any WebFetch, read `.claude/skills/ev-detail/sites.md` (or use `${CLAUDE_SKILL_DIR}/sites.md`) to get the per-site region prompts and URL patterns. Apply the region prompt for the current site in the WebFetch instruction."

**Warning signs:** Fork fetches full pages despite `sites.md` existing.

### Pitfall 5: `$ARGUMENTS` car count exceeds what the orchestrator can process

**What goes wrong:** User invokes `/ev-research` with 10+ cars. The orchestrator runs all forks sequentially, taking 30-50+ minutes. Context from all the status lines accumulates but remains small (just strings). Not a correctness failure but a usability concern.

**Why it happens:** No limit is documented for how many arguments `$ARGUMENTS` can carry. Each fork is isolated so context doesn't overflow, but wall-clock time is additive.

**How to avoid:** Document in the skill description that `/ev-research` is suitable for 2-6 cars per run. For larger batches, run multiple `/ev-research` calls.

---

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual golden-run validation (no test runner — skills produce markdown output) |
| Config file | none |
| Quick run command | `/ev-research "Volvo EX30"` (single-car smoke test) |
| Full suite command | `/ev-research "Volvo EX30" "Volvo EX30 Cross Country" "Renault 5" ` + separate used/leasing project runs |
| Estimated runtime | ~3-5 min per car (live fetches) + ~1 min per-site token comparison |

### Phase 6 Requirements → Test Map

| SC# | Behavior | Test Type | Verification Method | Automated? |
|-----|----------|-----------|--------------------|-----------| 
| SC#1 | ~80% page-content token reduction on 4 known sites | Before/after measurement | Compare content character counts: full fetch (Phase 2 files) vs region-only fetch (Phase 6 run) | Manual |
| SC#2 | Returns sections verbatim, not pre-parsed values | Field inspection | Research file prose matches source language; no JSON/structured-only output | Manual golden run |
| SC#3 | All VALIDATION-CHECKLIST.md fields still present after section isolation | Field presence check | Re-run 5 Phase 2 golden scenarios via `/ev-research`; compare each output file against VALIDATION-CHECKLIST.md field list | Manual golden run |
| SC#4 | Unknown site / missing region falls back to bounded full fetch, never aborts | Negative test | Invoke `/ev-detail` on a car whose pricing URL is not in `sites.md`; verify file is written (not aborted) with `max_content_tokens` backstop | Manual |
| SC#5 | Adding a site is a single localized edit | Structure test | Add a mock 5th site entry to `sites.md`; verify no changes needed to `ev-detail/SKILL.md` | Code review |
| SC#6 | 5 Phase 2 golden scenarios via `/ev-research` complete without overflow | Run completion | All 5 cars produce research files; orchestrator prints summary without context exhaustion | Manual 5-car batch run |
| SC#7 | Orchestrator context never holds raw page content or research file bodies | Context inspection | After `/ev-research` completes, verify context usage is proportional to car count × (status-line + file-path size), not car count × page size | Manual observation |

### Sampling Rate

- **Per wave:** Run `/ev-research "Volvo EX30"` (1-car smoke test) after each task wave to confirm Lever A and B mechanics are intact.
- **Phase gate:** All 7 SCs verified before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `ev-detail/sites.md` — does not exist yet; must be created in Wave 1 (Lever B first task)
- [ ] `ev-research/SKILL.md` — does not exist yet; must be created in Wave 1 (Lever A)
- [ ] Token measurement baseline: record character counts from Phase 2 golden run files (`projects/ev-detail-test-new/research/volvo-ex30.md`) before any Phase 6 changes — use this as the "before" baseline for SC#1 validation.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Full HTML→text page dump per fetch | Region-prompt + `max_content_tokens` backstop | Phase 6 | ~80% reduction in per-page token cost within each fork |
| Multi-car runs in one executor context | One `/ev-detail` fork per car via `/ev-research` orchestrator | Phase 6 | Structural overflow prevention for any multi-car run |
| `web_fetch_20250910` (basic) | `web_fetch_20260209` (dynamic filtering) | Available now; harness auto-selects | Dynamic filtering enabled without skill changes |

**Deprecated/outdated:**
- Running `/ev-detail` directly in a multi-car validation executor (root cause of 02-03 overflow). The validation harness must go through `/ev-research` after Phase 6.

---

## Open Questions

1. **`max_content_tokens` as skill prose vs harness parameter**
   - What we know: The API tool definition supports `max_content_tokens` as a JSON field. In Claude Code sessions, the harness configures the tool. CLAUDE.md says "use `max_content_tokens`" as guidance.
   - What's unclear: Whether the SKILL.md can instruct the model to apply a specific `max_content_tokens` limit per fetch, or whether this is a session-level harness setting.
   - Recommendation: The Lever B implementation task should open a Claude Code session, instruct it to WebFetch a large page with an explicit "limit to ~2000 tokens" prose instruction, and observe whether truncation occurs. If not, escalate to harness-level configuration.

2. **Parallel fork rate-limit behavior**
   - What we know: Background subagents can run concurrently; docs warn "Running many subagents that each return detailed results can consume significant context." The orchestrator only gets status lines back (small), not page content.
   - What's unclear: Whether ev-database.org or fdm.dk have rate limits that trigger on simultaneous requests from multiple forks.
   - Recommendation: Default to sequential dispatch. Document the parallel option in the orchestrator's SKILL.md as a comment the user can explore.

3. **`${CLAUDE_SKILL_DIR}` in backtick injection**
   - What we know: `${CLAUDE_SKILL_DIR}` is a documented substitution variable (the directory containing the skill's SKILL.md). Backtick injection runs shell commands at invocation time.
   - What's unclear: Whether `` !`cat ${CLAUDE_SKILL_DIR}/sites.md` `` works as a backtick injection (auto-loading `sites.md` into the prompt) or whether Claude must use the Read tool at Step 6.
   - Recommendation: Test in Wave 1. If backtick injection works, use it (cheaper — loads once at invocation). If not, use a Read instruction at Step 6.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Claude Code session | All skills | Yes | Current (web_fetch_20260209 available) | — |
| WebFetch dynamic filtering | Lever B region prompts | Yes (harness auto-selects) | web_fetch_20260209+ | max_content_tokens prose instruction |
| ev-database.org | ev-detail Step 6 | Yes (verified Phase 2) | Live site | No fallback (mandatory source) |
| fdm.dk | ev-detail Step 7 | Yes (verified Phase 2) | Live site | Graceful gap note (best-effort) |
| wheel-size.com | ev-detail Step 8 | Yes (verified Phase 2) | Live site | Graceful gap note (best-effort) |
| Bilbasen Blog | ev-detail Step 9 (used branch) | Yes (verified Phase 2) | Live site | Graceful gap note (best-effort) |

**No blocking missing dependencies.**

---

## Security Domain

This phase modifies Claude Code skill files (prompt text) and adds one supporting markdown file. No authentication, session management, cryptography, or external API keys are involved. No new attack surface is introduced beyond what `/ev-detail` already exposes (live web fetching of known EV research sites). Security enforcement: no ASVS categories apply to this configuration-only phase.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `max_content_tokens` can be applied via SKILL.md prose instruction in a Claude Code session (not just as an API-level tool parameter) | Lever B mechanics | If wrong, the backstop must be implemented differently (harness config or a different approach). The region prompt still works; only the ceiling backstop is affected. |
| A2 | Parallel fork dispatch may hit site rate limits on ev-database.org / fdm.dk | Open Questions #2 | If rate limits exist and parallel is chosen, some forks may fail. Sequential dispatch avoids this entirely. |
| A3 | `` !`cat ${CLAUDE_SKILL_DIR}/sites.md` `` works as backtick injection in SKILL.md (injecting sites.md content at invocation time) | Open Questions #3 | If wrong, use Read tool at Step 6 instead. Functionally equivalent but slightly higher per-turn cost. |
| A4 | Token reduction from region prompts is approximately 80% for the four known sites (based on the ratio of spec-table content to full page content) | SC#1, token reduction estimate | If reduction is lower (e.g., 50%), SC#1 target may not be met with region prompts alone. Would require tighter region definitions or `max_content_tokens` set to lower values. |

**All other claims in this research are VERIFIED or CITED from official documentation.**

---

## Sources

### Primary (HIGH confidence)

- [VERIFIED: code.claude.com/docs/en/slash-commands] — Fetched 2026-06-22. Skills frontmatter fields (`context`, `agent`, `allowed-tools`, `disable-model-invocation`, `argument-hint`, `$ARGUMENTS`, `$ARGUMENTS[N]`, `${CLAUDE_SKILL_DIR}`), supporting files pattern, `context: fork` + `agent: Explore` mechanics, `disable-model-invocation` behavior.
- [VERIFIED: code.claude.com/docs/en/sub-agents] — Fetched 2026-06-22. Fork vs named subagent isolation, Explore agent tools (Haiku + read-only), what loads at startup, parallel vs sequential, fork boundary (only final result returns), nested subagents depth limit, background subagent auto-deny behavior.
- [VERIFIED: platform.claude.com/docs/en/docs/agents-and-tools/tool-use/web-fetch-tool] — Fetched 2026-06-22. `web_fetch_20260209` dynamic filtering mechanics, `max_content_tokens` parameter behavior and approximation note, current tool version `web_fetch_20260318` (latest), interaction between dynamic filtering and `max_content_tokens`.

### Secondary (MEDIUM confidence)

- [CITED: `.planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md`] — 5 golden-run scenarios, field coverage baseline for SC#3.
- [CITED: `.planning/phases/02-detail-skill/02-03-SUMMARY.md`] — Confirmed root cause (D-01): executor ran all 5 cars in one context, exhausted at SUMMARY step. Confirmed: `/ev-detail` is already `context: fork`.
- [CITED: `.claude/skills/ev-detail/SKILL.md`] — Steps 6-9 are the four known sites and their current fetch instructions. Steps 4 + 6 already carry token-ceiling notes. Existing `allowed-tools` and `context: fork` frontmatter confirmed.
- [CITED: `.claude/skills/ev-new-project/SKILL.md`, `ev-switch-project/SKILL.md`] — Established frontmatter/backtick-injection/`$ARGUMENTS` patterns for the orchestrator to mirror.
- [CITED: `CLAUDE.md`] — `web_fetch_20260209` as current version, `max_content_tokens` guidance, `sites.md` pattern, Firecrawl reserved for bot-blocking, `context: fork` + Explore for detail skill.

### Tertiary (LOW confidence)

- [ASSUMED] Parallel fork rate-limit behavior on ev-database.org / fdm.dk (not tested).
- [ASSUMED] `max_content_tokens` is settable via SKILL.md prose in Claude Code sessions (vs API-level parameter only).
- [ASSUMED] Backtick injection of `sites.md` via `${CLAUDE_SKILL_DIR}` works in skill SKILL.md files.

---

## Metadata

**Confidence breakdown:**
- Lever A mechanics (context:fork, $ARGUMENTS, fork isolation): HIGH — verified in official docs
- Lever B WebFetch dynamic filtering: HIGH — verified in official docs
- Per-site region prompt wording: MEDIUM — grounded in known Phase 2 page structures, but exact wording is implementation-time tuning
- Token reduction estimate (~80%): MEDIUM — plausible from page structure analysis; needs empirical validation per D-08
- max_content_tokens as SKILL.md prose: LOW — assumed, needs implementation verification

**Research date:** 2026-06-22
**Valid until:** 2026-07-22 (WebFetch tool version may advance; region prompts may need tuning as sites evolve)
