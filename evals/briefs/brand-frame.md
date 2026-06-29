# Eval Brief: Brand Frame

## Purpose
Verify that the `report.json` produced by `wpp-report` correctly applies the Volvo Centum
brand tokens from `clients/volvo/brand.json`. A score ≥ 70 is required to pass.

## Ground Truth
This brief defines the rubric; there is no golden file. Expected values are derived
at runtime from `clients/volvo/brand.json`.

---

## Required Brand Token Values (Volvo Centum)

| Token                         | Expected Value                            |
|-------------------------------|-------------------------------------------|
| `colors.primary`              | `#1C3F6E`                                 |
| `colors.secondary`            | `#4A7FC1`                                 |
| `colors.accent`               | `#C8D8E8`                                 |
| `colors.background`           | `#FFFFFF`                                 |
| `typography.fontFamily`       | `Volvo Novum` (first family in the list)  |
| `typography.headingSize`      | `14`                                      |
| `typography.bodySize`         | `11`                                      |
| `canvas.width`                | `1280`                                    |
| `canvas.height`               | `1300`                                    |
| `canvas.gridColumns`          | `3`                                       |
| `canvas.gridRows`             | `3`                                       |

---

## Criteria

### 1. Canvas Dimensions  (weight: 0.25)
**What to check:** `report.json` → `config.canvasWidth` equals 1280 and
`config.canvasHeight` equals 1300.

**Scoring:**
- 100 — Both dimensions match exactly
- 50  — One dimension matches; other is within ±10 px
- 0   — Either dimension differs by more than 10 px or key is missing

---

### 2. Primary Colour Applied  (weight: 0.20)
**What to check:** The hex value `#1C3F6E` (case-insensitive) appears in at least one
visual's `color` or `fill` property within `report.json`.

**Scoring:**
- 100 — Primary colour found in visuals
- 50  — Primary colour found only in theme settings, not in individual visuals
- 0   — Primary colour not found

---

### 3. Font Family Applied  (weight: 0.20)
**What to check:** The string `Volvo Novum` appears in at least one visual's font
definition within `report.json`.

**Scoring:**
- 100 — Font family found in visuals
- 50  — Font family found in theme, not in visuals
- 0   — Font family not found

---

### 4. Data Colours Array  (weight: 0.15)
**What to check:** The report theme's `dataColors` array (or equivalent) contains
`#1C3F6E` as the first element, `#4A7FC1` as the second, and `#C8D8E8` as the third.

**Scoring:**
- 100 — All three data colours in correct order
- 75  — Two of three in correct positions
- 50  — All three present but order differs
- 0   — Fewer than two brand colours present

---

### 5. Background Colour  (weight: 0.10)
**What to check:** The report background colour is `#FFFFFF` (white).

**Scoring:**
- 100 — Background is exactly `#FFFFFF`
- 50  — Background is a near-white (luminance > 0.95) non-brand colour
- 0   — Background is a non-white colour

---

### 6. Non-Destructive Write  (weight: 0.10)
**What to check:** Sections of `report.json` that were not targeted by the brief
(e.g., bookmarks, drill-through configuration, RLS roles) remain unchanged from the
baseline snapshot.

**Scoring:**
- 100 — No untargeted sections modified
- 50  — Minor whitespace or key-ordering changes only
- 0   — Substantive changes to untargeted sections

---

## Pass Threshold
**70 / 100** weighted aggregate score.
