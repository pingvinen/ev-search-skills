# Phase 2: Detail Skill - Research

**Researched:** 2026-06-22
**Domain:** Claude Code skill authoring + multi-source EV data fetching (ev-database.org, FDM, Bilbasen, wheel-size.com)
**Confidence:** HIGH for ev-database.org/FDM patterns (live-verified); MEDIUM for Bilbasen market-range approach; LOW for greengarage.dk (404 on model pages)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** Phase 2 is the detail skill only. `/ev-detail` captures tire **size** (front/rear if different) per TIRE-01. No tire pricing, no scoring, no recommendations in this phase.

**D-02** The global `/ev-tire-sources` skill, median-of-histogram scoring, and top-3 tire recommendations (TIRE-04..07) + tire pricing (TIRE-02) and the tire-research prompt (TIRE-03) are deferred to their own future phase.

**D-03** ev-database.org specs are **mandatory**. If the car cannot be found there, abort with a clear message — do not write a file.

**D-04** FDM (via WebSearch→fetch), greengarage.dk, and used/leasing market pricing are **best-effort**. When a best-effort source yields nothing, write the file anyway with the gap explicitly noted (e.g., "No FDM test found as of [date]") per DETL-08.

**D-05** When a car name maps to multiple ev-database.org variants, auto-select the variant that **best matches the active project's BRIEF** (budget, range, must-haves). Document the chosen variant and note that other variants existed.

**D-06** Tie-breaker: prefer the **middle tier**. Where a model historically has 3 variants, the middle one has tended to offer the best value for money.

**D-07** `/ev-detail` branches on the project's `purchase_type` (read from BRIEF.md):
- `new` → tier 1 ("from") and tier 2 (best-value) DKK pricing (DETL-09).
- `used` → Bilbasen-derived **market price range** (low / typical / high) for the model — NOT a specific listing.
- `leasing` → typical **monthly payment + residual range** — NOT a specific offer.

**D-08** Used/leasing pricing is captured as a representative **market range**, not specific (stale-prone) individual listings.

**D-09** When a research file already exists for the requested car in the active project, **detect it and ask the user** whether to overwrite, skip, or update-in-place. Never clobber silently.

**D-10** No training data for specs (DETL-04). Every fact traces to a source URL + fetch date in the file's Sources section (DETL-05). Ownership signals labeled with confidence level + source (OWNR-01, OWNR-05 intent).

### Claude's Discretion

- FDM article discovery strategy (WebSearch query patterns, how many attempts before declaring "no test found").
- How aggressively to use greengarage.dk (best-effort, fetch-safety unverified — probe at implementation).
- ev-database.org token-ceiling mitigation (category-specific / per-car URLs vs `max_content_tokens`).
- Exact wording of confidence labels and per-section guidance already present in `car-template.md`.
- Filename normalization for `<make-model>.md` (e.g., `volvo-ex30.md`).
- Per-project `state.md` update format when recording a researched car.

### Deferred Ideas (OUT OF SCOPE)

- Tire pricing + tire-research prompt (TIRE-02, TIRE-03).
- Global `/ev-tire-sources` skill + median-of-histogram scoring + top-3 recommendations (TIRE-04..07) — its own future phase.
- ROADMAP/REQUIREMENTS reconciliation: move TIRE-02..07 out of Phase 2 before verification.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DETL-01 | Detail skill fetches deep specs from ev-database.org for a named car model | ev-database.org URL pattern verified; variant discovery via WebSearch confirmed |
| DETL-02 | Per-car markdown file written to active project's `research/<make-model>.md` with standardized sections | Filename normalization pattern defined; Write tool approach confirmed |
| DETL-03 | Per-car file includes WLTP range, charging specs, battery, performance, dimensions, cargo, DKK price | ev-database.org live-verified to expose all these fields |
| DETL-04 | All data fetched live at runtime — no training data used for specs | Skill prompt discipline pattern defined |
| DETL-05 | Every fact in per-car file cites source URL and fetch date | Sources table from car-template.md; pattern confirmed |
| DETL-06 | FDM real-world Danish range at 110 km/h extracted from FDM test articles (when available) | FDM articles live-verified to expose measured range at 110 km/h |
| DETL-07 | FDM qualitative verdict and pros/cons captured (when available) | FDM articles expose styrker/svagheder + verdict |
| DETL-08 | Skill handles missing FDM article gracefully (notes "no FDM test found") | Explicit gap-note pattern defined |
| DETL-09 | Per-car file includes tier 1 ("from price") and tier 2 (best-value) DKK prices | car-template.md already has these rows; sourcing via manufacturer sites |
| DETL-10 | Per-car file notes whether car is built on a dedicated EV platform or adapted ICE | ev-database.org "EV Dedicated Platform: Yes/No" field verified present |
| TIRE-01 | Per-car file captures tire size measurements (front and rear if different) | wheel-size.com verified accessible and data-rich; ev-database.org does NOT have tire sizes |
| OWNR-01 | Per-car file includes reliability reputation from FDM review narrative | FDM articles contain qualitative ownership notes inline with pros/cons |
| SRCH-07 | Purchase type influences which data sources and price fields are relevant | Three-branch pattern defined: new/used/leasing |
</phase_requirements>

---

## Summary

The `/ev-detail` skill fetches deep specs for a single named car from ev-database.org (mandatory primary source), FDM test articles (best-effort via WebSearch → WebFetch), and tire size from wheel-size.com (best-effort fallback). It then writes a per-car markdown file conforming to `car-template.md` into the active project's `research/` folder and updates the per-project `state.md`. The skill runs in `context: fork` + Explore agent to isolate multi-URL fetching from the main session.

The most critical technical findings from live verification: (1) ev-database.org does NOT include tire sizes on car pages — a dedicated fallback to wheel-size.com is required for TIRE-01; (2) the EX30 has 5+ separate ev-database.org entries (different IDs per variant) with no variant picker on the page itself — variant discovery must go through WebSearch; (3) FDM articles reliably expose measured range at 110 km/h, charging performance, pros/cons, and DKK pricing in server-rendered HTML accessible via WebFetch; (4) Bilbasen blog posts (not listing pages) are the reliable source for used market price ranges since the listing page itself did not render content to WebFetch; (5) greengarage.dk model-specific pages (e.g. `/volvo-ex30`) return 404 — the source is effectively unavailable except for a small set of dealer inventory pages.

**Primary recommendation:** Build the skill as a sequential step-numbered procedure: resolve name → discover variants via WebSearch → select best variant per BRIEF → fetch ev-database.org per-car page → attempt FDM discovery (2 WebSearch queries, 1 fetch attempt) → fetch tire size from wheel-size.com → branch on purchase_type for pricing → write file → update state.md.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Free-text car name → ev-database.org URL(s) | Skill (Claude reasoning) | WebSearch for discovery | No search API on ev-database.org; WebSearch returns the /car/{ID}/{Make-Model} URLs in result titles |
| Variant selection (D-05/D-06) | Skill (Claude reasoning) | BRIEF.md as input | Pure reasoning task — compare variant specs against BRIEF budget/range, apply middle-tier tie-breaker |
| Deep spec fetch | WebFetch (ev-database.org per-car URL) | — | Server-rendered HTML, high reliability, all spec fields present |
| FDM article URL discovery | WebSearch | — | FDM listing is a JS SPA; only individual article pages are WebFetch-able |
| FDM article content fetch | WebFetch | — | Individual FDM articles are server-rendered and freely accessible |
| Tire size lookup | wheel-size.com via WebFetch | Manufacturer spec sheet | ev-database.org confirmed to NOT include tire sizes |
| Used market price range | Bilbasen Blog articles via WebSearch + WebFetch | — | Bilbasen listing page did not render to WebFetch; blog articles have market-range summaries |
| Leasing price range | FDM leasing overview / Bilbasen Blog via WebSearch + WebFetch | — | Static editorial articles have representative market-range data |
| File write + state update | Write tool (Claude Code) | — | Native to skill environment |
| Re-run detection (D-09) | Bash(ls) + Skill (ask user) | — | Check file existence before any fetching |

---

## Standard Stack

### Core Technologies

| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| Claude Code skills | Current | Skill definition and invocation | Native to environment; `.claude/skills/<name>/SKILL.md` → `/slash-command` |
| WebFetch tool | `web_fetch_20260209` | Fetch server-rendered pages (ev-database.org, FDM articles, wheel-size.com, Bilbasen blog) | Built-in; HTML→text extraction; supports `max_content_tokens` filter |
| WebSearch tool | Native | Discover ev-database.org variant URLs; find FDM article slugs | Handles JS SPAs indirectly by hitting Google's index |
| Read tool | Native | Read global `state.md`, per-project `state.md`, `BRIEF.md`, existing research file | Native file access |
| Write tool | Native | Write `research/<make-model>.md`, update `state.md` | Native file write |
| Bash tool | macOS built-in | `ls` for re-run detection; curl fallback if WebFetch is blocked | Available in all Claude Code sessions |
| Markdown files | Plain text | Per-car output (`research/*.md`), state tracking | Zero dependencies; machine-readable for downstream `/ev-compare` |

**No external packages.** This is a Claude Code skill, not a Node.js project.

### Fetch Strategy by Source

| Source | Method | Reliability | Notes |
|--------|--------|-------------|-------|
| ev-database.org per-car page | WebFetch directly | HIGH [VERIFIED: live fetch 2026-06-22] | Server-rendered HTML; permissive robots.txt |
| ev-database.org listing/filter | WebSearch to get variant URLs | HIGH | No URL-based search; filter UI is JS-driven |
| FDM article | WebSearch slug → WebFetch article | MEDIUM [VERIFIED: live fetch 2026-06-22] | Listing is SPA; individual articles are server-rendered |
| wheel-size.com | WebFetch directly | HIGH [VERIFIED: live fetch 2026-06-22] | Server-rendered; tire sizes by year/make/model |
| Bilbasen listing page | NOT viable | LOW | Did not render to WebFetch |
| Bilbasen Blog | WebSearch → WebFetch article | MEDIUM [VERIFIED: live fetch 2026-06-22] | Static editorial content with market-range summaries |
| greengarage.dk model pages | NOT viable | NONE [VERIFIED: 404 on live fetch 2026-06-22] | `/volvo-ex30` returns 404; only inventory pages exist |
| greengarage.dk artikler/ | Potentially viable but LOW priority | LOW | Generic guides only; no per-model editorial reviews found |

---

## Architecture Patterns

### System Architecture Diagram

```
User invokes /ev-detail "Volvo EX30"
          |
          v
[Step 1] Read global state.md → active_project name
[Step 2] Read projects/<active>/BRIEF.md → budget, range, purchase_type
[Step 3] Read projects/<active>/state.md → existing research progress
          |
          v
[Step 4] Re-run detection: Bash(ls projects/<active>/research/<filename>.md)
         → File exists? Ask user: overwrite / skip / update
          |
          v
[Step 5] DISCOVER VARIANTS (WebSearch)
         Query: "ev-database.org <make> <model> specifications"
         → Returns URLs: /car/{ID}/{Make-Model-Variant}
         → Multiple URLs = multiple variants
          |
          v
[Step 6] SELECT VARIANT (Claude reasoning)
         Compare variant specs (battery size, range, price) against BRIEF
         Apply BRIEF budget/range first; middle-tier tie-breaker if ambiguous
         Document: "Selected <variant> from [list of variants]. Reason: <..."
          |
          v
[Step 7] FETCH SPECS — ev-database.org (mandatory)
         WebFetch https://ev-database.org/uk/car/{ID}/{Make-Model}
         Extract: WLTP range, real-world range mild/cold, battery kWh,
                  DC peak kW, AC kW, 10-80% min, 0-100s, cargo L,
                  tow capacity kg, power kW, platform type, dimensions
         If page not found or car not found: ABORT with clear message
          |
          v
[Step 8] FETCH FDM TEST (best-effort, 2-attempt limit)
         Attempt 1: WebSearch "site:fdm.dk/tests <make> <model> biltest"
         Attempt 2 (if no result): WebSearch "fdm.dk <make> <model> test"
         If URL found: WebFetch article URL
         Extract: measured range at 110 km/h, cold range, DC/AC kW,
                  verdict, styrker, svagheder, DKK prices, publication date
         If no URL found or fetch fails: note "No FDM test found as of [date]"
          |
          v
[Step 9] FETCH TIRE SIZE (best-effort)
         WebFetch https://www.wheel-size.com/size/<make>/<model>/<year>/
         Extract: OEM front tire size, rear tire size (if different)
         If page fails: note "Tire size not confirmed — check manufacturer spec sheet"
          |
          v
[Step 10] PURCHASE-TYPE BRANCH (from BRIEF.md purchase_type)
         new     → fetch tier 1 and tier 2 DKK prices from manufacturer DK website
         used    → WebSearch "bilbasen <make> <model> brugt pris" → WebFetch Bilbasen Blog
                   Extract: low / typical / high DKK range from market summary
         leasing → WebSearch "lease <make> <model> månedlig DKK 2025" → WebFetch article
                   Extract: typical monthly DKK + upfront + residual range
          |
          v
[Step 11] GREENGARAGE PROBE (optional, best-effort)
         WebFetch https://greengarage.dk/<make>-<model>/
         If 404: skip silently; do not note as gap (source known to be sparse)
         If content: extract ownership/practical notes only
          |
          v
[Step 12] WRITE FILE
         Path: projects/<active>/research/<make-model>.md
         Template: car-template.md sections (mandatory structure)
         Every fact → Sources table row with URL + fetch date
          |
          v
[Step 13] UPDATE STATE
         Append row to projects/<active>/state.md Research Progress table:
         | <make-model> | research/<make-model>.md | <date> | <yes/no/partial> |
         Note any source reliability observations in "Source Reliability Notes"
          |
          v
[Step 14] CONFIRM to user
         File written: projects/<active>/research/<make-model>.md
         Variant selected: <name> (reason)
         FDM: found / not found
         Gaps (if any): list missing fields
```

### Recommended Skill Structure

```
.claude/skills/
└── ev-detail/
    └── SKILL.md        # All steps inline; skill is ~200-300 lines
```

No supporting files needed — the skill is self-contained. `car-template.md` is the output contract (already exists at repo root).

### Frontmatter Pattern (mirrors ev-new-project/ev-switch-project)

```yaml
---
name: ev-detail
description: Research a specific EV model in depth. Use when the user asks to research a car, fetch specs for a model, or add a car to the project. Writes a sourced per-car file to the active project.
allowed-tools: WebFetch, WebSearch, Read, Write, Bash(ls *)
context: fork
agent: Explore
argument-hint: [car-model]
---
```

**Note:** `disable-model-invocation: true` is NOT used here — `/ev-detail` is explicitly user-invoked. The description controls auto-trigger behavior.

### Backtick Injection Pattern

```
Current global state:
!`cat state.md 2>/dev/null || echo "No active project — run /ev-new-project first"`

Car to research: $ARGUMENTS
```

This injects `active_project` at invocation time. The skill then reads BRIEF.md and per-project state.md inside the step body using Read tool calls.

### Anti-Patterns to Avoid

- **Fetching ev-database.org listing page for variant discovery:** The main listing is JS-filtered; filtered URLs like `?make=Volvo` return incomplete results. Use WebSearch instead.
- **WebFetch on Bilbasen listing pages:** The listing page (`bilbasen.dk/brugt/bil/volvo/ex30`) did not render content to WebFetch. Use Bilbasen Blog or WebSearch for market-range data.
- **Hardcoding tire size:** Tire sizes vary by trim — always fetch from wheel-size.com with the model year, not from training data.
- **Using greengarage.dk model pages as a source:** Model-specific pages (e.g. `/volvo-ex30`) return 404. Do not include greengarage.dk as an expected source in the SKILL.md prompt; treat it as truly optional probe.
- **Fetching multiple ev-database.org variant pages speculatively:** Fetch only the one selected variant. Token budget is limited in fork context.

---

## Open Technical Questions Resolved

### 1. ev-database.org: URL Pattern and Variant Discovery [VERIFIED: live fetch 2026-06-22]

**URL pattern:** `https://ev-database.org/uk/car/{ID}/{Make-Model-Variant}`

- `{ID}` is a numeric ID unique per variant (not per model family)
- `{Make-Model-Variant}` is a hyphenated slug: `Volvo-EX30-Single-Motor-ER`
- Variants of the same model have DIFFERENT IDs. Example: EX30 Single Motor = ID 1909, Single Motor ER = ID 1910, Twin Motor Performance = ID 1911

**Variant discovery strategy (D-05/D-06):**

ev-database.org has no URL-based search and the listing page filter UI is JavaScript-driven (returns incomplete results to WebFetch). The reliable discovery path is:

```
WebSearch query: "ev-database.org <make> <model> specifications"
```

This returns multiple result URLs with the exact `/car/{ID}/{Make-Model-Variant}` pattern in the page titles. Example output for "Volvo EX30":
- `https://ev-database.org/car/1910/Volvo-EX30-Single-Motor-ER`
- `https://ev-database.org/car/1909/Volvo-EX30-Single-Motor`
- `https://ev-database.org/uk/car/1911/Volvo-EX30-Twin-Motor-Performance`
- `https://ev-database.org/uk/car/3118/Volvo-EX30-Cross-Country`
- `https://ev-database.org/car/3480/Volvo-EX30-P5-Long-Range`

The skill does NOT need to fetch each variant page. The URLs themselves encode the variant name. Claude can reason about which variant to select based on URL slug alone (battery size visible in slug) and BRIEF budget/range, then fetch only the chosen page.

**Middle-tier tie-breaker (D-06):** When three standard variants are present (e.g., SR/LR/Performance or Standard/Plus/Ultra), prefer the second (middle) entry by battery size or price tier. When only two variants exist, prefer the larger battery if budget allows.

**Token mitigation:** Each ev-database.org car page is moderate size (~10-15k tokens). With `context: fork` and fetching only one variant page, no `max_content_tokens` truncation is needed for the car page itself. Apply `max_content_tokens` only if fetching the listing page (which is rarely needed given the WebSearch discovery approach).

### 2. Spec Fields Available on ev-database.org Car Pages [VERIFIED: live fetch 2026-06-22]

All required fields are present. Confirmed by fetching `/uk/car/1910/Volvo-EX30-Single-Motor-ER`:

| car-template.md field | ev-database.org label | Present? |
|----------------------|----------------------|---------|
| WLTP range | Range (WLTP) | YES |
| Real-world range (mild) | EVDB Real Range | YES |
| Real-world range (cold) | Real Range (Cold) | YES |
| Battery usable kWh | Useable Battery Capacity | YES |
| DC charge peak kW | Rapid Charging (DC max) | YES |
| AC charge rate kW | Home Charging (AC max) | YES |
| 10-80% DC charge time | 10-80% charge time | YES |
| 0-100 km/h | 0-62 mph | YES (convert) |
| Cargo L | Boot space | YES |
| Tow capacity kg | Towing Capacity (braked) | YES |
| Power output kW | Max Power | YES |
| EV platform | EV Dedicated Platform: Yes/No | YES + platform name |
| Tire size | **NOT PRESENT** | NO |

**Tire size gap:** ev-database.org does not expose tire specifications. wheel-size.com does. [VERIFIED: live fetch 2026-06-22]

### 3. FDM Article Discovery Strategy [VERIFIED: live fetch 2026-06-22]

**Working query pattern:**
```
WebSearch: "site:fdm.dk/tests biltest <make> <model>"
```

This reliably returns article URLs following the pattern `fdm.dk/tests/biltest/<slug>`. Multiple FDM tests may exist for the same model (different model years or re-tests). The skill should take the most recent article — identifiable by article date in the URL slug or by the publication date in the fetched content.

**Two-attempt limit (Claude's Discretion recommendation):**
1. Attempt 1: `site:fdm.dk/tests biltest <make> <model>`
2. Attempt 2 (if no result): `fdm.dk <make> <model> elbil test` (broader, drops `site:`)

After two WebSearch attempts with no result, write "No FDM test found as of [date]" in the FDM Test Notes section. Do not attempt further searches — FDM coverage is genuine (many models tested), so if two queries fail, the test likely does not exist.

**Article fetch reliability:** FDM articles are free, server-rendered, and accessible via WebFetch. [VERIFIED: two articles successfully fetched 2026-06-22]

**Fields extractable from FDM articles:**
- Measured range at 110 km/h, 20°C (the primary "real-world range" figure)
- Measured range at 0°C (cold weather)
- DC peak charge rate (kW, measured — may differ from claimed)
- AC charge rate (kW)
- Km recovered per 15/30 min charge (where present)
- Verdict (narrative recommendation, e.g., "anbefalelsesværdig")
- Styrker (strengths, bulleted)
- Svagheder (weaknesses, bulleted)
- DKK prices (base and tested trim)
- Private lease monthly price (where included)
- Publication date (important for source citation)

**Ownership signals (OWNR-01):** FDM verdict + pros/cons are the primary source of reliability reputation. These are qualitative narrative texts, not scores. Label them with confidence level: `HIGH (FDM test, [date])`.

### 4. Tire Size Source [VERIFIED: live fetch 2026-06-22]

**wheel-size.com** is accessible via WebFetch and exposes OEM tire fitment data by make/model/year.

URL pattern: `https://www.wheel-size.com/size/<make>/<model>/<year>/`

Example: `https://www.wheel-size.com/size/volvo/ex30/2024/` returns:
- Single Motor (268hp): OEM sizes 225/55R18 and 245/45R19 (multiple rim options)
- All configurations use identical front and rear sizes for EX30

Data is updated regularly (page showed "Last Update: June 20, 2026"). This is the recommended tire size source since ev-database.org does not carry this data.

**Skill instruction:** The skill should fetch the wheel-size.com page for the model year being researched. If the page returns 404 (uncommon for established models), note "Tire size unconfirmed — check manufacturer spec sheet."

**Front vs rear:** For most EVs, front and rear tires are the same size (as verified for EX30). Only fill in `Tire size (rear)` when the page shows a different rear size (performance variants sometimes differ).

### 5. Bilbasen / Used Market Price Range [VERIFIED: live fetch 2026-06-22]

**Bilbasen listing page (`bilbasen.dk/brugt/...`):** Did NOT render usable content via WebFetch in testing. Do not instruct the skill to fetch listing pages directly.

**Bilbasen Blog (`blog.bilbasen.dk`):** Server-rendered editorial content. Successfully fetched. Contains market-range summaries derived from listing data. These articles are the correct approach for extracting a low/typical/high market price range.

**Discovery pattern for used pricing:**
```
WebSearch: "bilbasen <make> <model> brugt pris" OR "bilbasen <make> <model> brugtkøb"
```

This reliably returns Bilbasen Blog articles with market analysis. The article for EX30 yielded:
- Low: ~220,000 DKK
- Typical: 220,000–230,000 DKK (Extended Range models)
- High: up to 278,900 DKK (near-new, low mileage)

**Caveat:** Bilbasen Blog articles are static and become stale. The skill must note the article's publication date alongside the market range figures. The format in the file should be:
```
Used market range (as of [article date]): 220,000–230,000 DKK typical; see bilbasen.dk for current listings
```

**autouncle.dk as supplement:** Also returns in WebSearch results. Contains average prices. Can be used as a secondary check. WebFetch accessibility not verified.

### 6. Leasing Price Range [VERIFIED: partial — Bilbasen Blog and FDM accessible]

**Source approach:** Bilbasen Blog (`blog.bilbasen.dk`) and FDM leasing overviews (`fdm.dk/nyheder`) both publish periodic "what you get for X DKK/month" articles. These are the best available sources for representative monthly payment ranges.

**FDM leasing overview** (`fdm.dk/nyheder/nyt-om-trafik-og-biler/kaempe-2026-oversigt-se-alle-leasingtilbud-rabatter-og-kampagner-paa-nye-biler`): Updated periodically; covers current campaign prices. WebFetch accessibility not individually verified but FDM pages generally accessible.

**Discovery pattern for leasing pricing:**
```
WebSearch: "lease <make> <model> månedlig DKK 2025" OR "privatleasing <make> <model>"
```

**Data format in file:** The skill should capture the monthly range as:
```
Leasing: from ~X,XXX DKK/month (Y,XXX km/year, Z months) as of [source date]; market range X–X DKK/month
```

Residual value is NOT a published figure in Danish privatleasing (the leasing company absorbs the depreciation risk — this was confirmed by the Bilbasen Blog article). Do not attempt to capture a residual value figure. Instead, note the depreciation risk context.

### 7. EV Platform Signal [VERIFIED: live fetch 2026-06-22]

ev-database.org exposes a labeled field: **"EV Dedicated Platform: Yes"** with the platform name in parentheses (e.g., "Geely SEA2" for EX30 ER, or "CMF-EV" for Renault 5). This is the authoritative source per D-10.

Format in car-template.md: `**EV platform:** Dedicated EV platform (Geely SEA2)` or `**EV platform:** Adapted ICE platform ([name])`

### 8. Re-run / Overwrite Detection (D-09) [ASSUMED — pattern fits Claude Code skill conventions]

The `ev-new-project` skill already uses this pattern for project creation:

```
Run Bash(ls projects/$ARGUMENTS/ 2>/dev/null).
If the directory EXISTS: Stop immediately and ask the user.
```

The same pattern applies for file detection in `/ev-detail`:

```
Run Bash(ls projects/<active>/research/<filename>.md 2>/dev/null).
If the file EXISTS: Tell the user the file already exists and ask:
  - "overwrite" — re-fetch all sources and replace the file
  - "skip" — exit without changes
  - "update" — re-fetch and add/update specific sections (advanced)
Wait for user response before proceeding.
```

Recommendation: support "overwrite" and "skip" in Phase 2; defer "update-in-place" (complex diffing logic) to a future enhancement.

### 9. Filename Normalization (Claude's Discretion) [ASSUMED — follows STACK.md convention]

The STACK.md research already defines: "Naming convention: lowercase, hyphenated. `research/renault-5-52kwh.md`, `research/volvo-ex30.md`."

**Normalization rules:**
1. Lowercase the full model name
2. Replace spaces and special characters with hyphens
3. Strip parentheses, slashes, dots (except to preserve version numbers where meaningful)
4. Trim leading/trailing hyphens
5. Battery variant in filename: include only if the user's argument specified it (e.g., `/ev-detail "Renault 5 52kWh"` → `renault-5-52kwh.md`; `/ev-detail "Renault 5"` → `renault-5.md`)

Examples:
- "Volvo EX30" → `volvo-ex30.md`
- "Renault 5 52kWh" → `renault-5-52kwh.md`
- "BMW iX1 xDrive" → `bmw-ix1-xdrive.md`
- "Mercedes-Benz CLA 250+" → `mercedes-benz-cla-250plus.md`

The skill should derive the filename from the `$ARGUMENTS` input, then confirm the chosen filename to the user in Step 14.

### 10. Per-Project state.md Update Format (Claude's Discretion) [VERIFIED: format from existing template]

The per-project `state.md` already has a Research Progress table with these columns:

```markdown
| Car model | File | Researched | FDM found |
|-----------|------|------------|-----------|
```

The skill should append one row per researched car:

```markdown
| Volvo EX30 Single Motor ER | research/volvo-ex30.md | 2026-06-22 | yes (2026-03-17) |
```

For "FDM found" values:
- `yes (YYYY-MM-DD)` — article found and fetched, article date in parentheses
- `no` — two WebSearch attempts made, no article found
- `partial` — article found but fetch failed

Also append to "Source Reliability Notes" any fetch-time observations (e.g., "wheel-size.com: loaded correctly for EX30 2024").

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tire size data | Custom tire size database or training data | wheel-size.com via WebFetch | ev-database.org has no tire data; wheel-size.com is maintained, accurate, and WebFetch-accessible |
| Used market prices | Scraping Bilbasen listing pages | Bilbasen Blog articles via WebSearch | Listing page does not render to WebFetch; blog articles provide summarized market-range data |
| Model variant picker | Custom UI or multi-page fetch | Claude reasoning from WebSearch URL slugs + BRIEF | URL slugs expose variant names; no need to fetch all variant pages to pick one |
| FDM article listing | Fetching `fdm.dk/tests/biltest` index | WebSearch `site:fdm.dk/tests biltest <model>` | FDM listing is a JS SPA; WebFetch returns empty article cards |
| State persistence | External database or JSON | Per-project `state.md` append via Write | Markdown is native to Claude Code; diffs cleanly; already has the table structure |

---

## Common Pitfalls

### Pitfall 1: Fetching ev-database.org listing/filter page for discovery

**What goes wrong:** `WebFetch https://ev-database.org/uk/?make=Volvo` returns a JS-driven filter result that contains only a subset of models (or none for older model years now "discontinued"). The EX30 MY24-26 did not appear in filtered results during testing.

**Why it happens:** ev-database.org uses JavaScript to render filtered results; WebFetch gets the pre-filter HTML.

**How to avoid:** Always use WebSearch to discover variant URLs. The query `"ev-database.org <make> <model> specifications"` returns Google-indexed pages with exact `/car/{ID}/{slug}` URLs in titles.

**Warning signs:** WebFetch of listing returns ≤3 Volvo models; EX30 variants are absent.

### Pitfall 2: Fetching multiple ev-database.org variant pages to compare specs

**What goes wrong:** Token budget exhausted in `context: fork` session after fetching 3-5 variant pages.

**Why it happens:** Each page is ~10-15k tokens. Fetching 5 variants = 50-75k tokens before writing begins.

**How to avoid:** The variant selection reasoning should happen BEFORE any fetching. Use WebSearch result URLs + URL slug analysis (battery/trim names visible in the slug) + BRIEF budget to pick ONE variant. Fetch only that one page.

### Pitfall 3: Treating greengarage.dk model pages as reliable

**What goes wrong:** Skill prompts Claude to attempt `WebFetch greengarage.dk/<make>-<model>/` expecting a model review page. Returns 404.

**Why it happens:** greengarage.dk model-specific pages (`/volvo-ex30`, `/renault-5`) return HTTP 404. Only their inventory/article pages exist for a small set of models.

**How to avoid:** Remove greengarage.dk from the mandatory source list entirely. If included at all, use only as a truly optional probe with silent 404 handling. Do not log a "gap" when greengarage.dk 404s.

### Pitfall 4: Confusing ev-database.org UK vs non-UK URLs

**What goes wrong:** WebSearch may return a mix of `/car/{ID}/...` (default, EUR-priced) and `/uk/car/{ID}/...` (GBP-priced) URLs for the same variant. Fetching the non-UK URL gives EUR pricing, not GBP.

**Why it happens:** ev-database.org has regional versions. WebSearch results include both.

**How to avoid:** The pricing in the file is DKK (from Danish manufacturer site, not from ev-database). For spec data, either URL works — spec values are identical across regional versions. Prefer `/uk/` URLs since that's what the skill has been validated against. Note that price fields on ev-database.org pages are NOT the source of DKK pricing — use manufacturer's Danish website for that.

### Pitfall 5: Treating FDM measured DC kW as the car's spec

**What goes wrong:** FDM may report a measured DC charge peak lower than the manufacturer spec (e.g., EX30: claimed 153 kW, FDM measured 102 kW). Treating the FDM figure as the spec creates misleading data.

**Why it happens:** FDM reports what they measured under their test conditions; ev-database.org reports the manufacturer's rated peak.

**How to avoid:** Always record both values separately and label each with its source:
- `DC charge peak (kW): 153` — source: ev-database.org
- `DC charge peak measured by FDM: 102 kW` — in FDM Test Notes section only

### Pitfall 6: FDM range at 110 km/h conflated with WLTP

**What goes wrong:** FDM measures range at 110 km/h (Danish motorway speed) in real conditions. WLTP is a controlled-cycle test. These MUST be labeled separately in the file.

**How to avoid:** car-template.md already has separate rows for WLTP range and real-world range. The WLTP row gets ev-database.org data; the real-world row gets FDM's measured figure. The skill instructions must explicitly forbid averaging them.

---

## Code Examples

### Frontmatter for ev-detail

```yaml
---
name: ev-detail
description: Research a specific EV model in depth. Use when the user asks to research a car, fetch specs for a model, or add a car to the active project. Writes a sourced per-car file to the active project.
allowed-tools: WebFetch, WebSearch, Read, Write, Bash(ls *)
context: fork
agent: Explore
argument-hint: [car-model]
---
```

[VERIFIED: mirrors pattern from ev-new-project/ev-switch-project, confirmed conventions 2026-06-22]

### Backtick injection at invocation

```
Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found — no active project. Run /ev-new-project first."`

Car to research: $ARGUMENTS
```

[VERIFIED: pattern from ev-switch-project/SKILL.md, 2026-06-22]

### Re-run detection step

```
**Step N — Check for existing research file**

Derive the filename: lowercase $ARGUMENTS, replace spaces with hyphens.
Run Bash(ls projects/<active_project>/research/<filename>.md 2>/dev/null).

If the file EXISTS:
> A research file already exists for this car: `research/<filename>.md`
> What would you like to do?
> - **overwrite** — re-fetch all sources and replace the file
> - **skip** — keep the existing file, no changes
>
> Reply with "overwrite" or "skip".

Wait for user response. Do not proceed until response received.
```

[ASSUMED — pattern follows ev-new-project overwrite guard convention]

### Variant selection step

```
**Step N — Discover variants on ev-database.org**

Run WebSearch: "ev-database.org <make> <model> specifications"

From the search results, extract all URLs matching pattern:
  https://ev-database.org/[uk/]car/{ID}/{Make-Model-Variant}

List the variants found. For each variant, note the battery/trim from its URL slug.

**Step N+1 — Select best variant**

Compare variants against BRIEF:
- Budget: prefer the variant whose estimated price fits within budget
- Range: prefer variants meeting the minimum range requirement
- Tie-breaker (D-06): when ambiguous, prefer the middle tier by battery size or price

State your selection clearly:
> Selected variant: <name> (ID: <ID>)
> Reason: <why — budget match / range / middle-tier tie-breaker>
> Other variants considered: <list>

Then fetch ONLY the selected variant's page.
```

[VERIFIED: variant IDs confirmed via live WebSearch 2026-06-22]

### wheel-size.com tire fetch

```
**Step N — Fetch tire size**

From the ev-database.org page, note the model year (MY).

WebFetch https://www.wheel-size.com/size/<make-lowercase>/<model-lowercase>/<year>/

Example: https://www.wheel-size.com/size/volvo/ex30/2024/

Extract:
- OEM front tire size (marked "OE")
- OEM rear tire size (if different from front)

If page returns 404: write "Tire size: unconfirmed — check manufacturer spec sheet"
If front == rear: write same size in both rows, add note "(square setup)"
```

[VERIFIED: wheel-size.com accessed successfully 2026-06-22, returned OEM sizes for EX30 2024]

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| WebFetch tool | ev-database.org, FDM, wheel-size.com, Bilbasen Blog fetches | YES | `web_fetch_20260209` | Bash + curl with HTML stripping |
| WebSearch tool | Variant discovery, FDM slug discovery, market price articles | YES | Native | None needed |
| Write tool | File output (`research/*.md`, state updates) | YES | Native | None |
| Read tool | state.md, BRIEF.md, existing research files | YES | Native | None |
| Bash tool | Re-run detection (`ls`), curl fallback | YES | macOS built-in | Skip detection step |
| wheel-size.com | Tire size (TIRE-01) | YES | Live site | Manufacturer spec PDF (manual) |
| Bilbasen Blog | Used market ranges (SRCH-07 used branch) | YES | Live site | autouncle.dk (not verified) |
| greengarage.dk model pages | Optional ownership supplement | NO (404) | — | Skip entirely |

**Missing dependencies with no fallback:** None that block the core skill. Greengarage.dk model pages are verified unusable but this was already a best-effort source per D-04.

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

This skill produces a markdown file; it has no unit tests in the traditional sense. Validation is done by observing the output of a real run against a known car.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual golden-run validation (no test runner; Claude Code skill output is markdown) |
| Config file | none — validation is observational |
| Quick run command | `/ev-detail "Volvo EX30"` in a Claude Code session with an active project |
| Full suite command | Run against 3 cars: Volvo EX30 (strong FDM coverage), Renault 5 (FDM exists), one car with no FDM test |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DETL-01 | ev-database.org specs fetched live | Golden run | `/ev-detail "Volvo EX30"` — check Sources table has ev-database.org URL | ❌ Wave 0 |
| DETL-02 | File written at correct path | Golden run | `Bash(ls projects/<active>/research/volvo-ex30.md)` | ❌ Wave 0 |
| DETL-03 | All spec fields populated | Field-presence check | Read output file; verify all car-template.md spec rows have non-empty Value column | ❌ Wave 0 |
| DETL-04 | No training data used | Prompt audit | Verify SKILL.md has explicit "do not use training data" instruction | ❌ Wave 0 |
| DETL-05 | Every fact has source URL + date | Citation completeness check | Count rows in Sources table; count non-empty Value cells in Specs table; assert rows ≥ cells | ❌ Wave 0 |
| DETL-06 | FDM real-world range present when available | Golden run (EX30 — FDM exists) | Check "Real-world range (mild)" row sources to fdm.dk | ❌ Wave 0 |
| DETL-07 | FDM verdict + pros/cons captured | Golden run | Check FDM Test Notes section has Styrker and Svagheder sub-sections | ❌ Wave 0 |
| DETL-08 | Missing FDM gracefully handled | Golden run (car with no FDM test) | FDM Test Notes section contains "No FDM test found as of" | ❌ Wave 0 |
| DETL-09 | Tier 1 and tier 2 DKK prices present | Golden run (new purchase_type) | Check Price DK tier 1 and tier 2 rows are populated | ❌ Wave 0 |
| DETL-10 | Platform type noted | Golden run | Check EV platform field has "Dedicated" or "Adapted ICE" value | ❌ Wave 0 |
| TIRE-01 | Tire size captured | Golden run | Check Tire size (front) row populated; verify source is wheel-size.com | ❌ Wave 0 |
| OWNR-01 | Reliability reputation from FDM | Golden run | FDM Test Notes or Ownership Signals has confidence-labeled FDM qualitative notes | ❌ Wave 0 |
| SRCH-07 (used) | Used market range in Bilbasen format | Golden run (used project) | Check "Market price range" rows populated; source is bilbasen/autouncle | ❌ Wave 0 |
| SRCH-07 (leasing) | Leasing monthly range captured | Golden run (leasing project) | Check "Monthly payment" rows populated | ❌ Wave 0 |
| D-09 | Re-run asks before overwriting | Behavior check | Run `/ev-detail "Volvo EX30"` twice; second run must pause and ask | ❌ Wave 0 |
| D-05/D-06 | Variant auto-selected with rationale | Golden run (multi-variant model) | Output includes "Selected variant: ... Reason: ..." text | ❌ Wave 0 |

### Validation Approach for Markdown-Producing Skills

Since the skill produces a markdown file rather than an API response, validation is observational:

1. **Golden-run against Volvo EX30:** Well-documented car, FDM test exists (2026-03-17), tire data on wheel-size.com, active used market on Bilbasen. Covers DETL-01..10, TIRE-01, OWNR-01.
2. **Gap-handling run:** Choose a car with no FDM test (verify by searching `site:fdm.dk/tests <make> <model>` first). Confirm the FDM Test Notes section has the gap note.
3. **Multi-variant run:** Choose Renault 5 (52kWh vs 40kWh variants). Verify variant selection reasoning appears in output and correct variant matches BRIEF budget.
4. **Purchase-type branches:** Run with `purchase_type: used` project and separately with `purchase_type: leasing`. Verify correct price section appears in each output.
5. **Re-run test:** Run on the same car twice. Verify second run pauses and asks before overwriting.

### Sampling Rate

- **Per task commit:** Not applicable (no automated test command; skill produces markdown)
- **Per wave merge:** Manual golden-run against Volvo EX30 before merging any wave
- **Phase gate:** All 5 validation scenarios above pass before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] No test infrastructure needed (skill produces markdown, not code)
- [ ] Validation checklist document at `.planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md` — covers the 5 golden-run scenarios above
- [ ] A test project with an appropriate BRIEF.md should be created before validation runs

---

## Security Domain

This phase has no authentication, no user data storage, no external API keys, and no network endpoints. All data is fetched read-only from public websites. ASVS categories V2/V3/V4/V6 do not apply.

**V5 Input Validation (applies):** The `$ARGUMENTS` input (car model name) is used in:
- WebSearch queries (no injection risk — queries are passed as plain text)
- Filename generation (hyphen normalization; no shell execution on the filename)
- Bash(`ls projects/<active>/research/<filename>.md`) — the filename is constructed by Claude, not directly interpolated from raw user input into the shell command. Claude's reasoning step normalizes it first.

Risk is LOW. The skill does not execute arbitrary shell commands from user input.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `car_search.md` as global criteria file | Per-project `BRIEF.md` under `projects/<name>/` | Phase 1 | Projects are isolated; multiple simultaneous research tracks possible |
| greengarage.dk as LOW-priority source | greengarage.dk model pages 404 — skip entirely | Verified 2026-06-22 | Remove from skill instructions; source is not viable |
| TIRE-01 sourced from ev-database.org | ev-database.org has no tire data — use wheel-size.com | Verified 2026-06-22 | wheel-size.com added as mandatory step for TIRE-01 |
| Bilbasen listing page for used prices | Bilbasen listing did not render — use Bilbasen Blog | Verified 2026-06-22 | Market-range articles via WebSearch + WebFetch instead |

**Deprecated:**
- `car_search.md` as the criteria file: replaced by `projects/<name>/BRIEF.md` in Phase 1. Do not reference `car_search.md` in the ev-detail skill.
- greengarage.dk model pages: 404. Remove from prompt instructions.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | "update-in-place" (partial re-fetch) can be deferred — overwrite/skip is sufficient for Phase 2 | Re-run / Overwrite | User might want to refresh FDM section only without re-fetching ev-db; low risk, easy to add later |
| A2 | Middle-tier tie-breaker (D-06) means the 2nd variant by battery/price order from WebSearch results | Variant resolution | Could pick wrong variant if WebSearch results order is non-canonical; add explicit sort instruction to skill |
| A3 | autouncle.dk is a viable supplement for used pricing | Used pricing | Not verified via live fetch; treat as fallback only |
| A4 | FDM `fdm.dk/nyheder` leasing overview is WebFetch-accessible | Leasing pricing | Not individually verified; FDM individual articles confirmed accessible, so likely OK |
| A5 | wheel-size.com URL pattern generalizes to all makes/models with `<make-lowercase>/<model-lowercase>/<year>/` | Tire source | Some model slugs may differ (e.g., "bmw" vs "bmw-i" for iX models); probe at implementation |

**If this table is empty:** It is not. A1–A5 need user or implementation confirmation.

---

## Sources

### Primary (HIGH confidence) — live-verified 2026-06-22

- `https://ev-database.org/uk/car/1910/Volvo-EX30-Single-Motor-ER` — all spec fields confirmed present; "EV Dedicated Platform: Yes (Geely SEA2)"; tire size NOT present [VERIFIED: live fetch 2026-06-22]
- `https://ev-database.org/uk/car/2135/Renault-5-E-Tech-52kWh-150hp` — spec fields confirmed; "EV Dedicated Platform: Yes"; tire size NOT present [VERIFIED: live fetch 2026-06-22]
- `https://fdm.dk/tests/biltest/test-flot-comeback-nu-er-volvo-ex30-endelig-voksen` — measured range 330 km at 110 km/h, 275 km at 0°C; styrker/svagheder; DKK prices 245,000/299,000; publication 2026-03-17 [VERIFIED: live fetch 2026-06-22]
- `https://fdm.dk/tests/biltest/renault-5-lille-elbil-med-retrolook-charme` — measured range 295 km at 110 km/h; FDM data fields confirmed; publication 2025-05-19 [VERIFIED: live fetch 2026-06-22]
- `https://www.wheel-size.com/size/volvo/ex30/2024/` — OEM tire sizes: 225/55R18 (base), 245/45R19 (standard), 245/40R20 (optional); front = rear for all EX30 configs [VERIFIED: live fetch 2026-06-22]
- `https://blog.bilbasen.dk/nu-er-volvo-ex30-et-staerkt-brugtkob` — used market range: 220,000–230,000 DKK typical; accessible as static article [VERIFIED: live fetch 2026-06-22]
- `https://greengarage.dk/volvo-ex30` — HTTP 404; model pages not available [VERIFIED: live fetch 2026-06-22]
- `.claude/skills/ev-new-project/SKILL.md` — established frontmatter conventions, backtick injection, step-numbered body [VERIFIED: read 2026-06-22]
- `.claude/skills/ev-switch-project/SKILL.md` — active-project read/write pattern [VERIFIED: read 2026-06-22]
- `car-template.md` — output contract; all section headings, spec rows, Sources table [VERIFIED: read 2026-06-22]

### Secondary (MEDIUM confidence)

- WebSearch: Volvo EX30 variants on ev-database.org — 5+ variant URLs confirmed (IDs 1909, 1910, 1911, 3118, 3477, 3478, 3480, 3481, 3483) [VERIFIED: WebSearch 2026-06-22]
- WebSearch: FDM biltest articles for Volvo EX30 — multiple tests confirmed [VERIFIED: WebSearch 2026-06-22]
- WebSearch: FDM biltest articles for Renault 5 — article confirmed at known slug [VERIFIED: WebSearch 2026-06-22]
- WebSearch: Bilbasen leasing/used articles — blog.bilbasen.dk confirmed as accessible editorial source [VERIFIED: WebSearch 2026-06-22]

---

## Metadata

**Confidence breakdown:**
- ev-database.org spec fields: HIGH — live-fetched two car pages; all required fields confirmed
- FDM article fetching: HIGH — two articles live-fetched; field extraction confirmed
- wheel-size.com tire data: HIGH — live-fetched EX30 2024; OEM sizes confirmed
- Variant discovery via WebSearch: HIGH — confirmed returns expected variant URLs
- Bilbasen used market range: MEDIUM — blog article live-fetched; listing page not accessible
- Bilbasen/FDM leasing data: MEDIUM — editorial articles confirmed accessible; specific leasing range methodology is loose
- greengarage.dk: VERIFIED UNUSABLE — model pages 404
- Filename normalization: LOW (ASSUMED) — convention from STACK.md, not tested in implementation
- Re-run detection pattern: LOW (ASSUMED) — modeled on ev-new-project; not tested for ev-detail

**Research date:** 2026-06-22
**Valid until:** 2026-07-22 (30 days — site structures are stable but market price data becomes stale faster; tire sizes are stable for existing model years)
