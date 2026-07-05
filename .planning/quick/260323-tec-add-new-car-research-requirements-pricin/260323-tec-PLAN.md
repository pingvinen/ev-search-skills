---
phase: quick-260323-tec
plan: "01"
objective: "Add new car research requirements: pricing tiers, wireless Android Auto, brand quality history, EV-native platform, per-brand budget exception"
tasks: 3
wave: 1
autonomous: true
---

# Quick Task 260323-tec Plan 01

## Task 1: Update REQUIREMENTS.md with new requirements

**Files:** `.planning/REQUIREMENTS.md`
**Action:** Add new requirements in appropriate sections:
- **DETL-09**: Per-car file includes tier 1 ("from price") and tier 2 equipment package DKK prices
- **DETL-10**: Per-car file notes whether the car is built on a dedicated EV platform or an adapted ICE platform
- **SRCH-04**: Search criteria schema supports per-brand budget overrides (e.g., a higher ceiling for one brand where the user has a discount arrangement)
- **SRCH-05**: Search criteria schema supports must-have features list (e.g., wireless Android Auto)
- **OWNR-06**: Brand research captures quality track record for the past 10 years — recent history only, not legacy reputation
- Update traceability table: DETL-09, DETL-10 → Phase 2; SRCH-04, SRCH-05 → Phase 1; OWNR-06 → Phase 4
- Update coverage count from 28 to 33 (adding 5 new requirements)

**Verify:** grep for DETL-09, DETL-10, SRCH-04, SRCH-05, OWNR-06 in REQUIREMENTS.md
**Done:** All 5 new requirements present with traceability

## Task 2: Update PROJECT.md active requirements and context

**Files:** `.planning/PROJECT.md`
**Action:**
- Add active requirements for pricing tiers, must-have features, brand quality research, and EV platform status
- Add context bullet about a per-brand budget override (a higher ceiling for one brand where the user has a discount arrangement)
- Add context bullet about wireless Android Auto as a must-have

**Verify:** PROJECT.md mentions pricing tiers, Android Auto, per-brand budget override, EV platform
**Done:** PROJECT.md reflects all new requirements and context

## Task 3: Update ROADMAP.md phase details

**Files:** `.planning/ROADMAP.md`
**Action:**
- Phase 1: Add SRCH-04, SRCH-05 to requirements list; add success criteria for per-brand budget overrides and must-have features in criteria schema
- Phase 2: Add DETL-09, DETL-10 to requirements list; add success criteria for pricing tiers and EV platform notation
- Phase 4: Add OWNR-06 to requirements list; add success criterion for 10-year brand quality research

**Verify:** All new requirement IDs appear in correct phases
**Done:** Roadmap phases include new requirements and success criteria
