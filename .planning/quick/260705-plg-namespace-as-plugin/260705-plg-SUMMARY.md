---
quick_id: 260705-plg
slug: namespace-as-plugin
date: 2026-07-05
status: complete
commit: f42ef51
---

# Summary: Namespace skills as the pingvinen-ev-search plugin

## What was done

Converted the six-skill suite from Homebrew-distributed loose skills into a single
Claude Code **plugin** (`pingvinen-ev-search`) served from a git-hosted **plugin
marketplace** (`pingvinen`) in this repo. Invocations are now
`/pingvinen-ev-search:<skill>` and no longer collide with other publishers' skills.

### Structure

```
.claude-plugin/marketplace.json                     # marketplace "pingvinen"
plugins/pingvinen-ev-search/
  .claude-plugin/plugin.json                         # plugin "pingvinen-ev-search" v0.1.0
  skills/{search,detail,compare,new-project,research,switch-project}/SKILL.md
  bin/ev-scaffold                                    # workspace seeder (Bash-tool PATH)
  templates/state.md                                 # seeded into workspace (mutable state)
  reference/car-template.md                          # per-car file format — shipped, not seeded
  README.md
```

### Post-review refinement (commit f34f58b)

Following review questions: `search` confirmed integral (discovery front-door, not a
leftover); `projects/` + `.gitignore` rules kept (they back the local-dev/test-fixture
flow). `car-template.md` moved from `templates/` (scaffolded) to `reference/` (shipped):
it is a read-only format the skills inline, so scaffolding froze a stale copy that never
tracked plugin updates. `ev-scaffold` now seeds only `state.md`.

- Skills `git mv`d and de-prefixed; every `/ev-<cmd>` cross-reference rewritten to
  `/pingvinen-ev-search:<cmd>` (SKILL.md files, state.md template, README, CLAUDE.md),
  with a guard so `ev-database.org`, `bin/ev-scaffold`, and the repo URL were untouched.
- `new-project` now runs `ev-scaffold` in a new Step 0 to seed the workspace
  deterministically (replaces the retired `ev-search-skills scaffold`).
- Removed `bin/ev-search-skills` and the `.claude/` tree.
- README.md + PUBLISHING.md rewritten for `/plugin marketplace add` + `/plugin install`.

### Verified

- Both manifests parse as JSON; structure matches the documented marketplace/plugin schema.
- No genuine leftover `/ev-<cmd>` invocations or `ev-search-skills` CLI usages (remaining
  hits are intentional: old-install cleanup paths and the `pingvinen/ev-search-skills` URL).
- All skill frontmatter (`context: fork`, `agent: Explore`, `disable-model-invocation`,
  `argument-hint`, `allowed-tools`) preserved across the move; `ev-scaffold` is `+x`.

## Install (new flow)

```
/plugin marketplace add pingvinen/ev-search-skills
/plugin install pingvinen-ev-search@pingvinen
/pingvinen-ev-search:new-project my-2026-search
```

## Follow-ups (not done here — out of this repo's scope)

- **Delete `Formula/ev-search-skills.rb` in the separate `pingvinen/homebrew-tap` repo**
  and repoint its README here. Documented in PUBLISHING.md.
- Optional: `claude plugin validate` could not fully run in this sandbox (git-auth noise);
  run it locally before publishing.
- Optional: the repo-root `projects/` dir and `.gitignore` project rules are now vestigial
  (the repo is a plugin source, not a workspace) — left as-is; prune if desired.
- Work is on branch `quick/namespace-as-plugin`; open a PR when ready.
