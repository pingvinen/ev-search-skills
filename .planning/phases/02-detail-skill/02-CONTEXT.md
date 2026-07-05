# Phase 2: Detail Skill - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Build and validate the core `/ev-detail [car name]` skill: it resolves a free-text car name to an ev-database.org model, fetches deep specs from multiple live sources, and writes a fully-sourced per-car research file conforming to `car-template.md` into the active project's `research/<make-model>.md`. The skill reads the active project from global `state.md` (backtick injection), runs in `context: fork` with the Explore agent for multi-URL fetching, and updates the per-project `state.md` research progress.

**Requirements in scope:** DETL-01..DETL-10, TIRE-01, OWNR-01, SRCH-07 (all three purchase types).

**Scope adjustments made during discussion (see Deferred Ideas + ⚠ ROADMAP note):**
- TIRE-02 (tire pricing) and TIRE-03 (tire research prompt) are **deferred** out of Phase 2.
- TIRE-04..TIRE-07 (global `/ev-tire-sources` skill + median-of-histogram scoring) remain in a **separate future phase**, not Phase 2.
- Phase 2 captures tire **size only** (TIRE-01).

</domain>

<decisions>
## Implementation Decisions

### Tire Research Scope
- **D-01:** Phase 2 is the detail skill only. `/ev-detail` captures tire **size** (front/rear if different) per TIRE-01. No tire pricing, no scoring, no recommendations in this phase.
- **D-02:** The global `/ev-tire-sources` skill, median-of-histogram scoring, and top-3 tire recommendations (TIRE-04..07) + tire pricing (TIRE-02) and the tire-research prompt (TIRE-03) are deferred to their own future phase. ⚠ This deviates from ROADMAP Phase 2 Success Criterion #4 and the Phase 2 requirements line — the ROADMAP must be updated (see Deferred Ideas).

### Source Orchestration & Failure Handling
- **D-03:** ev-database.org specs are **mandatory**. If the car cannot be found there, abort with a clear message — do not write a file.
- **D-04:** FDM (via WebSearch→fetch), greengarage.dk, and used/leasing market pricing are **best-effort**. When a best-effort source yields nothing, write the file anyway with the gap explicitly noted (e.g., "No FDM test found as of [date]") per DETL-08. Aligns with graceful-degradation intent.

### Variant Resolution
- **D-05:** When a car name maps to multiple ev-database.org variants (battery sizes, trims), auto-select the variant that **best matches the active project's BRIEF** (budget, range, must-haves). Document the chosen variant and note that other variants existed.
- **D-06:** Tie-breaker: prefer the **middle tier**. Rationale from the user — where a model historically has 3 variants, the middle one has tended to offer the best value for money.

### Purchase-Type-Aware Sourcing (SRCH-07)
- **D-07:** `/ev-detail` branches on the project's `purchase_type` (read from BRIEF.md):
  - `new` → tier 1 ("from") and tier 2 (best-value) DKK pricing (DETL-09).
  - `used` → Bilbasen-derived **market price range** (low / typical / high) for the model — NOT a specific listing.
  - `leasing` → typical **monthly payment + residual range** — NOT a specific offer.
- **D-08:** Used/leasing pricing is captured as a representative **market range**, not specific (stale-prone) individual listings. This is a research tool, not a purchase tool.

### Re-run / Overwrite Behavior
- **D-09:** When a research file already exists for the requested car in the active project, **detect it and ask the user** whether to overwrite, skip, or update-in-place. Never clobber silently (protects manual edits).

### Sourcing Rigor (locked by requirements, restated for the planner)
- **D-10:** No training data for specs (DETL-04). Every fact traces to a source URL + fetch date in the file's Sources section (DETL-05). Ownership signals labeled with confidence level + source (OWNR-01, OWNR-05 intent).

### Claude's Discretion
- FDM article discovery strategy (WebSearch query patterns, how many attempts before declaring "no test found").
- How aggressively to use greengarage.dk (best-effort, fetch-safety unverified — probe at implementation).
- ev-database.org token-ceiling mitigation (category-specific / per-car URLs vs `max_content_tokens`).
- Exact wording of confidence labels and per-section guidance already present in `car-template.md`.
- Filename normalization for `<make-model>.md` (e.g., `volvo-ex30.md`).
- Per-project `state.md` update format when recording a researched car.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Output Contract (the file `/ev-detail` produces)
- `car-template.md` — the per-car output template; section headings + inline guidance comments. Output MUST conform. Already includes tier1/tier2 price rows, WLTP-vs-real-world range distinction, EV-platform note, tire-size rows, Sources table.

### Skill Patterns to Mirror
- `.claude/skills/ev-new-project/SKILL.md` — established skill conventions: frontmatter (`name`, `description`, `allowed-tools`, `disable-model-invocation`, `argument-hint`), `!`cat state.md`` backtick injection, `$ARGUMENTS`, step-numbered procedural body.
- `.claude/skills/ev-switch-project/SKILL.md` — active-project read/write pattern.
- `.planning/research/STACK.md` — skill structure, web-fetching strategy per data source (ev-database HIGH/WebFetch, FDM MEDIUM/WebSearch-first, greengarage LOW/best-effort), `context: fork` + Explore agent, `max_content_tokens` guidance.
- `CLAUDE.md` — project conventions, web fetching strategy by source, "What NOT to use" guardrails.

### State Contracts
- `state.md` (repo root) — global state; `active_project` field read by `/ev-detail`.
- per-project `projects/<name>/state.md` — research progress table, discovered sources, fetch reliability notes (`/ev-detail` updates this).
- `projects/<name>/BRIEF.md` — purchase type + budget + must-haves; drives variant selection (D-05) and purchase-type branching (D-07).

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — DETL-01..10, TIRE-01, OWNR-01, SRCH-07 definitions (plus deferred TIRE-02..07).
- `.planning/ROADMAP.md` — Phase 2 goal + 7 success criteria (⚠ SC#4 tire pricing needs update per D-02).
- `.planning/phases/01-foundation/01-CONTEXT.md` — Phase 1 decisions D-01..D-11 (BRIEF schema, two-level state model, template philosophy).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `car-template.md`: the exact output structure `/ev-detail` must fill — no need to design fields, just populate.
- Phase 1 skills (`ev-new-project`, `ev-switch-project`): copy their frontmatter + backtick-injection + `$ARGUMENTS` idiom for `/ev-detail`.
- Per-project `state.md` already has a "Research Progress" table and "Discovered Sources" / "Source Reliability Notes" sections ready for `/ev-detail` to append to.

### Established Patterns
- Skills live in `.claude/skills/<name>/SKILL.md` (NOT `.claude/commands/` despite some CLAUDE.md prose — actual shipped location is `.claude/skills/`).
- Active project resolved via `!`cat state.md`` injection at invocation; no hardcoded project paths.
- Two-level state: global `state.md` (active project) + per-project `state.md` (research progress).

### Integration Points
- `/ev-detail` reads global `state.md` → active project → writes `projects/<active>/research/<make-model>.md` and updates `projects/<active>/state.md`.
- Output feeds Phase 3 `/ev-compare` (reads all `research/*.md`) — file structure must stay machine-readable per `car-template.md`.

</code_context>

<specifics>
## Specific Ideas

- Variant tie-breaker rationale (D-06): user observation that 3-variant model lineups historically have the middle trim as best value-for-money — encode "prefer middle tier" as the disambiguation default when BRIEF match is ambiguous.
- Used/leasing pricing as market **ranges** (D-08), explicitly to avoid stale single-listing data — keeps the file useful over time.

</specifics>

<deferred>
## Deferred Ideas

- **Tire pricing + tire-research prompt (TIRE-02, TIRE-03)** — deferred out of Phase 2 per D-01/D-02. Belongs with the tire-sources work.
- **Global `/ev-tire-sources` skill + median-of-histogram scoring + top-3 recommendations (TIRE-04..07)** — its own future phase. `/ev-detail` will later call into it to populate the Tire Research section.
- **⚠ ROADMAP reconciliation needed:** Phase 2 ROADMAP Success Criterion #4 ("Tire size ... and current pricing for a quality all-season set are captured") and the Phase 2 requirements line (TIRE-02, TIRE-03) overstate Phase 2's tire scope after these decisions. Update ROADMAP/REQUIREMENTS traceability to move TIRE-02..07 to a dedicated tire phase before marking Phase 2 verified.

</deferred>

---

*Phase: 02-detail-skill*
*Context gathered: 2026-06-22*
