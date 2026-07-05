# Requirements: Car Research Skills

**Defined:** 2026-03-22
**Core Value:** Quickly go from "what EVs match my criteria?" to informed, comparable research files

## Requirements

### Search & Discovery

- [ ] **SRCH-01**: Skills read search parameters from the active project's `brief.md` (budget, range, body type, seats, requirements, exclusions)
- [x] **SRCH-02**: Search skill queries ev-database.org and returns matching models with key specs
- [x] **SRCH-03**: Search results include DKK price, range, battery capacity, and body type per model
- [ ] **SRCH-04**: Search criteria schema supports per-brand budget overrides (e.g., a higher ceiling for one brand where the user has a discount arrangement)
- [ ] **SRCH-05**: Search criteria schema supports a must-have features list (e.g., wireless Android Auto) that filters results
- [ ] **SRCH-06**: Search criteria schema includes a `purchase_type` field with values: `new`, `used`, or `leasing` — defaults to `new` if omitted
- [x] **SRCH-07**: Purchase type influences which data sources and price fields are relevant (e.g., `used` triggers Bilbasen price lookup; `leasing` captures monthly payment and residual)

### Detail & Specs

- [x] **DETL-01**: Detail skill fetches deep specs from ev-database.org for a named car model
- [x] **DETL-02**: Per-car markdown file written to the active project's `research/<make-model>.md` with standardized sections
- [x] **DETL-03**: Per-car file includes WLTP range, charging specs (AC/DC kW, 10-80% time), battery capacity, performance, dimensions, cargo volume, DKK price
- [x] **DETL-04**: All data fetched live at runtime — no training data used for specs
- [x] **DETL-05**: Every fact in per-car file cites source URL and fetch date
- [x] **DETL-06**: FDM real-world Danish range at 110 km/h extracted from FDM test articles (when available)
- [x] **DETL-07**: FDM qualitative verdict and pros/cons captured (when available)
- [x] **DETL-08**: Skill handles missing FDM article gracefully (notes "no FDM test found")
- [x] **DETL-09**: Per-car file includes tier 1 ("from price") and tier 2 equipment package DKK prices — tier 2 is typically the best price-to-value ratio
- [x] **DETL-10**: Per-car file notes whether the car is built on a dedicated EV platform or an adapted ICE platform

### Comparison

- [x] **COMP-01**: Comparison skill reads all of the active project's `research/*.md` files and generates side-by-side table
- [x] **COMP-02**: Comparison table labels range methodology per column (WLTP vs FDM real-world)
- [x] **COMP-03**: Comparison output written to the active project's `comparison.md`

### Danish Market

- [ ] **DKMK-01**: Per-car file includes Danish registration tax note with 2026 BEV rate and deduction
- [ ] **DKMK-02**: Per-car file flags power output >150 kW as likely higher insurance tier

### Tires

- [x] **TIRE-01**: Per-car file captures tire size measurements (front and rear if different)
- [ ] **TIRE-02**: Per-car file includes current pricing for a set of quality helarsdaek (Michelin/Goodyear tier)
- [ ] **TIRE-03**: Tire research prompt template included in repo — finds data-driven tire testers, evaluates year-round performance balance (not winter-biased or summer-biased), checks ratings and pricing for the car's tire size
- [ ] **TIRE-04**: A global "tire sources" skill (`/ev-tire-sources`) identifies and maintains a list of 5+ trustworthy tire testers/reviewers (e.g., ADAC, TCS, AutoBild, etc.) — stored in a shared `tire-sources.md` file at repo root (not per-project)
- [ ] **TIRE-05**: Tire scoring uses a median-of-histogram approach — for each tire model, collect ratings from all available sources, treat the collection as a histogram, and use the median as the representative score (the most typical value, resistant to outlier reviews)
- [ ] **TIRE-06**: The tire sources list is designed for expansion — adding a new source means adding an entry to `tire-sources.md` with URL pattern and extraction hints; existing tire scores automatically incorporate the new source on next research run
- [ ] **TIRE-07**: Per-car tire research recommends top 3 all-season tires for the car's tire size, each with median score, price, and sources consulted

### Ownership Quality

- [x] **OWNR-01**: Per-car file includes reliability reputation from FDM review narrative
- [ ] **OWNR-02**: Per-car file includes DK workshop/service availability note
- [ ] **OWNR-03**: Per-car file includes brand-level reliability signals from Bilbasen used market data
- [ ] **OWNR-04**: Per-car file includes known issues or common complaints
- [ ] **OWNR-05**: Ownership signals explicitly labeled with confidence level and source
- [ ] **OWNR-06**: Brand research captures quality track record for the past 10 years — recent history only, not legacy reputation from decades ago

### Project Management

- [ ] **PROJ-01**: `/ev-new-project "<name>"` creates `projects/<name>/` with `brief.md` (from template schema), empty `research/` subfolder, and placeholder `comparison.md`
- [ ] **PROJ-02**: `/ev-switch-project "<name>"` sets active project context; subsequent skill invocations operate within that project's folder
- [ ] **PROJ-03**: Each project is a self-contained silo — skills never read or compare across project boundaries
- [ ] **PROJ-04**: Active project context persists across skill invocations within a session (no need to re-switch)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full TCO calculator | Electricity cost, tax, insurance vary too much per individual — false precision |
| Green owner tax (groen ejerafgift) | All matching cars fall in the same bracket — no differentiation value |
| Depreciation predictions | EV depreciation is volatile and speculative |
| Non-EV powertrains | EVs only |
| Dealer/inventory search | Research tool, not purchase tool |
| Mobile app or web UI | Claude Code is the interface |
| Real-time price tracking | Beyond skill scope; price captured at research time with timestamp |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SRCH-01 | Phase 1 | Pending |
| DETL-01 | Phase 2 | Complete |
| DETL-02 | Phase 2 | Complete |
| DETL-03 | Phase 2 | Complete |
| DETL-04 | Phase 2 | Complete |
| DETL-05 | Phase 2 | Complete |
| DETL-06 | Phase 2 | Complete |
| DETL-07 | Phase 2 | Complete |
| DETL-08 | Phase 2 | Complete |
| TIRE-01 | Phase 2 | Complete |
| TIRE-02 | Phase 5 | Pending |
| TIRE-03 | Phase 5 | Pending |
| OWNR-01 | Phase 2 | Complete |
| SRCH-02 | Phase 3 | Complete |
| SRCH-03 | Phase 3 | Complete |
| COMP-01 | Phase 3 | Complete |
| COMP-02 | Phase 3 | Complete |
| COMP-03 | Phase 3 | Complete |
| DKMK-01 | Phase 4 | Pending |
| DKMK-02 | Phase 4 | Pending |
| OWNR-02 | Phase 4 | Pending |
| OWNR-03 | Phase 4 | Pending |
| OWNR-04 | Phase 4 | Pending |
| OWNR-05 | Phase 4 | Pending |
| PROJ-01 | Phase 1 | Pending |
| PROJ-02 | Phase 1 | Pending |
| PROJ-03 | Phase 1 | Pending |
| PROJ-04 | Phase 1 | Pending |
| SRCH-04 | Phase 1 | Pending |
| SRCH-05 | Phase 1 | Pending |
| SRCH-06 | Phase 1 | Pending |
| SRCH-07 | Phase 2 | Complete |
| DETL-09 | Phase 2 | Complete |
| DETL-10 | Phase 2 | Complete |
| OWNR-06 | Phase 4 | Pending |
| TIRE-04 | Phase 5 | Pending |
| TIRE-05 | Phase 5 | Pending |
| TIRE-06 | Phase 5 | Pending |
| TIRE-07 | Phase 5 | Pending |

**Coverage:**

- Requirements: 39 total
- Mapped to phases: 39
- Unmapped: 0

---
*Requirements defined: 2026-03-22*
*Last updated: 2026-03-25 — added TIRE-04..07 (tire sources skill, median-of-histogram scoring, expandable pool, top-3 recommendations) and SRCH-06..07 (purchase type field)*
