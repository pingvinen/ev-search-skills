# Phase 3: Search and Compare - Pattern Map

**Mapped:** 2026-06-27
**Files analyzed:** 2 new skill files
**Analogs found:** 2 / 2

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `.claude/skills/ev-search/SKILL.md` | skill (fetch+write) | batch/transform | `.claude/skills/ev-detail/SKILL.md` | role-match (same site fetching, state.md write, step structure) |
| `.claude/skills/ev-compare/SKILL.md` | skill (read+write) | transform | `.claude/skills/ev-research/SKILL.md` + `.claude/skills/ev-new-project/SKILL.md` | role-match (orchestrator read pattern + write-side frontmatter) |

---

## Pattern Assignments

### `.claude/skills/ev-search/SKILL.md` (skill, fetch+write)

**Primary analog:** `.claude/skills/ev-detail/SKILL.md`
**Secondary analog:** `.claude/skills/ev-switch-project/SKILL.md` (frontmatter with no `context: fork`)

#### Frontmatter pattern

Copy from `.claude/skills/ev-detail/SKILL.md` lines 1–11, **with these changes**:
- `name:` → `ev-search`
- `description:` → search-specific trigger text (see below)
- `allowed-tools:` → `WebFetch, WebSearch, Read, Write, Bash(curl *, python3 *, ls *)`
- Remove `context: fork` and `agent: Explore` — ev-search runs inline (conversation context needed for follow-ups; same rationale as CLAUDE.md "search outputs to conversation" pattern)
- Keep `argument-hint:` absent (no arguments — reads brief.md instead)

```yaml
---
name: ev-search
description: Search for EV models matching the active project's criteria. Use when the user wants to find matching cars, run a search, or discover candidates. Reads brief.md and writes Search Candidates to state.md.
allowed-tools: WebFetch, WebSearch, Read, Write, Bash(curl *, python3 *, ls *)
---
```

#### Backtick injection pattern

Copy from `.claude/skills/ev-detail/SKILL.md` line 11 verbatim:

```
!`cat state.md 2>/dev/null || echo "state.md not found — no active project. Run /ev-new-project first."`
```

No `$ARGUMENTS` line (skill takes no arguments — criteria come from brief.md).

#### Step 1 — Active project resolution pattern

Copy from `.claude/skills/ev-detail/SKILL.md` lines 26–33 (Step 1 block) verbatim. Same guard: stop if `active_project` is `none` or state file not found.

#### Step 2 — Read project inputs pattern

Copy from `.claude/skills/ev-detail/SKILL.md` lines 37–43 (Step 2 block). For ev-search, read only `brief.md` (not state.md Research Progress table, which is irrelevant here). Adapt the field list to the brief's search-relevant fields: `budget` (preferred + maximum), `per_brand_overrides`, `body_type`, `seats`, minimum range, `must-have features`.

#### Bash(curl) + Bash(python3) discovery pattern

No existing analog — this is new. Use the extraction script from RESEARCH.md Pattern 1 (lines 246–298) as the implementation reference. Key conventions to embed in the skill steps:

```
Step: Fetch ev-database.org listing
Bash: curl -s -A "Mozilla/5.0" https://ev-database.org -o /tmp/evdb_listing.html

Sanity check before parsing:
Bash: wc -c /tmp/evdb_listing.html
If file is under 100,000 bytes: abort — bot detection triggered; tell the user.
```

```python
# Inline Python script passed to Bash(python3 -c "...")
# or written to /tmp/evdb_filter.py and executed
# Key shape class → body type mapping (embed in skill step):
# "SUV" / "crossover" → shape-suv
# "hatchback" → shape-hatchback
# "estate" / "wagon" → shape-station
# "sedan" → shape-sedan
# "MPV" → shape-mpv
# "pickup" → shape-pickup
```

Output format per candidate (pipe-delimited for easy shell parsing):
```
{name}|{url}|{range_km}km|{battery_kwh}kWh|EUR{price_eur}
```

#### DK price band WebSearch pattern

No existing analog — new. One WebSearch per candidate (≤20 candidates after filter + EUR pre-cap):

```
WebSearch: "<make> <model> pris DKK"
Extract first DKK price figure from snippet.
Bucket against brief budget:
  ≤ preferred → "within budget"
  between preferred and maximum → "slight stretch"
  > maximum (but within per-brand override if applicable) → "over budget"
  no price found → "price unknown"
```

Apply per-brand overrides from brief: use maximum budget × override multiplier as that brand's ceiling.

#### state.md write pattern (Search Candidates section)

Derived from `.claude/skills/ev-detail/SKILL.md` lines 323–338 (Step 12 — state.md update). Same Read-modify-Write pattern:

```
1. Read projects/<active_project>/state.md
2. If "## Search Candidates" section exists:
     Replace from "## Search Candidates" to the next "## " heading (or EOF) with new section content
   Else:
     Append new "## Search Candidates" section at end of file
3. Write full updated content back to projects/<active_project>/state.md
```

Search Candidates section schema (from RESEARCH.md Pattern 4, lines 342–353):

```markdown
## Search Candidates

_Last updated: [date] — criteria: [body type], [seats]+ seats, range ≥[X]km, battery ≥[Y]kWh, budget [preferred]–[max] DKK_

| Model | ev-database URL | Body | EVDB Range | Battery | DK Price Band | Verdict |
|-------|----------------|------|------------|---------|---------------|---------|
| Volvo EX30 SM ER | https://ev-database.org/car/1910/... | SUV | 365 km | 65 kWh | within budget (268–299k DKK) | match |
| BYD Atto 3 | https://ev-database.org/car/... | SUV | 330 km | 60 kWh | slight stretch (~370k DKK) | borderline: near budget ceiling |
```

**Column label note:** Always use "EVDB Range" (not "WLTP") for the range column — RESEARCH.md lines 356–360 document that `erange_real` is EVDB's own standardized estimate, not WLTP.

#### Conversation output + handoff pattern

No exact analog. Pattern from CLAUDE.md "search outputs to conversation" convention and CONTEXT.md D-11:

```
After writing state.md:
1. Present ranked candidate table in conversation (matches / borderlines / excluded separately)
2. End with copy-paste handoff command:
   /ev-research "Model A" "Model B" "Model C"
   listing only the match + borderline cars (not excluded).
```

---

### `.claude/skills/ev-compare/SKILL.md` (skill, transform/write)

**Primary analog (frontmatter):** `.claude/skills/ev-research/SKILL.md` lines 1–6 (write-side frontmatter with `disable-model-invocation: true`)
**Secondary analog (step structure):** `.claude/skills/ev-new-project/SKILL.md` lines 1–6 (Write-access skill, Glob pattern)

#### Frontmatter pattern

Copy from `.claude/skills/ev-research/SKILL.md` lines 1–6, with these changes:
- `name:` → `ev-compare`
- `description:` → compare-specific trigger text
- `allowed-tools:` → `Read, Write, Glob`
- Keep `disable-model-invocation: true` — mandatory (CONTEXT.md D-18, RESEARCH.md Pitfall 4)
- Remove `argument-hint` — no arguments needed

```yaml
---
name: ev-compare
description: Generate a comparison table from all researched cars in the active project. Reads all research/*.md files and writes comparison.md. Must be invoked explicitly — never auto-triggered.
allowed-tools: Read, Write, Glob
disable-model-invocation: true
---
```

#### Backtick injection pattern

Copy from `.claude/skills/ev-switch-project/SKILL.md` line 10 verbatim (same `cat state.md` pattern without `$ARGUMENTS` line):

```
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`
```

No `$ARGUMENTS` — no argument-hint needed.

#### Step 1 — Active project resolution pattern

Copy from `.claude/skills/ev-detail/SKILL.md` lines 26–33 (same guard). Identical to all other skills.

#### Glob → Read loop pattern

No exact analog for Glob in existing skills. Pattern from CLAUDE.md "comparison-skill stack pattern" and RESEARCH.md COMP-01:

```
Step: Discover research files
Glob: projects/<active_project>/research/*.md

For each path returned by Glob:
  Read the file
  Extract: all Specs table rows, EV platform line, FDM Test Notes,
           Ownership Signals, Pros, Cons
```

**Important:** Glob path MUST be constructed from the resolved `active_project` value, never hardcoded — RESEARCH.md Pitfall 5 (lines 470–476).

#### Comparison table output pattern

From RESEARCH.md Pattern 5 (lines 363–396) and Code Examples (lines 514–524). Row set from `car-template.md` lines 19–33:

```markdown
| Field | [Car A] | [Car B] | [Car C] |
|-------|---------|---------|---------|
| **WLTP range (km)** (manufacturer rated) | 476 | 410 | 402 |
| **Real-world range (mild) (km)** (FDM 110km/h, 20°C) | **330** | no FDM test | no FDM test |
| **Real-world range (cold) (km)** (FDM 110km/h, 0°C) | 275 | no FDM test | no FDM test |
| Battery (usable) (kWh) | | | |
| DC charge peak (kW) (manufacturer rated) | | | |
| AC charge rate (kW) | | | |
| 10-80% DC charge time (min) | | | |
| 0-100 km/h (s) | | | |
| Cargo (L) | | | |
| Tow capacity (kg) | | | |
| Tire size (front) | | | |
| Tire size (rear) | | | |
| Price DK tier 1 (from) (DKK) | | | |
| Price DK tier 2 (best value) (DKK) | | | |
| Power output (kW) | | | |
| EV platform | | | |
| FDM verdict (one-liner) | | | |
| FDM Styrker (top 2) | | | |
| FDM Svagheder (top 2) | | | |
| Ownership confidence | | | |
```

**Best-in-class marking:** Bold the best value per row. Higher-is-better rows (range, battery, cargo, tow): bold the highest. Lower-is-better rows (charge time, 0-100, price): bold the lowest.

**Gap rendering (D-17):** Explicit text, never blank:
- No FDM data → `no FDM test`
- Tire unconfirmed → `unconfirmed`
- Price not applicable for purchase type → `not available (leasing)`

**Output structure:**
```markdown
# Comparison: [active_project]

**Generated:** [date]
**Cars compared:** [N] — [list names]
**Sorted by:** [sort key used — e.g. "WLTP range descending"]

## Brief-Aware Verdict

[2-3 sentences: best fit for this brief and why, reasoned from the data]

## Spec Comparison

[full table above]
```

#### Write output pattern

Copy from `.claude/skills/ev-new-project/SKILL.md` Step 3c pattern: single Write call to `projects/<active_project>/comparison.md`. Overwrite unconditionally (no overwrite guard — the skill is explicitly invoked, D-18 `disable-model-invocation: true` prevents accidental triggers).

---

## Shared Patterns

### Active project resolution
**Source:** `.claude/skills/ev-detail/SKILL.md` lines 26–33
**Apply to:** Both new skills (Step 1 of each)
```
From the injected global state above, extract the `active_project` value.

If `active_project` is `none` or the state file was not found: stop immediately and tell the user:

> No active project found. Run `/ev-new-project [name]` to create a project first, or `/ev-switch-project [name]` to switch to an existing project.

Do not proceed.
```

### Backtick injection
**Source:** `.claude/skills/ev-detail/SKILL.md` line 11 / `.claude/skills/ev-switch-project/SKILL.md` line 10
**Apply to:** Both new skills (top of file, before step body)
```
!`cat state.md 2>/dev/null || echo "state.md not found — no active project. Run /ev-new-project first."`
```

### Numbered-step body discipline
**Source:** All existing skills (ev-detail, ev-research, ev-new-project, ev-switch-project)
**Apply to:** Both new skills
- Steps are numbered, titled, ordered
- Each step has "Follow these steps in order. Do NOT skip steps or reorder them." directive at top
- Best-effort steps say "never abort on a miss; write gap note and continue"
- Mandatory steps say "ABORT immediately" or "stop and tell the user"

### Write-side frontmatter gate
**Source:** `.claude/skills/ev-research/SKILL.md` line 5
**Apply to:** `/ev-compare` only
```yaml
disable-model-invocation: true
```
Must be present. Without it, Claude auto-invokes the skill on natural-language triggers and overwrites `comparison.md` without user intent.

### state.md Read-modify-Write
**Source:** `.claude/skills/ev-detail/SKILL.md` lines 323–338 (Step 12)
**Apply to:** `/ev-search` (writing Search Candidates section)
Pattern: always Read the full file first, modify the target section, Write the full content back. Never truncate other sections.

---

## No Analog Found

| File / Pattern | Reason |
|----------------|--------|
| `Bash(curl)` + `Bash(python3)` discovery step | No existing skill uses curl or python3; this is new to Phase 3 |
| DK price band via WebSearch snippet | No existing skill does per-item WebSearch for a price signal |
| Glob → Read loop for multiple research files | No existing skill reads multiple files via Glob |
| "Search Candidates" section schema in state.md | state.md currently has Research Progress / Source Reliability Notes / Discovered Sources sections only; new section appended |

For these patterns, use the RESEARCH.md Code Examples and Architecture Patterns sections directly (lines 246–298 for the Python extraction script; lines 342–353 for the state.md section schema; lines 363–396 for the comparison table layout).

---

## Metadata

**Analog search scope:** `.claude/skills/` (all 4 existing skills read in full)
**Canonical data contracts read:** `car-template.md` (15 spec rows), `projects/test-ev-detail-new/state.md` (section structure)
**Files scanned:** 6 (4 skill SKILL.md files + car-template.md + state.md)
**Pattern extraction date:** 2026-06-27
