---
phase: quick-260325-otn
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/REQUIREMENTS.md
  - .planning/PROJECT.md
autonomous: true
requirements: []
must_haves:
  truths:
    - "REQUIREMENTS.md contains tire research requirements with global tire sources skill, median-of-histogram scoring methodology, and expandable source pool"
    - "REQUIREMENTS.md contains purchase type requirement for search criteria (new, used, leasing)"
    - "PROJECT.md reflects all three new requirement areas in Active requirements and Context"
    - "New requirements integrate with existing multi-project architecture (per-project tire sources, purchase type per project)"
  artifacts:
    - path: ".planning/REQUIREMENTS.md"
      provides: "New TIRE-xx, SRCH-xx requirements"
      contains: "median-of-histogram"
    - path: ".planning/PROJECT.md"
      provides: "Updated Active requirements and Context sections"
      contains: "purchase type"
  key_links:
    - from: ".planning/REQUIREMENTS.md"
      to: ".planning/PROJECT.md"
      via: "requirement IDs referenced in both files"
      pattern: "TIRE-|SRCH-"
---

<objective>
Add three new requirement areas to PROJECT.md and REQUIREMENTS.md: (1) a tire research capability with a global tire sources skill that identifies trustworthy tire testers, scores tires using median-of-histogram approach, and supports expanding the source pool over time; (2) a purchase type field in search criteria supporting new, used, or leasing; (3) integration of both with the existing multi-project/multi-search architecture.

Purpose: Expand the requirements baseline before implementation begins, so Phase 1/2 planning can account for these capabilities.
Output: Updated REQUIREMENTS.md and PROJECT.md with new requirement IDs and context.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@search_criteria.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add tire research and purchase type requirements to REQUIREMENTS.md</name>
  <files>.planning/REQUIREMENTS.md</files>
  <action>
Add the following new requirements to REQUIREMENTS.md. Place them in the appropriate existing sections or create new sections as needed.

**Tire section — expand existing Tires section with new requirements after TIRE-03:**

- [ ] **TIRE-04**: A global "tire sources" skill (`/ev-tire-sources`) identifies and maintains a list of 5+ trustworthy tire testers/reviewers (e.g., ADAC, TCS, AutoBild, etc.) — stored in a shared `tire-sources.md` file at repo root (not per-project)
- [ ] **TIRE-05**: Tire scoring uses a median-of-histogram approach — for each tire model, collect ratings from all available sources, treat the collection as a histogram, and use the median as the representative score (the most typical value, resistant to outlier reviews)
- [ ] **TIRE-06**: The tire sources list is designed for expansion — adding a new source means adding an entry to `tire-sources.md` with URL pattern and extraction hints; existing tire scores automatically incorporate the new source on next research run
- [ ] **TIRE-07**: Per-car tire research recommends top 3 all-season tires for the car's tire size, each with median score, price, and sources consulted

**Search section — add after SRCH-05:**

- [ ] **SRCH-06**: Search criteria schema includes a `purchase_type` field with values: `new`, `used`, or `leasing` — defaults to `new` if omitted
- [ ] **SRCH-07**: Purchase type influences which data sources and price fields are relevant (e.g., `used` triggers Bilbasen price lookup; `leasing` captures monthly payment and residual)

**Update the Traceability table** to include the new requirements. For phase mapping:
- TIRE-04, TIRE-05, TIRE-06 map to Phase 2 (Detail Skill) since tire research is part of the detail skill
- TIRE-07 maps to Phase 2
- SRCH-06 maps to Phase 1 (Foundation) since it is a search criteria schema change
- SRCH-07 maps to Phase 2 (Detail Skill) since it affects data source selection

Update the coverage count at the bottom of the Traceability section.
  </action>
  <verify>
    <automated>grep -c "TIRE-04\|TIRE-05\|TIRE-06\|TIRE-07\|SRCH-06\|SRCH-07" .planning/REQUIREMENTS.md | grep -q "^6$" && echo "PASS: All 6 new requirements present" || echo "FAIL"</automated>
  </verify>
  <done>REQUIREMENTS.md contains all 6 new requirement IDs (TIRE-04 through TIRE-07, SRCH-06, SRCH-07) with full descriptions, traceability rows, and updated coverage count</done>
</task>

<task type="auto">
  <name>Task 2: Update PROJECT.md with new requirement areas and context</name>
  <files>.planning/PROJECT.md</files>
  <action>
Update PROJECT.md to reflect the three new requirement areas.

**Active requirements section — add these bullet points:**

- [ ] Tire research uses a global tire sources skill that identifies 5+ trustworthy tire testers and scores tires using median-of-histogram methodology (median = most typical value across sources)
- [ ] The tire sources pool is expandable — adding a new source does not require restructuring existing scores
- [ ] Per-car files recommend top 3 all-season tires with median scores and pricing for the car's tire size
- [ ] Search criteria include a purchase type field (`new`, `used`, `leasing`) that influences data sources and price fields
- [ ] Purchase type integrates with multi-project architecture — each project's `search_criteria.md` specifies its own purchase type

**Context section — add these bullets:**

- Tire scoring uses median-of-histogram: collect ratings from multiple testers, use median as representative score — resistant to outlier reviews and naturally improves as more sources are added
- Global tire sources list (`tire-sources.md`) is shared across projects — tire tester quality is not project-specific
- Purchase type (new/used/leasing) is per-project — a "family EV" project might be buying new while a "commuter" project explores leasing
- For used cars, Bilbasen is the primary DK source for pricing; for leasing, monthly payment and residual value matter more than sticker price

**Do NOT modify Key Decisions, Constraints, or Out of Scope sections** — these new areas fit within the existing project boundaries.
  </action>
  <verify>
    <automated>grep -q "median-of-histogram" .planning/PROJECT.md && grep -q "purchase.type" .planning/PROJECT.md && grep -q "tire-sources.md" .planning/PROJECT.md && echo "PASS" || echo "FAIL"</automated>
  </verify>
  <done>PROJECT.md Active requirements include tire research methodology, expandable sources, and purchase type. Context section explains median-of-histogram scoring, global vs per-project scope, and purchase type implications.</done>
</task>

</tasks>

<verification>
- All 6 new requirement IDs exist in REQUIREMENTS.md with descriptions
- Traceability table maps each new requirement to a phase
- Coverage count is updated
- PROJECT.md Active section references tire research, median-of-histogram, expandable sources, and purchase type
- PROJECT.md Context section explains the scoring methodology and per-project vs global scope
- No changes to ROADMAP.md (quick task, not phase work)
- No changes to code or skills
</verification>

<success_criteria>
REQUIREMENTS.md has 6 new requirement IDs (TIRE-04..07, SRCH-06..07) with full descriptions and traceability. PROJECT.md reflects tire research methodology, expandable source pool, and purchase type in both Active requirements and Context. New requirements reference integration with multi-project architecture where relevant.
</success_criteria>

<output>
After completion, create `.planning/quick/260325-otn-add-tire-research-purchase-type-and-inte/260325-otn-SUMMARY.md`
</output>
