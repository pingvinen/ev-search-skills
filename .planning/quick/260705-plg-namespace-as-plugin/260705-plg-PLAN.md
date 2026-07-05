---
quick_id: 260705-plg
slug: namespace-as-plugin
date: 2026-07-05
status: complete
---

# Quick Task 260705-plg: Namespace the skills by converting the suite to a Claude Code plugin

## Goal

The six loosely-installed skills (`ev-*` in `~/.claude/skills`) collide with other
publishers' globally-installed skills. Namespace them so invocation is
`/pingvinen-ev-search:<skill>`, which requires converting the suite from
Homebrew-distributed loose skills into a **Claude Code plugin** published via a
git-hosted **plugin marketplace** (colons are invalid in skill/plugin names, so the
originally-requested `pingvinen:ev-search:<name>` three-segment form is not achievable —
the plugin name carries the vendor prefix instead).

## Decisions (locked with user)

- **Convert to a plugin**, not a flat prefix rename. Idiomatic namespacing + room to grow.
- **Plugin name `pingvinen-ev-search`** (vendor prefix baked into the plugin name so it is
  collision-proof regardless of marketplace — the marketplace name only disambiguates at
  install time, never in the invocation or the `~/.claude/skills/<name>` directory).
- **Retire the Homebrew tap + `ev-search-skills` CLI** now. Distribution becomes
  `/plugin marketplace add` + `/plugin install`. Deleting the formula in the separate
  `pingvinen/homebrew-tap` repo is a manual follow-up (documented in PUBLISHING.md).
- **Scaffolding stays deterministic + token-free** via a bundled `bin/ev-scaffold` on the
  Bash-tool PATH, invoked by the `new-project` skill (replaces `ev-search-skills scaffold`).

## Verified facts (Claude Code docs)

- Skill/plugin names are kebab-case only (`a-z0-9-`); colons forbidden, silently fail to load.
- Plugin invocation is two-segment `/<plugin>:<skill>`; the plugin `name` is the namespace
  and the `~/.claude/skills/<name>` directory; skill `name:` frontmatter is ignored for
  `skills/<name>/SKILL.md` (directory basename wins).
- A plugin can bundle skills, commands, agents, hooks, **MCP servers**, LSP, monitors, and
  `bin/` executables (added to the Bash-tool PATH). Loose skills cannot declare an MCP server.
- Marketplace: `.claude-plugin/marketplace.json` at repo root; single repo can be both the
  marketplace and host the plugin via a `./plugins/<name>` source path.

## Tasks

1. Restructure into a plugin + marketplace:
   - `.claude-plugin/marketplace.json` (marketplace `pingvinen`).
   - `plugins/pingvinen-ev-search/.claude-plugin/plugin.json`.
   - `git mv` the six skills to `plugins/pingvinen-ev-search/skills/<name>/` dropping the
     `ev-` prefix (`search`, `detail`, `compare`, `new-project`, `research`, `switch-project`).
   - Move `state.md` + `car-template.md` to `plugins/pingvinen-ev-search/templates/`.
   - Add `bin/ev-scaffold` (idempotent workspace seeder using `${CLAUDE_PLUGIN_ROOT}`).
   - Remove `bin/ev-search-skills` and the empty `.claude/` tree.
2. Rewrite all cross-references: `/ev-<cmd>` → `/pingvinen-ev-search:<cmd>` and skill
   `name:` fields drop the `ev-` prefix, in every SKILL.md, the state.md template,
   README.md, CLAUDE.md. Guard so `ev-database.org`, `bin/ev-scaffold`, and the
   `pingvinen/ev-search-skills` repo URL are never mangled.
3. Wire `new-project` to call `ev-scaffold` (Step 0 + `allowed-tools` grant).
4. Rewrite README.md + PUBLISHING.md for the marketplace model; document tap retirement.

## Verify

- `python3 -c json.load` on both manifests; `claude plugin validate`.
- No genuine leftover `/ev-<cmd>` invocations or `ev-search-skills` CLI usages.
- All skill frontmatter (`context: fork`, `agent: Explore`, `disable-model-invocation`,
  `argument-hint`, `allowed-tools`) preserved through the move.

## Done when

Repo is a valid single-plugin marketplace, invocations are `/pingvinen-ev-search:<skill>`,
Homebrew wiring is gone from this repo, and scaffolding runs via the bundled CLI.
