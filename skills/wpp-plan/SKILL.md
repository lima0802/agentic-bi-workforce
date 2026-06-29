---
name: wpp-plan
description: WPP planning wrapper over Fabric powerbi-report-planning. Loads the client pack, applies WPP brief conventions, locks a spec, gets approval. Foundation = pinned Fabric skill. Use for any WPP dashboard requirements phase.
---

# wpp-plan (wraps `powerbi-report-planning`)

Foundational skill: **`powerbi-report-planning`** — pin its version; do not edit upstream.

## WPP conventions injected
- Brief = ground truth, written so the eval harness grades against it (`evals/briefs/`).
- Pull tokens, brand, paths from `clients/<client>/config.json` + `brand.json` — never ask
  for values the pack already holds.
- Default page plan = overview first; always lock spec + get user approval before files.

## Steps
1. Load client pack. 2. Run Fabric planning with pack as input. 3. Emit `evals/briefs/<task>.md`. 4. Approval → hand pack to wpp-model.
