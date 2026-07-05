---
phase: 2
slug: detail-skill
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-22
approved: 2026-06-22
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This phase produces markdown skill output, not code — validation is observational
> (golden-run against known cars), not unit-tested. See `02-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual golden-run validation (no test runner — skill output is markdown) |
| **Config file** | none — validation is observational |
| **Quick run command** | `/ev-detail "Volvo EX30"` in a Claude Code session with an active project |
| **Full suite command** | Golden runs across: Volvo EX30 (strong FDM coverage), Renault 5 (multi-variant), one car with no FDM test, plus one `used` and one `leasing` project |
| **Estimated runtime** | ~3–5 min per golden run (live fetches) |

---

## Sampling Rate

- **After every task commit:** Not applicable (no automated test command; tasks produce skill markdown)
- **After every plan wave:** Manual golden-run against Volvo EX30 before merging the wave
- **Before `/gsd-verify-work`:** All 5 golden-run scenarios below must pass
- **Max feedback latency:** ~5 min (one golden run)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Verification | File Exists |
|--------|----------|-----------|--------------|-------------|
| DETL-01 | ev-database.org specs fetched live | Golden run | Sources table has ev-database.org URL + fetch date | ✅ W0 |
| DETL-02 | File written at correct path | Golden run | `ls projects/<active>/research/volvo-ex30.md` | ✅ W0 |
| DETL-03 | All spec fields populated | Field-presence | Every car-template.md spec row has non-empty Value | ✅ W0 |
| DETL-04 | No training data used for specs | Prompt audit | SKILL.md carries explicit "no training data" instruction | ✅ W0 |
| DETL-05 | Every fact has source URL + date | Citation completeness | Sources table covers each populated spec cell | ✅ W0 |
| DETL-06 | FDM real-world 110 km/h range when available | Golden run (EX30) | Real-world range row sources to fdm.dk | ✅ W0 |
| DETL-07 | FDM verdict + pros/cons captured | Golden run | FDM Test Notes has Styrker/Svagheder + verdict | ✅ W0 |
| DETL-08 | Missing FDM gracefully handled | Golden run (no-FDM car) | FDM section contains "No FDM test found as of …" | ✅ W0 |
| DETL-09 | Tier 1 + tier 2 DKK prices (new) | Golden run (new) | Price DK tier 1 and tier 2 rows populated | ✅ W0 |
| DETL-10 | Platform type noted | Golden run | EV-platform field = "Dedicated" or "Adapted ICE" | ✅ W0 |
| TIRE-01 | Tire size (front/rear) captured | Golden run | Tire-size row populated; source is wheel-size.com | ✅ W0 |
| OWNR-01 | Reliability reputation, confidence-labeled | Golden run | Ownership/FDM notes carry confidence label + source | ✅ W0 |
| SRCH-07 (used) | Used market range, not a listing | Golden run (used) | Market-price low/typical/high rows populated | ✅ W0 |
| SRCH-07 (leasing) | Leasing monthly + residual range | Golden run (leasing) | Monthly-payment range rows populated | ✅ W0 |
| D-05/D-06 | Variant auto-selected with rationale | Golden run (multi-variant) | Output states selected variant + reason | ✅ W0 |
| D-09 | Re-run asks before overwriting | Behavior | Second run on same car pauses and asks | ✅ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Golden-Run Scenarios (the validation suite)

1. **Volvo EX30 (happy path):** FDM test exists (2026-03-17), tire data on wheel-size.com, active used market. Covers DETL-01..10, TIRE-01, OWNR-01.
2. **Gap-handling:** A car with no FDM test (verify via `site:fdm.dk/tests <make> <model>` first). Confirm the FDM gap note appears (DETL-08).
3. **Multi-variant:** Renault 5 (52 kWh vs 40 kWh). Verify variant-selection reasoning + BRIEF-budget match (D-05/D-06).
4. **Purchase-type branches:** One `used` project and one `leasing` project. Verify the correct price section appears in each (SRCH-07).
5. **Re-run:** Run the same car twice. Verify the second run pauses and asks before overwriting (D-09).

---

## Wave 0 Requirements

- [x] No test infrastructure needed — skill produces markdown, not code.
- [x] A test project with an appropriate `BRIEF.md` exists (or is created) before validation runs.
- [x] Optional: `.planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md` capturing the 5 golden-run scenarios for repeatable sign-off.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All Phase 2 behaviors | DETL-01..10, TIRE-01, OWNR-01, SRCH-07, D-05/D-06, D-09 | Output is a markdown research file produced by live web fetches; correctness is judged by reading the file, not by a test runner | Run the 5 golden-run scenarios above and inspect each output file against car-template.md |

*All Phase 2 behaviors are manual-verification by nature (markdown-producing skill).*

---

## Validation Sign-Off

- [x] All 5 golden-run scenarios pass
- [x] Sampling continuity: golden-run executed at each wave merge
- [x] Wave 0 (test project / BRIEF) ready before validation
- [x] No watch-mode flags (N/A — no test runner)
- [x] Feedback latency acceptable (~5 min per run)
- [x] `nyquist_compliant: true` set in frontmatter once scenarios are green

**Approval:** APPROVED 2026-06-22 — all 5 scenarios passed; nyquist_compliant set to true; wave_0_complete set to true.
