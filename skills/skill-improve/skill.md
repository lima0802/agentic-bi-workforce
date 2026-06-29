# Skill: skill-improve  (Weekly Self-Improvement)

## Purpose
Run once per week (or on-demand) to read eval logs, identify recurring failures, open
human-approved PRs with fixes, and append new lessons to `learnings.md`.

---

## Trigger

Scheduled: every Monday at 06:00 UTC, or via `router` with `task=improve`.

---

## Inputs  _(injected by the router)_

| Field     | Type   | Description                                           |
|-----------|--------|-------------------------------------------------------|
| `$config` | object | Client config from `clients/<client>/config.json`     |
| `$brand`  | object | Brand tokens from `clients/<client>/brand.json`       |
| `$brief`  | string | Path to the improvement brief (defaults to `evals/briefs/`)  |

---

## Algorithm

### Step 1 — Ingest eval logs
1. Read all files matching `logs/eval-*.json` (excluded from VCS; must exist locally).
2. For each log entry, extract:
   - `runId`, `timestamp`, `check`, `result` (`pass`/`fail`), `details`
3. Group by `check` and count failure frequency over the last 30 days.

### Step 2 — Identify top failures
- Select checks with `failRate > 0.2` (more than 20 % of runs failed).
- Rank by `failRate` descending; take the top 5.

### Step 3 — Root-cause analysis
For each top failure:
1. Load the corresponding eval brief from `evals/briefs/`.
2. Re-run the failed check in dry-run mode against the last-known artifact.
3. Produce a root-cause hypothesis (one sentence) and a proposed fix (code delta or
   skill-rule update).

### Step 4 — Draft PR
1. Apply proposed fixes to skill files or `learnings.md` in a new git branch named
   `improve/<YYYY-MM-DD>`.
2. Open a **draft** PR titled `[skill-improve] Weekly fixes <YYYY-MM-DD>`.
3. Set PR description to the root-cause analysis output.
4. **Do not merge**; flag PR for human review by adding the label `needs-human-review`.

### Step 5 — Append to learnings.md
For each identified failure, append one bullet to `learnings.md` in the format:

```
- [<YYYY-MM-DD>] <check-name>: <root-cause-one-liner> → <fix-summary>
```

Do **not** rewrite existing bullets; only append.

---

## Rules

- Never auto-merge; human approval is mandatory for all PRs opened by this skill.
- If `logs/eval-*.json` is empty or missing, log a warning and exit with code 0
  (no-op is not an error).
- The skill must itself pass the model-integrity and brand-frame gates before opening a PR.
- Do not propose fixes that contradict an existing bullet in `learnings.md`.

---

## Output

```json
{
  "runsAnalysed":  <number>,
  "topFailures":   ["<check1>", "<check2>"],
  "prOpened":      "<PR URL or null>",
  "lessonsAdded":  <number>
}
```
