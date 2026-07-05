---
name: detail
description: Research a specific EV model in depth. Use when the user asks to research a car, fetch specs for a model, or add a car to the active project. Writes a sourced per-car file to the active project.
allowed-tools: WebFetch, WebSearch, Read, Write, Bash(ls *)
context: fork
agent: Explore
argument-hint: [car-model]
---

Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found — no active project. Run /pingvinen-ev-search:new-project first."`

Car to research: $ARGUMENTS

Follow these steps in order. Do NOT skip steps or reorder them.

**DATA DISCIPLINE — MANDATORY (DETL-04):**
- Never use training data for any spec value (range, battery, charging, performance, cargo, price).
- Never conflate the manufacturer's rated DC peak kW (from ev-database.org) with any FDM-measured figure — record them separately.
- Never average or blend the WLTP range and the real-world range figures. They measure different things and must appear in separate rows.
- Every populated fact in the output file must trace to a source URL and fetch date in the Sources table (DETL-05). Assert this before writing the file.

---

**Step 1 — Resolve active project**

From the injected global state above, extract the `active_project` value.

If `active_project` is `none` or the state file was not found: stop immediately and tell the user:

> No active project found. Run `/pingvinen-ev-search:new-project [name]` to create a project first, or `/pingvinen-ev-search:switch-project [name]` to switch to an existing project.

Do not proceed.

---

**Step 2 — Read project inputs**

Using the Read tool:
- Read `projects/<active_project>/brief.md` — note: `budget` (preferred and maximum), `purchase_type` (new / used / leasing), `must-have features`, `brand notes`, and minimum range requirement.
- Read `projects/<active_project>/state.md` — note the Research Progress table to see which cars have already been researched.

These drive variant selection (Step 5) and the purchase-type pricing branch (Step 9).

---

**Step 3 — Normalize filename and detect re-run (D-09)**

Derive the research filename from `$ARGUMENTS`:
1. Lowercase the full argument string.
2. Replace spaces with hyphens.
3. Strip parentheses, slashes, and dots (except preserve version numbers where meaningful — e.g., `52kwh` not `52kWh`, `+` becomes `plus`).
4. Trim any leading or trailing hyphens.
5. Include a battery variant in the filename only if the user explicitly typed it in `$ARGUMENTS` (e.g., `/pingvinen-ev-search:detail "Renault 5 52kWh"` → `renault-5-52kwh.md`; `/pingvinen-ev-search:detail "Renault 5"` → `renault-5.md`).

Examples:
- "Volvo EX30" → `volvo-ex30.md`
- "Renault 5 52kWh" → `renault-5-52kwh.md`
- "BMW iX1 xDrive" → `bmw-ix1-xdrive.md`
- "Mercedes-Benz CLA 250+" → `mercedes-benz-cla-250plus.md`

Run `Bash(ls projects/<active_project>/research/<filename>.md 2>/dev/null)`.

If the file EXISTS, stop and ask the user:

> A research file already exists for this car: `research/<filename>.md`
> What would you like to do?
> - **overwrite** — re-fetch all sources and replace the file entirely
> - **skip** — keep the existing file, exit without changes
>
> Reply with "overwrite" or "skip".

Wait for the user's response before proceeding. On "skip": exit without any changes.

---

**Step 4 — Discover variants on ev-database.org (DETL-01)**

Run WebSearch: `"ev-database.org <make> <model> specifications"`

Replace `<make>` and `<model>` with the make and model extracted from `$ARGUMENTS` (e.g., for "Volvo EX30", query is: `"ev-database.org Volvo EX30 specifications"`).

From the search results, extract all URLs that match the pattern:
```
https://ev-database.org/[uk/]car/{ID}/{Make-Model-Variant}
```

List the variants found, noting for each:
- The numeric `{ID}` in the URL
- The variant name encoded in the URL slug (battery size, trim level, performance tier)

**Important:** Do NOT fetch the ev-database.org listing or filter page. The listing is JavaScript-driven and returns incomplete results to WebFetch. Rely solely on WebSearch results for variant discovery.

**Important:** Do NOT fetch multiple variant pages to compare specs. Token budget is limited in this fork context — fetching 3–5 pages before selecting would exhaust it (each page is ~10–15k tokens). All selection reasoning must happen from the URL slugs alone in this step.

If the WebSearch returns no ev-database.org URLs for this car: stop immediately and tell the user:

> This car could not be found on ev-database.org. No file has been written. (D-03)

---

**Step 5 — Select the best variant (D-05, D-06)**

Reason over the URL slugs from Step 4 against the BRIEF from Step 2. Apply in this order:

1. **Hard filter:** discard variants whose battery/range clearly falls below the BRIEF's minimum range requirement.
2. **Budget filter:** prefer variants whose price tier (inferred from slug — entry, standard, performance/premium) fits within the BRIEF's budget.
3. **Tie-breaker (D-06):** when multiple variants remain after filtering, prefer the **middle tier by battery size or price**. If 3 variants remain → pick the 2nd. If 2 remain → pick the larger battery if budget allows.

State the selection explicitly before moving to Step 6:

> **Selected variant:** `<Make-Model-Variant>` (ID: `<ID>`, URL: `<full URL>`)
> **Reason:** `<why — e.g., best range within budget / middle-tier tie-breaker / only variant>`
> **Other variants considered:** `<list the slugs you did NOT select and why>`

Prefer `/uk/` URLs when both `/car/` and `/uk/car/` variants appear for the same model — spec values are identical across regional versions, and `/uk/` URLs have been validated.

---

**Step 6 — Fetch mandatory ev-database.org specs (DETL-01, DETL-03, DETL-10, D-03)**

WebFetch the selected variant's URL from Step 5. In the WebFetch instruction, ask only for the
technical specification fields listed below — and explicitly exclude navigation, related-cars
listings, comparison widgets, ownership-cost blocks, and the EUR/GBP pricing block (ev-database.org
shows EUR/GBP prices, which are NOT used here; DKK pricing comes from Step 9). Make sure the
**EV Dedicated Platform** field is included even if it sits in a separate "About"/"Platform"
sub-section outside the main spec table.

Extract the following fields (all are present on ev-database.org car pages):

| car-template.md row | ev-database.org label |
|---|---|
| WLTP range (km) | Range (WLTP) |
| Real-world range mild (km) | EVDB Real Range |
| Real-world range cold (km) | Real Range (Cold) |
| Battery (usable) (kWh) | Useable Battery Capacity |
| DC charge peak (kW) | Rapid Charging (DC max) — this is the **rated** figure |
| AC charge rate (kW) | Home Charging (AC max) |
| 10-80% DC charge time (min) | 10–80% charge time |
| 0-100 km/h (s) | 0-62 mph — convert to 0-100 km/h (same distance, label accordingly) |
| Cargo (L) | Boot space |
| Tow capacity (kg) | Towing Capacity (braked) |
| Power output (kW) | Max Power |

Additionally extract:
- **EV platform (DETL-10):** Look for the label "EV Dedicated Platform" on the page.
  - If "Yes" with a platform name in parentheses: record as `Dedicated EV platform (<platform name>)`.
  - If "No": record as `Adapted ICE platform (<platform name if shown>)`.
- **Model year:** note the MY for use in the wheel-size.com lookup in Step 8.

If the page cannot be fetched or the car is not found: ABORT immediately — write NO file. Tell the user which URL was attempted and that the car is absent from ev-database.org (D-03).

Record this URL and today's date for the Sources table.

**Reminder:** The DC charge peak (kW) figure from ev-database.org is the manufacturer's **rated** figure. Do not treat it as a real-world measured figure. Any FDM-measured charging rate goes in the FDM Test Notes section ONLY (Step 7).

---

**Step 7 — FDM test: best-effort discovery and fetch (DETL-06, DETL-07, DETL-08, OWNR-01)**

When you fetch an FDM article (below), ask the WebFetch only for the editorial test body — the
verdict, the **Styrker** (strengths) and **Svagheder** (weaknesses) lists, the measured ranges, the
measured DC charge rate, and the DKK prices — and **return that text verbatim in the original Danish;
do NOT translate, summarise, or rephrase the Styrker/Svagheder wording.** Exclude navigation,
cookie/consent banners, related-article blocks, and ads. This step is best-effort — if a fetch
returns nothing usable, write the gap note and continue; never abort on a miss (D-04).

Attempt FDM article discovery with at most two WebSearch queries:

**Attempt 1:** `site:fdm.dk/tests biltest <make> <model>`

If Attempt 1 returns at least one `fdm.dk/tests/biltest/` URL: use the most recent article (identifiable by publication date in the article content or URL slug).

**Attempt 2 (only if Attempt 1 returns nothing):** `fdm.dk <make> <model> elbil test`

If both attempts return no results: write "No FDM test found as of <today's date>" in the FDM Test Notes section and proceed to Step 8. Do NOT abort — FDM is best-effort (D-04).

**If an FDM article URL was found:** WebFetch the most recent article URL. Extract:

- **Measured range at 110 km/h, 20°C** — this is the real-world Danish motorway range figure; write it into the `Real-world range (mild)` Specs row and source it to fdm.dk (DETL-06). **Override** the ev-database.org "EVDB Real Range" figure in that row since the FDM figure is a more relevant Danish real-world measurement.
- **Measured range at 0°C** — write into `Real-world range (cold)` row and source to fdm.dk.
- **FDM-measured DC peak kW** — record in FDM Test Notes ONLY with the label "FDM measured: X kW". Do NOT overwrite the rated DC charge peak (kW) in the Specs table (this would be pitfall #5 — the two figures differ and both are informative).
- **Verdict** — the FDM overall recommendation narrative.
- **Styrker** (strengths) — bulleted list.
- **Svagheder** (weaknesses) — bulleted list.
- **DKK prices** — base and tested trim prices as reported by FDM.
- **Publication date** — required for the Sources table and confidence label.

Capture FDM reliability reputation in Ownership Signals: label it `HIGH (FDM test, <article date>)` and summarise the qualitative ownership notes from the verdict and pros/cons (OWNR-01, D-10).

If the fetch fails after a URL was found: write "FDM test article could not be fetched as of <today's date>" in FDM Test Notes and continue (D-04).

Record the FDM article URL and today's fetch date for the Sources table.

---

**Step 8 — Tire size: best-effort from wheel-size.com (TIRE-01)**

When you fetch wheel-size.com (below), ask the WebFetch only for the OEM/OE factory-fitted tire-size
rows — exclude aftermarket fitments, ads, and user-review sections. This step is best-effort — never
abort on a miss; write the gap note and continue (D-04).

From the ev-database.org page in Step 6, note the model year (MY).

WebFetch: `https://www.wheel-size.com/size/<make-lowercase>/<model-lowercase>/<year>/`

Example: for Volvo EX30 MY2024 → `https://www.wheel-size.com/size/volvo/ex30/2024/`

Extract:
- OEM front tire size (marked "OE" on the page).
- OEM rear tire size, if different from the front.

Write to the Tire Research section and Specs rows:
- If front == rear: write the same size in both `Tire size (front)` and `Tire size (rear)` Specs rows; add the note "(square setup)".
- If front ≠ rear: write each size in its respective row.

If the page returns 404 or fails to load: write "Tire size: unconfirmed — check manufacturer spec sheet" in both tire rows and a note in Tire Research. Do NOT abort (D-04).

Source the tire size rows to the wheel-size.com URL and today's date.

**Scope note:** This step captures tire SIZE only. Tire pricing, tire scoring, and top-3 tire recommendations are deferred to Phase 5 and must NOT be added here (D-01/D-02).

---

**Step 9 — Purchase-type pricing branch (SRCH-07, D-07, D-08, DETL-09)**

For each WebFetch in this step, ask only for the pricing/market content the branch needs (DKK prices,
used-market ranges, or monthly leasing rates) and exclude unrelated page sections, configurators, and
ads. For Danish editorial sources (Bilbasen Blog, FDM), return the relevant figures and any quoted
price text verbatim — do not translate. This step is best-effort — never abort on a miss; write the
appropriate gap note and continue (D-04/D-07).

Read `purchase_type` from the brief.md you loaded in Step 2. Then follow the matching branch:

**Branch: `new`**

The price source for DKK pricing is the manufacturer's official Danish website, NOT ev-database.org (ev-database.org shows EUR/GBP prices, not DKK). Fetch the manufacturer's Danish configurator or price list.

Capture and record:
- **Tier 1 (from / base price):** the lowest published DKK price — write to `Price DK tier 1 (from) (DKK)` row.
- **Tier 2 (best-value trim):** the recommended mid-tier DKK price — write to `Price DK tier 2 (best value) (DKK)` row (DETL-09).

Source both price rows to the manufacturer's Danish website URL and today's fetch date.

**Branch: `used`**

WebSearch: `"bilbasen <make> <model> brugt pris"` or `"bilbasen <make> <model> brugtkøb"`

WebFetch the most relevant Bilbasen Blog article (`blog.bilbasen.dk/...`) — do NOT fetch the Bilbasen listing page (`bilbasen.dk/brugt/...`), which does not render content to WebFetch.

Extract the market range summary:
- Low DKK (bottom of market)
- Typical DKK (mid-market, most common)
- High DKK (near-new, low mileage)
- Article publication date (required — this data becomes stale)

Write to Danish Market Context section:
```
Used market range (as of [article date]): [low]–[typical] DKK typical; [high] DKK near-new.
See bilbasen.dk for current listings.
```

Source to the Bilbasen Blog article URL and today's fetch date. Note the article date is distinct from the fetch date.

**Branch: `leasing`**

WebSearch: `"privatleasing <make> <model> månedlig DKK"` or `"lease <make> <model> DKK 2025"`

WebFetch an editorial article (from `blog.bilbasen.dk` or `fdm.dk/nyheder`) that covers leasing market rates.

Extract:
- Typical monthly DKK range (low to high)
- Upfront payment if mentioned
- Lease term and annual km allowance if mentioned
- Article publication date

Write to Danish Market Context section:
```
Leasing: from ~X,XXX DKK/month ([annual km]/year, [months] months) as of [source date]; market range X,XXX–X,XXX DKK/month.
```

**Important — no residual value (D-07, D-08):** Danish privatleasing publishes no residual figure; the leasing company absorbs depreciation risk. Do NOT invent a residual value. Instead note: "Residual value: not published in Danish privatleasing — depreciation risk absorbed by leasing company."

Source to the article URL and today's fetch date.

---

**Step 10 — greengarage.dk (optional probe only)**

greengarage.dk model-specific pages (e.g., `/volvo-ex30`) return HTTP 404 and are not a viable source. Do NOT instruct a mandatory fetch. Do NOT log a gap note if 404. If desired, a silent probe may be attempted — a 404 is expected and must not block or delay the file write.

---

**Step 11 — Write the research file (DETL-02, DETL-05)**

Before writing: assert that every populated spec cell in the Specs table has a corresponding row in the Sources table (DETL-05). Any populated fact without a source URL and fetch date must be sourced or removed.

Write `projects/<active_project>/research/<filename>.md` (filename from Step 3).

Conform section-by-section to `car-template.md`:

1. **Header:** `# <Make Model Variant>` (use the full selected variant name from Step 5), `**Researched:** <today>`, `**Project:** <active_project>`.

2. **Quick Verdict:** 2–3 sentences — does this car meet the BRIEF's criteria? What stands out most?

3. **Specs table:** all fields extracted in Steps 6–9. Fill in the Value and Source columns for every populated row. Use the car-template.md row names exactly.

4. **EV platform:** populate the `**EV platform:**` line from Step 6.

5. **FDM Test Notes:** full FDM content if found (verdict, Styrker, Svagheder, charging performance, measured DC kW labeled as measured), or "No FDM test found as of <date>" if not found.

6. **Tire Research:** note the tire size captured in Step 8, and the note that pricing/scoring/top-3 recommendations are out of scope for Phase 2 (captured in Phase 5).

7. **Ownership Signals:** FDM reliability reputation from Step 7 with confidence label `HIGH (FDM test, <date>)`. If no FDM test found: write "No FDM reliability data — no test article found."

8. **Danish Market Context:** purchase-type-specific pricing from Step 9. Leave tax and insurance figures blank with the note: "Registration tax and insurance tier: captured in Phase 4 / Danish enrichment."

9. **Pros and Cons:** populate from FDM Styrker/Svagheder where available; supplement with any notable spec-level strengths/weaknesses.

10. **Sources table:** one row per fetched source. Every populated fact above must trace here. Columns: `Claim | Source URL | Fetch date`.

---

**Step 12 — Update per-project state.md**

Read `projects/<active_project>/state.md`. Append one row to the Research Progress table:

```
| <selected variant name> | research/<filename>.md | <today's date> | <yes (YYYY-MM-DD) / no / partial> |
```

Where the FDM found column is:
- `yes (YYYY-MM-DD)` — FDM article found and successfully fetched; date is the article's publication date.
- `no` — two WebSearch attempts made, no article found.
- `partial` — article URL found but fetch failed.

Also add any fetch-reliability observations (e.g., "wheel-size.com: loaded correctly for <model> <year>") to the Source Reliability Notes section.

Write the updated content back to `projects/<active_project>/state.md`.

---

**Step 13 — Confirm to user**

Report:
- File written: `projects/<active_project>/research/<filename>.md`
- Variant selected: `<name>` (reason: `<brief rationale>`)
- FDM: found (article date: `<date>`) / not found
- Tire size: confirmed from wheel-size.com / unconfirmed (check spec sheet)
- Gaps (if any): list any populated spec rows that could not be fully sourced, or any best-effort sources that yielded nothing
