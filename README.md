# EV Research Skills

A [Claude Code](https://claude.com/claude-code) **plugin** that researches and
compares **electric vehicles for the Danish market**. Point it at your criteria and it
goes from *"what EVs match my needs?"* to sourced, comparable research files — without
manually trawling multiple sites.

It fetches live data from known EV sources ([ev-database.org](https://ev-database.org/),
[FDM](https://fdm.dk/tests), [greengarage.dk](https://greengarage.dk/)) and writes
per-car research files and comparison tables you can diff in git.

> **Danish-market focused:** pricing is in DKK, tests come from FDM, and availability is
> checked for Denmark. The skills are still useful elsewhere, but the sources are DK-centric.

This repository holds the Claude Code **plugin** `pingvinen-ev-search` (under
`plugins/`). It is published through the shared **[`pingvinen/claude-plugins`](https://github.com/pingvinen/claude-plugins)**
marketplace, which pins this plugin to a released tag — so `main` here stays a
work-in-progress branch and only tagged releases are ever served.

## What's inside

The plugin's skills are invoked as `/pingvinen-ev-search:<skill>`:

| Skill | What it does |
|-------|--------------|
| `/pingvinen-ev-search:new-project` | Scaffold a new research project (seeds the workspace, then sets purchase type, budget, criteria) |
| `/pingvinen-ev-search:switch-project` | Switch the active project |
| `/pingvinen-ev-search:search` | Find EV models matching the active project's criteria |
| `/pingvinen-ev-search:detail` | Deep-research one model → a sourced per-car file |
| `/pingvinen-ev-search:research` | Broader research pass |
| `/pingvinen-ev-search:compare` | Build a comparison table across researched cars |

## Install

In a Claude Code session:

```
/plugin marketplace add pingvinen/claude-plugins
/plugin install pingvinen-ev-search@pingvinen
```

Then start Claude Code in an empty directory and create your first project:

```
/pingvinen-ev-search:new-project my-2026-search
```

That seeds the workspace (`state.md` and a `projects/` directory) via the plugin's
bundled `ev-scaffold` tool and creates the project. Answer the prompts, then use
`/pingvinen-ev-search:search`, `/pingvinen-ev-search:detail "Volvo EX30"`, and
`/pingvinen-ev-search:compare`.

To update later: `/plugin marketplace update pingvinen` then `/plugin update pingvinen-ev-search@pingvinen`.

### Local development / from a clone

You can run the plugin straight from a checkout without a marketplace:

```bash
git clone https://github.com/pingvinen/ev-search-skills.git
cd ev-search-skills
claude --plugin-dir plugins/pingvinen-ev-search   # loads the plugin for this session
```

Then `/pingvinen-ev-search:new-project my-ev-search` from whatever directory you want the
workspace seeded into.

## How it works

- **Criteria in, research out.** Your needs live in a project's `brief.md`, created by
  `/pingvinen-ev-search:new-project` when you answer its prompts. Skills read from there —
  nothing is hardcoded.
- **Projects.** Each search is a folder under `projects/<name>/` with its own `brief.md`,
  `research/*.md`, and `comparison.md`. `state.md` tracks which project is active.
- **Your research stays local.** It lives in the workspace you launch Claude Code in — the
  plugin only ships the skills and templates, never your data.

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
