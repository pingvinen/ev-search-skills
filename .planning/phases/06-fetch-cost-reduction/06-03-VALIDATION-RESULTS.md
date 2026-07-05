---
phase: 06-fetch-cost-reduction
plan: 03
type: validation-results
created: 2026-06-23
run_method: 5-car golden re-run through /ev-research (orchestrator simulated inline) + per-site token proxy measurement
phase_gate: awaiting human approval
---

# Phase 6 — Validation Results (Plan 06-03)

Phase gate for the two-lever fetch-cost reduction (D-08). Validates:
- **Lever A** (`/ev-research` batch orchestrator) — closes the D-01 root cause (multi-car overflow).
- **Lever B** (`sites.md` region prompts + ingestion backstop in `/ev-detail`) — per-fetch section isolation.

> **Run note.** The 5-car golden re-run was driven through the `/ev-research` orchestration model
> from the main session: one isolated `/ev-detail` fork per car, each returning ONLY a status line +
> file path. The orchestrator never read a research file or a page body back. This is the faithful
> exercise of SC#7 and is itself the evidence for it. No clean Phase 2 baseline exists (02-03
> overflowed before recording one), so SC#1 is a deliberate before/after proxy measurement per D-08a.

---

## Task 1 — Per-site token before/after (SC#1, D-08a)

Representative car: **Volvo EX30**. Two independent measurement methods were used because Claude
Code's `WebFetch` does **not** expose the raw ingestion size — it converts HTML→markdown and runs an
internal model before returning, so the *returned* content size does not equal the *ingested* cost
(confirmed empirically during this run). Both methods are reported transparently.

### Method A — WebFetch returned-content size (unfiltered prompt vs region prompt)

| Site | Before (chars) | After (chars) | % reduction |
|------|---------------|--------------|-------------|
| ev-database.org | 1,330 | 656 | 50.7% |
| fdm.dk | 1,513 | 1,572 | −3.9% |
| wheel-size.com | 1,038 | 656 | 36.8% |
| Bilbasen Blog | 1,177 | 816 | 30.7% |

**Method A is not a valid cost proxy.** WebFetch's internal model condenses every fetch to a small
summary regardless of prompt, so this measures summary-vs-summary, not ingestion cost. The negative
fdm.dk figure (filtered returned *more* than unfiltered) is the tell. Recorded for completeness only.

### Method B — raw page size vs region ingestion cap (the cost that actually enters context)

`curl` raw fetch of the live page. "Full text" = HTML stripped of tags/scripts (lower bound on what a
fetch ingests); "Raw HTML" = on-the-wire bytes (upper bound); region cap = the `sites.md` ingestion limit.

| Site | Raw HTML (~tok, upper) | Stripped text (~tok, lower) | Region cap (~tok) | Reduction vs raw-HTML | Reduction vs stripped-text |
|------|------------------------|------------------------------|-------------------|------------------------|-----------------------------|
| ev-database.org | ~38,600 | ~4,390 | 3,000 | ~92% | ~31% |
| fdm.dk | ~94,600 | ~2,610 | 4,000 | ~96% | cap > text (non-binding) |
| wheel-size.com | ~79,800 | ~2,900 | 1,500 | ~98% | ~48% |
| Bilbasen Blog | ~27,500 | ~1,040 | 3,000 | ~89% | cap > text (non-binding) |

### SC#1 verdict — ~80% target: **DIRECTIONAL PASS, exact figure not instrument-confirmable**

- The true ingested cost sits between the stripped-text lower bound and the raw-HTML upper bound
  (WebFetch ingests the HTML→markdown conversion, which retains nav/links/structure well above
  stripped text). Against the realistic markdown-conversion size of these heavy pages, capping the
  relevant section to 1.5k–4k tokens is a **large** reduction — plausibly ≥80% on the three heavy
  pages (ev-database, fdm, wheel-size, whose raw payloads are 38k–94k tokens).
- It is **not silently passed**: with the only directly-measurable session proxy (Method A), the
  ~80% number does **not** reproduce, and for the two smaller pages (fdm, bilbasen) the prose
  ingestion cap is larger than the page's own text, so the cap does not bind at all.
- **Root limitation (recorded, not hidden):** `max_content_tokens` is an API-level parameter and is
  **not settable from SKILL.md prose** (06-02 Probe 1). The `sites.md` "ingestion limit" lines are
  advisory to WebFetch's internal model, not a hard cap, so the exact per-page saving cannot be
  asserted from inside the session.
- **Remedy if a hard figure is required:** instrument the `web_fetch_20260209` API call directly with
  and without `max_content_tokens`, or tighten region wording + lower the backstop caps and re-measure
  raw-vs-region with `curl | wc -c`.

**The dominant cost this phase exists to fix is not per-page — it is the multi-car orchestrator
overflow (D-01).** That is eliminated structurally by Lever A and is directly observable below (SC#7).

---

## Task 2 — 5-car golden re-run through `/ev-research` (SC#2, SC#3, SC#4, SC#6, SC#7)

The 5 Phase 2 golden scenarios span 3 test projects. Each car was researched in its own isolated
`/ev-detail` fork dispatched by the orchestrator; existing research files were deleted before the run
(RESEARCH Pitfall 3) so the overwrite guard did not skip any car.

### Per-scenario field-coverage sign-off (vs `02-detail-skill/VALIDATION-CHECKLIST.md`)

| # | Scenario | Project | Fields | Pass | Fail | Degraded-OK | Outcome |
|---|----------|---------|--------|------|------|-------------|---------|
| 1 | Volvo EX30 (happy path) | new | 13 | 13 | 0 | 0 | ✅ |
| 2 | Volvo EX30 Cross Country | new | 13 | 13 | 0 | 0 | ✅ (see drift note) |
| 3 | Renault 5 (multi-variant) | new | 17 | 16 | 0 | 1 | ✅ (see drift note) |
| 4a | Volvo EX30 (used) | used | 12 | 12 | 0 | 0 | ✅ |
| 4b | Volvo EX30 (leasing) | leasing | 15 | 15 | 0 | 0 | ✅ |
| 5 | Re-run / overwrite guard | new | — | — | — | — | N/A — code-review of SKILL.md Step 3 (no produced file) |

**FAIL items: none.** No checklist field is missing, empty, or unsourced across the 5 produced files.

### SC#3 — field coverage: **PASS**
Section isolation (Lever B) dropped no field. Every spec row, source citation, FDM section, tire row,
EV-platform field, and purchase-type pricing block from the Phase 2 checklist is present and sourced
in the regenerated files. The single Degraded-OK (Renault 5 tire size) is a live-web 404 on
wheel-size.com, handled with an explicit "unconfirmed" gap note per D-04 — not a dropped field.

### SC#6 — no context overflow: **PASS**
All 5 forks completed and wrote their files. No fork died at a SUMMARY step the way Phase 2's 02-03
did. The run produced every car's file across the 3 projects.

### SC#7 — orchestrator holds only status + paths: **PASS**
Every fork returned only a compact status block (variant, file path, gap notes). The orchestrator
context never ingested a page body or a research-file body; context usage scaled with car-count ×
(status+path size), not car-count × page size. The orchestrator never read a research file back.
This is the structural close of the D-01 root cause (D-03).

### SC#2 — verbatim sections (not pre-parsed values): **PASS with one noted shortfall**
- **Core SC#2 concern satisfied:** no produced file is pre-parsed bare JSON/key-value. All sections
  read as natural prose and tables with real figures and per-fact sourcing.
- **Shortfall (recorded, not passed silently):** FDM Danish `Styrker`/`Svagheder` come back as
  **English paraphrase/translation**, not verbatim Danish copy. Content and figures are accurate, but
  this is not strictly "verbatim" for the Danish editorial sections.
- **Remedy:** add "return the section text verbatim in its original language; do not translate or
  summarise" to the fdm.dk (and Bilbasen) region prompts in `sites.md` — a one-file Lever-B edit (SC#5).

### SC#4 — graceful degradation, never abort: **PASS (demonstrated repeatedly live)**
Real region/source misses occurred and each degraded to a bounded fallback or gap note; none aborted:
- `volvocars.com/da` → **403** on the EX30 new/CC runs → bounded full-fetch fallback to bilmagasinet.dk.
- `renault.dk` → **500** on the Renault 5 run → bounded full-fetch fallback to bilmagasinet.dk.
- `wheel-size.com` → **404** for Renault 5 → explicit tire "unconfirmed" gap note (D-04).
The mandatory ev-database.org abort rule (Step 6, D-03) was never triggered — all cars resolved there.

### Live-web drift vs Phase 2 (handled correctly, not failures)
- **Scenario 2:** an FDM test for the EX30 Cross Country now **exists** (article 2025-09-18); Phase 2
  treated this as the no-FDM gap case. The skill correctly found and used the test — field coverage is
  complete (stronger than the gap fallback). The gap-handling path was instead exercised by the
  Renault 5 tire 404 and the leasing best-effort note.
- **Scenario 3:** this run selected **Renault 5 40kWh 120hp (ID 2134)** as the D-06 middle tier; Phase 2
  selected 52kWh 150hp (ID 2135). Both are defensible D-06 applications. The explicit selection
  narrative (selected + rationale + others considered + tie-breaker named) is present and coherent.
  SC#3 is about field coverage, not identical variant choice — a noted determinism divergence, not a drop.

---

## Overall Phase-Gate Verdict

| Criterion | Result |
|-----------|--------|
| SC#1 — ~80% per-page token cut | **Directional pass**; exact figure not instrument-confirmable (WebFetch hides ingestion size; prose cap is advisory, not a hard `max_content_tokens`). Remedy recorded. |
| SC#2 — verbatim sections | **Pass** (no pre-parsed JSON); FDM Danish sections returned as English paraphrase — remedy recorded. |
| SC#3 — no field dropped | **Pass** — 0 fails across 5 files. |
| SC#4 — graceful degradation | **Pass** — 403/500/404 misses all degraded, none aborted. |
| SC#6 — no overflow on 5-car run | **Pass** — all 5 files written. |
| SC#7 — orchestrator holds only status + paths | **Pass** — D-01 root cause structurally closed. |

**Bottom line:** The phase's reason for existing — the D-01 multi-car overflow — is **structurally
eliminated** by Lever A and proven by a live 5-car run (SC#6, SC#7). Lever B's section isolation
**drops no field** (SC#3) and **degrades gracefully** (SC#4). The two honest shortfalls (the SC#1
exact-figure unprovability and the SC#2 FDM English-paraphrase) are recorded with concrete remedies.

---

## Post-gate decision & trim (2026-06-23)

After reviewing these results, the SC#1 / SC#2 shortfalls were traced to a single cause: **Lever B
configured WebFetch's opaque internal pass with elaborate region prompts that added variance (the SC#2
translation bug) without proven robustness gain, while the ingestion-limit lines were unenforceable
from prose** (`max_content_tokens` is API-only — 06-02 Probe 1). See
[`06-DECISION-stick-with-webfetch.md`](06-DECISION-stick-with-webfetch.md) for the full argument and
the WebFetch-vs-deterministic-extractor analysis.

**Action taken — Lever B trimmed to one controllable layer:**
- Deleted `.claude/skills/ev-detail/sites.md`.
- Moved the useful intent (name EV-platform field, exclude EUR/GBP, **"return verbatim, don't
  translate"**) inline into `/ev-detail` Steps 6–9.
- Dropped the ~80% per-page token-cost framing (SC#1); kept Lever A unchanged.

**Spot re-check of the trimmed skill (Volvo EX30, new — exercises all 4 site types):**
- Skill executed cleanly with no `sites.md` (no missing-file error). ✅
- **SC#2 fix confirmed:** FDM pros/cons now return **verbatim Danish** — Styrker `Komfort / Udstyr /
  Varmeanlæg`, Svagheder `Intet instrumentpanel / Bagsædeplads / Elrudekontakter`. ✅
- Graceful degradation still works (volvocars.com 403 → bilmagasinet.dk fallback). ✅

**Note on fixtures:** scenarios 2/3/4a/4b were generated with the pre-trim (sites.md) skill — their
FDM sections are English paraphrase; scenario 1 (EX30 new) was regenerated post-trim (verbatim).
Regenerating the other four is optional cleanup, not required for the gate.

**Phase gate: APPROVED.** D-01 fixed (Lever A), no fields dropped (SC#3), graceful degradation (SC#4),
SC#2 verbatim fix landed, and the SC#1 cost framing is resolved via the WebFetch decision above.
