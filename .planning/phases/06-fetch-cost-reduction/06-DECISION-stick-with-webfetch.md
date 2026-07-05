---
phase: 06-fetch-cost-reduction
type: decision-record
status: accepted
created: 2026-06-23
decision: Stick with native WebFetch; trim Lever B to inline intent. Do not build a deterministic extractor service now.
supersedes_framing: "Lever B as an ~80% per-page token-cost optimizer (SC#1, D-08a)"
---

# Decision: Stick with WebFetch (and trim Lever B to one layer)

## Context

Phase 6 set out to cut EV-research fetch cost on two levers:
- **Lever A** — `/ev-research` orchestrator isolation (one `/ev-detail` fork per car; orchestrator
  holds only status + paths). Fixes the D-01 root cause: the multi-car run overflowing context.
- **Lever B** — per-fetch "section isolation": a `sites.md` file of per-site region prompts +
  `max_content_tokens`-style ingestion limits, wired into `/ev-detail` Steps 6–9. Framed as an
  **~80% per-page token reduction** (SC#1, D-08a).

Validation (06-03) tested both against the Phase 2 golden-run harness and measured per-site token
deltas. The measurements changed our understanding of Lever B and prompted this decision.

## What we measured (Volvo EX30, 4 known sites)

**Method A — WebFetch returned-content size** (unfiltered prompt vs region prompt):

| Site | Before (chars) | After (chars) | % reduction |
|------|---------------|--------------|-------------|
| ev-database.org | 1,330 | 656 | 50.7% |
| fdm.dk | 1,513 | 1,572 | **−3.9%** |
| wheel-size.com | 1,038 | 656 | 36.8% |
| Bilbasen Blog | 1,177 | 816 | 30.7% |

**Method B — raw page size vs region ingestion cap** (`curl`):

| Site | Raw HTML (~tok) | Stripped text (~tok) | Region cap (~tok) | vs raw-HTML | vs stripped-text |
|------|-----------------|----------------------|-------------------|-------------|------------------|
| ev-database.org | ~38,600 | ~4,390 | 3,000 | ~92% | ~31% |
| fdm.dk | ~94,600 | ~2,610 | 4,000 | ~96% | cap > text (non-binding) |
| wheel-size.com | ~79,800 | ~2,900 | 1,500 | ~98% | ~48% |
| Bilbasen Blog | ~27,500 | ~1,040 | 3,000 | ~89% | cap > text (non-binding) |

## Findings that drove the decision

1. **WebFetch summarizes server-side. The raw page never enters the session.** WebFetch fetches,
   converts HTML→markdown, and runs an internal model pass *before* returning a small result
   (~300–1,500 chars in Method A, regardless of prompt). So the large raw-HTML token counts
   (38k–94k) are **not in our session budget** — they are paid inside WebFetch's service. Our
   per-page session cost is already low without Lever B.

2. **The ingestion-limit lines were unenforceable.** `max_content_tokens` is an API-level parameter
   and **cannot be set from SKILL.md prose** (06-02 Probe 1). The `sites.md` "limit to ~N tokens"
   lines were advisory text to an opaque model, not a real cap — dead weight.

3. **Region prompts added a defect, not proven robustness.** Configuring WebFetch's opaque internal
   pass with an elaborate region prompt does not make the *same* model more reliable — it adds
   variance and a misinterpretation surface. Concretely, it produced the SC#2 **translation bug**:
   the prompt said "return the section," the internal model returned FDM's Danish Styrker/Svagheder
   **translated into English**. Phase 2 (which had *no* region prompts) already achieved full field
   coverage, so the prompts did not demonstrably improve robustness — and the "graceful degradation"
   credited to Lever B (403/500/404 → fallback) is the fork model's own best-effort logic, which
   predates Lever B.

4. **A deterministic extractor service would not bank session tokens — only fidelity.** We considered
   replacing/augmenting WebFetch with an external service (MCP/CLI) that finds the main article and
   strips HTML while preserving structure:
   - **Articles** (fdm.dk, Bilbasen): a solved problem — `trafilatura`/Readability extract clean,
     verbatim, structured markdown deterministically.
   - **Spec tables** (ev-database.org, wheel-size.com): article-extractors mangle tables; you'd need
     per-site CSS selectors — i.e. the maintenance we just trimmed, re-bought as code.
   - **Crucially:** because WebFetch already keeps *session* tokens low, a deterministic extractor
     saves session tokens **only if we also drop WebFetch for a `curl`+extract pipeline** — which
     re-introduces bot-blocking (our `curl` hit the same `volvocars.com` 403 WebFetch absorbs) and
     infra/selector maintenance. Its genuine win is **determinism + verbatim fidelity + no hidden
     model pass**, not token count.

## Decision

**Stick with native WebFetch.** Trim Lever B to a single, controllable instruction layer:
- **Deleted** `.claude/skills/ev-detail/sites.md` (region prompts + unenforceable ingestion limits).
- **Moved** the genuinely useful intent inline into `/ev-detail` Steps 6–9: name the EV-platform
  field, exclude EUR/GBP prices, and **"return verbatim in the original Danish; do not translate"**
  for FDM/Bilbasen sections. Verified by spot-check: FDM pros/cons now return verbatim Danish.
- **Kept Lever A unchanged** — it is the real fix for D-01 and is proven (SC#6/SC#7).
- **Dropped the ~80% per-page token-cost framing** (SC#1). It rested on a misread of how WebFetch
  ingests pages; the dominant cost was always the multi-car overflow, which Lever A eliminates.

**Do not build a deterministic extractor service now.** For ~4 sources researched a few cars at a
time, WebFetch's zero-infrastructure convenience outweighs the determinism gain.

## When to revisit

Reconsider a `curl` + `trafilatura`/CSS-selector pipeline (the only path where the ~80% materializes
as a banked number) **if**:
- model-in-the-loop fidelity issues (translation, table mangling, run-to-run variance) start
  degrading real research output at scale; or
- audit-grade verbatim sourcing becomes a requirement; or
- the source count grows large enough that per-site deterministic extraction pays for its maintenance.
