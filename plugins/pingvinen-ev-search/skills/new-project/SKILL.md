---
name: new-project
description: Create a new EV research project. Use when the user wants to start researching a new set of cars with different criteria.
allowed-tools: Write, Read, Bash(ev-scaffold*, mkdir *, ls *)
disable-model-invocation: true
argument-hint: [project-name]
---

!`cat state.md 2>/dev/null || echo "state.md not found"`

Project name requested: $ARGUMENTS

Follow these steps in order:

**Step 0 — Ensure the workspace is seeded**

Run `Bash(ev-scaffold)`. This bundled plugin tool creates `state.md` and
`car-template.md` in the workspace if they are missing (it never overwrites
existing files) and ensures a `projects/` directory exists. These are the files
the other skills read. Proceed once it completes.

**Step 1 — Check for existing project (D-10: never overwrite)**

Run `Bash(ls projects/$ARGUMENTS/ 2>/dev/null)`.

If the directory EXISTS (command returns any output): Stop immediately. Tell the user:

> Project "$ARGUMENTS" already exists. To resume work on it, run `/pingvinen-ev-search:switch-project "$ARGUMENTS"` instead. No files were changed.

Do not proceed past Step 1 if the project exists.

**Step 2 — Ask for purchase type (D-02: one budget section only)**

Ask the user:

> What is the purchase type for this project?
> - `new` — purchasing a new car (budget in DKK)
> - `used` — purchasing a used car (budget in DKK, plus age and mileage limits)
> - `leasing` — leasing (monthly budget in DKK/mo)
>
> Default is `new` if you don't specify.

Wait for the user's response before continuing. Record the chosen purchase type.

**Step 3 — Create the project scaffold**

Run `Bash(mkdir -p projects/$ARGUMENTS/research)`.

Then write three files:

**3a. Write `projects/$ARGUMENTS/brief.md`** using the BRIEF template below. Fill in the project name and the purchase type from Step 2. Include ONLY the budget subsection matching the chosen purchase type (not all three).

**3b. Write `projects/$ARGUMENTS/state.md`** using the per-project state template below. Fill in the project name, today's date, and the purchase type from Step 2.

**3c. Write `projects/$ARGUMENTS/comparison.md`** with this content:
```
# Comparison: $ARGUMENTS

No cars researched yet. Run /pingvinen-ev-search:detail to add cars.
```

**Step 4 — Update global state.md**

Read the current `state.md`. Update two things:
- In the YAML frontmatter: change `active_project:` to `$ARGUMENTS`
- In the markdown body under `## Active Project`: change `**Project:**` to `$ARGUMENTS`
- Update `last_updated:` in the frontmatter and `**Switched:**` in the body to today's date

Write the updated content back to `state.md`.

**Step 5 — Confirm to the user**

Tell the user what was created:
- `projects/$ARGUMENTS/brief.md` — fill in your search criteria here
- `projects/$ARGUMENTS/research/` — car research files will go here
- `projects/$ARGUMENTS/state.md` — tracks research progress
- `projects/$ARGUMENTS/comparison.md` — comparison table (populated by /pingvinen-ev-search:compare)
- Global `state.md` updated — active project is now `$ARGUMENTS`

Suggest they open `projects/$ARGUMENTS/brief.md` and fill in the criteria sections before running `/pingvinen-ev-search:search`.

---

## brief.md Template

Write this to `projects/$ARGUMENTS/brief.md`. Replace `[Project Name]` with the actual project name. Replace `[new/used/leasing]` with the purchase type. Include ONLY the budget subsection matching the purchase type.

```markdown
# Project Brief: [Project Name]

**Purchase type:** [new/used/leasing]

## Context

<!-- Why this search, what's being replaced, key constraints -->

## Budget

[INSERT ONE BUDGET SECTION HERE based on purchase type:]

[IF new:]
**Preferred range:** [amount] DKK
**Maximum:** [amount] DKK

[IF used:]
**Preferred range:** [amount] DKK
**Maximum:** [amount] DKK
**Max age:** [years]
**Max km:** [km]

[IF leasing:]
**Monthly budget:** [amount] DKK/mo
**Max upfront:** [amount] DKK
**Lease term:** [months]

### Per-brand overrides

<!-- Percentage uplift from base budget, per D-03. Example: <Brand>: +50% (e.g. where you have a discount arrangement) -->

## Must-Have Features

<!-- Hard requirements that filter results -->
- Electric only (BEV)

## Body Type

<!-- Preferred body style — e.g. SUV, hatchback, estate. Note any flexibility. -->

## Seats

<!-- Number of seats required — e.g. 4-5 seats -->

## Preferred Features

<!-- Nice-to-haves that don't filter but inform comparison -->

## Brand Notes

<!-- Per-brand research flags, exclusions, quality concerns -->
```

---

## Per-Project state.md Template

Write this to `projects/$ARGUMENTS/state.md`. Replace `[project name]` with the actual project name, `[date]` with today's date, and `[purchase type]` with the value from Step 2.

```markdown
# Project State: [project name]

**Created:** [date]
**Purchase type:** [purchase type]
**Status:** active

## Research Progress

| Car model | File | Researched | FDM found |
|-----------|------|------------|-----------|

## Source Reliability Notes

<!-- Fetch-time observations for this project's research session -->

## Discovered Sources

<!-- Useful URLs found during research that weren't in the initial brief -->
```
