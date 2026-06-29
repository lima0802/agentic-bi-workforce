# Skill: wpp-plan  (WPP Report Planning)

## Pinned upstream skill
`powerbi-report-planning`

This skill is a **thin WPP wrapper**. It injects WPP brand and safety rules, then delegates
all planning logic to the pinned Fabric skill. It must **never** call Fabric APIs directly.

---

## Purpose
Translate a plain-language brief into a structured report plan: page list, KPI definitions,
visual types, layout sketch, and a BM (Business Metric) slicer specification.

---

## Inputs  _(injected by the router)_

| Field       | Type   | Description                                    |
|-------------|--------|------------------------------------------------|
| `$config`   | object | Client config from `clients/<client>/config.json` |
| `$brand`    | object | Brand tokens from `clients/<client>/brand.json`   |
| `$brief`    | string | Path to the markdown brief                      |

---

## Brand injection rules

Before delegating to `powerbi-report-planning`, prepend the following block to the
brief context:

```
[WPP Brand Guard]
Primary colour  : {{$brand.colors.primary}}
Secondary colour: {{$brand.colors.secondary}}
Accent colour   : {{$brand.colors.accent}}
Background      : {{$brand.colors.background}}
Font family     : {{$brand.typography.fontFamily}}
Heading size    : {{$brand.typography.headingSize}}
Body size       : {{$brand.typography.bodySize}}
Logo path       : {{$brand.assets.logoPath}}
Canvas width    : {{$brand.canvas.width}}  px
Canvas height   : {{$brand.canvas.height}} px
Grid columns    : {{$brand.canvas.gridColumns}}
Grid rows       : {{$brand.canvas.gridRows}}
```

---

## Safety rules  _(always enforced, non-negotiable)_

1. **No greedy `<=` token regex** — never emit a TMDL measure containing an unanchored
   `<=` comparison against a string token; always scope to a specific column.
2. **No TMDL comments** — the output TMDL must contain zero `//` or `/* */` comment lines;
   they break Fabric's TMDL parser.
3. **Non-destructive output** — the plan must never propose deleting existing pages, measures,
   or visuals that are not explicitly listed in the brief as targets for replacement.
4. **Fresh UUIDs** — every new visual, page, and bookmark must be assigned a freshly
   generated UUID (v4); never reuse UUIDs from existing report artifacts.

---

## Output format

Return a JSON object with the following schema:

```json
{
  "reportTitle": "<string>",
  "canvasWidth":  <number>,
  "canvasHeight": <number>,
  "pages": [
    {
      "name":     "<string>",
      "order":    <number>,
      "visuals":  [
        {
          "id":        "<uuid-v4>",
          "type":      "<visual-type>",
          "title":     "<string>",
          "measure":   "<DAX measure name>",
          "position":  { "x": <n>, "y": <n>, "w": <n>, "h": <n> }
        }
      ],
      "slicers": [
        {
          "id":      "<uuid-v4>",
          "field":   "<table>/<column>",
          "label":   "<string>",
          "position":{ "x": <n>, "y": <n>, "w": <n>, "h": <n> }
        }
      ]
    }
  ],
  "brandApplied": true
}
```

`brandApplied` must be `true`; if any brand token is missing from `$brand`, abort with
`WPP_PLAN_ERR_MISSING_BRAND_TOKEN` and list the missing keys.
