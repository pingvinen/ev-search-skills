# Publishing & maintenance

How this repo gets published and how the Homebrew install works. Consumers don't
need this file — it's for the maintainer.

## Repos involved

| Repo | Purpose | Visibility |
|------|---------|------------|
| `pingvinen/ev-search-skills` | This repo — skills, templates, installer CLI, docs | public |
| `pingvinen/homebrew-tap` | Homebrew tap holding the formula | public |

## Current status

Both repos are live. The tap (`pingvinen/homebrew-tap`) already holds the formula
(`Formula/ev-search-skills.rb`, HEAD-only), so users install with:

```bash
brew tap pingvinen/tap
brew install --HEAD ev-search-skills
```

Formula changes are made directly in the tap repo. This repo no longer carries a
`dist/` copy of the formula — the tap is the single source of truth.

## Stable releases (deferred until CI/CD)

Launch is **HEAD-only** — the formula ships just a `head` stanza, so consumers use
`brew install --HEAD ev-search-skills`. We intentionally do **not** tag a version yet.

Versioning will be **SemVer** (`vMAJOR.MINOR.PATCH`), and tagging waits until the CI/CD
pipeline (below) is in place so releases are automated and verified rather than hand-cut.

When ready, the stable line is added by giving the formula a tagged tarball + sha256:

```bash
git tag v0.1.0 && git push origin v0.1.0
gh release create v0.1.0 --generate-notes
URL="https://github.com/pingvinen/ev-search-skills/archive/refs/tags/v0.1.0.tar.gz"
curl -sL "$URL" | shasum -a 256   # → paste into the formula's sha256, add matching url
brew audit --strict --online pingvinen/tap/ev-search-skills
```

Also bump `VERSION` in `bin/ev-search-skills` to match the tag.

## CI/CD pipeline (planned — prerequisite for stable tagging)

Lives in `.github/workflows/` of this repo. Intended jobs:

- **CI (push / PR):** `shellcheck bin/ev-search-skills`; run the CLI smoke tests
  (`version`, `scaffold` into a temp dir, `install`→`uninstall` round-trip); optional
  `brew audit`/`brew test` of the formula.
- **Release (on tag `v*`):** create the GitHub release, compute the tarball sha256, and
  open a PR (or push) to `pingvinen/homebrew-tap` updating the formula's `url` + `sha256`
  (e.g. via a formula-bump action). This is what unblocks SemVer stable releases.

Until these exist, keep the tap HEAD-only.

## Note on license & Homebrew

The suite is licensed **PolyForm Noncommercial 1.0.0** (non-commercial use only). That
is *not* an OSI "open source" license, so this cannot live in `homebrew-core` — a
personal tap (`homebrew-tap`) is the correct distribution channel and has no such
restriction. The formula records `license :cannot_represent` because PolyForm has no
SPDX identifier.
