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
plugins/pingvinen-ev-search/
  .claude-plugin/plugin.json                         # plugin "pingvinen-ev-search" v0.1.0
  skills/{search,detail,compare,new-project,research,switch-project}/SKILL.md
  bin/ev-scaffold                                    # workspace seeder (Bash-tool PATH)
  templates/state.md                                 # seeded into workspace (mutable state)
  reference/car-template.md                          # per-car file format — shipped, not seeded
  README.md
.releaserc.json                                      # semantic-release config
.github/workflows/release.yml                        # release + publish-to-marketplace
```

(The `.claude-plugin/marketplace.json` catalog was later moved out to a separate
marketplace repo — see the release-infrastructure note below.)

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

### Release infrastructure (commit fa795e6)

Adopted a one-repo-per-plugin + shared-marketplace layout so a second plugin slots in and
`main` here stays a work branch:

- Catalog moved OUT of this repo to a separate `pingvinen/claude-plugins` marketplace repo
  (scaffold staged in scratchpad: `marketplace-repo/`). Its entry pins this plugin to a
  `vX.Y.Z` tag via a `git-subdir` source → only tagged commits are served.
- `.releaserc.json` — semantic-release writes the version into `plugin.json` (exec+jq),
  commits it back (git) so the tag carries it, cuts a GitHub Release (github). Conventional
  Commits drive versioning.
- `.github/workflows/release.yml` (`workflow_dispatch`), modelled on the voksenium
  `cycjimmy/semantic-release-action` + `RELEASE_TOKEN_PAT` setup: `release` job tags/releases,
  `publish-to-marketplace` job opens a PR to the marketplace repo pinning the new tag.
  Both `jq` mutations dry-run-verified.

## Install (new flow)

```
/plugin marketplace add pingvinen/claude-plugins
/plugin install pingvinen-ev-search@pingvinen
/pingvinen-ev-search:new-project my-2026-search
```

## Follow-ups (not done here — need action outside this repo / decisions)

- **Create the `pingvinen/claude-plugins` marketplace repo** from the staged scaffold
  (`scratchpad/marketplace-repo/`). Confirm the repo name — `claude-plugins` is a placeholder
  used in the workflow env + docs; rename in lockstep if changed.
- **Add the `RELEASE_TOKEN_PAT` secret** to this repo — a token with `contents:write` here
  AND `contents:write`+`pull-requests:write` on the marketplace repo.
- **Delete `Formula/ev-search-skills.rb` in the separate `pingvinen/homebrew-tap` repo**
  and repoint its README. Documented in PUBLISHING.md.
- Optional: run `claude plugin validate` locally (sandbox git-auth noise blocked it here).
- Optional: repo-root `projects/` + `.gitignore` rules kept intentionally (back the
  local-dev/test-fixture flow).
- Work is on branch `quick/namespace-as-plugin`; open a PR when ready.
