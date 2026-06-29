# Skill: wpp-model  (WPP Semantic Model Authoring)

## Pinned upstream skill
`semantic-model-authoring`

This skill is a **thin WPP wrapper**. It injects WPP brand and safety rules, then delegates
all model-authoring logic to the pinned Fabric skill. It must **never** call Fabric APIs directly.

---

## Purpose
Create or update a PBIP semantic model (`.Dataset/` / TMDL files) based on a report plan
produced by `wpp-plan`. Outputs valid, comment-free TMDL that passes the Fabric TMDL parser.

---

## Inputs  _(injected by the router)_

| Field        | Type   | Description                                              |
|--------------|--------|----------------------------------------------------------|
| `$config`    | object | Client config from `clients/<client>/config.json`        |
| `$brand`     | object | Brand tokens from `clients/<client>/brand.json`          |
| `$brief`     | string | Path to the model brief or the plan JSON from `wpp-plan` |
| `$pbip_path` | string | Absolute path to the PBIP repo root (targeted by path)   |

---

## Safety rules  _(always enforced, non-negotiable)_

1. **No greedy `<=` token regex** — never emit a TMDL measure containing an unanchored
   `<=` comparison against a string token; always scope to a specific column reference.
2. **No TMDL comments** — the output TMDL must contain zero `//` or `/* */` comment lines.
   The Fabric TMDL parser rejects files containing comments; strip all comments before writing.
3. **Non-destructive writes** — only write files that are listed as new or modified targets;
   never delete or truncate existing TMDL files not mentioned in the brief.
4. **Fresh UUIDs** — every new table, partition, measure, and relationship must carry a
   freshly generated UUID (v4) in the `lineageTag` field; never copy an existing `lineageTag`.
5. **Model integrity gate** — after writing, the model must pass `evals/gates.ps1 -Check Model`
   before the skill reports success.

---

## TMDL output rules

- Each measure file: `model.bim` → TMDL folder at `<pbip_path>/<model>.Dataset/definition/`.
- Format: one `.tmdl` file per table; measure expressions use 4-space indentation.
- DAX expressions: terminate every branch with an explicit `RETURN` or value; no open-ended
  filter contexts.
- Relationships: always specify `crossFilteringBehavior` explicitly.
- Encode string literals as `"..."` (double-quoted), never single-quoted.

---

## Output

Return a JSON object:

```json
{
  "modelPath":    "<absolute path to the model .Dataset folder>",
  "tablesWritten": ["<table1>", "<table2>"],
  "measuresAdded": ["<MeasureName1>", "<MeasureName2>"],
  "gateResult":   "pass",
  "brandApplied": true
}
```

Abort with `WPP_MODEL_ERR_TMDL_COMMENTS` if any comment survives in generated TMDL.
Abort with `WPP_MODEL_ERR_GATE_FAIL` if the model integrity gate does not pass.
