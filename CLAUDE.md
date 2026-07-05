# Project conventions


## Git & CI
- **Stage early, commit often:** Stage changes with `git add` frequently. Commit at natural checkpoints throughout a task — not only at the end. This protects against token exhaustion mid-work.

## Trusted/suggested sites
- https://ev-database.org/
- https://fdm.dk/tests
- https://fdm.dk/nyheder
- https://greengarage.dk/

<!-- GSD:project-start source:PROJECT.md -->
## Project

**EV Research Skills**

A suite of Claude Code skills — **published via Homebrew** (`pingvinen/homebrew-tap`) and installed globally into `~/.claude/skills` — that help research and compare electric vehicles for the Danish market. The skills fetch data from known EV sites (ev-database.org, FDM, greengarage.dk) and produce per-car research files and comparison tables. A living tool that stays useful as new models release.

The skills are decoupled from research data: they ship via the package, while each user's searches live in their own workspace (see below). This repo is both the skill source **and** a usable workspace, but the intended consumer experience is `ev-search-skills install` (skills → global) + `ev-search-skills scaffold` (seed a workspace anywhere).

**Core Value:** Quickly go from "what EVs match my criteria?" to informed, comparable research files — without manually trawling multiple sites.

### Constraints

- **Platform**: Claude Code skills (`.claude/skills/`), distributed via Homebrew and installed globally; the `ev-search-skills` CLI (`bin/`) handles install/uninstall/scaffold
- **Data freshness**: Skills must fetch live data, not rely on training data
- **Input**: All search criteria come from a project's `brief.md` (created by `/ev-new-project`) — no hardcoded parameters. `state.md` tracks the active project
- **Output**: Per-car files and comparison tables under `projects/<name>/` in the user's workspace — never committed back into the skills package
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## The Core Concept: This Is Not a Normal Tech Stack
## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Claude Code skills | Current (`.claude/skills/`) | Skill definition and invocation | Native to the environment, no external runtime; SKILL.md files in this directory become `/slash-commands` and are auto-invoked by Claude |
| Claude WebFetch tool | `web_fetch_20260209` (current) | Fetching server-rendered pages | Built into Claude Code sessions; no API key; handles HTML→text extraction natively; newer version supports dynamic filtering to reduce token cost |
| Claude WebSearch tool | Native to Claude Code | Discovering article URLs on FDM.dk before fetching | Handles dynamic/JS sites indirectly — find the URL via search, then fetch the static article |
| Bash (curl) | macOS built-in | Fallback for sites that block WebFetch | Claude Code's Bash tool can curl; useful when WebFetch gets bot-blocked |
| Markdown files | Plain text | Parameter input (`projects/<name>/brief.md`) and output (`projects/<name>/research/*.md`) | Zero dependencies; version-controllable; Claude reads/writes natively |
### Supporting Libraries / Patterns
| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| `!`backtick injection` in SKILL.md` | Inject live data before Claude sees the prompt (e.g., `!`cat state.md``) | Reading the active project from `state.md` at skill invocation time; `brief.md` is then read with the Read tool |
| `$ARGUMENTS` substitution | Pass a car model name to the detail skill | `/ev-detail "Renault 5 52kWh"` |
| Supporting files in skill directory | Keep SKILL.md under 500 lines; offload site-specific URL patterns to `sites.md` | When site-specific logic grows large |
| `context: fork` + `agent: Explore` | Run research in isolated subagent without main session history | The detail skill fetching 5+ URLs for one car |
| `disable-model-invocation: true` | Prevent Claude from auto-triggering write-side skills (comparison generator) | Any skill that creates/overwrites files |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| Claude Code itself | Interactive development and testing of skills | Run `/ev-new-project` then `/ev-search` in a scaffolded workspace to test live |
| Git | Versioning research outputs | `projects/<name>/research/*.md` files benefit from diff-ability; commit after each research session |
## Skill Structure
### Location and Format
### Minimal SKILL.md Structure
### Frontmatter Fields Used in This Project
| Field | Used For | Why |
|-------|---------|-----|
| `name` | Skill invocation name | Becomes `/skill-name` |
| `description` | Auto-invocation trigger | Claude uses this to decide when to load the skill automatically |
| `allowed-tools` | Scope tool access | `WebFetch, WebSearch, Read` for search/detail; add `Write` for file-writing skills |
| `disable-model-invocation: true` | Comparison skill | The comparison skill overwrites files — should only run when explicitly invoked |
| `context: fork` | Detail skill | Runs in isolated subagent; prevents multi-URL fetch from polluting main session |
| `argument-hint` | User guidance | `[car-model]` shown in autocomplete for ev-detail |
## Web Fetching Strategy by Data Source
### ev-database.org — HIGH reliability with WebFetch
### fdm.dk/tests — MEDIUM reliability, use WebSearch first
### greengarage.dk — LOW priority, supplementary use only
### Bash/curl as fallback
## Markdown Output Patterns
### Per-car file: `projects/<name>/research/[make-model].md`
# [Make Model Variant]
## Quick Verdict
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
## Ownership Signals
## Danish Market Context
## Pros
- ...
## Cons
- ...
### Comparison table: `projects/<name>/research/comparison.md`
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Native WebFetch | Firecrawl MCP | If ev-database.org starts returning bot-blocking; Firecrawl has dedicated scraping infrastructure that bypasses anti-bot measures |
| WebSearch → WebFetch for FDM | Puppeteer/Playwright via Bash | Only if FDM moves to full SPA without server-rendered article pages; heavy dependency, not worth it for current site structure |
| Claude Code skills | Python script | If the research needs to run headlessly/scheduled; Claude Code is interactive-only |
| `.claude/skills/` | `.claude/commands/` | Functionally identical; skills format is preferred per current docs because it supports supporting files |
| Per-car markdown files | SQLite / JSON | Markdown is readable in the IDE, diffs cleanly, and feeds directly into Claude's context for comparison — no schema overhead |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Scraping ev-database.org with Playwright/Puppeteer | The site is server-rendered — no JS execution needed; adding a headless browser is unnecessary complexity | Native WebFetch |
| Fetching fdm.dk listing index directly | Nuxt.js SPA — WebFetch does not execute JavaScript; listing cards are not in the server-rendered HTML | WebSearch to find article URLs |
| Hardcoded car model lists in skills | Breaks the "living tool" requirement; new models need constant maintenance | Read criteria from the active project's `brief.md` (resolved via `state.md`) |
| Storing results as JSON or YAML | Requires parsing step before Claude can reason over them; markdown is natively readable in context | `projects/<name>/research/*.md` markdown files |
| `context: fork` on the ev-search skill | Search is exploratory; benefits from conversation context (user can ask follow-ups). Fork mode loses this | Inline execution (default) for search; fork only for detail fetching |
| Multiple separate WebFetch calls without `max_content_tokens` | Large pages (ev-database.org listing) can consume 25,000+ tokens each; unguarded multi-fetch will exhaust context | Set `max_content_tokens` or fetch category-specific pages |
## Stack Patterns by Skill Type
- Execution: inline (no `context: fork`) — user may want to ask follow-up questions
- Tools: `WebFetch, WebSearch, Read`
- Input: `!`cat state.md`` to resolve the active project, then Read `projects/<name>/brief.md` for criteria
- Output: Search Candidates written to `projects/<name>/state.md`
- Execution: `context: fork`, `agent: Explore` — multiple URL fetches in isolation
- Tools: `WebFetch, WebSearch, Read, Write`
- Input: `$ARGUMENTS` = car model name
- Output: writes `projects/<name>/research/[model].md`
- Execution: inline
- Tools: `Read, Write, Glob`
- Input: reads all `projects/<name>/research/*.md`
- Output: writes or overwrites `projects/<name>/research/comparison.md`
- Frontmatter: `disable-model-invocation: true` — never auto-trigger file writes
## Version Compatibility Notes
| Concern | Detail |
|---------|--------|
| WebFetch JS limitation | Official docs (verified 2026-03-22): "The web fetch tool currently does not support websites dynamically rendered via JavaScript." This applies to Claude Code's session WebFetch and the API WebFetch tool. FDM.dk's listing pages are affected; individual article pages are not. |
| Skill format parity | `.claude/commands/` and `.claude/skills/` are functionally identical as of current Claude Code docs. Skills format is preferred for new work. |
| `web_fetch_20260209` dynamic filtering | Available on Sonnet 4.6 (the model powering this session). Reduces token cost by filtering content before it enters context. Use when fetching large EV listing pages. |
## Sources
- `https://code.claude.com/docs/en/slash-commands` — Skills/commands format, frontmatter fields, `$ARGUMENTS`, `context: fork`, `allowed-tools` (HIGH confidence, fetched directly)
- `https://code.claude.com/docs/en/permissions` — WebFetch permission syntax, tool availability in Claude Code sessions (HIGH confidence, fetched directly)
- `https://platform.claude.com/docs/en/docs/agents-and-tools/tool-use/web-fetch-tool` — WebFetch JavaScript limitation, `max_content_tokens`, URL validation rules (HIGH confidence, official Anthropic API docs)
- `https://ev-database.org/` — Verified server-rendered HTML, permissive robots.txt, URL pattern `/uk/car/{ID}/{Make-Model}` (HIGH confidence, live fetch)
- `https://fdm.dk/tests/biltest/test-flot-comeback-nu-er-volvo-ex30-endelig-voksen` — Verified free article access, data fields available (WLTP/measured range, charging, pros/cons, DKK pricing) (HIGH confidence, live fetch)
- `https://fdm.dk/tests/biltest` — Verified Nuxt.js SPA listing; article URLs follow `/tests/biltest/[slug]` pattern (HIGH confidence, live fetch)
- `https://greengarage.dk/sitemap.xml` — Content categories confirmed: inventory, guides, model-specific pages (HIGH confidence, live fetch)
- `https://www.firecrawl.dev/blog/claude-code-skill` — Firecrawl as fallback for bot-blocked sites pattern (MEDIUM confidence, third-party blog)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

### Projects & test fixtures
- Real research projects live under `projects/<name>/` and **are tracked in git** — this is where your actual EV searches live.
- **Test fixtures are named with a `test-` prefix** (e.g. `projects/test-ev-detail-new/`). They are throwaway directories for exercising/validating the skills (golden runs) and are **git-ignored** via `projects/test-*/` in `.gitignore`. Do not rely on their contents being committed; regenerate them as needed.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
