# Roadmap: Car Research Skills

## Overview

Five phases that build the skill suite in dependency order: a data contract first, then the core detail skill (the highest-value piece), then the search and comparison skills that depend on having real per-car files to work with, then Danish market and ownership quality enrichment, and finally tire research (a global tire-sources skill and scoring) that layers on top of a stable detail skill. Every phase leaves the system in a usable state.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Define the data contract and criteria file that all skills depend on (completed 2026-06-22)
- [x] **Phase 2: Detail Skill** - Build and validate the core skill that fetches deep specs and writes per-car files (completed 2026-06-22)
- [x] **Phase 3: Search and Compare** - Build the search and comparison skills that work on top of existing per-car files (completed 2026-06-28)
- [ ] **Phase 4: Danish Enrichment** - Layer in ownership quality signals and Danish market context
- [ ] **Phase 5: Tire Research** - Global tire-sources skill with median-of-histogram scoring; tire pricing and top-3 all-season recommendations in per-car files
- [x] **Phase 6: Fetch-Cost Reduction** - Cut context/token cost of EV research via two levers — per-car fork isolation (orchestrator) + per-fetch section isolation — so research/validation runs stop overflowing context (completed 2026-06-23)

## Phase Details

### Phase 1: Foundation

**Goal**: The data contract exists — criteria file, per-car file template, and source fetch patterns are defined so every subsequent skill builds on a stable schema
**Depends on**: Nothing (first phase)
**Requirements**: SRCH-01, SRCH-04, SRCH-05, SRCH-06, PROJ-01, PROJ-02, PROJ-03, PROJ-04
**Success Criteria** (what must be TRUE):

  1. The active project's `brief.md` exists with documented schema covering budget, range, body type, seats, requirements, and exclusions *(schema is the Phase 1 deliverable; "Claude reads it correctly when invoked" is a runtime behavior of `/ev-search`, verified in Phase 3)*
  2. `car-template.md` exists with labeled sections for WLTP range, FDM real-world range, charging specs, DKK price, Danish tax, tire size, and a mandatory Sources section with URL and fetch date fields
  3. The template enforces the WLTP/real-world range distinction so the two figures cannot be silently mixed in any skill output
  4. Running `/ev-new-project "family-ev"` creates `projects/family-ev/` with `brief.md`, `research/` subfolder, and `comparison.md`
  5. Running `/ev-switch-project "family-ev"` sets active project context so that `/ev-detail`, `/ev-search`, and `/ev-compare` operate within `projects/family-ev/`
  6. The `brief.md` schema supports per-brand budget overrides (e.g., BMW with a higher ceiling) *(schema is the Phase 1 deliverable; "the search skill respects them" is verified in Phase 3 `/ev-search`)*
  7. The `brief.md` schema supports a must-have features list (e.g., wireless Android Auto) *(schema is the Phase 1 deliverable; "the search skill uses it to filter results" is verified in Phase 3 `/ev-search`)*

**Plans:** 2 plans

Plans:

- [x] 01-01-PLAN.md — Data contracts: car-template.md and global state.md
- [x] 01-02-PLAN.md — Project management skills: /ev-new-project and /ev-switch-project

### Phase 2: Detail Skill

**Goal**: Users can run `/ev-detail [car name]` and receive a fully sourced, structured per-car research file in `research/`
**Depends on**: Phase 1
**Requirements**: DETL-01, DETL-02, DETL-03, DETL-04, DETL-05, DETL-06, DETL-07, DETL-08, DETL-09, DETL-10, TIRE-01, OWNR-01, SRCH-07
**Success Criteria** (what must be TRUE):

  1. Running `/ev-detail volvo-ex30` produces the active project's `research/volvo-ex30.md` with all required fields populated from live fetches — no training data used for any spec
  2. Every fact in the per-car file cites a source URL and fetch date in the Sources section
  3. FDM real-world Danish range at 110 km/h is present when an FDM test article exists, and the file notes "no FDM test found" when it does not
  4. Tire size (front and rear if different) is captured in the per-car file (tire pricing and recommendations are Phase 5)
  5. FDM qualitative verdict and pros/cons are captured when available and attributed with confidence level
  6. Per-car file includes tier 1 ("from price") and tier 2 equipment package DKK prices
  7. Per-car file notes whether the car is built on a dedicated EV platform or an adapted ICE platform

**Plans:** 3/3 plans complete
Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Validation fixtures: three purchase-type test projects + golden-run checklist
- [x] 02-02-PLAN.md — Author the /ev-detail skill (ev-database fetch, variant selection, FDM/tire/pricing, file write)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-03-PLAN.md — Golden-run validation of /ev-detail against the 5 scenarios

### Phase 3: Search and Compare

**Goal**: Users can discover matching EV models from their criteria file and generate a side-by-side comparison table from existing per-car files
**Depends on**: Phase 2
**Requirements**: SRCH-02, SRCH-03, COMP-01, COMP-02, COMP-03
**Success Criteria** (what must be TRUE):

  1. Running `/ev-search` reads the active project's `brief.md` and returns a list of matching models from ev-database.org with DKK price, range, battery capacity, and body type for each
  2. Running `/ev-compare` reads all of the active project's `research/*.md` files and writes the active project's `comparison.md` with one column per car
  3. The comparison table labels the range methodology per column (WLTP vs FDM real-world) so the figures are unambiguous

**Plans**: 2 plans

- [x] 03-01-PLAN.md — `/ev-search` skill: brief.md → ev-database discovery → DK price band → Search Candidates in state.md + `/ev-research` handoff (SRCH-02, SRCH-03)
- [x] 03-02-PLAN.md — `/ev-compare` skill: Glob research/*.md → side-by-side comparison.md with separate labelled WLTP/FDM range rows (COMP-01, COMP-02, COMP-03)

### Phase 4: Danish Enrichment

**Goal**: Per-car files include Danish market context and ownership quality signals beyond FDM data, making the research actionable for a Danish buyer
**Depends on**: Phase 2
**Requirements**: DKMK-01, DKMK-02, OWNR-02, OWNR-03, OWNR-04, OWNR-05, OWNR-06
**Success Criteria** (what must be TRUE):

  1. Per-car file includes a Danish registration tax note with the 2026 BEV rate and deduction, fetched live from Motorstyrelsen with a source URL and fetch date
  2. Per-car file flags power output >150 kW with an insurance tier annotation
  3. Per-car file includes a DK workshop and service availability note
  4. Per-car file captures brand-level reliability signals and known issues or common complaints, each labeled with confidence level and source
  5. Brand quality research covers the past 10 years only — recent track record, not legacy reputation

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete   | 2026-06-22 |
| 2. Detail Skill | 3/3 | Complete   | 2026-06-22 |
| 3. Search and Compare | 2/2 | Complete    | 2026-06-28 |
| 4. Danish Enrichment | 0/TBD | Not started | - |
| 5. Tire Research | 0/TBD | Not started | - |
| 6. Fetch-Cost Reduction | 3/3 | Complete    | 2026-06-23 |

### Phase 5: Tire Research

**Goal**: A global `/ev-tire-sources` skill maintains a pool of 5+ trustworthy tire testers and scores all-season tires using median-of-histogram methodology; `/ev-detail` calls into it to populate each per-car file with tire pricing and the top 3 all-season recommendations for the car's tire size
**Depends on**: Phase 2 (the detail skill exists to call into tire research)
**Requirements**: TIRE-02, TIRE-03, TIRE-04, TIRE-05, TIRE-06, TIRE-07
**Success Criteria** (what must be TRUE):

  1. `/ev-tire-sources` maintains a shared `tire-sources.md` at repo root listing 5+ trustworthy tire testers (e.g., ADAC, TCS, AutoBild) with URL pattern and extraction hints per source
  2. Adding a new source means adding one entry to `tire-sources.md` — no restructuring of existing scores
  3. Tire scoring uses median-of-histogram: ratings collected across all available sources, median taken as the representative score
  4. Per-car files capture current pricing for a quality all-season set (Michelin/Goodyear tier) for the car's tire size
  5. Per-car files recommend the top 3 all-season tires with median score, price, and sources consulted
  6. `tire-sources.md` is global (repo root), not per-project, and is shared across all projects

**Plans:** 2/2 plans complete

Plans:

- [ ] TBD (run /gsd-plan-phase 5 to break down)

### Phase 6: Fetch-Cost Reduction

**Goal**: Live web fetches cost dramatically fewer tokens so research and validation runs stop overflowing context — without sacrificing the model's ability to read values across sites that change layout or word fields differently between cars
**Depends on**: Phase 2 (the `/ev-detail` skill is the primary consumer of fetched pages)
**Requirements**: TBD (run /gsd-plan-phase 6 to break down)

> **⚠ Scope reconciled 2026-06-22 (discuss-phase, see `06-CONTEXT.md`).** Discussion established the 02-03 overflow had **two independent causes**, so this phase is re-scoped from fetch-only to **context-cost reduction across two complementary workstreams, sequenced isolation-first**:
>
> - **Lever A — per-car isolation (primary):** a thin batch-orchestrator skill (working name `/ev-research "car1" "car2" …`) that spawns **one isolated `/ev-detail` fork per car** and collects back **only** each car's status + result-file path — never raw fetches or file bodies. This is the direct fix for the 02-03 failure (the executor ran all 5 golden cars in one context and exhausted it at the SUMMARY step). The isolation guarantee is structural, not a documented convention.
> - **Lever B — per-fetch section isolation:** the original fetch-only scope below (candidate #2). Each known page fetch returns only the relevant content **section** verbatim, so each fork stays light.
>
> Sequencing: Lever A lands first; because each isolated fork is then far lighter, the cheap in-skill Lever B is very likely "sufficient" — the trigger for **not** building the MCP server (candidate #3, deferred). Structured extraction (candidate #1's opposite) stays rejected. The candidate-solutions table and criteria 1–5 below describe **Lever B**; **Lever A criteria are 6–7** in Success Criteria.

**Motivation**: Phase 2 plan 02-03 (golden-run validation) exhausted its entire context window doing ~5 live golden-run fetches and died before writing its SUMMARY. Two independent causes (per `06-CONTEXT.md` D-01): (A) **batching** — the executor ran all 5 cars in one context instead of honoring `/ev-detail`'s existing `context: fork` isolation per car; and (B) **per-page weight** — full HTML→text page dumps are the dominant token sink across the whole tool — nav, footer, ads, scripts, and related-articles markup vastly outweigh the dozen fields a research file actually needs, and in an agentic fork each fetched page is re-billed as input on every subsequent turn.

**Candidate solutions** (a deliberate robustness-vs-token-cost tradeoff):

| # | Approach | Tokens/page | Robustness to site/wording change | Who interprets |
|---|----------|-------------|-----------------------------------|----------------|
| 1 | Full HTML→text (status quo) | highest | total — model sees everything | model |
| 2 | **Section isolation (RECOMMENDED)** | low (~80%+ reduction) | **high** — model still reads prose | **model** |
| 3 | Structured value extraction | lowest | brittle — selectors rot, wording variance breaks it | server |

1. **Full HTML→text (baseline)** — fetch the whole page, model sees everything. Highest tokens per page; total robustness; no new infrastructure. This is the current behavior and the cause of the 02-03 overflow.

2. **Section isolation (RECOMMENDED)** — a fetch layer (WebFetch with `max_content_tokens` + per-site region prompts, escalating to a small MCP server) returns only the relevant **content section** of a known page *verbatim* — the spec-table container on ev-database.org, the article body on fdm.dk, the size block on wheel-size.com, the listing/price region on bilbasen — **not parsed values**. Drops boilerplate for ~80%+ reduction while keeping HIGH robustness, because the *model* still does the semantic reading and so absorbs layout shifts and wording differences between car X and car Y (e.g. "WLTP range" vs "Range (WLTP)"). The server's only durable knowledge is *where* the meaningful region lives per site, not how to parse it. Can tier further: return the main region by default, let the model request a tighter sub-section if still large. Fits the project's "living tool that survives new models and new sites" constraint.

3. **Structured value extraction** — server parses pages into typed fields (range, battery, charging, prices, tire sizes) and returns compact JSON. Lowest tokens, but **brittle**: CSS selectors rot on layout change and per-car wording variance breaks extraction, and the server owns interpretation — fighting the living-tool requirement. Keep Firecrawl MCP in reserve only for bot-blocking, not for token reduction.

**Recommendation to carry into planning**: Prefer #2 (section isolation). Implement first as the cheap in-skill win — WebFetch `max_content_tokens` + targeted per-site region prompts — then escalate to a small MCP server returning structured **sections** per known site (ev-database, FDM, wheel-size, Bilbasen) for deterministic, repeatable region selection if the in-skill approach proves insufficient.

**Success Criteria** (what must be TRUE):

*Lever B — per-fetch section isolation:*

  1. A representative `/ev-detail` golden run consumes materially fewer fetch tokens than the Phase 2 baseline (target: page-content tokens reduced ~80%+ on the four known sites)
  2. The chosen approach returns content *sections*, not pre-parsed values, so the model still reads and interprets the figures
  3. The isolated section for each known site still contains every field the Phase 2 golden runs check (no field silently dropped by trimming) — validated against the Phase 2 VALIDATION-CHECKLIST scenarios
  4. The fetch layer degrades gracefully on an unknown site or a missing region (falls back to a bounded full fetch, never aborts)
  5. Adding or adjusting a site's region selector is a single localized change — no restructuring of the skill or other sites' handling

*Lever A — per-car isolation:*

  6. A multi-car run (the 5 Phase 2 golden scenarios through the new `/ev-research` orchestrator) completes without overflowing context and produces each car's research file
  7. The orchestrator context never holds raw page content or research-file bodies — only per-car status + result-file paths cross the fork boundary back to it

**Plans:** 3/3 plans complete

Plans:

**Wave 1**

- [x] 06-01-PLAN.md — Lever A: the `/ev-research` batch orchestrator (one isolated `/ev-detail` fork per car; collects only status + path)
- [x] 06-02-PLAN.md — Lever B: `ev-detail/sites.md` per-site region selectors + wire Steps 6-9 to region prompt + `max_content_tokens` backstop (open-question probes front-loaded)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 06-03-PLAN.md — Validation: per-site token before/after (~80% target) + 5-car golden re-run through `/ev-research` (no field dropped, no overflow)

## Backlog

### Phase 999.1: /ev-new-project guided Q&A brief elicitation (BACKLOG)

**Goal:** Turn `/ev-new-project` from a passive template writer into a guided Q&A that helps the user think through the search up front and populates `brief.md` from their answers.

Today the skill (`.claude/skills/ev-new-project/SKILL.md`) asks a single question (purchase type), then scaffolds a `brief.md` full of empty `<!-- comment -->` placeholder sections the user fills in by hand. After purchase type, it should walk the user through the aspects that matter and write their answers into `brief.md`: context / what's being replaced, budget (with per-brand overrides), body type, seats, must-have features (hard filters) vs preferred features (nice-to-haves), and exclusions / brand notes.

**Motivation:** On the real `example-2026` project the user ended up doing exactly this Q&A manually; guiding it in the skill would remove that friction.

**Open design questions (resolve at plan time):**

- How adaptive the questions are — e.g. follow-ups keyed to purchase type (`used` adds age/mileage limits, `leasing` adds term/upfront).
- Whether aspects the user skips still fall back to templated placeholder sections (so nothing is silently dropped) rather than being omitted.
- How lightweight vs thorough to keep the question set.

**Scope:** Phase 1 skill enhancement, single file (`ev-new-project/SKILL.md`), no dependencies. Independent of Phase 4 (Danish Enrichment).

**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with /gsd-review-backlog when ready)
