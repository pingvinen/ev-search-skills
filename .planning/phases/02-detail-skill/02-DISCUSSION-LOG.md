# Phase 2: Detail Skill - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-22
**Phase:** 2-detail-skill
**Areas discussed:** Tire scope, Sourcing & failure handling, Variant resolution, Purchase type, Used/lease data granularity, Re-run behavior

---

## Tire Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Basic now, skill later | Capture tire size + all-season price estimate inline (TIRE-01/02/03); defer scoring skill | |
| Full tire stack now | Build /ev-tire-sources + median-of-histogram + top-3 in this phase | |
| Detail skill only | /ev-detail with tire size only; defer all pricing + sourcing | ✓ |

**User's choice:** Detail skill only.
**Notes:** Tire size captured (TIRE-01) but no pricing/scoring in Phase 2. Flagged that this defers TIRE-02/TIRE-03 which currently appear in ROADMAP SC#4 / Phase 2 requirements line — recorded as a ROADMAP reconciliation item.

---

## Sourcing & Failure Handling

| Option | Description | Selected |
|--------|-------------|----------|
| ev-db mandatory, rest best-effort | ev-database required (abort if not found); FDM/greengarage/tire best-effort with noted gaps | ✓ |
| All best-effort, always write | Never abort; always write with missing fields flagged | |
| Strict — all-or-nothing | Require ev-db + FDM attempt; refuse below completeness threshold | |

**User's choice:** ev-db mandatory, rest best-effort.
**Notes:** Matches DETL-08 graceful-degradation intent.

---

## Variant Resolution

| Option | Description | Selected |
|--------|-------------|----------|
| Ask user to pick | List matching variants, user chooses | |
| Pick best BRIEF match | Auto-select variant best fitting BRIEF; document choice | ✓ (modified) |
| Document all in one file | One file, section per variant | |

**User's choice:** Pick best BRIEF match, with a middle-tier tie-breaker.
**Notes:** User added the tie-breaker rule — when ambiguous, prefer the middle tier; historically, 3-variant lineups have the middle trim as best value for money.

---

## Purchase Type

| Option | Description | Selected |
|--------|-------------|----------|
| new only now | Handle purchase_type=new fully; defer used/leasing | |
| All three now | Branch /ev-detail: used → Bilbasen, leasing → monthly + residual | ✓ |
| new + used now, leasing later | Handle new + used; defer leasing | |

**User's choice:** All three now.
**Notes:** Follow-up clarified granularity (see next area).

---

## Used/Lease Data Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Market range, not listings | Used → DKK low/typical/high range; leasing → typical monthly + residual range | ✓ |
| Specific best listing | Fetch and cite a specific current listing/offer | |
| Both: range + one example | Market range plus one representative listing | |

**User's choice:** Market range, not listings.
**Notes:** Research tool, not purchase tool — avoid stale single-listing data.

---

## Re-run Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Overwrite + refresh dates | Re-fetch and overwrite; git preserves history | |
| Ask before overwriting | Detect existing file; ask overwrite/skip/update | ✓ |
| Skip with notice | Skip if file exists; require manual delete | |

**User's choice:** Ask before overwriting.
**Notes:** Protects against clobbering manual edits.

---

## Claude's Discretion

- FDM article discovery strategy (WebSearch patterns, attempt count before "no test found").
- greengarage.dk usage (best-effort, fetch-safety unverified).
- ev-database.org token-ceiling mitigation.
- Confidence-label wording and per-section guidance (already in car-template.md).
- `<make-model>.md` filename normalization.
- Per-project state.md update format.

## Deferred Ideas

- Tire pricing + tire-research prompt (TIRE-02, TIRE-03).
- Global /ev-tire-sources skill + median-of-histogram scoring + top-3 recommendations (TIRE-04..07) — its own future phase.
- ROADMAP/REQUIREMENTS reconciliation: move TIRE-02..07 out of Phase 2 before verification.
