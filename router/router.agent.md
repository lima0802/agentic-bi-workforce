---
name: bi-workforce-router
description: Top-level BI dashboard workforce dispatcher. Resolves client and task, loads the client config + brand pack, then delegates to the matching dashboard skill (engine). Use to start any client dashboard build. Triggers on "build dashboard", "run workforce", "<client> ddm".
---

# BI Workforce Router

Route a dashboard request to the right client pack + skill. Client specifics live in
`clients/<client>/`; the BI engine is client-agnostic.

## Step 1 — Resolve client + task
- client: `volvo` (default). task: `ddm-start` (default).
- Load `clients/<client>/config.json` (tokens, target PBIP path, ENABLE_BM) and
  `brand.json` (font, colors, frame geometry).

## Step 2 — Dispatch
| client | task | skill (engine) |
|---|---|---|
| volvo | ddm-start | `../skills/digital-direct-marketing-dashboard-start` |

The DDM skill delegates only through the WPP wrappers — `wpp-plan` → `wpp-model` →
`wpp-report` (in `../skills/`). WPP wrappers call the **pinned** Fabric foundation skills;
never call Fabric directly. Pass the client pack to the engine as overrides.

## Step 3 — Eval gate
After build, run `evals/eval.ps1` against `evals/briefs/<task>.md`. Tier-1 gates must be
0/0; Tier-2 judge ≥ threshold. Log to `logs/`. On fail, propose a skill PR — never silent.
