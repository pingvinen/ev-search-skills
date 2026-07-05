# Pitfalls Research

**Domain:** Claude Code skill suite for EV data aggregation (Danish market)
**Researched:** 2026-03-22
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: JavaScript-Rendered Pages Silently Returning Empty Content

**What goes wrong:**
WebFetch converts HTML to markdown and returns it. For JavaScript-rendered pages, that means returning the shell HTML with no actual data. The skill gets a response — it just contains loading spinners and navigation chrome instead of car specs. Claude will not error; it will attempt to parse nothing and produce hallucinated or empty output.

**Why it happens:**
WebFetch does not execute JavaScript. Developers assume "I can fetch that URL" means "I can get the data at that URL." FDM.dk uses Nuxt.js (SSR with client-side hydration), and its test listings are partially server-rendered but with content that loads asynchronously. Greengarage.dk uses a client-side AutoUncle vehicle listing system embedded via JavaScript. If the SSR hydration boundary sits around the data block, WebFetch gets nothing useful.

**How to avoid:**
Test each target URL manually with WebFetch before writing any parsing logic. Check whether the returned markdown contains real car data or just navigation/loading text. For each source, document clearly whether it is fetch-safe. Build a small "probe" step into skills that validates the response contains expected data before proceeding. FDM article pages (individual test URLs) are likely fetch-safe even if the index page is not.

**Warning signs:**
- Skill returns a result but car names or specs are absent
- Output contains phrases like "loading", "JavaScript required", or only navigation links
- Skill works sometimes but not others (race condition between SSR and JS hydration)

**Phase to address:**
Phase 1 (foundation/source probing) — verify fetchability of every target URL before building any parsing logic around it.

---

### Pitfall 2: Hardcoded URL Patterns Breaking When Sites Restructure

**What goes wrong:**
Skills contain paths like `https://ev-database.org/car/1234/volvo-ex30` — when the site renames slugs, renumbers IDs, or restructures URLs (e.g., adding a country prefix `/dk/car/...`), every skill breaks silently. The skill fetches a 404 page and attempts to parse "Page Not Found" as car data.

**Why it happens:**
It is faster to hardcode a known URL than to build a discovery step. EV database sites frequently restructure during major updates or when adding multi-country support. Industry data shows 10-15% of scrapers require weekly fixes due to DOM and endpoint changes.

**How to avoid:**
Never hardcode deep URLs. Skills should always start from a known stable entry point (the site root or a search URL) and navigate to the target programmatically. For ev-database.org, use the search/filter URL with parameters (e.g., `?make=volvo&model=ex30`) rather than a direct car URL. Use WebSearch as the discovery mechanism: `site:ev-database.org volvo ex30` is more resilient than a stored URL.

**Warning signs:**
- Skill output references a 404 or redirect page
- Car detail pages return generic content
- Skill worked last month but not today with no code changes

**Phase to address:**
Phase 1 (skill architecture) — establish the URL discovery pattern before any car-specific work begins.

---

### Pitfall 3: Mixing WLTP and Real-World Range Without Labeling

**What goes wrong:**
The comparison table shows "Range: 357 km" for one car and "Range: 280 km" for another, but the first is WLTP and the second is a real-world FDM test figure. The user makes decisions based on a comparison that is not comparing the same thing. WLTP figures run 10-40% higher than real-world in Nordic winter conditions.

**Why it happens:**
ev-database.org provides WLTP figures as the headline. FDM tests report real-world range from Danish road conditions. Greengarage.dk may list manufacturer WLTP. A skill that pulls from multiple sources without tracking provenance produces a contaminated comparison.

**How to avoid:**
Every range figure in a per-car file must be labeled with its source and methodology: `Range (WLTP): 357 km`, `Range (FDM real-world test): 218 km`, `Range (source: ev-database.org)`. The comparison table must never mix methodologies in the same column. Use a consistent primary figure (WLTP from ev-database.org) for comparison purposes, and surface real-world test data separately.

**Warning signs:**
- Research files contain a bare "Range: X km" with no source label
- Comparison table has wildly inconsistent gaps between similar cars
- Detail skill pulls range from whatever source responds first

**Phase to address:**
Phase 1 (data schema) — define the per-car file schema with labeled fields before writing any fetch logic.

---

### Pitfall 4: Claude Code Skill Character Budget Overflow

**What goes wrong:**
Adding more than 5-7 skills causes the skill metadata block to exceed the character budget (16,000 chars by default, 2% of context window). Skills added beyond the budget are silently dropped — Claude does not know they exist. The user invokes a skill that Claude cannot see and gets a "I don't have a skill for that" response, or Claude falls back to training data.

**Why it happens:**
Each skill description consumes approximately 109 characters of XML overhead plus the description text. This project plans at minimum 3 skills (search, detail, compare). Additional utility skills (refresh, validate, format) can quickly push over the limit. The budget comment `<!-- Showing 4 of 7 skills -->` is the only warning and only visible in raw system prompt inspection.

**How to avoid:**
Keep skill descriptions short and mutually exclusive. For this project, target 3-5 skills maximum. Prefer manual invocation (user types `/research:detail volvo-ex30`) over autonomous skills. Monitor the skill list periodically with a simple count. If new utility skills are needed, consider merging them into an existing skill as subcommand arguments rather than separate files.

**Warning signs:**
- Invoking a skill by name produces "I don't have that capability"
- Claude suggests doing manually what a skill is supposed to do
- Adding a new skill causes an older one to stop working

**Phase to address:**
Phase 1 (skill architecture) — establish skill count discipline before any skills are written.

---

### Pitfall 5: Danish Registration Tax Data Going Stale Mid-Research

**What goes wrong:**
The skill fetches registration tax data or hardcodes bracket values into prompts. Danish EV registration tax rules changed significantly in 2024, 2025, and again for 2026 (the increase to 48% was postponed; the DKK 161,300 deduction applies only while the freeze holds). A skill that bakes in 2025 figures and is used in 2027 produces incorrect TCO context.

**Why it happens:**
Registration tax logic is complex enough that developers simplify it to a fixed formula. The Danish tax landscape for EVs is actively in flux as subsidy phase-outs are negotiated annually in the Finance Act.

**How to avoid:**
Do not hardcode registration tax values in skill instructions. Skills should direct Claude to fetch current figures from Motorstyrelsen (motorst.dk) or elbilviden.dk at research time, not use pre-loaded constants. Alternatively, note in the per-car file that tax figures were sourced on a specific date and should be reverified before purchase decisions.

**Warning signs:**
- Per-car files contain registration tax calculations with no date stamp
- Skills contain DKK thresholds as literal numbers in the prompt text
- A user reports the tax figure is wrong for a car they researched

**Phase to address:**
Phase 2 (detail skill) — tax fetching must be live, not cached, from the first implementation.

---

### Pitfall 6: Overengineering the Architecture for a Personal Tool

**What goes wrong:**
The project grows a caching layer, a database backend, a structured JSON schema with migrations, and a validation pipeline. Build time balloons while actual car research stalls. The tool becomes a maintenance burden instead of a research aid.

**Why it happens:**
Claude Code skills are powerful enough to warrant architectural thinking, and developers familiar with production systems apply production patterns to personal tools. The subagent system, context forking, and plugin architecture are all available and tempting to use.

**How to avoid:**
The output format is markdown files in `research/`. That is the database. The schema is whatever fields are in the file. Resist building anything that is not directly in service of "go from car name to research file in one command." If a skill works for its purpose, do not refactor it. Add complexity only when a concrete pain point demands it, not in anticipation of future needs.

**Warning signs:**
- More than one day spent on infrastructure before the first research file exists
- Writing helper scripts that other scripts call
- Discussing caching strategies before the basic fetch works

**Phase to address:**
All phases — establish this discipline at project start, revisit at each phase boundary.

---

### Pitfall 7: Training Data Contaminating Research Output

**What goes wrong:**
Claude knows many EVs from training data. When a WebFetch call returns partial or empty content, Claude fills in gaps from training knowledge — silently. The research file looks complete but contains specifications from Claude's memory (which may be a different trim level, an older model year, or simply wrong).

**Why it happens:**
Claude is designed to be helpful and will use available knowledge when tool results are insufficient. A skill that says "fetch specs for the Volvo EX30" without explicit instructions to fail loudly on missing data will produce plausible-looking but unverified output.

**How to avoid:**
Skills must include explicit instructions: "If the fetched page does not contain the required data fields, stop and report what was found versus what was missing. Do not supplement with prior knowledge." Every fact in a per-car file must be traceable to a URL and fetch date. Consider adding a `Sources:` section to each research file listing every URL fetched.

**Warning signs:**
- Research file contains specs with no source URL
- Spec values match what you'd expect but no fetch was logged
- Range or price figures differ from what the source URL actually shows

**Phase to address:**
Phase 1 (skill template design) — the per-car file template must require source attribution before data fields are added.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoding specific car URLs in skill prompts | Faster to write one skill for one car | Every URL change breaks it; cannot add new cars without editing skill | Never — use discovery patterns instead |
| Using training data for baseline specs | Saves a fetch call | Silent staleness; no source attribution | Never for this project |
| One monolithic skill that does search + detail + compare | Simpler file structure | Context window exhausted before output is complete; hard to debug | Never — keep skills focused |
| Copying range figures without labeling methodology | Cleaner output | Apples-to-oranges comparison table | Never — always label source and standard |
| Fetching and ignoring the `robots.txt` | Easier to build | Risk of IP block from sites that enforce it | Check robots.txt first; respect crawl delays |

---

## Integration Gotchas

Common mistakes when connecting to the target sites.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| ev-database.org | Fetching the main listing page (JavaScript-loaded filter results) | Fetch individual car detail pages directly; they are SSR-rendered with full specs |
| fdm.dk | Fetching `/tests` index (Nuxt SSR but asynchronous data loading) | Use WebSearch `site:fdm.dk [car model]` to discover individual test article URLs, then fetch those |
| greengarage.dk | Fetching the homepage (AutoUncle JS widget, no SSR car data) | Fetch the `/artikler` section for editorial content; individual article pages are more likely to be fetch-safe |
| Motorstyrelsen | Trying to scrape the tax calculator (form-based, JS-rendered) | Fetch the static rates page at motorst.dk/en-us/individuals/vehicle-taxes/registration-tax/registration-tax-and-rates instead |
| WebFetch redirect handling | Assuming auto-redirect following | WebFetch does not follow cross-host redirects; a second explicit fetch call is required with the destination URL |

---

## Performance Traps

Patterns that work at small scale but degrade in a personal research context.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Fetching all sources for every skill invocation | Each research run takes 5+ minutes and hits context limits | Fetch only what the current task needs; detail skill only fetches one car | At 3+ sources per car |
| Loading full page content without filtering | 100 KB markdown pages flood context before Claude can reason about them | Instruct Claude to extract only named fields and discard page chrome | Any page over ~20 KB |
| Comparison skill re-fetching live data | Comparison results change between runs; hard to review | Comparison reads from existing per-car files, not live sites | First time a site is unavailable |
| Subagents spawning subagents for simple tasks | Token consumption explodes; tasks timeout | Use subagents only when true parallelism is needed; most tasks are sequential | Any task with >2 levels of nesting |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Search skill:** Returns car names but has no logic to discover the detail page URL — verify the output includes a fetchable URL, not just a name
- [ ] **Detail skill:** Produces a research file but all specs come from one source — verify at least ev-database.org AND one Danish source (FDM or greengarage) are cited
- [ ] **Comparison skill:** Generates a table but range column mixes WLTP and real-world figures — verify every range cell has a methodology label
- [ ] **Per-car file:** Contains ownership/reliability notes but no source — verify notes are sourced from FDM reviews or greengarage editorial, not Claude training data
- [ ] **Danish tax context:** File mentions "no registration tax" or a specific amount — verify the figure includes the date it was retrieved and a link to source
- [ ] **car_search.md integration:** Skill reads the file but ignores parameters outside its expected fields — verify skill handles unknown parameters gracefully instead of silently ignoring them

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Training data contamination found in research files | MEDIUM | Re-run detail skill with explicit "no prior knowledge" instruction; add source requirement to skill template; audit all existing files |
| Site restructure breaks URL patterns | LOW | Update discovery step in skill (WebSearch-based discovery is resilient); no per-car file changes needed if files store source URLs |
| WLTP/real-world mix found in comparison table | LOW | Add methodology labels to per-car files; regenerate comparison from existing files |
| Skill budget overflow drops a skill | LOW | Shorten skill descriptions; merge utility functionality; verify budget with skill count audit |
| Tax figures stale in existing research files | LOW | Add a "tax note" section to skill template with refresh instruction; re-run detail skill for affected cars |
| JavaScript page returning empty content | MEDIUM | Switch to WebSearch-based article discovery for that source; document in CLAUDE.md which sources require this approach |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| JavaScript pages returning empty content | Phase 1: Source probing | Manually fetch each source URL and confirm car data is present in markdown output |
| Hardcoded URLs breaking on site restructure | Phase 1: Skill architecture | Skill uses search/discovery to find URLs, never hardcodes them |
| WLTP vs real-world range mixing | Phase 1: Data schema | Per-car file template has labeled range fields before any car is researched |
| Skill character budget overflow | Phase 1: Skill design | Skill count stays at or below 5; descriptions are under 200 chars each |
| Danish tax data going stale | Phase 2: Detail skill | Tax section includes fetch date and source URL, not hardcoded values |
| Overengineering for a personal tool | All phases | Each phase delivers at least one working research file before any infrastructure work |
| Training data contaminating output | Phase 1: Skill template | Skill instructions include explicit "fail loudly on missing data" directive |

---

## Sources

- [Claude Code Skills documentation](https://code.claude.com/docs/en/skills) — official skill architecture and limitations
- [AI in Testing #9: The Invisible Limitations of Claude Code Skills](https://medium.com/@cheparsky/ai-in-testing-9-the-invisible-limitations-of-claude-code-skills-you-didnt-know-f3adbdcf3680) — character budget overflow, skill discovery gaps
- [Inside Claude Code's Web Tools: WebFetch vs WebSearch](https://mikhail.io/2025/10/claude-code-web-tools/) — content truncation, redirect behavior, domain restrictions
- [State of Web Scraping 2026](https://www.browserless.io/blog/state-of-web-scraping-2026) — 10-15% weekly breakage rates, DOM shift patterns
- [EV Range vs Real Range](https://driveauthority.com/ev-range-vs-real-range-why-advertised-numbers-mislead/) — WLTP vs real-world gap, winter range degradation
- [2025 EV Range Testing Methods](https://motorwatt.com/ev-blog/trends/ev-range-testing-methods) — WLTP/EPA/real-world methodology differences
- [Registreringsafgift på elbiler 2026 — FDM](https://fdm.dk/nyheder/nyt-om-trafik-og-biler/2025-10-saa-meget-falder-afgiften-paa-dyre-elbiler-2026) — Danish EV tax freeze and bracket changes
- [Motorstyrelsen registration tax rates](https://motorst.dk/en-us/individuals/vehicle-taxes/registration-tax/registration-tax-and-rates) — official Danish tax authority
- [The Four Claude Code Building Blocks](https://productpeak.substack.com/p/the-four-claude-code-building-blocks) — when subagents are appropriate vs. overkill
- Direct site probing: ev-database.org (SSR with JS enhancement — listing data present in HTML), fdm.dk (Nuxt SSR, asynchronous data loading), greengarage.dk (AutoUncle JS widget — homepage not fetch-safe)

---
*Pitfalls research for: Claude Code EV research skill suite, Danish market*
*Researched: 2026-03-22*
