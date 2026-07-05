# Phase 3: Search and Compare - Research

**Researched:** 2026-06-27
**Domain:** Claude Code skills — ev-database.org HTML parsing, DK EV pricing, comparison table generation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- D-01: Discovery mechanism is NOT pre-decided — spike cheapest-first. Three levels: (1) curl-able JSON/XHR or server-rendered filtered URL, (2) knowledge-seeded candidate names verified against detail pages, (3) local headless tool. Adopt lightest path with good coverage.
- D-02: No paid services. Firecrawl cloud rejected. Only free/open-source/local tools permitted.
- D-03: Pure WebSearch-driven discovery disfavoured — flood risk and poor coverage.
- D-04: Per-candidate fetch depth is shallow — only SC#1 fields (price band, range, battery, body type). No full /ev-detail depth at search stage.
- D-05: No FX/currency conversion. EUR/GBP prices on ev-database cannot be converted to meaningful DKK (Danish car taxation is structurally different).
- D-06: Search stage shows a rough DK price band/bucket, not a precise figure.
- D-07: DK price band comes from a cheap live WebSearch per candidate (`"<make> <model> pris DKK"`). Take snippet figure, bucket it, label it indicative.
- D-08 (discretion, recommended): Anchor bands to brief budget (preferred + maximum, incl. per-brand overrides). Labels: "within budget" / "slight stretch (near-miss)" / "over budget".
- D-09: `/ev-search` persists candidate list to per-project `state.md` in new "Search Candidates" section. One row per candidate: model name, ev-database URL, body type, EVDB range, battery, DK price band, filter verdict (match / borderline+reason / excluded+reason).
- D-10: `/ev-search` gains Write access to `projects/<active>/state.md`. Tools: WebSearch, Read, Write, Bash(curl *, python3 *, ls *).
- D-11: `/ev-search` also presents the ranked list in conversation and ends with a copy-paste `/ev-research "A" "B" ...` command.
- D-12: Near-misses surfaced and flagged separately, never silently dropped. Hard-filter only on cheaply knowable fields.
- D-13: Re-running `/ev-search` overwrites the "Search Candidates" section with a dated snapshot. No stale rows.
- D-14: `comparison.md` is decision support: full ~15 spec rows, best-in-class highlighted per row, brief-aware verdict at top.
- D-15: Include condensed qualitative signals: FDM verdict one-liner, top pros/cons, ownership confidence.
- D-16: WLTP range and real-world (FDM) range as separate, per-column-labelled rows. Never merged or averaged.
- D-17: Gaps render explicitly ("no FDM test", "tire size unconfirmed") — never blank or guessed.
- D-18: `/ev-compare` is write-side → `disable-model-invocation: true`, tools `Read, Write, Glob`.

### Claude's Discretion

- Exact discovery tactic within D-01 spike order (which ev-database URL/endpoint, query patterns, candidate-set size).
- Exact band scheme labels and boundaries (D-08 recommends brief-budget-relative).
- Per-candidate WebSearch query wording for DK price band signal.
- Ranking/sort order of candidate list and comparison columns.
- Exact "Search Candidates" section schema/columns in `state.md`.
- `comparison.md` layout details (table grouping, qualitative row formatting, best-in-class visual marking).
- Whether to cap candidate count and at what number.

### Deferred Ideas (OUT OF SCOPE)

- Adopting Playwright MCP / self-hosted Firecrawl — only if zero-install discovery proves insufficient.
- CLAUDE.md "What NOT to use" nuance update for headless browser — only if D-01 escalates.
- Tire scoring / pricing (Phase 5), Danish tax & insurance enrichment (Phase 4).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCH-02 | Search skill queries ev-database.org and returns matching models with key specs | Confirmed: ev-database.org root page (8.9 MB) is server-rendered with all 1,367 car entries and filter data embedded as hidden spans. curl + Python extraction is the recommended approach. |
| SRCH-03 | Search results include DKK price, range, battery capacity, and body type per model | Confirmed: range and battery come from listing HTML; DK price via WebSearch snippet; body type from shape-* class. |
| COMP-01 | Comparison skill reads all of the active project's `research/*.md` files and generates side-by-side table | Confirmed: Glob finds files, Read loads each, comparison table built from car-template.md field set. |
| COMP-02 | Comparison table labels range methodology per column (WLTP vs FDM real-world) | Confirmed: car-template.md has separate WLTP range and Real-world range (mild/cold) rows. Must label source per column. |
| COMP-03 | Comparison output written to the active project's `comparison.md` | Confirmed: Write tool writes `projects/<active>/comparison.md`. |

</phase_requirements>

---

## Summary

The critical D-01 discovery question is resolved by live probe: ev-database.org's root page (`https://ev-database.org`) is **fully server-rendered** at 8.9 MB and contains all 1,367 current car entries with filter data embedded as hidden CSS-class spans. A `curl` call with a browser user-agent followed by a Python one-liner can extract matching candidates (by body type, seat count, range, and battery) in seconds, with no JavaScript execution, no paid service, and no per-car detail-page fetches at search stage. This is D-01 Step 1 confirmed viable — the cheapest path wins.

DK pricing is confirmed impossible from ev-database.org (EUR prices only, no DK equivalent). The D-07 approach — a cheap WebSearch per candidate (`"<make> <model> pris DKK"`) — is confirmed working in live tests: Renault 5 52kWh → from DKK 224,990; Volvo EX30 SM ER → from DKK 244,900. Snippets carry a figure suitable for brief-budget bucketing.

`/ev-compare` design is straightforward: Glob finds `research/*.md` files, Read loads each, the car-template.md field set (15 rows) defines the comparison rows, and WLTP vs FDM range stays as separate rows per D-16. The skill writes `comparison.md` and must be gated with `disable-model-invocation: true` (D-18).

**Primary recommendation:** Use Bash(curl) + Bash(python3) as the discovery engine for `/ev-search`. Cap the candidate list at ~20 after filtering, do per-candidate DK price WebSearch (≤10 searches), write Search Candidates to `state.md`, present ranked list and handoff command in conversation.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| EV model discovery | Claude skill (inline) | ev-database.org HTML | Skill fetches and filters the listing; ev-database is the data source |
| DK price signal | Claude WebSearch | Snippet extraction | One search per candidate; no dedicated pricing API needed |
| Candidate persistence | Per-project `state.md` | — | Existing artifact, new section appended |
| Brief parsing | Claude skill reads brief.md | — | SRCH-01 contract: all criteria come from brief |
| Spec comparison | Claude skill (inline) | research/*.md files | Skill reads the per-car files and builds the table |
| Comparison output | `projects/<active>/comparison.md` | — | Write-side skill, always explicit invocation |

---

## Standard Stack

### Core

| Tool / Pattern | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Bash(curl) | macOS built-in (8.7.1 confirmed) | Fetch ev-database.org root HTML listing | WebFetch cannot handle 8.9 MB listing; curl streams to /tmp file cheaply |
| Bash(python3) | macOS built-in (3.14.6 confirmed) | Parse HTML, extract filtered car entries | Single-pass regex extraction; no external packages; available on every macOS install |
| Claude WebSearch | native | DK price band per candidate | Snippet carries price figure; no full-page fetch needed |
| Claude Read | native | Load brief.md, state.md, research/*.md | Standard skill input mechanism |
| Claude Write | native | Update state.md, write comparison.md | Standard skill output mechanism |
| Claude Glob | native | Discover research/*.md files | Pattern-match without knowing filenames in advance |

### Supporting Patterns

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| `!cat state.md` backtick injection | Inject active_project at skill load time | Both new skills — same as all existing skills |
| Browser user-agent in curl | Bypass ev-database.org bot detection | Without `-A "Mozilla/5.0"`, the server returns a 404 page (confirmed) |
| `/tmp/evdb_listing.html` staging file | Hold 8.9 MB download between curl and python3 steps | Avoids piping huge HTML through shell variable; file is ephemeral, no cleanup needed |
| EUR price as pre-filter hint | Rough ordering before DK price search | Sort candidates by EUR price ascending before DK search — reduces searches for clearly over-budget cars |
| Glob → Read loop | Load all research files for /ev-compare | Glob gives paths, Read loads each — no hardcoded filenames |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| curl + python3 | WebFetch on ev-database.org root | 8.9 MB WebFetch would exhaust context even with max_content_tokens; curl is free and bypasses token cost entirely |
| curl + python3 | Playwright MCP for JS-rendered filter | Playwright is heavier, requires npx install; the listing is already server-rendered — no JS needed |
| WebSearch per candidate for DK price | Bilbasen Blog fetch per candidate | Blog fetch is better quality but 5-10x more expensive; at search stage, snippet price is sufficient for bucketing |

**Installation:** Nothing to install. All tools (curl, python3) are macOS built-ins confirmed available on this machine.

---

## Package Legitimacy Audit

No external packages are installed in this phase. All tools used (curl, python3, Claude built-in tools) are either OS built-ins or native Claude Code capabilities. No npm/pypi/crates packages required.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| (none) | — | — | — |

---

## Architecture Patterns

### System Architecture Diagram

```
/ev-search invocation
        |
        v
[Read: global state.md]  → active_project
        |
        v
[Read: projects/<active>/brief.md]
    body_types, seats, min_range, budget_preferred, budget_max, per_brand_overrides
        |
        v
[Bash: curl -s -A "Mozilla/5.0" https://ev-database.org -o /tmp/evdb_listing.html]
        |
        v
[Bash: python3 filter script]
    → reads /tmp/evdb_listing.html
    → regex extracts list-items
    → filters by body_type (shape-*), seats, erange_real, battery
    → outputs: name | /car/{ID}/{slug} | range | battery | EUR_price
        |
        v
[For each candidate (≤20):]
    [WebSearch: "<make> <model> pris DKK"]
    → extract DK price from snippet
    → bucket vs brief budget → verdict (match / borderline / excluded)
        |
        v
[Write: "Search Candidates" section → projects/<active>/state.md]
        |
        v
[Present ranked list in conversation]
[End with: /ev-research "A" "B" ...]


/ev-compare invocation
        |
        v
[Read: global state.md] → active_project
        |
        v
[Glob: projects/<active>/research/*.md]
        |
        v
[Read: each research file]
    → extract 15 Specs rows, FDM Test Notes, Ownership Signals, Pros, Cons
        |
        v
[Build comparison table]
    → one column per car
    → best-in-class highlighted per row
    → WLTP range and FDM real-world range as separate labelled rows (D-16)
    → gaps as explicit text (D-17)
        |
        v
[Add brief-aware verdict at top + condensed qualitative rows]
        |
        v
[Write: projects/<active>/comparison.md]
```

### Recommended Project Structure

Skills live in `.claude/skills/` per CLAUDE.md:

```
.claude/skills/
├── ev-search/
│   └── SKILL.md          # /ev-search skill
└── ev-compare/
    └── SKILL.md          # /ev-compare skill
```

No supporting `sites.md` needed — Phase 6 confirmed sites.md wasn't implemented as a separate file; patterns went inline in ev-detail. Same convention applies here.

### Pattern 1: ev-database.org Root Page HTML Extraction

**What:** Fetch the 8.9 MB root HTML with curl, pipe through a Python regex to extract car entries, filter by brief criteria.

**When to use:** Discovery step of `/ev-search` — replaces the JS-blocked filter listing.

**Evidence:** Live probe confirmed. Root page has 1,367 `data-jplist-item` entries fully server-rendered. Volvo EX30 SM ER verified: range 365 km, battery 65 kWh, EUR 42,611, body shape-suv. [VERIFIED: live curl probe 2026-06-27]

**HTML data structure per car entry:**
```html
<div class="list-item" data-jplist-item>
  <!-- Car name and URL -->
  <a href="/car/1910/Volvo-EX30-Single-Motor-ER" class="title">
    <span class="hidden">Volvo EX30 Single Motor ER</span>
  </a>
  <!-- Body type (hidden, used by jplist filter) -->
  <span class="shape-suv hidden">SUV</span>
  <!-- Seat count (in icon class) -->
  <i class="seats-5 fas fa-user">
  <!-- Specs display -->
  <span class="erange_real">365 km</span>
  <!-- Hidden filter values -->
  <span class="battery hidden">65</span>       <!-- kWh as integer -->
  <span class="fastcharge_speed hidden">158</span>  <!-- kW -->
  <span class="towweight hidden">1600</span>    <!-- kg -->
  <span class="pricefilter hidden">42611</span> <!-- EUR, NOT DKK -->
</div>
```

**Body type shape classes:** `shape-suv`, `shape-hatchback`, `shape-sedan`, `shape-station`, `shape-liftback`, `shape-mpv`, `shape-pickup`, `shape-coupe`, `shape-cabrio`, `shape-spv`

**Seat count classes:** `seats-2`, `seats-4`, `seats-5`, `seats-7`

**Extraction script sketch:**
```python
# Source: live probe of ev-database.org HTML, 2026-06-27
import re

with open('/tmp/evdb_listing.html', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Extract all car entries
items = re.findall(
    r'<div class="list-item" data-jplist-item>(.*?)</div>\s*\n</div>',
    content, re.DOTALL
)

# Filter by brief criteria
BODY_SHAPE_CLASSES = ['shape-suv']   # derived from brief body_type field
MIN_SEATS = 5
MIN_RANGE_KM = 250
MIN_BATTERY_KWH = 40

results = []
for item in items:
    # Body type check
    shapes = re.findall(r'class="(shape-[a-z]+) hidden"', item)
    if not any(s in shapes for s in BODY_SHAPE_CLASSES):
        continue
    # Seat count check
    seat_m = re.search(r'seats-(\d+)', item)
    if not seat_m or int(seat_m.group(1)) < MIN_SEATS:
        continue
    # Range check
    range_m = re.search(r'class="erange_real">(\d+) km<', item)
    if not range_m or int(range_m.group(1)) < MIN_RANGE_KM:
        continue
    # Battery check
    bat_m = re.search(r'class="battery hidden">(\d+)<', item)
    if not bat_m or int(bat_m.group(1)) < MIN_BATTERY_KWH:
        continue
    # Extract fields
    name_m = re.search(r'class="hidden">([^<]+)</span></a>', item)
    url_m = re.search(r'href="(/car/\d+/[^"]+)" class="title"', item)
    price_m = re.search(r'class="pricefilter hidden">(\d+)<', item)
    results.append({
        'name': name_m.group(1) if name_m else '',
        'url': 'https://ev-database.org' + (url_m.group(1) if url_m else ''),
        'range_km': int(range_m.group(1)),
        'battery_kwh': int(bat_m.group(1)),
        'price_eur': int(price_m.group(1)) if price_m else 0,
    })

results.sort(key=lambda x: x['price_eur'])
for r in results:
    print(f"{r['name']}|{r['url']}|{r['range_km']}km|{r['battery_kwh']}kWh|EUR{r['price_eur']}")
```

### Pattern 2: Brief Criteria → ev-database Shape Class Mapping

**What:** Map human-readable body type text from brief.md to ev-database shape CSS class names.

**When to use:** `/ev-search` Step interpreting brief body type field before running filter.

```
"SUV" / "crossover" → shape-suv
"hatchback" → shape-hatchback
"estate" / "wagon" → shape-station
"sedan" → shape-sedan
"MPV" → shape-mpv
"pickup" → shape-pickup
```

If brief body type mentions both SUV and hatchback, include both shape classes in the filter.

### Pattern 3: DK Price Band via WebSearch (D-07, D-08)

**What:** Per-candidate DK price lookup using WebSearch snippet.

**When to use:** After getting candidate list from HTML filter, for each car.

**Confirmed working:** [VERIFIED: live probe 2026-06-27]
- Query: `"Renault 5 52kWh pris DKK"` → snippet yields "fra 224.990 DKK" / "fra 189.990 DKK"
- Query: `"Volvo EX30 pris DKK 2026"` → snippet yields "fra 244.900 DKK" / "279.000 DKK Plus trim"

**Band labels relative to brief budget (D-08):**
- `within budget` — DK from-price ≤ brief preferred budget
- `slight stretch` — DK from-price between preferred and maximum
- `over budget` — DK from-price > maximum (still show if within per-brand override)
- `price unknown` — WebSearch snippet yields no price figure

**Note:** If a brand has a per-brand override in the brief (e.g., BMW: +50%), apply the override ceiling for that brand before bucketing.

### Pattern 4: Search Candidates Section in state.md (D-09)

**What:** Append or overwrite a "Search Candidates" section in the per-project `state.md`.

**Location in file:** After the existing sections (Research Progress, Source Reliability Notes, Discovered Sources). If section already exists, overwrite it (D-13).

**Schema:**
```markdown
## Search Candidates

_Last updated: [date] — criteria: [body type], [seats]+ seats, range ≥[X]km, battery ≥[Y]kWh, budget [preferred]–[max] DKK_

| Model | ev-database URL | Body | EVDB Range | Battery | DK Price Band | Verdict |
|-------|----------------|------|------------|---------|---------------|---------|
| Volvo EX30 SM ER | https://ev-database.org/car/1910/... | SUV | 365 km | 65 kWh | within budget (268–299k DKK) | match |
| Renault 5 52kWh | https://ev-database.org/car/2135/... | Hatchback | 335 km | 52 kWh | within budget (225–255k DKK) | match |
| BYD Atto 3 | https://ev-database.org/car/... | SUV | 330 km | 60 kWh | slight stretch (~370k DKK) | borderline: near budget ceiling |
| Honda e:Ny1 | https://ev-database.org/car/... | SUV | 260 km | 68 kWh | slight stretch | borderline: range below 300km target |
```

**Verdict values:**
- `match` — passes all hard filters, within budget
- `borderline: [reason]` — one soft criterion misses (budget near-miss, must-have unconfirmable at search stage)
- `excluded: [reason]` — clear hard fail (range well below minimum, clearly over-budget)

**EVDB Range label note:** The `erange_real` figure from ev-database.org's listing is EVDB's own standardized estimate under mild conditions (not WLTP and not FDM-measured). Label it as "EVDB range" in the column header to avoid confusion with WLTP or FDM figures.

### Pattern 5: /ev-compare Table Structure

**What:** Comparison table layout for `comparison.md`.

**When to use:** `/ev-compare` generating the output file.

**Column order:** Sort by a useful comparison axis (e.g., range descending, or tier-1 price ascending). State the sort key used.

**Row set from car-template.md** (15 spec rows + qualitative rows):
```
Range: WLTP (km)                ← labelled "WLTP (manufacturer)"
Range: real-world mild (km)     ← labelled "FDM measured at 110km/h, 20°C" or "EVDB estimate"
Range: real-world cold (km)     ← labelled "FDM measured at 110km/h, 0°C" or "EVDB estimate"
Battery (usable) (kWh)
DC charge peak (kW)             ← labelled "manufacturer rated"
AC charge rate (kW)
10-80% DC charge time (min)
0-100 km/h (s)
Cargo (L)
Tow capacity (kg)
Tire size (front)
Tire size (rear)
Price DK tier 1 (from) (DKK)
Price DK tier 2 (best value) (DKK)
Power output (kW)
---
EV platform
FDM verdict (one-liner)
FDM Styrker (top 2)
FDM Svagheder (top 2)
Ownership confidence
```

**Best-in-class marking:** Use bold or a marker like `*` on the best value per row. For rows where lower is better (charge time, 0-100, price), mark the lowest. For rows where higher is better (range, battery, tow, cargo), mark the highest.

**Gap rendering (D-17):** If a field is missing from a research file, write `no FDM test` / `unconfirmed` / `not available (purchase_type)` — never leave blank.

### Anti-Patterns to Avoid

- **Fetching ev-database.org with WebFetch (listing page):** The listing is 8.9 MB. Even with `max_content_tokens`, WebFetch would consume enormous token budget and likely still truncate. Use Bash(curl) instead.
- **Using the fragment-based filter URL:** The `#accelerate=false&...` URL fragment is never sent to the server — it's a client-side jplist state. The server always returns all cars regardless of fragment.
- **Using EUR price to compute DKK:** Danish car registration taxes make EUR → DKK conversion meaningless (the Volvo EX30 SM ER is EUR 42,611 on ev-database but DKK 268,900 in Denmark — that's 6.3x, not the 7.4x EUR/DKK exchange rate).
- **Fetching ev-database.org without browser user-agent:** Without `-A "Mozilla/5.0"`, the server returns a 404 page (64 KB). Always include the user-agent header. [VERIFIED: live probe 2026-06-27]
- **Including WLTP and FDM range in the same comparison row:** D-16 is locked — these must be separate rows with separate source labels.
- **Treating erange_real from the listing as WLTP:** The ev-database listing shows its own EVDB standardized estimate ("erange_real"), not the official WLTP figure. The Volvo EX30 SM ER is listed as 365 km EVDB real vs. 476 km WLTP on the detail page. Label it accurately.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML parsing for car data | Custom regex parser | The extraction pattern in this research (confirmed working) | The ev-database HTML structure is stable and well-documented from live probe |
| DK price lookup | Scraping manufacturer websites | WebSearch snippet extraction | Manufacturer sites often return 403 (volvocars.com/da confirmed 403); snippets are sufficient for bucketing |
| Body type mapping | Fuzzy NLP matching | Explicit brief-text → shape-class map | Limited set (10 classes); hardcoded map is more reliable |
| Comparison table formatting | Custom template language | Inline Markdown generation from research files | The skill's LLM generation directly produces Markdown — no templating engine needed |

**Key insight:** The ev-database listing page is doing the heavy lifting — all filter data is already embedded in the HTML as hidden spans because jplist (the JS filter library) needs it. We're free-riding on their existing server-rendered structure.

---

## Runtime State Inventory

> Omitted — this is a greenfield skill addition phase, not a rename/refactor. No existing runtime state is affected.

---

## Common Pitfalls

### Pitfall 1: curl without browser User-Agent returns 404 page

**What goes wrong:** `curl https://ev-database.org` returns a 64 KB "Page not Found" HTML page instead of the 8.9 MB car listing. The Python filter script then finds zero cars.

**Why it happens:** ev-database.org checks the User-Agent header and blocks non-browser clients from the listing page.

**How to avoid:** Always use `-A "Mozilla/5.0"` (or any common browser UA string). Add an early sanity check: if the downloaded file is under 100 KB, abort with an error before attempting to parse.

**Warning signs:** The python3 script reports "0 matching cars found" with no other error; `/tmp/evdb_listing.html` is ~64 KB instead of ~8-9 MB.

### Pitfall 2: confusing erange_real (EVDB) with WLTP range

**What goes wrong:** The skill uses `erange_real` from the listing as the "range" field in the Search Candidates table, but the user or comparison step interprets it as WLTP. Actual WLTP may be 100+ km higher (Volvo EX30: 365 km EVDB vs 476 km WLTP).

**Why it happens:** Both fields are called "range"; the listing doesn't show WLTP — only EVDB's own standardized estimate.

**How to avoid:** Always label the range figure in the Search Candidates table as "EVDB range (std. conditions)" — not "WLTP". Note that the real WLTP figure appears on the detail page and is fetched by `/ev-detail`.

**Warning signs:** Range figures in the Search Candidates table look lower than expected for a well-known car.

### Pitfall 3: ev-database.org listing returns too many candidates after filtering

**What goes wrong:** Even with body type + seat + range + battery filters applied, the result set is 100+ cars (confirmed: 527 SUVs with 5 seats and range ≥ 300 km). Doing a DK price WebSearch for all 100+ candidates would be too expensive and slow.

**Why it happens:** The brief criteria are broad (body type + seats + range minimum). Many EVs qualify.

**How to avoid:** Add an EUR price pre-filter. Sort candidates by EUR price ascending, cap at 20-25 candidates. For clearly out-of-budget cars (EUR price > 1.5× the brief maximum when converted naively), exclude them before doing DK price searches. The exact cutoff is Claude's discretion (D-Claude's-discretion).

**Warning signs:** The filter step returns 50+ candidates before DK price lookup.

### Pitfall 4: Write-side comparison skill auto-triggers

**What goes wrong:** Claude auto-invokes `/ev-compare` when the user says something like "compare these cars" or "show me a comparison" — overwriting an existing `comparison.md` without explicit user intent.

**Why it happens:** Without `disable-model-invocation: true`, Claude reads the skill description and triggers it in response to natural language triggers.

**How to avoid:** `/ev-compare` MUST have `disable-model-invocation: true` in frontmatter (D-18). User must explicitly type `/ev-compare`.

### Pitfall 5: /ev-compare reads research files from the wrong project

**What goes wrong:** `/ev-compare` reads `research/*.md` from a different project than the active one, or reads across project boundaries (violates PROJ-03).

**Why it happens:** If the Glob pattern is hardcoded (e.g., `research/*.md` without the active project prefix), or if the active project wasn't resolved before Globbing.

**How to avoid:** Step 1 of `/ev-compare` MUST resolve active project from global `state.md` before constructing the Glob path. Pattern must be `projects/<active_project>/research/*.md`.

### Pitfall 6: Search Candidates section clobbers other state.md sections

**What goes wrong:** When updating `state.md` with the Search Candidates section, the Write tool replaces the whole file, losing the Research Progress table and Source Reliability Notes.

**Why it happens:** The skill reads the entire `state.md`, appends/replaces the Search Candidates section, then writes the full file back — but if the read-then-write logic isn't careful, it truncates.

**How to avoid:** The skill must Read `state.md` first, then either: (a) append the section if absent, or (b) replace only the text between `## Search Candidates` and the next `##` heading. Write the full content back. Never overwrite state.md without first reading it.

---

## Code Examples

### Extracting active project from backtick injection

```
# In SKILL.md frontmatter backtick:
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`

# In skill body, Claude reads the injected content:
From the injected global state above, extract the active_project value.
If active_project is "none" or not found: stop and ask user to run /ev-new-project.
```

Source: pattern mirrored from all existing skill files (ev-detail, ev-research, ev-switch-project).

### Detecting "Search Candidates" section exists / overwriting it

```
# Pseudo-logic for Step: update state.md
# 1. Read projects/<active>/state.md
# 2. If "## Search Candidates" is present:
#      Replace from "## Search Candidates" to next "## " heading (or EOF) with new section
# 3. Else:
#      Append new "## Search Candidates" section at end of file
# 4. Write full updated content back
```

### Comparison table column header format (D-16 compliance)

```markdown
| Field | [Car A name] | [Car B name] | [Car C name] |
|-------|-------------|-------------|-------------|
| **Range: WLTP (km)** (manufacturer rated) | 476 | 410 | 402 |
| **Range: real-world mild (km)** (FDM 110km/h, 20°C) | **330** | no FDM test | no FDM test |
| **Range: real-world cold (km)** (FDM 110km/h, 0°C) | 275 | no FDM test | no FDM test |
```

Best-in-class marked bold. Gaps explicit ("no FDM test"). Range methodology labeled in parentheses in row name (D-16).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fetching ev-database.org JS filter page | Parse the server-rendered root page HTML via curl | Confirmed 2026-06-27 (live probe) | Zero JS execution needed; full car database accessible without headless browser |
| Separate sites.md for URL patterns | Inline URL patterns in SKILL.md | Phase 6 (confirmed no sites.md was created) | Simpler — one file per skill, no shared dependency |

**No deprecated patterns** in this phase domain.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The ev-database.org root page HTML structure (jplist hidden spans for shape, battery, range, price) is stable and won't change format between research and implementation | Architecture Patterns / Code Examples | Extraction script breaks silently; would need updating. Low risk — jplist HTML structure is driven by the filter library, not likely to change frequently. |
| A2 | A browser User-Agent of "Mozilla/5.0" (generic) continues to bypass bot detection; stricter UA checking could be added by ev-database.org | Common Pitfalls | curl returns 404 page again; would need to update UA string or escalate to WebFetch with region prompt. |
| A3 | The brief's minimum range requirement maps directly to the erange_real threshold (EVDB standardized range). If the user's range requirement is a real-world range (e.g., "I need 300 km at motorway speed"), the EVDB figure is roughly comparable but not identical. | Architecture Patterns | Borderline cars might pass or fail the filter incorrectly. Mitigated by labeling and surfacing near-misses. |

**All tagged [ASSUMED] claims are training-knowledge-based. No additional user confirmation needed — all three risks are low and the implementation can self-detect failures (e.g., file size check for A1/A2).**

---

## Open Questions

1. **Body type mapping for "SUV / crossover"**
   - What we know: ev-database uses `shape-suv` class for SUVs. Crossovers at ev-database.org appear to be categorized as SUV.
   - What's unclear: Whether "crossover" styled cars (e.g., Renault 4) are tagged `shape-suv` or `shape-hatchback` in the listing.
   - Recommendation: At implementation time, run the extraction for a known crossover model (e.g., Renault 4) and verify its shape class. If it's `shape-hatchback`, the brief mapping needs to include both.

2. **Candidate count cap**
   - What we know: Filtering SUV 5-seat range≥300km gives 527 results; with battery≥50kWh might give ~100-150.
   - What's unclear: The right EUR price pre-filter threshold to get to ≤20 candidates for DK price searches.
   - Recommendation: Start with EUR price ≤ (brief max DKK / 6) as a rough proxy (the Volvo EX30 SM ER ratio is 6.3x). If that leaves >20, tighten range or battery minimums from brief.

3. **Handling per-brand budget overrides in DK price bucketing**
   - What we know: The brief has a per-brand overrides section (e.g., a brand +50% where the user has a discount arrangement).
   - What's unclear: Whether the override is a multiplier on the preferred budget, the maximum, or both.
   - Recommendation: Apply the override to the maximum budget (the ceiling). If "[brand] +50%": that brand's ceiling = brief_max × 1.5. Prefer the maximum as the override anchor since "preferred" is aspirational anyway.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| curl | ev-database HTML fetch | Yes | 8.7.1 | WebFetch with region prompt (higher token cost) |
| python3 | HTML parsing / filtering | Yes | 3.14.6 | Bash grep/sed pipeline (less readable, brittle) |
| Claude WebSearch | DK price per candidate | Yes (native) | — | — |
| Claude Glob | research/*.md discovery in /ev-compare | Yes (native) | — | Bash(ls projects/<active>/research/*.md) |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual golden-run validation (no automated test framework in this project) |
| Config file | none — validation is via skill invocation in Claude Code session |
| Quick run command | `/ev-search` then inspect conversation output and `projects/<active>/state.md` |
| Full suite command | `/ev-search` → pick 2 cars → `/ev-research "A" "B"` → `/ev-compare` → inspect `comparison.md` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRCH-02 | `/ev-search` queries ev-database.org and returns matching models | manual golden-run | `/ev-search` (no args) in active project with brief.md filled | No — Wave 0 creates test project |
| SRCH-03 | Search results include DKK price, range, battery, body type per model | manual golden-run | Inspect Search Candidates table in state.md after SRCH-02 run | No — part of SRCH-02 run |
| COMP-01 | `/ev-compare` reads all research/*.md and generates side-by-side table | manual golden-run | `/ev-compare` after researching ≥2 cars | No — Wave 0 uses existing test-ev-detail-new project |
| COMP-02 | Comparison table labels range methodology per column | manual inspection | Inspect comparison.md for WLTP row label and FDM row label | No — part of COMP-01 run |
| COMP-03 | Comparison output written to active project's `comparison.md` | file existence | `ls projects/<active>/comparison.md` after COMP-01 | No — part of COMP-01 run |

### Sampling Rate

- **Per skill implementation commit:** Invoke the skill once manually and verify output shape.
- **Phase gate:** Full workflow run: `/ev-search` (creates Search Candidates) → `/ev-research "A" "B"` (uses existing test fixtures or runs 2 fresh cars) → `/ev-compare` (writes comparison.md with range rows labeled) → inspect all 3 Success Criteria.

### Wave 0 Gaps

- [ ] Test project setup: create a real project (not test-* fixture) with a filled `brief.md` to validate `/ev-search` against real criteria. Use the user's actual EV search project if one exists, or `/ev-new-project "phase3-test"`.
- [ ] Existing `projects/test-ev-detail-new/` with 3 researched cars is available for `/ev-compare` validation — no new research needed.

*(No automated test framework gaps — this project uses manual golden-run validation consistent with existing Phase 1/2 patterns.)*

---

## Security Domain

> This phase adds two Claude Code skills. No web-accessible endpoints, no authentication, no user data handling. ASVS categories do not apply to offline Claude Code skills operating on local files.

The only security-relevant consideration: the skill fetches `https://ev-database.org` via curl. The URL is hardcoded and the result is parsed as text — no eval, no shell injection, no credential exposure.

---

## Sources

### Primary (HIGH confidence)

- Live probe: `curl -A "Mozilla/5.0" https://ev-database.org` on 2026-06-27 — confirmed 8.9 MB server-rendered HTML with 1,367 jplist car entries; extracted Volvo EX30 SM ER data matching known values. [VERIFIED]
- Live probe: `curl https://ev-database.org` (no UA) on 2026-06-27 — confirmed 64 KB "Page not Found" response, establishing user-agent requirement. [VERIFIED]
- HTML structure analysis: Python3 regex extraction of list-item blocks confirmed all filter data fields (shape-*, seats-*, erange_real, battery hidden, pricefilter hidden). [VERIFIED]
- Live WebSearch: `"Renault 5 52kWh pris DKK"` — snippet confirmed DKK price in result, from DKK 224,990 / 189,990 signals in snippets. [VERIFIED]
- Live WebSearch: `"Volvo EX30 pris DKK 2026"` — snippet confirmed DKK price range 244,900–333,900 DKK. [VERIFIED]
- Project files read: `car-template.md`, `projects/test-ev-detail-new/state.md`, `projects/test-ev-detail-new/brief.md`, `projects/test-ev-detail-new/research/volvo-ex30.md` — confirmed field set, state.md section structure, live research file format. [VERIFIED]
- Existing skills read: `ev-detail/SKILL.md`, `ev-research/SKILL.md`, `ev-new-project/SKILL.md`, `ev-switch-project/SKILL.md` — confirmed frontmatter patterns, backtick injection, step conventions. [VERIFIED]

### Secondary (MEDIUM confidence)

- CONTEXT.md decisions D-01..D-18 (from prior /gsd:discuss-phase session) — user-locked decisions, treated as authoritative constraints.
- ev-database.org jplist library pattern: client-side filtering via CSS classes on server-rendered HTML is a documented jplist v1.x pattern; the data-jplist-item structure is standard. [ASSUMED — pattern recognized from inspection, not from jplist docs]

### Tertiary (LOW confidence)

- Body type class completeness: the set of `shape-*` classes extracted from the live HTML (shape-suv, shape-hatchback, shape-sedan, shape-station, shape-liftback, shape-mpv, shape-pickup, shape-coupe, shape-cabrio, shape-spv) was extracted from live data and appears complete, but ev-database may add new body types without notice.

---

## Metadata

**Confidence breakdown:**
- Discovery mechanism: HIGH — live probe confirmed, code verified, data extraction tested.
- DK price band approach: HIGH — live WebSearch confirmed DK prices in snippets.
- ev-compare structure: HIGH — car-template.md read directly, field set confirmed.
- Skill frontmatter patterns: HIGH — mirrored from existing working skills.
- Candidate count / filtering thresholds: MEDIUM — filter logic confirmed working but optimal thresholds (candidate cap, EUR pre-filter cutoff) are discretion items.

**Research date:** 2026-06-27
**Valid until:** 2026-09-27 (90 days — ev-database.org HTML structure is stable; DK price snippets will still work; price figures will be stale after ~30 days but bucketing approach is robust to that)
