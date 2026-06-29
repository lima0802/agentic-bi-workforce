---
name: bi-workforce-router
description: Top-level BI dashboard workforce dispatcher. Resolves client and task, loads the client config + brand pack, then delegates to the matching dashboard skill (engine). Use to start any client dashboard build. Triggers on "build dashboard", "run workforce", "<client> ddm".
---

# BI Workforce Router

Route a dashboard request to the right client pack + skill. Client specifics live in
`clients/<client>/`; the BI engine is client-agnostic.

## Step 0 — Intake (ask one at a time, before any file change)
1. Dashboard goal and primary audience?
2. Client + PBIP project and page to modify?
3. KPIs required first?
4. Filters users need?
5. Date behavior (presets + granularity)?
6. Comparison mode (vs prior year / prior period)?
7. Multi-currency conversion?
8. Initialize standard start setup first?
9. Acceptance checks — what does "done" look like?

## Step 1 — Resolve client + task
- client: `volvo` (default). task: `ddm-start` (default).
- Load `clients/<client>/config.json` (tokens, target PBIP path, ENABLE_BM) and
  `brand.json` (font, colors, frame geometry).

## Step 2 — Plan + approval gate (before implementation)
Write `_brief/dashboard-plan.md`: scope, confirmed KPI list, confirmed filter list,
date/comparison behavior, selected skills + execution order, validation checklist, and an
explicit approval line. Do not build until the user approves.

## Step 3 — Dispatch
| client | task | skill (engine) |
|---|---|---|
| volvo | ddm-start | `../skills/digital-direct-marketing-dashboard-start` |

The DDM skill delegates only through the WPP wrappers — `wpp-plan` → `wpp-model` →
`wpp-report` (in `../skills/`). WPP wrappers call the **pinned** Fabric foundation skills;
never call Fabric directly. Pass the client pack to the engine as overrides.

## Step 4 — Eval gate
After build, run `evals/eval.ps1` against `evals/briefs/<task>.md`. Tier-1 gates must be
0/0; Tier-2 judge ≥ threshold. Log to `logs/`. On fail, propose a skill PR — never silent.

## Mandatory validation (before completion)
KPI values resolve w/o measure errors; date slicer filters trend visuals; granularity
changes axis values; comparison selector updates series; hidden utility slicers not visible;
no schema errors in touched files; no unresolved runtime failures.
