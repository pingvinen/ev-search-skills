# Car Research Skills

## What This Is

A suite of Claude Code skills local to this repo that help research and compare electric vehicles. The skills read search parameters from `car_search.md`, fetch data from known EV sites (ev-database.org, FDM, greengarage.dk), and produce per-car research files and comparison tables. A living tool that stays useful as new models release. The suite supports multiple named search projects, each in its own `projects/<name>/` folder, so different searches (family car, commuter, etc.) stay isolated.

## Core Value

Quickly go from "what EVs match my criteria?" to informed, comparable research files — without manually trawling multiple sites.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Skills read search parameters from the active project's `brief.md` (budget, range, body type, etc.)
- [ ] Search skill queries known EV sites and returns matching models
- [ ] Detail skill fetches deep specs, reviews, and ownership signals for a given car
- [ ] Per-car markdown files generated in the active project's `research/` directory (e.g. `projects/family-ev/research/volvo-ex30.md`)
- [ ] Comparison skill generates side-by-side table from the active project's per-car files
- [ ] Ownership quality signals captured: reliability reputation, parts cost, brand quality, insurance notes
- [ ] Danish market context: registration tax check, green owner tax, DK-specific pricing
- [ ] Skills persist research state (discovered sources, rejected sources, fetch reliability notes) to a dedicated research state file — separate from GSD's STATE.md — so future sessions and agents can build on prior work without rediscovering context
- [ ] `/ev-new-project "<name>"` scaffolds a project folder at `projects/<name>/` with `brief.md` (from template), empty `research/` subfolder, and empty `comparison.md`
- [ ] `/ev-switch-project "<name>"` sets the active project context so all other skills operate within that project
- [ ] Each project is a self-contained silo — no cross-project comparison
- [ ] Search criteria support per-brand budget overrides (e.g., higher ceiling for BMW)
- [ ] Search criteria support a must-have features list (e.g., wireless Android Auto)
- [ ] Per-car file includes tier 1 and tier 2 equipment package DKK prices
- [ ] Per-car file notes whether the car is on a dedicated EV platform or adapted ICE platform
- [ ] Brand research covers quality track record for the past 10 years only
- [ ] Tire research uses a global tire sources skill that identifies 5+ trustworthy tire testers and scores tires using median-of-histogram methodology (median = most typical value across sources)
- [ ] The tire sources pool is expandable — adding a new source does not require restructuring existing scores
- [ ] Per-car files recommend top 3 all-season tires with median scores and pricing for the car's tire size
- [ ] Search criteria include a purchase type field (`new`, `used`, `leasing`) that influences data sources and price fields
- [ ] Purchase type integrates with multi-project architecture — each project's `brief.md` specifies its own purchase type

### Out of Scope

- Precise TCO calculator — electricity cost, green owner tax, and registration tax are roughly equal across small EVs; not worth building a full model
- Depreciation predictions — too speculative to be useful
- Non-EV powertrains — EVs only
- Dealer/inventory search — this is research, not purchase
- Mobile app or web UI — Claude Code is the interface

## Context

- User is replacing a small city EV — specific criteria are in `car_search.md`
- Data sources: ev-database.org (specs/range), FDM (Danish tests/reviews/news), greengarage.dk
- Data sources are not exhaustive — the list should grow as better or more specialized sources are discovered. Skills (especially the detail skill) should accommodate additional sources without restructuring
- Ownership quality matters: past experience with the user's current car showed brand reliability/parts cost can dominate TCO
- Insurance can vary significantly with power output, worth noting per car
- This is a living research tool, not a one-time analysis — new models should be easy to add
- Skills should use whatever web access method works best per source (WebFetch, WebSearch, curl)
- Multiple search projects supported — each project gets its own folder under `projects/` with isolated search criteria, research files, and comparison output
- A per-brand budget override is supported — the budget ceiling can be higher for one brand where the user has a discount arrangement
- Wireless Android Auto is a must-have feature for the current search
- Equipment pricing matters: tier 1 ("from price") and tier 2 (best value) should both be captured per car
- EV platform origin matters: purpose-built EVs vs adapted ICE platforms have different trade-offs
- Brand quality assessment should focus on recent 10-year track record, not decades-old reputation
- Tire scoring uses median-of-histogram: collect ratings from multiple testers, use median as representative score — resistant to outlier reviews and naturally improves as more sources are added
- Global tire sources list (`tire-sources.md`) is shared across projects — tire tester quality is not project-specific
- Purchase type (new/used/leasing) is per-project — a "family EV" project might be buying new while a "commuter" project explores leasing
- For used cars, Bilbasen is the primary DK source for pricing; for leasing, monthly payment and residual value matter more than sticker price

## Constraints

- **Platform**: Claude Code skills (`.claude/commands/` local to this repo)
- **Data freshness**: Skills must fetch live data, not rely on training data
- **Input**: All search criteria come from the active project's `brief.md` — no hardcoded parameters
- **Output**: Per-car files in the active project's `research/` subfolder, comparison tables in the active project's `comparison.md`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Claude Code skills as interface | No separate app to build/maintain; leverages existing tooling | -- Pending |
| car_search.md as parameter source | User maintains their own criteria; skills stay generic | -- Pending |
| Per-car markdown files | Easy to read, diff, and version; feed into comparison | -- Pending |
| Ownership quality over precise TCO | For small EVs the hard numbers are similar; brand quality/reliability matters more | -- Pending |
| Multi-project architecture | Different searches (family car vs commuter) need separate criteria and results; a single car_search.md forces overwriting | -- Pending |
| Per-project criteria file named `brief.md` | Phase 1 implementation (01-02) named the per-project criteria file `brief.md`; supersedes the earlier `search_criteria.md`/`car_search.md` naming. Contract docs aligned to code rather than re-renaming the shipped skills | ✓ Phase 1 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-25 — added tire research methodology, expandable sources, and purchase type requirements*
