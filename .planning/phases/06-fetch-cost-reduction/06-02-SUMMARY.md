---
phase: 06-fetch-cost-reduction
plan: "02"
subsystem: ev-detail-lever-b
tags: [skill, sites-config, web-fetch, token-reduction]
requires: []
provides: [ev-detail/sites.md, ev-detail-lever-b-wiring]
affects: [ev-detail/SKILL.md]
tech_stack:
  added: []
  patterns: [per-site-region-prompt, prose-ingestion-limit, read-instruction-for-supporting-file]
key_files:
  created:
    - .claude/skills/ev-detail/sites.md
  modified:
    - .claude/skills/ev-detail/SKILL.md
decisions:
  - "Probe 1=b: max_content_tokens is an API-level tool parameter not settable from SKILL.md prose; express backstop as prose ingestion-limit instruction per site"
  - "Probe 2=b: backtick injection with ${CLAUDE_SKILL_DIR}/sites.md not verified for skill supporting files; use Read instruction at Step 6 preamble instead"
  - "sites.md uses prose ingestion limits (~N tokens) as best-effort backstop per each site's typical content weight"
  - "ev-database.org region prompt explicitly names EV-platform field to prevent silent omission (RESEARCH Pitfall 2)"
  - "Fallback entry never aborts; existing per-step abort/degrade split in SKILL.md preserved exactly"
metrics:
  duration: "2m 38s"
  completed: "2026-06-22"
  tasks_completed: 3
  files_changed: 2
status: complete
---

# Phase 06 Plan 02: Lever B — Per-Site Section Isolation Summary

**One-liner:** Per-site region prompts + prose ingestion limits wired into ev-detail Steps 6-9 via a new `sites.md` supporting file, cutting per-page token weight while returning content verbatim for model reading.

---

## What Was Built

### New file: `.claude/skills/ev-detail/sites.md`

A shared supporting file (the "single localized edit point" per D-06/SC#5) containing:
- Five sections: ev-database.org, fdm.dk, wheel-size.com, Bilbasen Blog/Manufacturer DK (with three purchase-type sub-cases: used, new, leasing), and a Fallback entry.
- Each known-site section provides: URL pattern, region prompt (describes WHERE the content is — never pre-parses values), and a prose ingestion limit.
- The ev-database.org region prompt explicitly names every required field group including the EV-platform field (which may sit outside the main spec table), preventing silent omission on trimming.
- The Fallback entry instructs a bounded full fetch (no region prompt, ingestion limit only) and never aborts — preserving SC#4 and D-07.

### Modified file: `.claude/skills/ev-detail/SKILL.md`

Steps 6-9 each received a preamble that:
- Step 6: instructs Claude to Read `.claude/skills/ev-detail/sites.md` at the start of the step; applies the ev-database.org region prompt + ~3,000 token ingestion limit; graceful degradation to bounded full fetch if region yields nothing; existing mandatory-abort rule (D-03) preserved.
- Step 7: applies fdm.dk region prompt + ~4,000 token ingestion limit; graceful degradation; existing best-effort gap-note degrade (D-04) preserved.
- Step 8: applies wheel-size.com region prompt + ~1,500 token ingestion limit; graceful degradation; existing best-effort degrade preserved.
- Step 9: applies the matching sub-case region prompt (used/new/leasing) + sub-case ingestion limit; graceful degradation; existing best-effort degrade preserved.

No field-extraction tables, data-discipline rules, variant-selection logic, or output contracts were altered. SKILL.md remains at 359 lines (under the 500-line limit).

---

## Task 1 — Probe Findings (RESEARCH Open Questions 1 & 3)

### Probe 1 — max_content_tokens settability (RESEARCH Open Question 1 / Assumption A1)

**Outcome: (b) — prose instruction only; no harness-level max_content_tokens from SKILL.md**

**Evidence:** The Anthropic API docs confirm `max_content_tokens` is a tool-definition parameter (JSON schema field configured at the API level). In Claude Code sessions, the harness manages tool configuration; SKILL.md prose is not a tool-configuration mechanism. The dynamic filtering region prompt IS the primary lever (executes server-side before content reaches context). The backstop must therefore be expressed as a prose instruction: "Limit the content you ingest from this fetch to approximately N tokens."

**Impact on implementation:** sites.md expresses each site's backstop as a prose ingestion limit (e.g., "approximately 3,000 tokens" for ev-database.org). The region prompt does the smart selection; the prose limit is a best-effort ceiling hint. This is weaker than a hard tool parameter — an unexpected layout could exceed the prose limit — but the region prompt provides the primary reduction, and the prose limit adds a model-level best-effort guard.

### Probe 2 — ${CLAUDE_SKILL_DIR} backtick injection of sites.md (RESEARCH Open Question 3 / Assumption A3)

**Outcome: (b) — use Read instruction at Step 6 preamble**

**Evidence:** The existing `state.md` backtick injection in ev-detail line 11 uses `cat state.md` — a relative path that resolves from the repo working directory (not from the skill directory). The `state.md` file is at the repo root, making this a coincidence of location rather than evidence that `${CLAUDE_SKILL_DIR}` expands correctly in backtick injections. The RESEARCH.md classifies `${CLAUDE_SKILL_DIR}` backtick injection as ASSUMED (LOW confidence, Open Question 3). Given the risk of a silent load failure (RESEARCH Pitfall 4), the safe verified path is a Read instruction inside the Step 6 preamble.

**Impact on implementation:** A Read instruction `Read '.claude/skills/ev-detail/sites.md'` was added as the first action in Step 6. Steps 7-9 reference "the sites.md read in Step 6" — this keeps the file read once per skill invocation (not per step) and avoids redundant reads.

---

## Deviations from Plan

### None — plan executed exactly as written.

The probe findings matched the RESEARCH.md's anticipated outcomes (both questions resolved as option (b)). The implementation approach (Option B Read instruction, prose ingestion limits) was planned as the fallback and carried through consistently.

---

## Verification Results

Task 2 automated check:
```
test -f .claude/skills/ev-detail/sites.md
grep -q 'ev-database.org' ... fdm.dk ... wheel-size.com ... bilbasen ... fallback ... platform
→ PASS
```

Task 3 automated check:
```
grep -q 'sites.md' SKILL.md → PASS
grep -ci 'region prompt' SKILL.md → 13 occurrences → PASS
wc -l SKILL.md → 359 < 500 → LINECHECK_PASS
```

---

## Success Criteria Status

| SC# | Description | Status |
|-----|-------------|--------|
| SC#1 | ~80% per-page token reduction (measured in Plan 03) | Deferred to Plan 03 measurement |
| SC#2 | Returns sections verbatim, not pre-parsed values | Met — region prompts describe location only; no value extraction in sites.md |
| SC#3 | All VALIDATION-CHECKLIST fields obtainable from trimmed sections | Met — ev-database.org prompt names every required field group including EV-platform |
| SC#4 | Unknown site / missing region falls back to bounded full fetch, never aborts | Met — Fallback entry in sites.md; graceful degradation preamble in each step |
| SC#5 | Adding a site is a single localized sites.md edit | Met — SKILL.md only references sites.md; no step-level site logic |
| RESEARCH OQ#1 | max_content_tokens settability resolved | Resolved: (b) prose instruction only |
| RESEARCH OQ#3 | ${CLAUDE_SKILL_DIR} backtick injection viability | Resolved: (b) Read instruction required |

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 2 | e422a9b | feat(06-02): create ev-detail/sites.md with per-site region selectors and fallback |
| Task 3 | a03eb0d | feat(06-02): wire ev-detail Steps 6-9 to apply per-site region prompts and backstop |

---

## Known Stubs

None. Both deliverable files are fully implemented; no placeholder values or "TODO" stubs.

---

## Threat Flags

No new security-relevant surface introduced. The region prompts are read-only instruction text loaded from a local file (`.claude/skills/ev-detail/sites.md`). The fetched page content (now region-trimmed) crosses into the fork as before — read-only, untrusted, same surface as the pre-existing ev-detail fetch steps.

## Self-Check: PASSED

- `.claude/skills/ev-detail/sites.md` — FOUND
- `.claude/skills/ev-detail/SKILL.md` — FOUND (modified)
- Commit e422a9b — FOUND (git log confirmed)
- Commit a03eb0d — FOUND (git log confirmed)
