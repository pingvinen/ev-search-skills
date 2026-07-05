---
phase: 06-fetch-cost-reduction
plan: 03
type: summary
status: complete
created: 2026-06-23
---

# Plan 06-03 Summary — Phase Gate Validation

Validated the two-lever fetch-cost reduction and closed the phase gate (D-08).

## What was done

- **Task 1 — per-site token measurement (SC#1):** measured Volvo EX30 across the 4 known sites with
  two methods (WebFetch returned-size; `curl` raw-size vs region cap). Recorded in
  `06-03-VALIDATION-RESULTS.md`.
- **Task 2 — 5-car golden re-run through `/ev-research` (SC#2/3/4/6/7):** drove the 5 Phase 2 golden
  scenarios across all 3 test projects through the orchestrator (one isolated `/ev-detail` fork per
  car, status+path returned only). Field coverage verified against `VALIDATION-CHECKLIST.md`.
- **Task 3 — human-verify gate:** approved after a discussion that reframed the conclusion.

## Outcome (phase gate: PASSED)

| SC | Result |
|----|--------|
| SC#7 orchestrator holds only status+paths | ✅ D-01 multi-car overflow structurally closed |
| SC#6 5-car run, no overflow | ✅ all files written |
| SC#3 no field dropped | ✅ 0 fails across 5 files |
| SC#4 graceful degradation | ✅ live 403/500/404 misses all degraded, none aborted |
| SC#2 verbatim, not pre-parsed | ✅ (no JSON); FDM English-paraphrase defect **fixed** by the trim below |
| SC#1 ~80% per-page cut | Framing **dropped** — resolved via decision to stick with WebFetch |

## Key decision & deviation (validation-driven)

The SC#1/SC#2 shortfalls traced to one cause: Lever B configured WebFetch's opaque internal pass with
region prompts that added variance (translation bug) without proven gain, and its ingestion-limit
lines were unenforceable from prose (`max_content_tokens` is API-only).

**Lever B was trimmed to one controllable layer** (deviation from 06-02 as built):
- Deleted `.claude/skills/ev-detail/sites.md`.
- Moved useful intent (name EV-platform field, exclude EUR/GBP, "return verbatim, don't translate")
  inline into `/ev-detail` Steps 6–9.
- Kept Lever A (`/ev-research`) unchanged — the real D-01 fix.

Spot-checked the trimmed skill (EX30 new): runs cleanly with no `sites.md`, FDM pros/cons now verbatim
Danish, graceful degradation intact.

**Decision recorded:** stick with native WebFetch; do not build a deterministic extractor service now.
Full argument + measurements in `06-DECISION-stick-with-webfetch.md`.

## Key files

- Created: `06-03-VALIDATION-RESULTS.md`, `06-DECISION-stick-with-webfetch.md`
- Modified: `.claude/skills/ev-detail/SKILL.md` (Steps 6–9 trimmed to inline intent)
- Deleted: `.claude/skills/ev-detail/sites.md`
- Validation byproducts: regenerated `projects/ev-detail-test-*/research/*.md` fixtures (scenario 1
  post-trim/verbatim; scenarios 2–4 pre-trim/paraphrase — optional cleanup)

## Follow-ups (optional)

- Regenerate the 4 pre-trim fixtures through the trimmed skill for verbatim consistency.
- Revisit a `curl`+`trafilatura`/CSS-selector pipeline only if model-in-loop fidelity issues bite at
  scale or audit-grade verbatim sourcing is required (see decision record "When to revisit").

## Self-Check: PASSED
