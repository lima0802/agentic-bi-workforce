---
name: wpp-model
description: WPP semantic-model wrapper over Fabric semantic-model-authoring. Applies WPP safety rules (literal-token replace, fresh UUIDs, no TMDL comments) and DDM calendar/BM templates. Foundation = pinned Fabric skill. Use for any WPP model build.
---

# wpp-model (wraps `semantic-model-authoring`)

Foundational skill: **`semantic-model-authoring`** — pinned; not edited.
Read `../../learnings.md` first — prior-workflow lessons override defaults.

## WPP safety rules (non-negotiable)
- Replace ONLY known tokens literally; never greedy `<[^>]+>` (DAX `<=` corruption).
- Fresh UUID v4 for every lineageTag/relationship/LDT GUID.
- No `//` comments inside `.tmdl`.
- Validate via ImportFromTmdlFolder + measure_operations Get (state Ready, `<=` intact).

## Steps
A–D from DDM SKILL using `templates/semantic-model/` + client tokens; validate; hand to wpp-report.
