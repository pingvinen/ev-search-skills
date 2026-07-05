# Project Research Summary

**Project:** EV Research Skill Suite (Danish Market)
**Domain:** Claude Code skill suite for automated EV web research and comparison
**Researched:** 2026-03-22
**Confidence:** HIGH

## Executive Summary

This project is a Claude Code skill suite — not a traditional software application. There is no runtime, no build step, no package.json. The "product" is three markdown-defined skills (`ev-search`, `ev-detail`, `ev-compare`) that teach Claude to fetch, parse, and compare EV specifications from Danish and European sources. The recommended approach is to build the smallest possible working system first: a parameter file (`car_search.md`), an output template, and a single detail-fetching skill. Everything else derives from having real per-car research files to work with.

The three data sources differ significantly in fetch reliability. ev-database.org is server-rendered and directly fetchable via WebFetch — it is the primary spec source. fdm.dk serves Danish real-world test data (measured range at 110 km/h on Danish roads) but its listing index requires WebSearch discovery before article-level WebFetch can work. greengarage.dk is a supplementary source useful for ownership signals on selected models. The critical design decision is to never hardcode URLs, always use search-then-fetch discovery patterns, and clearly label all data by source and methodology to prevent WLTP figures from contaminating comparisons with real-world figures.

The main risks are architectural overreach and data integrity. Overengineering (adding databases, caching, JSON schemas, complex pipelines) is the dominant failure mode for personal Claude Code tools — the markdown files in `research/` are the database. Data integrity risks are more subtle: Claude will silently fill gaps from training data when fetches return empty content, WLTP and real-world range figures are easy to mix in comparison tables, and Danish registration tax rates change annually. All three are preventable by establishing a strict per-car file schema with mandatory source attribution before writing any fetch logic.

---

## Key Findings

### Recommended Stack

This project uses no external dependencies beyond Claude Code's native tools. The stack is: Claude Code skills (`.claude/skills/`) for skill definition, WebFetch for server-rendered pages (ev-database.org), WebSearch for discovering article URLs on JavaScript-heavy sites (fdm.dk), Bash/curl as a fallback for bot-blocked URLs, and plain markdown files for all input and output.

The one meaningful version consideration is that `web_fetch_20260209` (current) supports dynamic content filtering via `max_content_tokens` — this is important for ev-database.org's large listing pages, which can otherwise consume 25,000+ tokens per fetch. The skill format at `.claude/skills/<name>/SKILL.md` is preferred over `.claude/commands/` because it supports bundled supporting files (templates, site patterns).

**Core technologies:**
- Claude Code skills: skill invocation and orchestration — native to environment, zero external dependencies
- WebFetch (`web_fetch_20260209`): direct page fetching — handles HTML-to-text natively, supports content filtering
- WebSearch: URL discovery for JS-heavy sites — bypasses SPA listing pages by querying Google's index of server-rendered articles
- Markdown files: input (`car_search.md`) and output (`research/*.md`) — diffs cleanly, natively readable in Claude context, zero schema overhead
- Bash/curl: fallback fetching — available if WebFetch is bot-blocked on a source

### Expected Features

The feature dependency chain is: `car_search.md` (criteria) enables the search skill, which produces candidate model names, which enables the detail skill, which produces per-car research files, which enables the comparison skill. Nothing works until the per-car file schema and template are defined — they are the contract the entire system depends on.

**Must have (table stakes):**
- `car_search.md` parameter file with documented schema — the entry point for all skill parameterization
- Search skill (ev-database.org) — reads criteria, returns matching models with key specs
- Detail skill (ev-database.org + FDM) — fetches deep specs and Danish real-world test data, writes per-car file
- Per-car markdown output with standardized sections — feeds the comparison skill
- Comparison table generation from existing per-car files — the final deliverable

**Should have (differentiators):**
- FDM review integration — real-world Danish range at 110 km/h, not just WLTP
- Danish registration tax note per car — 2026 rate with fetch date and source URL
- Green owner tax (groen ejerafgift) note — annual running cost signal
- Insurance power output flag — flags >150 kW as likely higher insurance tier
- Ownership quality signals — reliability reputation, DK workshop availability

**Defer (v2+):**
- greengarage.dk integration — relevant only if user pivots to used EV purchase
- Ownership quality signals beyond FDM — requires additional sources (J.D. Power, Bilbasen used market)
- Full TCO calculator — false precision; individual variables (home charging tariff, annual km) make any number misleading

### Architecture Approach

The system follows a strict three-layer design: an input layer (`car_search.md`), a skill layer (`.claude/skills/`), and an output layer (`research/*.md` + `comparison.md`). Skills communicate exclusively through files — no shared in-memory state, no database. The per-car file is the durable handoff between skills. An `ev-sources` background skill holds site-specific fetch patterns and is auto-loaded by Claude when other EV skills are active, keeping individual skill files under the 500-line recommended ceiling.

**Major components:**
1. `car_search.md` — single source of truth for search criteria; skills re-read it at every invocation so criteria changes take effect immediately without editing skill files
2. `ev-search` skill — discovers candidate models; runs inline (not forked) so users can ask follow-up questions in the same session
3. `ev-detail` skill — fetches one car deeply; runs with `context: fork` to isolate multi-URL fetches from main session; writes `research/[make-model].md`
4. `ev-compare` skill — reads all `research/*.md` via Glob, generates `comparison.md`; has `disable-model-invocation: true` to prevent unexpected file writes
5. `ev-sources` skill — background site knowledge (URL patterns, fetch quirks); `user-invocable: false`, auto-loaded by Claude

### Critical Pitfalls

1. **JS-rendered pages returning empty content silently** — WebFetch does not execute JavaScript; fdm.dk's listing index and greengarage.dk's homepage return useless shell HTML. Prevention: use WebSearch to discover article URLs first; probe every target URL manually before writing parsing logic around it.

2. **Training data contaminating research files** — Claude fills gaps from training knowledge when fetches return empty content; output looks complete but is unverifiable. Prevention: skill instructions must explicitly require "fail loudly on missing data — do not supplement with prior knowledge"; every fact in a per-car file must cite a URL and fetch date.

3. **Mixing WLTP and real-world range without labeling** — ev-database.org provides WLTP; FDM provides real-world Danish measurements; unlabeled mixing makes comparisons meaningless. Prevention: per-car file template must enforce labeled range fields (`Range (WLTP): X km`, `Range (FDM real-world): Y km`) before any car is researched.

4. **Skill character budget overflow** — each Claude Code skill consumes approximately 109 chars of XML overhead plus description text; the 16,000-char default budget supports roughly 5-7 skills before silent truncation drops skills. Prevention: cap at 5 skills; keep descriptions under 200 chars each; merge utility functions into existing skills as subcommand arguments.

5. **Overengineering for a personal tool** — production patterns (caching, databases, JSON schemas, migrations) balloon build time while real research stalls. Prevention: enforce that each phase must deliver at least one working research file before any infrastructure work proceeds; the `research/` markdown files are the database.

---

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation and Data Contract

**Rationale:** The per-car file template is the schema contract the entire system depends on. `ev-compare` cannot work without it, and training data contamination is impossible to prevent retroactively once files exist without source attribution. The architecture research explicitly identifies this as the correct build order: foundation before any car-specific work. All seven critical pitfalls are seeded in Phase 1 — getting the schema and source-probing patterns right here prevents costly retrofitting.

**Delivers:**
- `car_search.md` with documented criteria schema
- `car-template.md` with labeled fields for range (WLTP and real-world), charging, price, ownership, Danish tax — including mandatory `Sources:` section
- `ev-sources` skill with site fetch patterns and URL discovery logic for ev-database.org, fdm.dk, and greengarage.dk
- Manual probe of each target URL confirming fetch-safe status and data availability

**Addresses:** `car_search.md` parameter file (P1), per-car file format (P1)

**Avoids:** Training data contamination (Pitfall 7), WLTP/real-world mixing (Pitfall 3), hardcoded URL breakage (Pitfall 2)

---

### Phase 2: Core Detail Skill (Highest Value)

**Rationale:** The architecture research is explicit: `ev-detail` is the highest-value skill and should be built and validated first. It produces the research files that make everything else testable. The comparison skill cannot be meaningfully tested without real per-car files. The search skill is a convenience — users can supply model names manually to bootstrap. Phase 2 focuses on making one car's research file excellent before scaling.

**Delivers:**
- `ev-detail` skill: fetches ev-database.org specs + FDM review article (via WebSearch discovery) for a named car
- Writes `research/[make-model].md` using `car-template.md`
- Validated on 2-3 real cars (e.g., Volvo EX30, Skoda Enyaq) with all required fields populated and sourced
- Danish registration tax note fetched live from Motorstyrelsen (not hardcoded)

**Uses:** WebFetch (ev-database.org), WebSearch + WebFetch (fdm.dk), `context: fork` for isolated multi-URL fetching

**Implements:** ev-detail skill, car-template.md output contract

**Avoids:** Danish tax staleness (Pitfall 5), overengineering (Pitfall 6)

---

### Phase 3: Comparison and Search Skills

**Rationale:** With real per-car files existing from Phase 2, both the comparison and search skills can be built against real data. The comparison skill is primarily a reader — low implementation risk once the per-car file schema is stable. The search skill is a discovery convenience; it can be tested against the same sources already validated in Phase 2.

**Delivers:**
- `ev-compare` skill: reads all `research/*.md` via Glob, generates `comparison.md` with consistent columns; `disable-model-invocation: true` to prevent unexpected file writes
- `ev-search` skill: reads `car_search.md` criteria, searches ev-database.org, returns matching model list for user review; runs inline (not forked)
- Validated comparison table for 3+ cars with labeled range methodology per cell

**Implements:** ev-compare skill, ev-search skill, full Search → Detail → Compare workflow

**Avoids:** Skill character budget overflow (Pitfall 4 — cap confirmed at 5 skills: ev-sources, ev-search, ev-detail, ev-compare + one spare)

---

### Phase 4: Danish Market Enrichment

**Rationale:** These features add significant value for Danish buyers but do not block the core research workflow. They are additive enhancements to per-car files that can be layered in once the base skill suite is stable. The green owner tax and insurance power flag are low-complexity annotations; ownership quality signals beyond FDM are higher-complexity and may not be needed if FDM data proves sufficient.

**Delivers:**
- Green owner tax (groen ejerafgift) note added to car template and populated by `ev-detail`
- Insurance power output flag (>150 kW tier annotation) added to `ev-detail`
- Ownership quality signals beyond FDM if warranted (Bilbasen used market reputation, brand-level reliability notes with explicit confidence labeling)

**Addresses:** Danish market context features (P2 features from FEATURES.md)

---

### Phase Ordering Rationale

- **Schema before data:** The per-car template defines the contract `ev-compare` depends on. Any research files created before the schema is finalized will need retroactive editing. This is why Phase 1 produces zero car research files — it only produces the infrastructure for doing so correctly.
- **Detail before search:** `ev-detail` produces the artifacts that make every other skill testable. `ev-search` is a convenience; the user can supply model names manually. Building detail first validates that the data sources actually provide the required fields.
- **Compare after detail:** The comparison skill is pure derivation from existing files. It cannot be meaningfully tested without at least two complete per-car files.
- **Danish enrichment last:** Registration tax, green owner tax, and insurance flags add value but do not affect the core research decision. They are additive annotations, not structural requirements.

### Research Flags

Phases with well-documented patterns (no deeper research needed):
- **Phase 1 (Foundation):** Claude Code skill format, file structure, and template patterns are fully documented and verified. No research-phase needed.
- **Phase 2 (Detail Skill):** ev-database.org URL patterns and FDM WebSearch-then-WebFetch pattern are verified by live probing. Standard implementation.
- **Phase 3 (Compare/Search):** Glob-based file reading and comparison table generation are standard Claude Code patterns.

Phases that may benefit from targeted research during planning:
- **Phase 4 (Danish Enrichment):** Ownership quality signal sourcing is flagged HIGH complexity in FEATURES.md. If Bilbasen or J.D. Power data is needed, a targeted research-phase on those sources is warranted before implementation.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official Claude Code skills docs verified by live fetch; ev-database.org URL patterns confirmed by live probe; WebFetch JS limitation confirmed by official Anthropic API docs |
| Features | HIGH | Live site inspection of ev-database.org and fdm.dk confirmed data field availability; FDM budget test and EV overview pages verified; Danish tax rules confirmed from Motorstyrelsen and eCarsTrade |
| Architecture | HIGH | Official Claude Code skills documentation verified; `context: fork`, `disable-model-invocation`, `user-invocable: false` patterns confirmed; component boundaries validated against agentskills.io standard |
| Pitfalls | HIGH | WebFetch JS limitation confirmed from official docs and live site probing; skill character budget figures sourced from Claude Code skills documentation; WLTP vs real-world gap documented from multiple sources |

**Overall confidence:** HIGH

### Gaps to Address

- **greengarage.dk editorial content availability:** The homepage uses AutoUncle JS widget and is not fetch-safe. The `/artikler` section may have SSR-rendered editorial content, but individual article fetch-safety was not verified by live probe. Treat greengarage.dk as best-effort supplementary in Phase 2; probe at implementation time before committing to it as a source.

- **ev-database.org listing page token cost:** The main listing page is confirmed large (potentially 25,000+ tokens). The `max_content_tokens` filtering approach is documented but the optimal filter parameters for extracting candidate models without overflow were not empirically tested. The search skill (Phase 3) should use category-specific URLs (e.g., `/uk/cat/range/Small-Car`) rather than the full listing as a fallback strategy.

- **Ownership quality signals sourcing:** This is flagged P2 in FEATURES.md and HIGH complexity. There is no confirmed source for systematic Danish-market reliability data beyond qualitative FDM review notes. This gap should be explicitly stated in per-car files ("ownership signals sourced from FDM review narrative — limited sample") rather than treated as authoritative data.

---

## Sources

### Primary (HIGH confidence)
- `https://code.claude.com/docs/en/slash-commands` — skills format, frontmatter fields, `$ARGUMENTS`, `context: fork`, `allowed-tools`
- `https://platform.claude.com/docs/en/docs/agents-and-tools/tool-use/web-fetch-tool` — WebFetch JavaScript limitation, `max_content_tokens`, URL validation
- `https://ev-database.org/` — verified server-rendered HTML, permissive robots.txt, URL pattern `/uk/car/{ID}/{Make-Model}`
- `https://fdm.dk/tests/biltest/test-flot-comeback-nu-er-volvo-ex30-endelig-voksen` — verified free article access, data fields available (WLTP/measured range, charging, pros/cons, DKK pricing)
- `https://fdm.dk/tests/biltest` — verified Nuxt.js SPA listing; individual article pages fetch-safe
- `https://motorst.dk/en-us/individuals/vehicle-taxes/registration-tax/registration-tax-and-rates` — Danish registration tax rules
- `https://greengarage.dk/sitemap.xml` — content categories confirmed (inventory, guides, model-specific pages)
- `https://code.claude.com/docs/en/skills` — skill architecture and character budget limits

### Secondary (MEDIUM confidence)
- `https://ecarstrade.com/blog/car-taxes-denmark` — 40% BEV rate for 2026, DKK 161,300 deduction
- `https://mikhail.io/2025/10/claude-code-web-tools/` — WebFetch redirect behavior, content truncation patterns
- `https://www.browserless.io/blog/state-of-web-scraping-2026` — 10-15% weekly scraper breakage rates
- FDM test overview and budget EV test pages — confirmed FDM data fields and methodology

### Tertiary (LOW confidence)
- `https://medium.com/@cheparsky/ai-in-testing-9-the-invisible-limitations-of-claude-code-skills-you-didnt-know-f3adbdcf3680` — skill character budget overflow behavior (third-party, unverified against official docs)
- `https://www.firecrawl.dev/blog/claude-code-skill` — Firecrawl as fallback for bot-blocked sites (third-party blog; pattern is reasonable but not tested against ev-database.org)

---
*Research completed: 2026-03-22*
*Ready for roadmap: yes*
