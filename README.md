# EV Research Skills

A small suite of [Claude Code](https://claude.com/claude-code) skills that research and
compare **electric vehicles for the Danish market**. Point it at your criteria and it
goes from *"what EVs match my needs?"* to sourced, comparable research files — without
manually trawling multiple sites.

It fetches live data from known EV sources ([ev-database.org](https://ev-database.org/),
[FDM](https://fdm.dk/tests), [greengarage.dk](https://greengarage.dk/)) and writes
per-car research files and comparison tables you can diff in git.

> **Danish-market focused:** pricing is in DKK, tests come from FDM, and availability is
> checked for Denmark. The skills are still useful elsewhere, but the sources are DK-centric.

## What's inside

| Skill | What it does |
|-------|--------------|
| `/ev-new-project` | Scaffold a new research project (purchase type, budget, criteria) |
| `/ev-switch-project` | Switch the active project |
| `/ev-search` | Find EV models matching the active project's criteria |
| `/ev-detail` | Deep-research one model → a sourced per-car file |
| `/ev-research` | Broader research pass |
| `/ev-compare` | Build a comparison table across researched cars |

## Install

### Homebrew (recommended)

```bash
brew tap pingvinen/tap
brew install --HEAD ev-search-skills   # stable SemVer releases land once CI/CD is set up

ev-search-skills install               # copy the /ev-* skills into ~/.claude/skills
ev-search-skills scaffold my-ev-search # seed a research workspace
cd my-ev-search
claude                                  # start Claude Code here
```

Then in the session run `/ev-new-project my-2026-search`, answer the prompts, and use
`/ev-search`, `/ev-detail "Volvo EX30"`, `/ev-compare`.

The `ev-search-skills` CLI has three commands: `install` (skills → `~/.claude/skills`),
`scaffold [dir]` (seed a workspace), and `uninstall`.

### Manual / from a clone

The skills are **workspace-scoped** — they read and write files (`state.md`, `projects/`)
relative to the directory you run Claude Code in. You can clone this repo and use it as a
workspace directly:

```bash
git clone https://github.com/pingvinen/ev-search-skills.git my-ev-search
cd my-ev-search
./bin/ev-search-skills install   # optional: also expose skills globally
claude
```

Or copy `.claude/skills/`, `state.md`, `car-template.md`, and `search_criteria.md` into
an existing workspace's root.

## How it works

- **Criteria in, research out.** Your needs live in `search_criteria.md` (a template is
  included) or in a project's `brief.md` created by `/ev-new-project`. Skills read these —
  nothing is hardcoded.
- **Projects.** Each search is a folder under `projects/<name>/` with its own `brief.md`,
  `research/*.md`, and `comparison.md`. `state.md` tracks which project is active.
- **Your research stays local.** `projects/*` is git-ignored by default, so your actual
  car search never gets committed back to this template (see [`.gitignore`](.gitignore)).

## Requirements

- Claude Code (skills use `WebFetch`, `WebSearch`, `Read`, `Write`, and light `Bash`).
- No API keys, no external runtime — everything runs inside the Claude Code session.

## Project history

This repo was built with the [GSD](https://github.com/) planning workflow; the
development history lives under `.planning/`. Those docs use a generic example search —
they don't contain anyone's personal data.

## License

**PolyForm Noncommercial 1.0.0** — see [LICENSE](LICENSE). Use, modify, and share it
freely for any non-commercial purpose (personal, research, education, nonprofit).
Commercial use is not permitted. For a commercial license, open an issue.
