---
name: ev-compare
description: Generate a comparison table from researched cars in the active project. Reads all research/*.md files and writes comparison.md as a side-by-side decision-support table with one column per car, labelled range rows, and a brief-aware verdict. Must be invoked explicitly with /ev-compare — never auto-triggered.
allowed-tools: Read, Write, Glob
disable-model-invocation: true
---

Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`

Follow these steps in order.

---

**Step 1 — Resolve active project**

From the injected global state above, extract the `active_project` value.

If `active_project` is `none` or the state file was not found: stop immediately and tell the user:

> No active project found. Run `/ev-new-project [name]` to create a project first, or `/ev-switch-project [name]` to switch to an existing project.

Do not proceed past Step 1 if no active project exists.

Record the resolved `active_project` value. You will use it to construct all file paths in the steps below.

---

**Step 2 — Discover research files (COMP-01)**

Glob `projects/<active_project>/research/*.md` — replacing `<active_project>` with the value resolved in Step 1.

If Glob returns zero files, stop and tell the user:

> No research files found in `projects/<active_project>/research/`. Research some cars first by running `/ev-search` to find candidates, then `/ev-research "Car A" "Car B"` to fetch their specs.

If Glob returns exactly one file, note that a comparison of one car is trivial but still produce the single-column table — one column is valid output.

Record the full list of file paths returned. The count of paths is the number of cars to compare.

---

**Step 3 — Read each file and extract fields**

For each file path from Step 2, use the Read tool to load the file content.

From each file, extract the following fields (matching the rows in `car-template.md`):

**15 Specs rows:**
1. WLTP range (km)
2. Real-world range (mild) (km)
3. Real-world range (cold) (km)
4. Battery (usable) (kWh)
5. DC charge peak (kW)
6. AC charge rate (kW)
7. 10-80% DC charge time (min)
8. 0-100 km/h (s)
9. Cargo (L)
10. Tow capacity (kg)
11. Tire size (front)
12. Tire size (rear)
13. Price DK tier 1 (from) (DKK)
14. Price DK tier 2 (best value) (DKK)
15. Power output (kW)

**Plus these qualitative fields:**
- EV platform (from the `**EV platform:**` line)
- FDM verdict: the one-liner verdict from the FDM Test Notes section
- FDM Styrker: the top 2 strengths listed in FDM Test Notes
- FDM Svagheder: the top 2 weaknesses listed in FDM Test Notes
- Ownership confidence: the overall confidence signal from Ownership Signals section

**Gap handling (D-17 — mandatory):** If a field is missing or marked as unknown in the research file, record it as explicit text — never leave blank or guess:
- Missing FDM data → `no FDM test`
- Tire unconfirmed → `unconfirmed`
- Price not applicable for this project's purchase type → `not available (<purchase_type>)`
- Any other missing value → `not available`

Also note the car's display name (from the file's `# [Make Model Variant]` heading) for use as a column header.

---

**Step 4 — Build the comparison table (COMP-01, COMP-02, D-14, D-16, D-17)**

Construct a Markdown table with one column per car.

**Column order:** Sort by a useful comparison axis. Default: WLTP range descending. If several cars share the same WLTP range, use tier-1 price ascending as a tiebreaker. State the sort key used in the file header.

**CRITICAL — range rows must be THREE separate rows (D-16, COMP-02):**

| Row label | Methodology label in parentheses | Notes |
|-----------|-----------------------------------|-------|
| `**WLTP range (km)**` | `(manufacturer rated)` | The official WLTP figure from ev-database.org |
| `**Real-world range (mild) (km)**` | `(FDM 110km/h, 20°C)` if from FDM test, or `(EVDB estimate)` if from ev-database | |
| `**Real-world range (cold) (km)**` | `(FDM 110km/h, 0°C)` if from FDM test, or `(EVDB estimate)` if from ev-database | |

Never merge these three rows. Never average WLTP and real-world figures. This is a hard requirement (D-16 is locked).

**Best-in-class marking per row:**
- Bold the best value in each row.
- Rows where higher is better: WLTP range, real-world range (mild), real-world range (cold), battery, cargo, tow, power output — **bold the highest numeric value**.
- Rows where lower is better: charge time (10-80%), 0-100 km/h, tier-1 price, tier-2 price — **bold the lowest numeric value**.
- Do not mark best-in-class if all values in the row are gap text (no FDM test, not available, etc.).

**Full row order in the table:**

```
| **WLTP range (km)** (manufacturer rated) | ... |
| **Real-world range (mild) (km)** (FDM 110km/h, 20°C) | ... |
| **Real-world range (cold) (km)** (FDM 110km/h, 0°C) | ... |
| Battery (usable) (kWh) | ... |
| DC charge peak (kW) (manufacturer rated) | ... |
| AC charge rate (kW) | ... |
| 10-80% DC charge time (min) | ... |
| 0-100 km/h (s) | ... |
| Cargo (L) | ... |
| Tow capacity (kg) | ... |
| Tire size (front) | ... |
| Tire size (rear) | ... |
| Price DK tier 1 (from) (DKK) | ... |
| Price DK tier 2 (best value) (DKK) | ... |
| Power output (kW) | ... |
| EV platform | ... |
| FDM verdict (one-liner) | ... |
| FDM Styrker (top 2) | ... |
| FDM Svagheder (top 2) | ... |
| Ownership confidence | ... |
```

---

**Step 5 — Add the brief-aware verdict and output header (D-14, D-15)**

Read `projects/<active_project>/brief.md` to obtain the search criteria: budget (preferred and maximum), body type, must-have features, range requirements, brand notes.

Write a `## Brief-Aware Verdict` section: 2-3 sentences naming the best overall fit for this brief and why, reasoned from the comparison data against the brief criteria. Reference specific rows (e.g., real-world range, tier-1 price) to justify the verdict.

Construct the output file header block:

```
# Comparison: <active_project>

**Generated:** [today's date]
**Cars compared:** [N] — [comma-separated list of car display names]
**Sorted by:** [sort key used — e.g. "WLTP range descending"]
```

---

**Step 6 — Write comparison.md (COMP-03)**

Write the complete file in a single Write call to `projects/<active_project>/comparison.md`. Overwrite unconditionally — this skill runs only on explicit `/ev-compare` invocation (`disable-model-invocation: true` prevents accidental triggers, D-18).

File structure:
1. Header block (from Step 5)
2. `## Brief-Aware Verdict` (from Step 5)
3. `## Spec Comparison` (the full table from Step 4)

---

**Step 7 — Confirm to the user**

After writing, report:
- File written: `projects/<active_project>/comparison.md`
- Cars compared: [N] — [list names]
- Sorted by: [sort key]
- Any cars with notable gaps: list cars where 5 or more fields were gap text, so the user knows which research files could benefit from a re-run
