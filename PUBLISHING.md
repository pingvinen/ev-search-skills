# Publishing & maintenance

How this plugin is built and published. Consumers don't need this file — it's for the
maintainer.

## What this repo is

This repository holds a single Claude Code **plugin**, `pingvinen-ev-search`. It is *not*
the marketplace — the catalog lives in a separate repo (see below) so that one marketplace
can aggregate several `pingvinen-*` plugins, each in its own repo, à la a Homebrew tap.

```
plugins/pingvinen-ev-search/
  .claude-plugin/plugin.json           # plugin manifest (name: pingvinen-ev-search)
  skills/<name>/SKILL.md               # the six skills → /pingvinen-ev-search:<name>
  bin/ev-scaffold                      # workspace seeder, on the Bash-tool PATH
  templates/state.md                   # seeded into the workspace (mutable state)
  reference/car-template.md            # per-car file format — shipped, not seeded
.releaserc.json                        # semantic-release config
.github/workflows/release.yml          # release + publish-to-marketplace pipeline
```

The plugin `name` (`pingvinen-ev-search`) is the invocation namespace and the directory
name under `~/.claude/skills/`. The vendor prefix is baked into the plugin name itself — so
it does not collide with anyone else's plugin regardless of marketplace.

## The two repos

| Repo | Role |
|------|------|
| `pingvinen/ev-search-skills` (this) | The plugin source + its release pipeline |
| `pingvinen/claude-plugins` | The marketplace catalog (`.claude-plugin/marketplace.json`) that pins each plugin to a released tag |

The marketplace entry uses a `git-subdir` source pinned to a `ref` (a `vX.Y.Z` tag), so
**`main` here is a normal work branch** — only tagged releases are ever served to users.

## How users install

```
/plugin marketplace add pingvinen/claude-plugins
/plugin install pingvinen-ev-search@pingvinen
```

`pingvinen/claude-plugins` is the marketplace repo; `@pingvinen` is its marketplace `name`.
Upgrades: `/plugin marketplace update pingvinen` then `/plugin update pingvinen-ev-search@pingvinen`.

## Releasing (automated)

Releases are driven by [Conventional Commits](https://www.conventionalcommits.org/) and
`semantic-release`. To cut one, run the **Release plugin** workflow (Actions →
`workflow_dispatch`). It:

1. Analyses commits since the last tag and computes the next SemVer.
2. Writes that version into `plugins/pingvinen-ev-search/.claude-plugin/plugin.json`
   (via `@semantic-release/exec` + `jq`) and commits it back (`@semantic-release/git`) so
   the tag contains the bumped version.
3. Creates the `vX.Y.Z` tag and a GitHub Release with generated notes.
4. Opens a PR against `pingvinen/claude-plugins` bumping this plugin's `source.ref` to the
   new tag. **Merging that PR publishes the release** to marketplace users.

Why the version bump matters: Claude Code uses the plugin `version` as the update cache
key — users only get an update when it changes. Each released tag therefore carries a
distinct `version`.

### Prerequisites

- **`RELEASE_TOKEN_PAT`** secret in this repo: a PAT (or GitHub App token) with
  `contents: write` here (tag, release, push the version-bump commit) **and**
  `contents: write` + `pull-requests: write` on `pingvinen/claude-plugins` (open the
  publish PR). A fine-grained PAT scoped to both repos is the least-privilege option.
- The marketplace repo must already list this plugin (bootstrap its
  `.claude-plugin/marketplace.json` once — see the scaffold in this project's notes).

### Validate locally before releasing

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
- Update that repo's README to point at `/plugin marketplace add pingvinen/claude-plugins`.

For users who previously ran `ev-search-skills install`, the old loose skills still sit in
`~/.claude/skills/ev-*`. They can remove them with:

```bash
rm -rf ~/.claude/skills/ev-new-project ~/.claude/skills/ev-switch-project \
       ~/.claude/skills/ev-search ~/.claude/skills/ev-detail \
       ~/.claude/skills/ev-research ~/.claude/skills/ev-compare
brew uninstall ev-search-skills && brew untap pingvinen/tap   # if installed via Homebrew
```

## Note on license

The suite is licensed **PolyForm Noncommercial 1.0.0** (non-commercial use only). That is
*not* an OSI "open source" license. Distribution as a git-hosted plugin marketplace has no
such restriction. The plugin manifest records `"license": "PolyForm-Noncommercial-1.0.0"`.
