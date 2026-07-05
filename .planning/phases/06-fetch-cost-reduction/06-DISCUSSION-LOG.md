# Phase 6: Fetch-Cost Reduction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-22
**Phase:** 06-fetch-cost-reduction
**Areas discussed:** Phase scope vs MCP, Fetch-trim mechanism, Per-site config home, Baseline & validation, (emergent) Per-car isolation architecture

---

## WebFetch mechanics (clarifying exchange, no decision)

The user questioned how the WebFetch region prompt could save tokens if "something has to read all the HTML to apply the prompt." Clarified (verified against the cached claude-api skill reference):
- HTML→text conversion is server-side and never enters the model's context window.
- `max_content_tokens` truncates the *cleaned* ingested text.
- `web_fetch_20260209` dynamic filtering trims **before** content reaches context.
- A fetched page is re-billed as input on every subsequent turn within a fork, so per-page cuts compound across turns.

User also asked whether `web_fetch_20260209` was stale/locked: it is a date-versioned tool identifier (current per cached refs), and `/ev-detail` is unversioned anyway (`allowed-tools: WebFetch`), so nothing is pinned. Filtered-out content is off-context but not strictly free — two things are being protected: context window and the token bill. All folded into CONTEXT D-09 / D-10.

---

## Phase scope vs MCP — REFRAMED mid-discussion

Original question (in-skill only / in-skill+MCP / decide-after-spike) was superseded once the user observed that the 02-03 overflow was an **architecture** problem: each car should run in its own agent context. Grounding confirmed the executor ran all 5 cars in one context (02-03-SUMMARY) and that `/ev-detail` already forks per call. The scope question was re-posed against this understanding.

| Option | Description | Selected |
|--------|-------------|----------|
| Both levers, isolation first | Re-scope to context-cost reduction: per-car isolation, then per-fetch section isolation; MCP likely unnecessary | ✓ |
| Isolation only; defer fetch work | Phase becomes isolation-only; measure, open a later phase for fetch if needed | |
| Fetch-only; isolation elsewhere | Keep ROADMAP fetch scope; handle batching separately | |

**User's choice:** Both levers, isolation first.
**Notes:** User: "each car should be done in its own agent with a clear context… I do not see any gains from doing 5 cars in a single agent context." → CONTEXT D-01, D-02, D-04.

---

## Per-car isolation architecture (Lever A)

| Option | Description | Selected |
|--------|-------------|----------|
| Batch orchestrator skill | `/ev-research` spawns one isolated `/ev-detail` fork per car; collects only status + file path | ✓ |
| Documented invariant, no new skill | Hard rule to always invoke per-car forks; no enforcement | |
| Fix validation layer only | Narrow fix to the golden-run harness; no general batch tool | |

**User's choice:** Batch orchestrator skill.
**Notes:** Structural isolation guarantee, reusable for real research sessions. → CONTEXT D-02, D-03.

---

## Fetch-trim mechanism (Lever B)

| Option | Description | Selected |
|--------|-------------|----------|
| Region prompt + token cap | Per-site prompt targets the region; `max_content_tokens` backstop | ✓ |
| Region prompt only | Filter prompt, no hard ceiling | |
| Token cap only | Blunt cap, no region targeting | |

**User's choice:** Region prompt + token cap. → CONTEXT D-05.

---

## Per-site config home

| Option | Description | Selected |
|--------|-------------|----------|
| Shared sites.md supporting file | Region hints + URL patterns in one reusable file | ✓ |
| Inline in ev-detail SKILL.md | Per-site prompts in the skill body | |

**User's choice:** Shared `sites.md`. → CONTEXT D-06.

---

## Baseline & validation

| Option | Description | Selected |
|--------|-------------|----------|
| Per-site before/after + golden re-run | Measure per-site token delta (SC#1) + re-run 5 scenarios via `/ev-research` (SC#3, no overflow) | ✓ |
| Per-site token check only | Measure reduction, trust existing field coverage | |
| Field-coverage only | Re-run scenarios, no measured token figure | |

**User's choice:** Per-site before/after + golden re-run. → CONTEXT D-08.

---

## Claude's Discretion

- Parallel vs sequential fan-out of per-car forks in `/ev-research`.
- Exact `max_content_tokens` value per site.
- Precise region-prompt wording per site.
- Orchestrator end-of-run summary format.

## Deferred Ideas

- MCP "sections server" — deferred unless in-skill Lever A + B prove insufficient.
- Structured value extraction — remains rejected; Firecrawl reserved for bot-blocking only.
