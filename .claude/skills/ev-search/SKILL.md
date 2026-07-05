---
name: ev-search
description: Search for EV models matching the active project's criteria. Use when the user wants to find matching cars, run a search, or discover candidates. Reads brief.md and writes Search Candidates to state.md.
allowed-tools: WebFetch, WebSearch, Read, Write, Bash(curl *, python3 *, ls *)
---

Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found — no active project. Run /ev-new-project first."`

Follow these steps in order. Do NOT skip steps or reorder them.

---

**Step 1 — Resolve active project**

From the injected global state above, extract the `active_project` value.

If `active_project` is `none` or the state file was not found: stop immediately and tell the user:

> No active project found. Run `/ev-new-project [name]` to create a project first, or `/ev-switch-project [name]` to switch to an existing project.

Do not proceed.

---

**Step 2 — Read project brief**

Using the Read tool, read `projects/<active_project>/brief.md`.

Extract and note these fields (all drive filtering and bucketing):
- **Budget preferred:** the preferred upper bound (DKK) — used for "within budget" band ceiling
- **Budget maximum:** the absolute ceiling (DKK) — used for "slight stretch" band ceiling
- **Per-brand overrides:** any per-brand budget multipliers (e.g., "BMW: +50%") — apply as a multiplier on the maximum for that brand's ceiling
- **Body Type:** the preferred body style (e.g., "SUV / crossover", "hatchback") — this maps to ev-database shape classes in Step 4
- **Seats:** minimum seat count required (extract the number — e.g., "4-5 seats" → minimum 4 seats, prefer 5)
- **Must-Have Features:** record these, but do NOT use them as hard filters at search stage — they cannot be confirmed from the listing HTML and will be noted as borderline reasons only (D-12)

Derive a **minimum range** from the brief context if stated; if not explicit, use a sensible floor (e.g., 250 km EVDB range). This is Claude's discretion.

---

**Step 3 — Fetch ev-database.org listing (D-01)**

Run:
```
Bash: curl -s -A "Mozilla/5.0" https://ev-database.org -o /tmp/evdb_listing.html
```

Then immediately sanity-check the file size:
```
Bash: wc -c /tmp/evdb_listing.html
```

If the file is under 100,000 bytes: ABORT immediately. Tell the user:

> ev-database.org returned a very small file (~64 KB) — this is the bot-detection 404 page, not the car listing.
> The browser user-agent check may have changed. The search cannot proceed.

Do NOT attempt to parse the file if it is under 100,000 bytes.

---

**Step 4 — Filter candidates with python3 (D-01, D-04)**

Map the brief's Body Type text to ev-database shape CSS classes:
- "SUV" or "crossover" → `shape-suv`
- "hatchback" → `shape-hatchback`
- "estate" or "wagon" → `shape-station`
- "sedan" → `shape-sedan`
- "MPV" → `shape-mpv`
- "pickup" → `shape-pickup`

If the brief lists two body types, include both shape classes in the filter (any-match logic).

Derive filtering thresholds from the brief:
- `MIN_SEATS` — minimum seat count from brief (e.g., 4)
- `MIN_RANGE_KM` — minimum EVDB real-world range from brief or 250 km default
- `MIN_BATTERY_KWH` — a sensible floor (e.g., 40 kWh); Claude's discretion
- `MAX_EUR_PRICE` — rough EUR pre-filter cap: use `(brief_max_DKK / 6)` as a proxy (the Volvo EX30 SM ER ratio is 6.3×; 6 is a safe conservative divisor). This excludes clearly over-budget candidates before per-candidate DK price searches.

Write the following python3 script to `/tmp/evdb_filter.py`, then execute it with `Bash: python3 /tmp/evdb_filter.py`:

```python
# Source: live probe of ev-database.org HTML, 2026-06-27 (Phase 3 research)
# Extracts car entries matching brief criteria from the server-rendered listing.
import re
import sys

# --- CONFIGURE THESE from the brief (Claude substitutes at runtime) ---
BODY_SHAPE_CLASSES = ['shape-suv']   # list of ev-database CSS shape classes
MIN_SEATS = 4
MIN_RANGE_KM = 250
MIN_BATTERY_KWH = 40
MAX_EUR_PRICE = 55000   # rough pre-filter cap: brief_max_DKK / 6
CANDIDATE_CAP = 20      # max candidates to emit (sorted by EUR price ascending)
# --- END CONFIGURATION ---

with open('/tmp/evdb_listing.html', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Extract all car list-item blocks
items = re.findall(
    r'<div class="list-item" data-jplist-item>(.*?)</div>\s*\n</div>',
    content, re.DOTALL
)

if not items:
    print(f'ERROR: No list-item blocks found — HTML structure may have changed', file=sys.stderr)
    sys.exit(1)

results = []
excluded_count = 0
for item in items:
    # Body type check (any-match across configured shape classes)
    shapes = re.findall(r'class="(shape-[a-z]+) hidden"', item)
    if not any(s in shapes for s in BODY_SHAPE_CLASSES):
        continue

    # Seat count check
    seat_m = re.search(r'seats-(\d+)', item)
    if not seat_m or int(seat_m.group(1)) < MIN_SEATS:
        continue

    # Range check (EVDB real-world range)
    range_m = re.search(r'class="erange_real">(\d+) km<', item)
    if not range_m or int(range_m.group(1)) < MIN_RANGE_KM:
        continue

    # Battery check
    bat_m = re.search(r'class="battery hidden">(\d+)<', item)
    if not bat_m or int(bat_m.group(1)) < MIN_BATTERY_KWH:
        continue

    # EUR price pre-filter (exclude clearly over-budget cars before DK price search)
    price_m = re.search(r'class="pricefilter hidden">(\d+)<', item)
    price_eur = int(price_m.group(1)) if price_m else 0
    if price_eur > MAX_EUR_PRICE:
        excluded_count += 1
        continue

    # Extract name and URL
    name_m = re.search(r'class="hidden">([^<]+)</span></a>', item)
    url_m = re.search(r'href="(/car/\d+/[^"]+)" class="title"', item)

    results.append({
        'name': name_m.group(1) if name_m else '(unknown)',
        'url': 'https://ev-database.org' + (url_m.group(1) if url_m else ''),
        'range_km': int(range_m.group(1)),
        'battery_kwh': int(bat_m.group(1)),
        'price_eur': price_eur,
    })

# Sort by EUR price ascending (cheapest first — reduces DK search cost for over-budget tail)
results.sort(key=lambda x: x['price_eur'])

# Cap the candidate list
capped = results[:CANDIDATE_CAP]
print(f'# Found {len(results)} matching candidates ({excluded_count} excluded by EUR pre-filter); emitting top {len(capped)} by price')
for r in capped:
    print(f"{r['name']}|{r['url']}|{r['range_km']}km|{r['battery_kwh']}kWh|EUR{r['price_eur']}")
```

Before running: substitute the configuration block at the top of the script with the values derived from the brief and Step 4 thresholds (BODY_SHAPE_CLASSES, MIN_SEATS, MIN_RANGE_KM, MIN_BATTERY_KWH, MAX_EUR_PRICE).

If the script exits with an error or prints "0 matching candidates": report the failure — do NOT proceed to DK price search with zero candidates.

Parse the pipe-delimited output into a working candidate list: `name | ev-database URL | EVDB range (km) | battery (kWh) | EUR price`.

---

**Step 5 — DK price band per candidate (D-05, D-06, D-07, D-08)**

For each candidate from Step 4 (up to the cap of ~20), run one WebSearch:

```
WebSearch: "<make> <model> pris DKK"
```

Replace `<make> <model>` with the car name from the pipe-delimited output (e.g., "Volvo EX30 Single Motor ER pris DKK").

From the search snippet, extract the first clearly labelled DKK price figure (look for "DKK", "kr.", or ",-" in Danish context). Take the "from" or base price if multiple tiers are shown.

Bucket against the brief budget using these band labels (D-08):
- `within budget` — DK from-price ≤ brief **preferred** budget
- `slight stretch` — DK from-price between preferred and **maximum** budgets
- `over budget` — DK from-price > maximum (still include the candidate if within a per-brand override ceiling)
- `price unknown` — no DKK price figure found in the snippet

**Per-brand overrides:** if the brief specifies a per-brand override (e.g., "BMW: +50%"), calculate that brand's effective ceiling as `brief_max × (1 + override_fraction)`. Apply this as the "over budget" gate for cars of that brand — they remain visible if within the override ceiling.

**Important — no EUR→DKK conversion (D-05):** do NOT convert EUR prices from ev-database.org to DKK. Danish registration taxation makes the ratio highly variable (6–8× depending on model and trim). Use WebSearch DKK figures only.

Label each band value as indicative — it is a live-search snapshot, not a precise price.

Assign a verdict to each candidate:
- `match` — passes all hard filters (body type, seats, range, battery) AND within budget (within budget OR slight stretch is acceptable)
- `borderline: <reason>` — passes hard filters but: budget is slight stretch near maximum, OR a must-have feature from the brief cannot be confirmed at this shallow stage
- `excluded: <reason>` — hard fail: clearly over budget for all brands, OR EUR pre-filter already excluded it (these appear as excluded in the table, not as WebSearch candidates)

Near-misses (borderline) are NEVER silently dropped — they must appear in the output (D-12).

---

**Step 6 — Write Search Candidates section to state.md (D-09, D-10, D-13)**

Read `projects/<active_project>/state.md` using the Read tool. Hold the full file content in context.

Find or create the `## Search Candidates` section:
- If `## Search Candidates` exists in the file: replace the block from `## Search Candidates` through the next `## ` heading (or end of file if it is the last section) with the new section content below.
- If `## Search Candidates` does NOT exist: append the new section at the end of the file.

Write the full updated content back to `projects/<active_project>/state.md`.

**Never truncate other sections** (Research Progress, Source Reliability Notes, Discovered Sources). The write must contain all original content outside the Search Candidates block plus the new Search Candidates content.

**Section format:**

```
## Search Candidates

_Last updated: [today's date] — criteria: [body type], [seats]+ seats, range ≥[MIN_RANGE_KM]km, battery ≥[MIN_BATTERY_KWH]kWh, budget [preferred]–[maximum] DKK_

| Model | ev-database URL | Body | EVDB Range | Battery | DK Price Band | Verdict |
|-------|----------------|------|------------|---------|---------------|---------|
| [model name] | [url] | [body type] | [range_km] km | [battery_kwh] kWh | [band label] | [verdict] |
```

**Column labelling rules:**
- Range column MUST be labelled `EVDB Range` — NOT "WLTP". The `erange_real` figure from ev-database.org is EVDB's own standardized estimate under mild conditions, not the official WLTP figure (which is typically 50–100 km higher). Conflating the two is Pitfall 2.
- Section heading MUST be exactly `## Search Candidates` (no trailing text).

Include ALL candidates: match, borderline, AND excluded (with reason in Verdict column). The full candidate set is the record. Excluded cars show `excluded: [reason]` so re-runs are traceable.

**Security note (T-03-02):** The state.md path is constructed only from the `active_project` value resolved in Step 1 — never from user-supplied path input or page content. Extract only the specific data fields; do not eval or shell-interpolate any page content.

---

**Step 7 — Present ranked list and handoff command (D-11, D-12)**

Present the candidates to the user in conversation, grouped as three sections:

**Matches** — candidates with `match` verdict, sorted by EVDB range descending (longest range first).

**Borderline** — candidates with `borderline: <reason>` verdict. For each, state the specific reason (budget near-miss, must-have unconfirmable, etc.).

**Excluded** — candidates with `excluded: <reason>` verdict. List briefly; do not hide them.

After the grouped list, output a copy-paste ready handoff command listing only the match and borderline candidates (NOT excluded):

```
/ev-research "[Match Car 1]" "[Match Car 2]" "[Borderline Car 1]"
```

Use the exact model names as they appear in the ev-database listing (e.g., "Volvo EX30 Single Motor ER", "Renault 5 E-Tech 52kWh 150hp"). Quote each name individually so `/ev-research` can handle them as separate arguments.

Tell the user: "Run the handoff command above to research the selected cars in depth, or pick a subset."
