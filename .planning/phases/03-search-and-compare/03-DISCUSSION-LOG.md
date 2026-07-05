# Phase 3: Search and Compare - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-27
**Phase:** 3-search-and-compare
**Areas discussed:** Search discovery method, DKK price in results, Search output & handoff, Compare: scope & verdict

---

## Search discovery method

### Discovery mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Knowledge-seeded + live-verified | Propose candidate model names from EV knowledge, verify each live on ev-database | |
| WebSearch-driven only | Harvest ev-database URLs from criteria-built WebSearch queries | |
| You decide at research time | Leave tactic to researcher/planner | |
| **(emergent)** Spike cheapest-first, escalate only if needed | curl JSON/server-rendered URL → knowledge-seeded → local free headless tool last | ✓ |

**User's choice:** Spike cheapest-first, escalate only if needed.
**Notes:** User raised Firecrawl. Clarified Firecrawl *cloud* is paid — user rejected paid services for this personal-skills project ("not building a product, just useful skills for my own needs"). Explored free/local alternatives: self-hosted Firecrawl (Docker, open-source but heavy), Playwright MCP (`npx @playwright/mcp`, lighter local headless), and the cheapest zero-install option — a curl-able JSON/XHR endpoint or server-rendered filtered URL on ev-database. Landed on cheapest-first spike with paid services off the table.

### Per-candidate depth

| Option | Description | Selected |
|--------|-------------|----------|
| Shallow pass | Only the four SC#1 fields per candidate | |
| Names + key specs from search snippets | Pull specs from snippets, fetch only when needed | |
| You decide | Let research/planning choose | ✓ |

**User's choice:** You decide.
**Notes:** Depth folds into whatever the discovery spike selects; search stays shallow regardless (SC#1 fields only, not /ev-detail depth).

---

## DKK price in results

### Sourcing approach

| Option | Description | Selected |
|--------|-------------|----------|
| Estimate to filter, real DKK for shortlist | EUR→DKK estimate to rank, real price for shortlist | |
| Estimate only, confirm at /ev-detail | Labeled estimate per match | |
| You decide | Let research/planning choose | |
| **(emergent)** Price bands, no FX | Rough DK band at search; real pricing at shortlist | ✓ |

**User's choice:** No FX conversion — Danish car tax is fundamentally different, so converted figures don't work. Use an initial price segment/bucket/range at search, then real pricing (new/used/leasing) for the shortlist.
**Notes:** Replaced the FX-based options entirely with price bands.

### Price exactness

| Option | Description | Selected |
|--------|-------------|----------|
| Rough magnitude is fine | Labeled estimate just needs the right ballpark | ✓ |
| Tax-aware rough adjustment | Apply a Danish uplift for trustworthier near-budget filtering | |
| You decide | Let research determine | |

**User's choice:** Rough magnitude is fine.

### Band definition & source (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| Relative to brief budget | Bands anchored to budget (within / stretch / over) | (Claude's discretion — recommended) |
| Fixed absolute DKK bands | Static <250k/250–350k/… segments | |
| Cheap live DK-price search per candidate | One light WebSearch per candidate, bucket the snippet | ✓ |
| Market-knowledge seed, spot-verify shortlist | Band from knowledge, confirm at /ev-detail | |

**User's choice:** Band type → "You decide" (Claude recommends brief-budget-relative bands). Band source → cheap live DK-price search per candidate.

---

## Search output & handoff

### Output destination

| Option | Description | Selected |
|--------|-------------|----------|
| Chat list + ready /ev-research command | Conversation output + copy-paste handoff | (kept, plus state.md) |
| Also write an editable shortlist file | New candidates.md artifact | |
| You decide | Let planning choose | |
| **(emergent)** Persist to per-project state.md | Store candidates in state.md for presentation + initial filtering | ✓ |

**User's choice:** Use the per-project state file to store enough information to present the list and do initial filtering to decide which cars to go deep on.
**Notes:** Reuses the existing per-project state.md (new "Search Candidates" section) rather than a new file. /ev-search gains Write access. Still presents in chat with a ready /ev-research command.

### Near-misses

| Option | Description | Selected |
|--------|-------------|----------|
| Surface, flagged separately | Hard-filter on cheap fields; flag borderline with reason | ✓ |
| Strict exclude | Drop anything not fully matching | |
| You decide | Let planning choose | |

**User's choice:** Surface, flagged separately.

### Re-run behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Overwrite with a dated snapshot | Latest results replace the section, stamped | ✓ |
| Merge, preserve manual notes | Keep annotations, update/add cars | |
| You decide | Let planning choose | |

**User's choice:** Overwrite with a dated snapshot.

---

## Compare: scope & verdict

### Verdict level

| Option | Description | Selected |
|--------|-------------|----------|
| Table + best-in-class + brief verdict | Highlight winners per row + brief-aware recommendation | ✓ |
| Table + best-in-class highlighting | Highlight winners, no overall verdict | |
| Neutral table only | Pure side-by-side | |

**User's choice:** Table + best-in-class + brief verdict.

### Row scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full specs + condensed qualitative | ~15 spec rows + FDM verdict/pros-cons/ownership | ✓ |
| Specs only | Numeric rows only | |
| You decide | Let planning choose | |

**User's choice:** Full specs + condensed qualitative.
**Notes:** SC#3 (WLTP vs real-world per-column labeling) and explicit gap rendering are locked by the success criteria + car-template, not gray areas.

---

## Claude's Discretion

- Per-candidate depth (folds into the discovery spike result).
- Price band scheme/labels and boundaries (Claude recommends brief-budget-relative).
- Per-candidate DK price-band WebSearch query wording.
- Candidate ranking/sort order and comparison column order.
- "Search Candidates" section schema in state.md.
- comparison.md layout details (grouping, qualitative-row formatting, best-in-class marking).
- Whether/where to cap candidate count.

## Deferred Ideas

- Adopting a local headless tool (Playwright MCP / self-hosted Firecrawl) — only if zero-install discovery spikes prove insufficient.
- CLAUDE.md "What NOT to use" nuance update — if discovery escalates to a local headless browser for the JS filter listing (the existing ban targets server-rendered detail pages).
- Tire scoring/pricing (Phase 5) and Danish tax/insurance enrichment (Phase 4) — out of scope here.
