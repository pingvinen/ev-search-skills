# pingvinen-ev-search

A Claude Code **plugin** that researches and compares electric vehicles for the
Danish market. It fetches live data from [ev-database.org](https://ev-database.org/),
[FDM](https://fdm.dk/tests), and [greengarage.dk](https://greengarage.dk/) and writes
sourced per-car research files and comparison tables you can diff in git.

## Skills

Invoked as `/pingvinen-ev-search:<skill>`:

| Skill | What it does |
|-------|--------------|
| `/pingvinen-ev-search:new-project` | Scaffold a new research project (seeds the workspace, then sets purchase type, budget, criteria) |
| `/pingvinen-ev-search:switch-project` | Switch the active project |
| `/pingvinen-ev-search:search` | Find EV models matching the active project's criteria |
| `/pingvinen-ev-search:detail` | Deep-research one model → a sourced per-car file |
| `/pingvinen-ev-search:research` | Broader research pass across several models |
| `/pingvinen-ev-search:compare` | Build a comparison table across researched cars |

## Install

```
/plugin marketplace add pingvinen/claude-plugins
/plugin install pingvinen-ev-search@pingvinen
```

Then start Claude Code in an empty directory and run
`/pingvinen-ev-search:new-project my-2026-search` — it seeds the workspace
(`state.md` and a `projects/` directory) via the bundled `ev-scaffold` tool
and creates your first project.

See the [repository README](https://github.com/pingvinen/ev-search-skills) for the
full workflow, and [PUBLISHING.md](https://github.com/pingvinen/ev-search-skills/blob/main/PUBLISHING.md)
for maintenance.

## License

**PolyForm Noncommercial 1.0.0** — non-commercial use only.
