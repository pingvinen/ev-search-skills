---
phase: 6
slug: fetch-cost-reduction
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-22
signed_off: 2026-06-23
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Note:** this is a Claude Code *skills* project (markdown SKILL.md files), not a
> compiled/unit-tested codebase. There is no pytest/jest/go-test framework. Validation
> is **behavioral**, via the Phase 2 golden-run harness re-run through the new
> `/ev-research` orchestrator (per CONTEXT.md D-08) plus before/after token measurement.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — behavioral golden-run validation (markdown skills project) |
| **Config file** | `.planning/phases/02-detail-skill/VALIDATION-CHECKLIST.md` (field-coverage baseline), `.planning/phases/02-detail-skill/02-VALIDATION.md` (5 golden scenarios) |
| **Quick run command** | `/ev-detail "<one golden car>"` then diff the produced research file against `car-template.md` fields |
| **Full suite command** | `/ev-research "<5 golden cars>"` then check each research file against `VALIDATION-CHECKLIST.md` |
| **Estimated runtime** | ~5–15 min (live fetches, 5 cars) |

---

## Sampling Rate

- **After every task commit:** lint the edited SKILL.md / sites.md (structure + frontmatter valid; referenced files resolve)
- **After Lever B wave:** single-car `/ev-detail` golden run — confirm no checked field dropped + capture per-site token counts (SC#1)
- **After Lever A wave:** `/ev-research` multi-car run — confirm isolation (orchestrator holds no page bodies, SC#7) and no overflow (SC#6)
- **Before `/gsd-verify-work`:** full 5-car golden run reproduces every `VALIDATION-CHECKLIST.md` checked field (SC#3)
- **Max feedback latency:** single-car run (~2–3 min)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Verification | Status |
|---------|------|------|-------------|-----------------|-----------|--------------|--------|
| 06-01-* | 01 (Lever A) | 1 | orchestrator isolation | N/A | behavioral | `/ev-research` run; orchestrator context never ingests a page body; returns status + path per car (SC#6, SC#7) | ⬜ pending |
| 06-02-* | 02 (Lever B) | 1 | section isolation | N/A | behavioral | per-site region prompt returns section verbatim; `max_content_tokens` backstop holds; ~80% token cut vs baseline (SC#1, SC#2) | ⬜ pending |
| 06-02-* | 02 (Lever B) | 1 | graceful degradation | N/A | behavioral | unknown site / missing region → bounded full fetch, never aborts (SC#4) | ⬜ pending |
| 06-02-* | 02 (Lever B) | 1 | localized site edits | N/A | source | adding/adjusting a site = single `sites.md` edit, no skill restructuring (SC#5) | ⬜ pending |
| 06-03-* | 03 (Validation) | 2 | field coverage | N/A | behavioral | 5 golden scenarios through `/ev-research` reproduce every `VALIDATION-CHECKLIST.md` field (SC#3) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase validation — the Phase 2 golden-run fixtures
(`VALIDATION-CHECKLIST.md`, `02-VALIDATION.md`, 5 golden cars) are the ready-made harness.
No new framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ~80%+ per-page token reduction (SC#1) | Lever B | Token counts are observed from live fetch output, not assertable by a test runner | Capture page-content tokens for each of the 4 known sites with section isolation OFF vs ON; record the delta |
| No context overflow on 5-car run (SC#6) | Lever A | Overflow is a runtime context-window event, only observable during a real multi-car run | Run `/ev-research` with the 5 golden cars; confirm it completes and writes all 5 files + a SUMMARY without exhausting context |
| Fork-boundary isolation (SC#7) | Lever A | Structural property of `context: fork`; verified by inspecting what crosses back to the orchestrator | Confirm the orchestrator's returned context contains only status lines + file paths, never page bodies |

---

## Validation Sign-Off

- [x] All tasks have a behavioral or source verification mapped above
- [x] Sampling continuity: every wave has at least one golden-run check
- [x] Golden-run harness (Phase 2 fixtures) covers all checked fields — 5-car re-run through `/ev-research`, 0 fields dropped (SC#3)
- [x] Token-reduction baseline captured per site (SC#1) — see `06-03-VALIDATION-RESULTS.md`; framing resolved via `06-DECISION-stick-with-webfetch.md`
- [x] `nyquist_compliant: true` set in frontmatter after sign-off

**Approval:** approved 2026-06-23. Phase gate passed: D-01 overflow fixed (Lever A), no fields dropped (SC#3), graceful degradation (SC#4). Lever B trimmed to inline intent; decision to stick with WebFetch recorded.
