---
name: ev-switch-project
description: Switch the active EV research project. Use when the user says "switch to project X" or "change project".
allowed-tools: Write, Read, Bash(ls *)
disable-model-invocation: true
argument-hint: [project-name]
---

Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`

Switch to project: $ARGUMENTS

Follow these steps in order:

**No-argument handling (D-09)**

If `$ARGUMENTS` is empty or not provided:
- Run `Bash(ls projects/ 2>/dev/null || echo "No projects found")` to list existing projects.
- If projects exist: ask the user which project to switch to, showing the list.
- If no projects exist: tell the user there are no projects yet and suggest `/ev-new-project [name]` to create one.
- Stop here and wait for user input. Do not proceed with the steps below until a project name is provided.

---

**Step 1 — Verify the project exists**

Run `Bash(ls projects/$ARGUMENTS/ 2>/dev/null)`.

If the directory does NOT exist (command returns no output):
- Run `Bash(ls projects/ 2>/dev/null || echo "No projects found")` to list what is available.
- Tell the user:

> Project "$ARGUMENTS" does not exist. Available projects:
> [list from ls output]
>
> To create a new project, run `/ev-new-project "$ARGUMENTS"`.

Stop here. Do not modify `state.md` if the project doesn't exist.

**Step 2 — Update global state.md**

Read the current `state.md`. Note the current `active_project` value (this is the previous project, shown in Step 3).

Update the file:
- In the YAML frontmatter: change `active_project:` to `$ARGUMENTS`
- In the markdown body under `## Active Project`: change `**Project:**` to `$ARGUMENTS`
- Update `last_updated:` in the frontmatter and `**Switched:**` in the body to today's date

Write the updated content back to `state.md`.

**Step 3 — Confirm the switch to the user**

Tell the user:
- Previous active project: [value from before the update]
- New active project: `$ARGUMENTS`

Then run `Bash(ls projects/$ARGUMENTS/research/ 2>/dev/null || echo "No cars researched yet")` and show the research files if any exist, formatted as a brief summary:

> **Research files in this project:**
> [file list, or "No cars researched yet" if empty]

Suggest the user run `/ev-search` to find cars or `/ev-detail [car model]` to research a specific car.
