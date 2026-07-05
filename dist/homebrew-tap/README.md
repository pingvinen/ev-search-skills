# homebrew-tap (staging copy)

These files belong in a **separate** GitHub repo named `homebrew-tap`
(so the full name is `github.com/pingvinen/homebrew-tap`). Homebrew requires the
`homebrew-` prefix for the short `brew tap pingvinen/tap` form to resolve.

## Set it up

```bash
# 1. Create the tap repo (public) and clone it
gh repo create pingvinen/homebrew-tap --public --clone
cd homebrew-tap

# 2. Copy this Formula/ directory in
mkdir -p Formula
cp /path/to/ev-search-skills/dist/homebrew-tap/Formula/ev-search-skills.rb Formula/

git add -A && git commit -m "Add ev-search-skills formula" && git push
```

## Consumers then run

```bash
brew tap pingvinen/tap
brew install --HEAD ev-search-skills   # works immediately from main
# (once a release tag + sha256 are wired, plain `brew install ev-search-skills`)
ev-search-skills install               # copy /ev-* skills into ~/.claude/skills
ev-search-skills scaffold my-ev-search # seed a research workspace
```

See `PUBLISHING.md` in the main repo for cutting a release and filling the sha256.
