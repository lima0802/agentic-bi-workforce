# Skill: wpp-report  (WPP Report Authoring)

## Pinned upstream skill
`powerbi-report-authoring`

This skill is a **thin WPP wrapper**. It injects WPP brand and safety rules, then delegates
all report-authoring logic to the pinned Fabric skill. It must **never** call Fabric APIs directly.

---

## Purpose
Produce or update `report.json` inside a PBIP report folder so that the canvas matches the
approved plan from `wpp-plan`. The PBIP repo is **never** recreated — this skill targets
existing files by path and makes only the changes required by the brief.

---

## Inputs  _(injected by the router)_

| Field        | Type   | Description                                              |
|--------------|--------|----------------------------------------------------------|
| `$config`    | object | Client config from `clients/<client>/config.json`        |
| `$brand`     | object | Brand tokens from `clients/<client>/brand.json`          |
| `$brief`     | string | Path to the report brief or the plan JSON from `wpp-plan`|
| `$pbip_path` | string | Absolute path to the PBIP repo root (targeted by path)   |

---

## Brand injection rules

All visual properties below are **mandatory** when creating or updating a visual; any
unset property is a skill error:

| Property          | Token source                        |
|-------------------|-------------------------------------|
| `fontFamily`      | `$brand.typography.fontFamily`      |
| `fontSize`        | `$brand.typography.bodySize`        |
| `titleFontSize`   | `$brand.typography.headingSize`     |
| `background`      | `$brand.colors.background`          |
| `foreground`      | `$brand.colors.primary`             |
| `dataColors[0]`   | `$brand.colors.primary`             |
| `dataColors[1]`   | `$brand.colors.secondary`           |
| `dataColors[2]`   | `$brand.colors.accent`              |
| `canvasWidth`     | `$brand.canvas.width`               |
| `canvasHeight`    | `$brand.canvas.height`              |

---

## Safety rules  _(always enforced, non-negotiable)_

1. **Non-destructive `report.json`** — load the existing `report.json`, apply only the
   delta required by the brief (add/update targeted visuals), and write it back.
   Never replace the entire file with a skeleton; preserve all untouched sections.
2. **Fresh UUIDs** — every new visual object in `report.json` must have a freshly
   generated UUID (v4) `name` field; never duplicate an existing visual `name`.
3. **No TMDL comments** — if the brief touches any `.tmdl` files, apply the same
   no-comment rule as `wpp-model`.
4. **Brand gate** — after writing, the report must pass `evals/gates.ps1 -Check Brand`
   before the skill reports success.
5. **Canvas dimensions** — `canvasWidth` and `canvasHeight` in `report.json` must equal
   `$brand.canvas.width` and `$brand.canvas.height` respectively.

---

## Layout rules for KPI grids

When the brief specifies an N×M KPI grid:
- Divide the canvas width by M and canvas height by the number of rows to derive cell sizes.
- Position each KPI card so cells are evenly spaced with a 12 px gutter.
- Respect `$brand.canvas.gridColumns` and `$brand.canvas.gridRows` as the authoritative grid.

---

## Output

Return a JSON object:

```json
{
  "reportJsonPath": "<absolute path to report.json>",
  "visualsAdded":   ["<uuid1>", "<uuid2>"],
  "visualsUpdated": ["<uuid3>"],
  "brandApplied":   true,
  "gateResult":     "pass"
}
```

Abort with `WPP_REPORT_ERR_DESTRUCTIVE_WRITE` if the skill would overwrite sections of
`report.json` not targeted by the brief.
Abort with `WPP_REPORT_ERR_BRAND_GATE_FAIL` if the brand gate does not pass.
