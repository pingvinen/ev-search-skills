# Phase 6: Fetch-Cost Reduction - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Stop research and validation runs from overflowing context (and cut the token
bill) when researching EVs. Discussion established that the Phase 2 plan 02-03
overflow had **two independent causes**, so this phase is re-scoped from
"fetch-cost reduction" to **context-cost reduction** across two complementary
workstreams, sequenced isolation-first:

- **Lever A — per-car isolation (primary):** a batch orchestrator so multi-car /
  validation runs research each car in its own fresh agent context. This is the
  direct fix for the 02-03 failure (the executor ran all 5 cars in one context).
- **Lever B — per-fetch section isolation:** make each individual page fetch
  return only the relevant content *section* (verbatim, not parsed values) so
  each car's own fork stays light and the bill drops ~80% per page. This is the
  original ROADMAP Phase 6 scope (candidate solution #2).

**Out of scope:** the MCP "sections server" (candidate solution #3 / the
in-skill escalation target) is **deferred** unless A+B in-skill prove
insufficient against the success criteria. Structured value extraction
(candidate #1's brittle opposite) stays rejected. No change to *what* per-car
research files contain — only *how* the data is fetched and how runs are
orchestrated.

**⚠ ROADMAP reconciliation required before planning closes:** the ROADMAP
Phase 6 entry (title "Fetch-Cost Reduction", the goal line, and the 3-candidate
-solutions table) describes fetch-only scope. It must be updated to the
two-lever framing above (isolation + fetch), same pattern as the Phase 2 ⚠
note. The 5 existing Success Criteria still apply to Lever B; Lever A needs its
own criteria added (multi-car run completes without overflow; orchestrator
context never holds raw page content).
</domain>

<decisions>
## Implementation Decisions

### Root Cause (grounds the whole phase)
- **D-01:** The 02-03 overflow was a **batching** failure, not primarily a
  per-page-weight failure. Per 02-03-SUMMARY: the executor "exhausted its
  context window at the SUMMARY-writing step" after running all 5 golden cars
  in its own single context. `/ev-detail` is **already** `context: fork,
  agent: Explore` — a single interactive call is already isolated. The gap is
  the multi-car / validation layer that did not honor that isolation.

### Lever A — Per-Car Isolation
- **D-02:** Build a thin **batch orchestrator skill** (working name
  `/ev-research "car1" "car2" ...`) that spawns **one isolated `/ev-detail`
  fork per car** and collects back **only** each car's status + result-file
  path — never the raw fetches or file bodies. The isolation guarantee is
  structural, not a documented convention.
- **D-03:** The validation harness (and any future multi-car run) goes through
  this orchestrator rather than running cars sequentially in one context.
- **D-04:** Sequencing — isolation (A) lands first. Because each isolated fork
  is then far lighter, the cheap in-skill Lever B is very likely "sufficient,"
  which is the ROADMAP's own trigger for **not** building the MCP server.

### Lever B — Per-Fetch Section Isolation
- **D-05:** Trim each known page with a **per-site region prompt + a
  `max_content_tokens` backstop**. The prompt does the smart selection (e.g.
  "return only the spec-table container" on ev-database, "the article body" on
  fdm.dk, "the size block" on wheel-size, "the listing/price region" on
  Bilbasen); the cap guarantees a ceiling so an unexpected layout cannot blow
  the budget. Return the **section verbatim**, never pre-parsed values — the
  model still does the semantic reading (preserves robustness to layout/wording
  drift, which is the project's "living tool" constraint).
- **D-06:** Per-site region selectors + URL patterns live in a **shared
  `sites.md` supporting file**, referenced by `/ev-detail` and (later)
  `/ev-search` / `/ev-compare`. Adding or adjusting a site = one localized edit
  (satisfies SC#5). Matches the `sites.md` pattern already named in CLAUDE.md.
- **D-07:** Graceful degradation (SC#4) carries forward unchanged: on an unknown
  site or a missing region, fall back to a **bounded full fetch**, never abort.

### Validation / Baseline
- **D-08:** No clean Phase 2 token baseline exists (02-03 overflowed before
  recording one), so prove the targets with two cheap measurements:
  (a) **per-site before/after** page-content token counts with isolation off vs
  on, for the ~80% claim (SC#1); and (b) **re-run the 5 golden scenarios through
  `/ev-research`** to confirm no checked field dropped (SC#3, against
  `VALIDATION-CHECKLIST.md`) and that the run completes without overflow
  (the Lever A criterion).

### Mechanics established during discussion (context for the planner)
- **D-09:** HTML→text conversion is **server-side and free to context** — the
  raw page never enters the model's context window. The token sink that
  overflowed is the *cleaned-text dump* landing in the fork. `max_content_tokens`
  truncates ingested content; dynamic filtering (the `web_fetch` region prompt)
  trims **before** content reaches context. Both reduce the same thing.
- **D-10:** In an agentic fork, a fetched page is **re-billed as input on every
  subsequent turn** until the fork ends — so an ~80% per-page cut multiplies
  across the turns that follow it. This is why both context pressure and the $
  bill move together and move a lot. Lever A removes cross-car compounding;
  Lever B removes per-page weight within a fork.

### Claude's Discretion
- Parallel vs sequential fan-out of per-car forks in `/ev-research` (rate-limit
  / throughput tradeoff).
- The exact `max_content_tokens` value per site.
- The precise region-prompt wording per site.
- The orchestrator's user-facing end-of-run summary format (N cars: status +
  path each).
- `/ev-detail` is unversioned (`allowed-tools: WebFetch`); it auto-uses whatever
  web-fetch version the harness ships — no version to pin or maintain.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Scope (⚠ needs reconciliation per <domain>)
- `.planning/ROADMAP.md` — Phase 6 entry: goal, 5 Success Criteria, and the
  3-candidate-solutions table (full-HTML / section-isolation / structured
  extraction). Title/goal/table describe fetch-only scope and must be updated to
  the two-lever framing; Lever A needs its own success criteria added.

### The Overflow Evidence (the "why" of this phase)
- `.planning/phases/02-detail-skill/02-03-SUMMARY.md` — documents the
  context-window exhaustion at the SUMMARY step (D-01 root cause).

### The Fetch Consumer (what Lever B modifies)
- `.claude/skills/ev-detail/SKILL.md` — already `context: fork, agent: Explore`.
  Steps 4–10 are the live-fetch sites: ev-database.org (Step 6, mandatory),
  fdm.dk (Step 7), wheel-size.com (Step 8), manufacturer DK / Bilbasen (Step 9).
  These are the four "known sites" the region prompts + `sites.md` cover. Already
  carries token-ceiling notes (Step 4, Step 6).

### Field-Coverage Baseline (SC#3 validation target)
- `.planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md` — the signed-off
  golden-run checklist; the re-run must reproduce every checked field.
- `.planning/phases/02-detail-skill/02-VALIDATION.md` — the 5 golden-run
  scenario definitions.
- `car-template.md` — the per-car output contract; every field here must still
  be obtainable from the isolated sections (no field silently dropped, SC#3).

### Conventions & Prior Decisions
- `CLAUDE.md` — web-fetching strategy per source, `max_content_tokens` guidance,
  the `sites.md` supporting-file pattern, and the "What NOT to use" guardrails
  (no Playwright on ev-database, no Firecrawl for token reduction — reserve for
  bot-blocking only).
- `.planning/phases/02-detail-skill/02-CONTEXT.md` — Phase 2 decisions D-01..D-10
  (esp. the ev-database token-ceiling mitigation already noted as discretion;
  the `context: fork` + Explore pattern; per-project state contracts).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/skills/ev-detail/SKILL.md` already forks (`context: fork`) and already
  contains every per-site fetch step — Lever B edits these in place (add region
  prompt + cap, source regions from `sites.md`). No new fetch logic to design.
- Phase 1 skills (`ev-new-project`, `ev-switch-project`) are the frontmatter /
  backtick-injection / `$ARGUMENTS` idiom to mirror for the new `/ev-research`
  orchestrator skill.
- The 5 golden-run fixtures + `VALIDATION-CHECKLIST.md` from Phase 2 are the
  ready-made validation harness for D-08.

### Established Patterns
- Skills live in `.claude/skills/<name>/SKILL.md` (NOT `.claude/commands/`).
- `context: fork` + `agent: Explore` is the established isolation pattern — the
  orchestrator (`/ev-research`) extends it from one car to N cars.
- A `sites.md` supporting file beside the skill is the named pattern for
  offloading per-site logic (CLAUDE.md).

### Integration Points
- `/ev-research` → spawns N × `/ev-detail` forks → each writes
  `projects/<active>/research/<car>.md` and updates per-project `state.md`;
  orchestrator returns only paths + status.
- `/ev-detail` → `sites.md` for region selectors per known site.
- Output of both still feeds Phase 3 `/ev-compare` (file structure unchanged).

</code_context>

<specifics>
## Specific Ideas

- `/ev-research "EX30" "Renault 5" "iX1"` → one isolated fork per car, each
  returning a short status line + file path; the orchestrator context never
  holds a page body. (User's stated design.)
- Region-prompt examples surfaced in discussion: ev-database = spec-table
  container; fdm.dk = article body; wheel-size = the size block; Bilbasen =
  listing/price region.

</specifics>

<deferred>
## Deferred Ideas

- **MCP "sections server"** (ROADMAP candidate solution #3 escalation target) —
  deferred. Only build if in-skill Lever A + Lever B fail to hit the success
  criteria. Isolation-first sequencing (D-04) is expected to make it unnecessary.
- **Structured value extraction** — remains rejected (brittle; fights the
  living-tool requirement). Firecrawl stays reserved for bot-blocking only, not
  token reduction.

</deferred>

---

*Phase: 06-fetch-cost-reduction*
*Context gathered: 2026-06-22*
