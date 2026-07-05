---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no runtime code — all deliverables are markdown files and SKILL.md prompts) |
| **Config file** | none |
| **Quick run command** | `ls -la state.md car-template.md .claude/skills/ev-new-project/SKILL.md .claude/skills/ev-switch-project/SKILL.md` |
| **Full suite command** | `find projects/ .claude/skills/ -name "*.md" \| head -20 && cat state.md` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run `ls -la` on expected output files
- **After every plan wave:** Verify all expected files exist with correct structure
- **Before `/gsd:verify-work`:** Full file existence and content grep checks
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | SRCH-04 | file+grep | `grep -c "WLTP range" car-template.md && grep -c "Real-world range" car-template.md` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | SRCH-05 | file+grep | `grep -c "WLTP" car-template.md && grep -c "Real-world\|FDM" car-template.md && grep -c "Source URL" car-template.md` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | PROJ-01 | file | `test -f .claude/skills/ev-new-project/SKILL.md` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | PROJ-02 | file | `test -f .claude/skills/ev-switch-project/SKILL.md` | ❌ W0 | ⬜ pending |
| 01-02-03 | 02 | 2 | PROJ-03, PROJ-04 | file+grep | `grep "active_project" state.md` | ❌ W0 | ⬜ pending |
| 01-02-04 | 02 | 2 | SRCH-01, SRCH-06 | file+grep | `grep -c "BRIEF.md" .claude/skills/ev-new-project/SKILL.md && grep -c "purchase.type\|Purchase type" .claude/skills/ev-new-project/SKILL.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No test framework installation needed — all verification is file existence and content grep
- Phase 1 produces only markdown files and SKILL.md prompt files; no runtime code to unit-test

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `/ev-new-project "family-ev"` creates correct folder structure | PROJ-01 | Requires Claude Code skill invocation | Run `/ev-new-project "family-ev"` and verify `projects/family-ev/BRIEF.md`, `projects/family-ev/research/`, `projects/family-ev/comparison.md` exist |
| `/ev-switch-project "family-ev"` updates active project | PROJ-02 | Requires Claude Code skill invocation | Run `/ev-switch-project "family-ev"` and check `state.md` contains `family-ev` as active project |
| WLTP/real-world range cannot be silently mixed | SRCH-05 | Requires reading template guidance and verifying structural separation | Inspect `car-template.md` for separate WLTP and real-world range rows with separate source columns |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 1s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
