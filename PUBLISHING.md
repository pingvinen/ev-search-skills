# Publishing & maintenance

How this repo gets published as a Claude Code plugin marketplace. Consumers don't need
this file — it's for the maintainer.

## What this repo is

This repository is a **Claude Code plugin marketplace** named `pingvinen`. It hosts a
single plugin, `pingvinen-ev-search`.

```
.claude-plugin/marketplace.json        # marketplace catalog (name: pingvinen)
plugins/pingvinen-ev-search/
  .claude-plugin/plugin.json           # plugin manifest (name: pingvinen-ev-search)
  skills/<name>/SKILL.md               # the six skills → /pingvinen-ev-search:<name>
  bin/ev-scaffold                      # workspace seeder, on the Bash-tool PATH
  templates/{state.md,car-template.md} # seed files
```

The plugin `name` (`pingvinen-ev-search`) is the invocation namespace and the directory
name under `~/.claude/skills/`. The vendor prefix is baked into the plugin name itself —
not just the marketplace — so it does not collide with anyone else's plugin regardless of
which marketplace they publish from.

## How users install

```
/plugin marketplace add pingvinen/ev-search-skills
/plugin install pingvinen-ev-search@pingvinen
```

`pingvinen/ev-search-skills` is the GitHub `owner/repo` of this marketplace repo;
`@pingvinen` is the marketplace `name` from `marketplace.json`.

## Releasing changes

1. Edit skills / templates / `bin/ev-scaffold` under `plugins/pingvinen-ev-search/`.
2. Bump `version` in `plugins/pingvinen-ev-search/.claude-plugin/plugin.json` (SemVer).
   Claude Code uses the plugin version as the update cache key.
3. Commit and push to `main`.
4. Users pick it up with `/plugin marketplace update pingvinen` then
   `/plugin update pingvinen-ev-search@pingvinen`.

Validate locally before pushing:

```bash
claude plugin validate ./plugins/pingvinen-ev-search
shellcheck plugins/pingvinen-ev-search/bin/ev-scaffold
```

## Retiring the old Homebrew distribution

Earlier versions shipped the skills as loose files copied into `~/.claude/skills` via a
Homebrew tap (`pingvinen/homebrew-tap`) and an `ev-search-skills` CLI. That model is
**retired** in favour of the plugin marketplace. This repo no longer contains the CLI or
Homebrew wiring.

Remaining manual cleanup — **in the separate `pingvinen/homebrew-tap` repo** (not this one):

- Remove `Formula/ev-search-skills.rb`.
- Update that repo's README to point here (`/plugin marketplace add pingvinen/ev-search-skills`).

For users who previously ran `ev-search-skills install`, the old loose skills still sit in
`~/.claude/skills/ev-*`. They can remove them with:

```bash
rm -rf ~/.claude/skills/ev-new-project ~/.claude/skills/ev-switch-project \
       ~/.claude/skills/ev-search ~/.claude/skills/ev-detail \
       ~/.claude/skills/ev-research ~/.claude/skills/ev-compare
brew uninstall ev-search-skills && brew untap pingvinen/tap   # if installed via Homebrew
```

## CI/CD (planned)

Lives in `.github/workflows/` of this repo. Intended jobs:

- **CI (push / PR):** `claude plugin validate ./plugins/pingvinen-ev-search`;
  `shellcheck plugins/pingvinen-ev-search/bin/ev-scaffold`; JSON lint of the manifests.
- No release/tarball step is required — the marketplace serves directly from `main`.

## Note on license

The suite is licensed **PolyForm Noncommercial 1.0.0** (non-commercial use only). That is
*not* an OSI "open source" license. Distribution as a git-hosted plugin marketplace has no
such restriction — users just add the marketplace and install. The plugin manifest records
`"license": "PolyForm-Noncommercial-1.0.0"`.
