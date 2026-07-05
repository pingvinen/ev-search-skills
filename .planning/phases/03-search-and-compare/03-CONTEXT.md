# Phase 3: Search and Compare - Context

**Gathered:** 2026-06-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Build two new skills on top of the existing per-car research files:

- **`/ev-search`** — reads the active project's `brief.md`, discovers EV models that match the criteria, and returns a list of matching models from ev-database.org with (per SC#1) DKK price, range, battery capacity, and body type for each. It persists the candidate list to the per-project `state.md` and presents it in the conversation with a ready-to-run `/ev-research` handoff. It is a **shallow** discovery pass — deep per-car research stays the job of `/ev-detail`.
- **`/ev-compare`** — reads all of the active project's `research/*.md` files and writes the active project's `comparison.md` with one column per car (SC#2), labelling range methodology per column (SC#3).

**Requirements in scope:** SRCH-02, SRCH-03, COMP-01, COMP-02, COMP-03.

**Fixed by ROADMAP Success Criteria (not gray areas):**
1. `/ev-search` reads `brief.md` → matching models with DKK price, range, battery, body type each.
2. `/ev-compare` reads all `research/*.md` → writes `comparison.md`, one column per car.
3. Comparison labels range methodology per column (WLTP vs FDM real-world).

**Out of scope (new capabilities → other phases):** adding new filter dimensions beyond the brief schema; cross-project comparison (PROJ-03 forbids it); tire scoring (Phase 5); Danish tax/insurance enrichment (Phase 4). The brief schema (budget incl. per-brand overrides, range, body, seats, must-haves, purchase_type) is the fixed filter input — `/ev-search` consumes it, it is not extended here.

</domain>

<decisions>
## Implementation Decisions

### Search discovery mechanism (`/ev-search`)
- **D-01:** ev-database.org's listing/filter page is JavaScript-driven and blocked to WebFetch (established Phase 2, see ev-detail SKILL.md Step 4). The discovery mechanism is **not pre-decided** — the phase researcher must **spike cheapest-first** and adopt the lightest approach that gives good coverage:
  1. **Zero-install, most direct:** does ev-database expose a `curl`-able JSON/XHR endpoint behind the filter, or a *server-rendered* filtered listing URL (query params)? `curl` is already available (Bash) — if this works it is the cheapest and most direct path.
  2. **Zero-install fallback:** knowledge-seeded candidate model **names** from the brief (bounded set, ~8–15, not a WebSearch flood), then verify each against its **own server-rendered ev-database detail page** (WebFetch-friendly, same as `/ev-detail`). Sidesteps the JS filter entirely. Weakness: a brand-new model outside Claude's knowledge could be missed (add by hand).
  3. **Escalate only if coverage is poor:** a **local, free, open-source** headless tool to render the filter page — Playwright MCP (`npx @playwright/mcp`, lighter) or self-hosted Firecrawl (Docker, heavier). User-run on their own machine.
- **D-02:** **No paid services.** Firecrawl *cloud* is rejected (paid). Firecrawl is open-source/self-hostable, so it is permitted only as a local, free option; Playwright MCP is the lighter local alternative. This is the user's hard constraint for the project ("personal skills, not a product").
- **D-03:** Pure WebSearch-driven discovery is **disfavoured** — risk of a flood of hits requiring many costly WebFetches, and/or poor coverage. Use it only as a component of approach #1/#2 (e.g. resolving a known model name to its ev-database URL), not as the primary discovery engine.
- **D-04:** Per-candidate fetch depth follows whichever mechanism wins — `/ev-search` only needs the four SC#1 fields (price band, range, battery, body type) cheaply; it must NOT do full `/ev-detail`-depth research.

### Search-stage pricing (`/ev-search`)
- **D-05:** **No FX/currency conversion.** EUR/GBP prices on ev-database are not convertible to a meaningful DKK figure because Danish car taxation is fundamentally different from other countries. A converted figure would mis-rank cars.
- **D-06:** Search stage shows a rough DK **price band/bucket**, not a precise figure (SC#1 "DKK price" is satisfied by an explicitly-labeled indicative band). Real, precise pricing — new (tier1/tier2), used (Bilbasen range), leasing (monthly) — is reserved for the **shortlist** via `/ev-detail`'s existing purchase-type branch.
- **D-07:** The band signal comes from a **cheap live DK-price search per candidate** (e.g. `"<make> <model> pris DKK"`) — take the snippet figure, bucket it, label it indicative. Live (no training data for the figure), and precision doesn't matter since it's only bucketed.
- **D-08 (Claude's discretion, recommended):** Anchor bands to the **brief budget** (preferred + maximum, incl. per-brand overrides) — e.g. *within budget* / *slight stretch (near-miss)* / *over* — rather than arbitrary absolute DKK thresholds. "Rough magnitude is fine" (user) — bucketing only needs ballpark accuracy.

### Search output & handoff (`/ev-search`)
- **D-09:** `/ev-search` persists the candidate list to the **per-project `state.md`** in a new **"Search Candidates"** section (reuses the existing artifact alongside Research Progress / Discovered Sources / Source Reliability Notes — no new file to drift). One row per candidate: model name, ev-database URL, body type, WLTP range, battery, DK price band, and a **filter verdict** (match / borderline+reason / excluded+reason). This stored shallow data both renders the list and drives which cars to take deep with `/ev-research`.
- **D-10:** This means `/ev-search` gains **Write** access to `projects/<active>/state.md` (it was previously envisioned as conversation-only). Tools become roughly `WebFetch, WebSearch, Read, Write, Bash(ls *)` (+ whatever D-01's chosen mechanism needs).
- **D-11:** `/ev-search` also **presents the ranked list in the conversation** and ends with a copy-paste-ready `/ev-research "A" "B" ...` for the cars the user picks (matches CLAUDE.md "search outputs to conversation" convention; the state.md write is the persistence layer, not a replacement for the chat output).
- **D-12:** **Near-misses are surfaced, flagged separately**, never silently dropped. Hard-filter only on what's cheaply knowable (body type, rough range, budget band). Cars that slightly stretch budget, or whose must-haves (e.g. wireless Android Auto) can't be confirmed cheaply at search stage, go in a flagged "borderline" group with the reason. Must-haves are deep-spec — confirmed at `/ev-detail`. The user decides what to research.
- **D-13:** Re-running `/ev-search` for a project **overwrites the Search Candidates section with a dated snapshot** (latest discovery wins; no stale rows linger). Fits the living-tool freshness model.

### Comparison output (`/ev-compare`)
- **D-14:** `comparison.md` is **decision support, not a neutral dump**: the full ~15 spec rows from `car-template.md` (one column per car), **best-in-class highlighted per row** (longest range, fastest charge, lowest price band, etc.), **plus a short brief-aware verdict at the top** ("best fit for this brief: X because…"), reasoned from the data.
- **D-15:** Include **condensed qualitative signals** in addition to specs: FDM verdict one-liner, top pros/cons, ownership confidence — the research files already hold these. Not specs-only.
- **D-16:** SC#3 (locked): WLTP range and real-world (FDM) range stay as **separate, per-column-labelled rows**, mirroring `car-template.md`. Never merged or averaged (carries forward Phase 2 data discipline).
- **D-17:** Gaps render **explicitly** (e.g. "no FDM test", "tire size unconfirmed") — never blank or guessed — so missing data is visible in the comparison.
- **D-18:** `/ev-compare` is a write-side skill → `disable-model-invocation: true` (never auto-trigger a file overwrite), tools `Read, Write, Glob` (per CLAUDE.md comparison-skill pattern). It reads only the active project's `research/*.md` (PROJ-03: no cross-project reads).

### Claude's Discretion
- The exact discovery tactic within D-01's spike order (which ev-database URL/endpoint, query patterns, candidate-set size).
- Exact band scheme labels and boundaries (D-08 recommends brief-budget-relative).
- Per-candidate WebSearch query wording for the DK price-band signal.
- Ranking/sort order of the candidate list and the comparison columns.
- Exact "Search Candidates" section schema/columns in `state.md`.
- `comparison.md` layout details (table grouping, how condensed qualitative rows are formatted, how best-in-class is visually marked).
- Whether to cap the candidate count and at what number.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Output & input contracts
- `car-template.md` — the per-car file structure `/ev-compare` reads (the ~15 spec rows, FDM notes, ownership, pros/cons, Sources). Defines every comparable field and the WLTP-vs-real-world separate-rows contract (D-16).
- `projects/<active>/state.md` (per-project) — `/ev-search` writes the new "Search Candidates" section here (D-09); also holds Research Progress used to know what's already researched. See `projects/test-ev-detail-new/state.md` for the live shape.
- `projects/<active>/brief.md` — the filter input for `/ev-search`: budget (preferred + maximum), per-brand overrides, must-have features, body type, seats, purchase_type. See `projects/test-ev-detail-new/brief.md`.
- `state.md` (repo root) — global state; `active_project` field both skills read via `!`cat state.md`` injection.

### Skills to mirror / integrate with
- `.claude/skills/ev-detail/SKILL.md` — the deep-research skill `/ev-search` hands off to. Step 4 documents the ev-database JS-listing limitation (D-01); Step 9 documents the purchase-type DKK pricing branch (real pricing reserved for shortlist, D-06); Steps 6–9 show the inline per-site region-prompt + `max_content_tokens` pattern to reuse for any `/ev-search` fetch.
- `.claude/skills/ev-research/SKILL.md` — the batch orchestrator `/ev-search` hands off to (`/ev-research "A" "B" ...`); D-11's suggested command must match its arg format. Note its Step 4 fork-boundary discipline (it reads only paths/status, not file bodies) — `/ev-compare` is the consumer that actually reads the research files.
- `.claude/skills/ev-new-project/SKILL.md`, `.claude/skills/ev-switch-project/SKILL.md` — frontmatter conventions (`name`, `description`, `allowed-tools`, `disable-model-invocation`, `argument-hint`), `!`cat state.md`` backtick injection, `$ARGUMENTS`, numbered-steps body. Mirror these for both new skills.

### Conventions & strategy
- `CLAUDE.md` — web-fetching strategy per source (ev-database HIGH/WebFetch but listing JS-blocked; WebSearch→fetch for FDM), the "search outputs to conversation" pattern (D-11), the comparison-skill stack pattern (`Read, Write, Glob` + `disable-model-invocation`, D-18), and the "What NOT to use" guardrails — incl. the Playwright/Firecrawl notes that need a nuance update if D-01 escalates to a local headless tool (the existing note targets *detail* pages, which are server-rendered; rendering the JS *filter listing* is a different, justified case).

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — SRCH-02, SRCH-03, COMP-01, COMP-02, COMP-03 definitions (and SRCH-01/04/05/06 brief-schema fields `/ev-search` consumes).
- `.planning/ROADMAP.md` — Phase 3 goal + the 3 Success Criteria (the fixed constraints above).
- `.planning/phases/02-detail-skill/02-CONTEXT.md` — Phase 2 decisions (mandatory-source/best-effort split, variant selection, purchase-type branching) that `/ev-search` discovery and `/ev-detail` handoff build on.
- `.planning/phases/06-fetch-cost-reduction/06-CONTEXT.md` — section-isolation / region-prompt + `max_content_tokens` discipline and the per-car fork isolation pattern; any `/ev-search` fetch should stay light in the same spirit.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `car-template.md`: fixed field set → `/ev-compare` maps template rows directly to comparison rows; no field design needed.
- Per-project `state.md` already has sectioned structure (Research Progress / Discovered Sources / Source Reliability Notes) — `/ev-search` appends a sibling "Search Candidates" section (D-09).
- Phase 1/2 skills supply the frontmatter + backtick-injection + `$ARGUMENTS` idiom to copy for both new skills.
- `ev-detail` Steps 6–9 already demonstrate the lightweight region-prompted fetch pattern `/ev-search` should reuse for any per-candidate fetch.

### Established Patterns
- Skills live in `.claude/skills/<name>/SKILL.md` (NOT `.claude/commands/`).
- Active project resolved via `!`cat state.md`` injection; no hardcoded project paths.
- ev-database **detail** pages are server-rendered (WebFetch-friendly); the **listing/filter** page is JS-driven (blocked) — the core constraint shaping D-01.
- Write-side skills carry `disable-model-invocation: true` (per CLAUDE.md; applies to `/ev-compare`, D-18).
- No shared `sites.md` exists in the repo — Phase 6 region prompts ended up inline in `ev-detail`. `/ev-search` defines its own ev-database query approach (the D-06 06-CONTEXT `sites.md` plan was not implemented as a separate file).

### Integration Points
- Workflow chain: `/ev-search` (brief.md → candidates in state.md + chat) → user picks → `/ev-research "A" "B"` → N× `/ev-detail` forks → `research/*.md` → `/ev-compare` → `comparison.md`.
- `/ev-search` reads global `state.md` → active project → reads `brief.md`, writes `projects/<active>/state.md`.
- `/ev-compare` reads global `state.md` → active project → reads all `projects/<active>/research/*.md`, writes `projects/<active>/comparison.md`.

</code_context>

<specifics>
## Specific Ideas

- User's framing on pricing: "Applying an FX conversion to prices from other countries does not work, as our tax system on cars is completely different. Perhaps what we need is an initial price segment/bucket/range, and then for the shortlist, we get into the real pricing (including leasing, used etc)." → D-05..D-08.
- User's framing on output: store enough in the per-project state file to present the list and do initial filtering to decide which cars to go deep on. → D-09.
- User's tooling ethos: "we are not really building a product per se, just a bunch of useful skills for my own needs" → no paid deps; local/free/zero-install preferred (D-01, D-02).
- Search example handoff: `/ev-search` → ranked chat list → `/ev-research "Volvo EX30" "Renault 5" ...`.

</specifics>

<deferred>
## Deferred Ideas

- **Adopting a local headless tool (Playwright MCP / self-hosted Firecrawl)** — only if the zero-install discovery spikes (D-01 steps 1–2) prove insufficient on coverage. Not built speculatively.
- **CLAUDE.md "What NOT to use" nuance update** — if D-01 escalates to a local headless browser for the JS filter listing, update the Playwright/Firecrawl guardrail so it reads as "no browser for server-rendered *detail* pages" rather than a blanket ban. Do at implementation time, only if that path is taken.
- **Tire scoring / pricing, Danish tax & insurance enrichment** — Phases 5 and 4 respectively; not part of search or compare.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 3-search-and-compare*
*Context gathered: 2026-06-27*
