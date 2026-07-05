# Stack Research

**Domain:** Claude Code skill suite for EV web research
**Researched:** 2026-03-22
**Confidence:** HIGH (Claude Code skills docs fetched directly from code.claude.com; site accessibility verified by live fetch)

## The Core Concept: This Is Not a Normal Tech Stack

There is no runtime, no build tool, no package.json. The "stack" here is:

1. **Claude Code skills** — markdown files in `.claude/skills/` that teach Claude to do things
2. **Claude's native tools** — WebFetch, WebSearch, Read, Write, Bash available to skills
3. **A plain markdown file** (`car_search.md`) as the parameter source
4. **Output files** written by Claude to `research/`

The question "what stack should we use?" is mostly answered by "Claude Code with its native tools." The interesting choices are: how to structure skills, which fetch method to use per data source, and what fallback patterns handle site-specific obstacles.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Claude Code skills | Current (`.claude/skills/`) | Skill definition and invocation | Native to the environment, no external runtime; SKILL.md files in this directory become `/slash-commands` and are auto-invoked by Claude |
| Claude WebFetch tool | `web_fetch_20260209` (current) | Fetching server-rendered pages | Built into Claude Code sessions; no API key; handles HTML→text extraction natively; newer version supports dynamic filtering to reduce token cost |
| Claude WebSearch tool | Native to Claude Code | Discovering article URLs on FDM.dk before fetching | Handles dynamic/JS sites indirectly — find the URL via search, then fetch the static article |
| Bash (curl) | macOS built-in | Fallback for sites that block WebFetch | Claude Code's Bash tool can curl; useful when WebFetch gets bot-blocked |
| Markdown files | Plain text | Parameter input (`car_search.md`) and output (`research/*.md`) | Zero dependencies; version-controllable; Claude reads/writes natively |

### Supporting Libraries / Patterns

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| `!`backtick injection` in SKILL.md` | Inject live data before Claude sees the prompt (e.g., `!`cat car_search.md``) | Reading `car_search.md` at skill invocation time |
| `$ARGUMENTS` substitution | Pass a car model name to the detail skill | `/ev-detail "Renault 5 52kWh"` |
| Supporting files in skill directory | Keep SKILL.md under 500 lines; offload site-specific URL patterns to `sites.md` | When site-specific logic grows large |
| `context: fork` + `agent: Explore` | Run research in isolated subagent without main session history | The detail skill fetching 5+ URLs for one car |
| `disable-model-invocation: true` | Prevent Claude from auto-triggering write-side skills (comparison generator) | Any skill that creates/overwrites files |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Claude Code itself | Interactive development and testing of skills | Run `/ev-search "budget 300000 DKK range 300km"` to test live |
| Git | Versioning research outputs | `research/*.md` files benefit from diff-ability; commit after each research session |

---

## Skill Structure

### Location and Format

Project-scoped skills live at `.claude/skills/<skill-name>/SKILL.md`. They become `/skill-name` commands. The `.claude/commands/` path also works and is equivalent; the skills path is preferred because it supports supporting files.

```
.claude/skills/
├── ev-search/
│   ├── SKILL.md          # Main skill: reads car_search.md, searches EV sites, returns matching models
│   └── sites.md          # URL patterns for ev-database.org, fdm.dk, greengarage.dk
├── ev-detail/
│   ├── SKILL.md          # Main skill: fetches deep spec + review data for one car model
│   └── output-template.md  # Template for research/[car-name].md output files
└── ev-compare/
    └── SKILL.md          # Reads existing research/*.md files, generates comparison table
```

### Minimal SKILL.md Structure

```yaml
---
name: ev-search
description: Search EV databases for cars matching criteria in car_search.md. Use when the user asks to find matching EVs, search for electric cars, or wants candidates for research.
allowed-tools: WebFetch, WebSearch, Read
---

Read the search criteria:
!`cat car_search.md`

Using the criteria above, search ev-database.org for matching models...
```

### Frontmatter Fields Used in This Project

| Field | Used For | Why |
|-------|---------|-----|
| `name` | Skill invocation name | Becomes `/skill-name` |
| `description` | Auto-invocation trigger | Claude uses this to decide when to load the skill automatically |
| `allowed-tools` | Scope tool access | `WebFetch, WebSearch, Read` for search/detail; add `Write` for file-writing skills |
| `disable-model-invocation: true` | Comparison skill | The comparison skill overwrites files — should only run when explicitly invoked |
| `context: fork` | Detail skill | Runs in isolated subagent; prevents multi-URL fetch from polluting main session |
| `argument-hint` | User guidance | `[car-model]` shown in autocomplete for ev-detail |

---

## Web Fetching Strategy by Data Source

This is the most critical decision. Each source has different accessibility characteristics.

### ev-database.org — HIGH reliability with WebFetch

**Assessment:** Server-rendered HTML. Permissive robots.txt (no disallows). Data is in the page source, not JavaScript-injected. Individual car pages follow `/uk/car/{ID}/{Make-Model}` pattern.

**Recommended method:** `WebFetch` directly.

**Pattern:**
```
Fetch https://ev-database.org/uk/ to get the current car listing.
Find cars matching the search criteria.
For each matching car, fetch its detail page: https://ev-database.org/uk/car/{ID}/{Make-Model}
Extract: real range (mild/cold weather), battery capacity, charging power (AC/DC),
efficiency, dimensions, price, V2L/V2H support, tow capacity.
```

**Data available per car:** Real range at different temperatures and speeds, efficiency (Wh/km), battery capacity (usable), charge port types, AC charge rate, DC peak rate, 0-100 time, cargo volume, weight, Euro NCAP, price (EUR, convert to DKK).

**Limitation:** The listing page is large. Use `max_content_tokens` or targeted fetches of category pages (e.g. `/uk/cat/range/Small-Car`) to reduce token cost.

---

### fdm.dk/tests — MEDIUM reliability, use WebSearch first

**Assessment:** Nuxt.js SPA — content is server-side rendered for SEO but the site shell is JavaScript-heavy. WebFetch **does not support JavaScript-rendered pages** per official docs. However, individual article pages are accessible because their content is in the server-rendered HTML. The catch is that the listing index requires JS for navigation.

**Recommended method:** WebSearch to discover article URLs, then WebFetch to read the article.

**Pattern:**
```
Use WebSearch: "site:fdm.dk/tests [car model] biltest"
Take the article URL from search results.
WebFetch the individual article URL.
Extract: WLTP range, measured range (highway, cold), charging performance,
verdict, pros/cons (styrker/svagheder), price tested, recommendation.
```

**Data available per article (verified on Volvo EX30):** Measured highway range at specified temperature, DC max charge rate, AC charge rate, km recovered per 15/30 min charge, specific strengths and weaknesses, DKK price (base and tested), driving impressions. No numerical score — verdict is narrative.

**Access:** Fully free, no paywall detected on tested articles.

**Why not direct listing fetch:** fdm.dk/tests and fdm.dk/tests/biltest load article list via JS navigation. Fetching these URLs returns the Nuxt shell without populated article cards. WebSearch bypasses this by hitting Google's index of the rendered pages.

---

### greengarage.dk — LOW priority, supplementary use only

**Assessment:** Primarily a car dealer/e-commerce site, not a review site. Vehicle inventory data is available (specs, pricing, leasing). Editorial content is limited — guides exist (used EV buying, battery maintenance) but these are generic, not per-model reviews. Individual car pages exist for some models (Tesla Model 3, VW ID.3, Volvo XC40, Honda e, Fiat 500e, Mini SE, BMW i4).

**Recommended method:** WebFetch for individual model pages when they exist. Skip for models not in their inventory.

**Best use:** Ownership quality signals for specific models they sell. Their angle is brand-neutral EV consulting, so their model write-ups emphasize practical ownership experience.

**What to extract:** Practical ownership notes, charging real-world tips, range realism notes, brand quality signals. Not primary spec source.

---

### Bash/curl as fallback

If WebFetch returns a bot-detection response (Cloudflare, 403, etc.) on a specific URL:

```bash
curl -s -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "https://example.com/car-page" | sed 's/<[^>]*>//g' | head -200
```

The Bash tool is available in Claude Code. Skills can instruct Claude to use it as fallback. This is uglier (raw HTML stripping) but works when WebFetch is blocked. ev-database.org has not shown bot-blocking behavior in testing.

---

## Markdown Output Patterns

### Per-car file: `research/[make-model].md`

Naming convention: lowercase, hyphenated. `research/renault-5-52kwh.md`, `research/volvo-ex30.md`.

Standard sections (enforce in the ev-detail skill's output template):

```markdown
# [Make Model Variant]

**Researched:** [date]
**Sources:** [ev-database.org, fdm.dk test, greengarage.dk]

## Quick Verdict
[2-3 sentences: does it meet the search criteria, what stands out]

## Specs
| Field | Value |
|-------|-------|
| Real range (mild) | km |
| Real range (cold) | km |
| Battery (usable) | kWh |
| DC charge peak | kW |
| AC charge rate | kW |
| 0-100 km/h | s |
| Cargo | L |
| Tow capacity | kg |
| Price DK (est.) | DKK |

## FDM Test Notes
[What FDM measured and said]

## Ownership Signals
[Reliability reputation, parts cost, insurance notes, brand quality]

## Danish Market Context
[Registration tax tier, green owner tax, DK-specific pricing if found]

## Pros
- ...

## Cons
- ...
```

### Comparison table: `research/comparison.md`

The ev-compare skill reads all `research/*.md` files and generates a side-by-side table. Claude's Read and Glob tools handle file discovery natively — no scripting needed.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Native WebFetch | Firecrawl MCP | If ev-database.org starts returning bot-blocking; Firecrawl has dedicated scraping infrastructure that bypasses anti-bot measures |
| WebSearch → WebFetch for FDM | Puppeteer/Playwright via Bash | Only if FDM moves to full SPA without server-rendered article pages; heavy dependency, not worth it for current site structure |
| Claude Code skills | Python script | If the research needs to run headlessly/scheduled; Claude Code is interactive-only |
| `.claude/skills/` | `.claude/commands/` | Functionally identical; skills format is preferred per current docs because it supports supporting files |
| Per-car markdown files | SQLite / JSON | Markdown is readable in the IDE, diffs cleanly, and feeds directly into Claude's context for comparison — no schema overhead |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Scraping ev-database.org with Playwright/Puppeteer | The site is server-rendered — no JS execution needed; adding a headless browser is unnecessary complexity | Native WebFetch |
| Fetching fdm.dk listing index directly | Nuxt.js SPA — WebFetch does not execute JavaScript; listing cards are not in the server-rendered HTML | WebSearch to find article URLs |
| Hardcoded car model lists in skills | Breaks the "living tool" requirement; new models need constant maintenance | Read criteria from `car_search.md` dynamically via `!`cat car_search.md`` |
| Storing results as JSON or YAML | Requires parsing step before Claude can reason over them; markdown is natively readable in context | `research/*.md` markdown files |
| `context: fork` on the ev-search skill | Search is exploratory; benefits from conversation context (user can ask follow-ups). Fork mode loses this | Inline execution (default) for search; fork only for detail fetching |
| Multiple separate WebFetch calls without `max_content_tokens` | Large pages (ev-database.org listing) can consume 25,000+ tokens each; unguarded multi-fetch will exhaust context | Set `max_content_tokens` or fetch category-specific pages |

---

## Stack Patterns by Skill Type

**ev-search skill (finding candidates):**
- Execution: inline (no `context: fork`) — user may want to ask follow-up questions
- Tools: `WebFetch, WebSearch, Read`
- Input: `!`cat car_search.md`` to inject criteria
- Output: list of matching models in the conversation (not written to files)

**ev-detail skill (deep research on one car):**
- Execution: `context: fork`, `agent: Explore` — multiple URL fetches in isolation
- Tools: `WebFetch, WebSearch, Read, Write`
- Input: `$ARGUMENTS` = car model name
- Output: writes `research/[model].md`

**ev-compare skill (side-by-side table):**
- Execution: inline
- Tools: `Read, Write, Glob`
- Input: reads all `research/*.md`
- Output: writes or overwrites `research/comparison.md`
- Frontmatter: `disable-model-invocation: true` — never auto-trigger file writes

---

## Version Compatibility Notes

| Concern | Detail |
|---------|--------|
| WebFetch JS limitation | Official docs (verified 2026-03-22): "The web fetch tool currently does not support websites dynamically rendered via JavaScript." This applies to Claude Code's session WebFetch and the API WebFetch tool. FDM.dk's listing pages are affected; individual article pages are not. |
| Skill format parity | `.claude/commands/` and `.claude/skills/` are functionally identical as of current Claude Code docs. Skills format is preferred for new work. |
| `web_fetch_20260209` dynamic filtering | Available on Sonnet 4.6 (the model powering this session). Reduces token cost by filtering content before it enters context. Use when fetching large EV listing pages. |

---

## Sources

- `https://code.claude.com/docs/en/slash-commands` — Skills/commands format, frontmatter fields, `$ARGUMENTS`, `context: fork`, `allowed-tools` (HIGH confidence, fetched directly)
- `https://code.claude.com/docs/en/permissions` — WebFetch permission syntax, tool availability in Claude Code sessions (HIGH confidence, fetched directly)
- `https://platform.claude.com/docs/en/docs/agents-and-tools/tool-use/web-fetch-tool` — WebFetch JavaScript limitation, `max_content_tokens`, URL validation rules (HIGH confidence, official Anthropic API docs)
- `https://ev-database.org/` — Verified server-rendered HTML, permissive robots.txt, URL pattern `/uk/car/{ID}/{Make-Model}` (HIGH confidence, live fetch)
- `https://fdm.dk/tests/biltest/test-flot-comeback-nu-er-volvo-ex30-endelig-voksen` — Verified free article access, data fields available (WLTP/measured range, charging, pros/cons, DKK pricing) (HIGH confidence, live fetch)
- `https://fdm.dk/tests/biltest` — Verified Nuxt.js SPA listing; article URLs follow `/tests/biltest/[slug]` pattern (HIGH confidence, live fetch)
- `https://greengarage.dk/sitemap.xml` — Content categories confirmed: inventory, guides, model-specific pages (HIGH confidence, live fetch)
- `https://www.firecrawl.dev/blog/claude-code-skill` — Firecrawl as fallback for bot-blocked sites pattern (MEDIUM confidence, third-party blog)

---
*Stack research for: Claude Code EV research skill suite*
*Researched: 2026-03-22*
