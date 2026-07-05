# Feature Research

**Domain:** EV research and comparison skill suite (Claude Code)
**Researched:** 2026-03-22
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features any EV research tool must have to feel useful. Missing these = the skill does not replace manual browsing.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Search/filter by criteria | Without this the user still has to browse; this is the whole point of not doing it manually | LOW | Read from `car_search.md`: budget, range, body type, seats, etc. |
| Real WLTP range (not manufacturer claim) | EV buyers know WLTP overstates; they expect corrected or measured range | LOW | ev-database.org provides real-world estimates |
| Real-world range at motorway speed | City range vs 110 km/h range differ dramatically; both needed | MEDIUM | FDM measures at 110 km/h — fetch from test articles |
| Charging specs (AC/DC kW, 10-80% time) | Charging speed determines road-trip usability | LOW | ev-database.org provides this |
| Battery capacity (usable kWh) | Buyers compare usable, not gross, capacity | LOW | Available on ev-database.org per car |
| Performance specs (0-100, top speed) | Table-stakes data field; buyers always check | LOW | ev-database.org |
| Price in DKK | Danish market context; EUR prices are not useful | LOW | ev-database.org has DK pricing |
| Physical dimensions and cargo volume | Practicality check; replaces a small city car segment | LOW | ev-database.org includes cargo and dimensions |
| Per-car markdown output file | Without a persistent output the skill is a dead-end; feeds comparison | LOW | Write to `research/<make-model>.md` |
| Side-by-side comparison table | The end product — this is what replaces a spreadsheet | MEDIUM | Read from existing per-car files, generate table |

### Differentiators (Competitive Advantage)

Features that make this skill suite better than opening four browser tabs manually.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| FDM review integration | Danish real-world tests on Danish roads at Danish motorway speed — far more relevant than generic European tests | MEDIUM | WebFetch FDM test articles; match by model name; extract range at 110 km/h and qualitative verdict |
| Ownership quality signals | Experience with the user's current car taught that reliability and parts cost can dominate TCO; no generic tool surfaces this | HIGH | Requires cross-referencing brand reputation, DK workshop availability, known issues; partially from FDM/greengarage, partially LLM knowledge |
| Insurance note by power output | Danish insurance varies significantly with kW; easy to miss when comparing | LOW | Note power output + flag if >150 kW as likely higher insurance tier |
| Danish registration tax note | Registreringsafgift is 40% in 2026 with a DKK 161,300 BEV deduction; affects sticker vs real cost | MEDIUM | Not a full calculator (out of scope), but a per-car note on approximate tax band and deduction applicability |
| Green owner tax (groen ejerafgift) note | Annual running cost that differs by vehicle weight/efficiency; worth capturing | LOW | Note approximate band; exact figure from Motorstyrelsen |
| Structured criteria file (`car_search.md`) | User maintains their own search parameters; skills stay generic and reusable for next car purchase | LOW | Skills read from file, not hardcoded |
| Living tool pattern | New model released? Run the search skill again. Generic skills mean no rework | LOW | Skill design: no hardcoded car names |
| Freshness enforcement | Training data is stale; skills must fetch live data | LOW | Design constraint: all data fetched at runtime, never from Claude training |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full TCO calculator | Feels rigorous; buyers want a "total number" | Electricity cost, tax, and insurance vary too much per individual to be accurate; false precision is worse than a note | Note the variables that differ per-user (home charging tariff, annual km); let user apply their own numbers |
| Depreciation predictions | Buyers want to know resale value | EV depreciation is volatile and market-dependent; any number is speculation | Note general segment depreciation reputation (e.g. "early EVs depreciated heavily; Chinese brands uncertain") as a qualitative signal |
| Dealer inventory / stock search | "Can I buy it now?" feels useful | This is a research tool, not a purchase tool; inventory changes hourly and requires dealer API access | Out of scope by design — point user to brand website or mobile.de/bilbasen |
| Real-time price tracking | Users want to know if prices change | Requires persistent storage, webhooks, or polling; far beyond a Claude Code skill | Capture price at research time with a timestamp in the per-car file |
| Non-EV powertrains (PHEV, HEV, ICE) | User might want to compare all options | Broadens scope significantly; project is explicitly EV-only | Stated out of scope in PROJECT.md |
| Mobile app or web UI | "Make it a website" | Adds build/deploy/maintenance overhead for no research value | Claude Code is the interface — that is a feature, not a limitation |
| Automatic re-research on schedule | Keep data fresh automatically | Cron jobs and background tasks are not a Claude Code skill pattern | User runs skills on demand when they want fresh data |

## Feature Dependencies

```
[car_search.md parameter file]
    └──required by──> [Search skill] (cannot filter without criteria)
                          └──produces──> [Per-car files in research/]
                                            └──required by──> [Comparison skill]

[Per-car files]
    └──enhanced by──> [Detail skill] (enriches with FDM review + ownership signals)

[FDM review fetch]
    └──enhances──> [Per-car files] (adds real-world DK range, verdict)

[Ownership quality signals]
    └──enhances──> [Per-car files] (adds reliability note, insurance flag)

[Danish market context]
    └──enhances──> [Per-car files] (adds tax note, green owner tax band)
```

### Dependency Notes

- **Search skill requires car_search.md:** Skills must read criteria from file; without the file there is nothing to filter against.
- **Comparison skill requires per-car files:** The comparison table is generated from existing research files — at least two must exist before comparison is meaningful.
- **Detail skill enhances per-car files:** The detail skill can be run after the search skill to enrich an existing file, or as part of the same flow. It is not a hard blocker for the comparison, but comparison output is richer when detail data is present.
- **FDM review fetch is best-effort:** Not every car has an FDM test. The skill must handle gracefully when no FDM article is found.
- **Danish market context is additive:** Registration tax note and green owner tax note enhance the per-car file but do not block the core search/compare flow.

## MVP Definition

### Launch With (v1)

Minimum viable product that validates the concept and replaces manual browsing.

- [ ] `car_search.md` parameter file with documented schema — without this nothing is parameterized
- [ ] Search skill: reads `car_search.md`, queries ev-database.org, returns matching models with key specs
- [ ] Detail skill: fetches deep specs from ev-database.org + FDM review if available; writes `research/<make-model>.md`
- [ ] Per-car file format: standardized markdown with range, charging, price, specs, ownership note, FDM verdict
- [ ] Comparison skill: reads existing per-car files, outputs side-by-side table

### Add After Validation (v1.x)

- [ ] Danish registration tax note per car — add once core files are working; confirm tax band logic is correct
- [ ] Green owner tax note — simple lookup once per-car files are validated
- [ ] Insurance power output flag — quick annotation; add when detail skill is stable

### Future Consideration (v2+)

- [ ] Ownership quality signals beyond FDM — would need additional sources (J.D. Power, Bilbasen used market data); high complexity, validate need first
- [ ] Greengarage.dk integration — used/demo market; only relevant if user pivots to used EV purchase

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| car_search.md schema | HIGH | LOW | P1 |
| Search skill (ev-database.org) | HIGH | MEDIUM | P1 |
| Detail skill (ev-database.org + FDM) | HIGH | MEDIUM | P1 |
| Per-car markdown file output | HIGH | LOW | P1 |
| Comparison table generation | HIGH | LOW | P1 |
| FDM review integration | HIGH | MEDIUM | P1 |
| Ownership quality signals | HIGH | HIGH | P2 |
| Danish tax note | MEDIUM | LOW | P2 |
| Green owner tax note | MEDIUM | LOW | P2 |
| Insurance power flag | MEDIUM | LOW | P2 |
| Full TCO calculator | LOW | HIGH | P3 (anti-feature) |
| Depreciation predictions | LOW | HIGH | P3 (anti-feature) |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have or explicitly avoided

## Competitor Feature Analysis

These are the manual sites the skill suite replaces. The "Our Approach" column describes what the skill adds on top of or instead of each.

| Feature | ev-database.org | fdm.dk | greengarage.dk | Our Approach |
|---------|-----------------|--------|----------------|--------------|
| Specs/range data | Comprehensive; real-world estimates | Limited; focus on test narrative | Minimal; marketplace focus | Fetch from ev-database.org programmatically |
| Real-world DK range at 110 km/h | No (WLTP only) | Yes — measured in tests | No | Extract from FDM test articles |
| Danish pricing | Yes (DK locale) | Mentioned in tests | Yes (used market) | Pull from ev-database.org DK |
| Charging specs | Yes | Sometimes in test | No | Pull from ev-database.org |
| Ownership/reliability | No | Qualitative in some tests | No | Synthesize from FDM + LLM knowledge; flag confidence |
| Registration tax | No | Mentioned occasionally | No | Add as per-car note with 2026 rate |
| Side-by-side comparison | Yes (interactive UI) | No | No | Generate markdown table from per-car files |
| Filterable search | Yes (web UI) | No | Partial (marketplace filters) | Skill reads criteria from car_search.md |
| Structured persistent output | No | No | No | Per-car markdown files in `research/` — unique to this tool |

## Sources

- ev-database.org — live site inspection, feature inventory
- [FDM test overview](https://fdm.dk/guides/elbil/test-af-elbiler-komplet-oversigt) — confirmed test methodology and data fields
- [FDM budget EV test](https://fdm.dk/tests/biltest/test-af-fire-elbiler-til-200000-kroner) — confirmed FDM data categories
- [Motorstyrelsen registration tax](https://motorst.dk/en-us/individuals/vehicle-taxes/registration-tax/registration-tax-and-rates) — DK tax rules confirmed
- [eCarsTrade DK tax 2026](https://ecarstrade.com/blog/car-taxes-denmark) — 40% rate for BEVs in 2026, DKK 161,300 deduction
- [Insurify EV insurance data](https://insurify.com/car-insurance/report/electric-vehicle-insurance-costs/) — insurance cost variation by power output confirmed
- [InsideEVs comparison tool](https://insideevs.com/reviews/344001/compare-evs/) — feature inventory of a peer comparison tool

---
*Feature research for: EV research and comparison skill suite (Claude Code, Danish market)*
*Researched: 2026-03-22*
