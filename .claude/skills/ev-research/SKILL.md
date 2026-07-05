---
name: ev-research
description: Research one or more EV models in depth by spawning one isolated /ev-detail fork per car. Use when the user wants to research multiple cars, run a batch research session, or run a validation pass. Suitable for roughly 2-6 cars per run. Never auto-triggered — must be invoked explicitly.
allowed-tools: Read, Bash(ls *)
disable-model-invocation: true
argument-hint: ["car1" "car2" ...]
---

Current global state:
!`cat state.md 2>/dev/null || echo "state.md not found -- no active project"`

Cars to research: $ARGUMENTS

Follow these steps in order.

**No-argument handling**

If `$ARGUMENTS` is empty or not provided:
- Tell the user the expected invocation format:

  > Usage: `/ev-research "car1" "car2" ...`
  > Example: `/ev-research "Volvo EX30" "Renault 5" "BMW iX1"`
  >
  > Provide at least one car name in quotes. Each quoted name is researched in its own isolated context.

- Stop here. Do not proceed with the steps below.

---

**Step 1 — Confirm active project**

From the injected global state above, extract the `active_project` value.

If `active_project` is `none` or the state file was not found: stop immediately and tell the user:

> No active project found. Run `/ev-new-project [name]` to create a project first, or `/ev-switch-project [name]` to switch to an existing one.

Do not proceed past Step 1 if no active project exists.

---

**Step 2 — Parse car list from $ARGUMENTS**

Parse `$ARGUMENTS` as a shell-quoted list of car names. Each quoted token (e.g., `"Volvo EX30"`, `"Renault 5"`) is one car. Use `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, `$ARGUMENTS[2]`, etc. to access individual cars.

Build a working list — for example:
- Car 0: `$ARGUMENTS[0]`
- Car 1: `$ARGUMENTS[1]`
- ...

State the list explicitly before proceeding:

> Cars in this batch: [list each car on its own line]
> Active project: [active_project]
> Research files will be written to: `projects/<active_project>/research/`

---

**Step 3 — Dispatch one /ev-detail fork per car (sequential foreground)**

For each car in the working list from Step 2, invoke `/ev-detail "<car>"` and wait for that fork to complete before dispatching the next.

**Default is sequential foreground dispatch.** This is safer than parallel because:
- It avoids hitting site rate limits (ev-database.org, fdm.dk) from simultaneous fetches.
- Foreground forks surface the interactive overwrite prompt from `/ev-detail` Step 3 — allowing you to choose "overwrite" or "skip" for each car that already has a research file.

**Note on parallel dispatch:** You may optionally instruct Claude to invoke all /ev-detail forks in parallel. However, background forks auto-deny any interactive prompts, including the /ev-detail Step 3 overwrite prompt. If research files already exist for any car in the batch, those cars will be silently skipped in parallel mode. Delete existing research files before a parallel batch re-run.

**Note on batch size:** /ev-research is suitable for roughly 2-6 cars per run. For larger batches, run multiple /ev-research calls.

---

**Step 4 — Record status and path per car (fork boundary enforcement)**

After each `/ev-detail` invocation completes, record only the status line and file path from the fork's output. Do NOT use the Read tool on the research file. The research file is for Phase 3's `/ev-compare` skill, not for this orchestrator's context.

Specifically, capture from each fork's Step 13 output:
- The "File written:" path (e.g., `projects/<active_project>/research/volvo-ex30.md`)
- The overall status: `OK` if the file was written successfully, `FAILED` if ev-database.org returned no result or the file was not written

Store these per car. Do NOT load the file content. Do NOT use WebFetch or WebSearch.

---

**Step 5 — Print final summary table**

After all forks have completed, print a summary table:

| Car | Status | File |
|-----|--------|------|
| [car name] | OK / FAILED | [file path or "— not written"] |

Then add a brief note of any gaps or failures for follow-up.

If all cars succeeded: tell the user they can now run `/ev-compare` to generate a comparison table.
