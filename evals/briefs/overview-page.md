# Eval Brief: Overview Page (Volvo DDM)

## Purpose
Verify that the Volvo DDM overview page has been correctly reproduced and restyled to
Volvo Centum. This is the primary POC deliverable.

## Target
- **Report:** Volvo DDM Overview page
- **Canvas:** 1280 × 1300 px
- **Layout:** 9 KPI cards in a 3×3 grid
- **Charts:** Mixed (bar + line) below the KPI grid
- **Slicers:** BM (Business Metric) slicer at the top of the page
- **Style:** Volvo Centum brand (see `clients/volvo/brand.json`)

## Ground Truth
This brief defines the rubric; there is no golden file. Scores are derived from
structural inspection of `report.json` and brand-token matching.

---

## Criteria

### 1. KPI Card Count  (weight: 0.20)
**What to check:** The overview page contains exactly 9 visuals of type `card` or
`kpiVisual`.

**Scoring:**
- 100 — Exactly 9 KPI cards present
- 75  — 7 or 8 KPI cards present
- 50  — 6 KPI cards present
- 0   — Fewer than 6 or more than 9 KPI cards

---

### 2. 3×3 Grid Layout  (weight: 0.20)
**What to check:** The 9 KPI cards are positioned in 3 columns and 3 rows.
- Column width = (1280 − 2 × 24 px padding − 2 × 12 px gutters) ÷ 3 ≈ 397 px
- Row height is consistent across all 3 rows
- Cards are evenly spaced within the 12 px gutter constraint

**Scoring:**
- 100 — All 9 cards within ±20 px of the ideal 3×3 grid positions
- 75  — 7–8 cards within tolerance
- 50  — 5–6 cards within tolerance
- 0   — Fewer than 5 cards in the correct grid position

---

### 3. BM Slicer Present  (weight: 0.15)
**What to check:** The page contains at least one slicer visual connected to a
`Business Metric` or `BM` column/field.

**Scoring:**
- 100 — BM slicer present and connected to the correct field
- 50  — Slicer present but field connection unclear or wrong
- 0   — No slicer on the page

---

### 4. Mixed Charts Present  (weight: 0.15)
**What to check:** Below the KPI grid, the page contains at least one bar chart
(`clusteredBarChart` or `clusteredColumnChart`) **and** at least one line chart
(`lineChart` or `lineClusteredColumnComboChart`).

**Scoring:**
- 100 — Both a bar chart and a line chart are present
- 50  — Only one of the two chart types is present
- 0   — Neither chart type is present

---

### 5. Volvo Centum Brand Applied  (weight: 0.15)
**What to check:** The KPI cards and charts use Volvo Centum brand tokens:
- Primary colour `#1C3F6E` in titles or value text
- Font family `Volvo Novum`
- Canvas dimensions 1280 × 1300

**Scoring:**
- 100 — All three brand checks pass
- 75  — Two of three brand checks pass
- 50  — One brand check passes
- 0   — No brand tokens applied

---

### 6. KPI Measures Connected  (weight: 0.10)
**What to check:** Each of the 9 KPI card visuals is bound to a distinct DAX measure
(no two cards share the same measure binding, no binding is null or empty).

**Scoring:**
- 100 — All 9 cards bound to distinct non-null measures
- 75  — 7–8 cards correctly bound
- 50  — 5–6 cards correctly bound
- 0   — Fewer than 5 cards correctly bound

---

### 7. Non-Destructive PBIP Write  (weight: 0.05)
**What to check:** The PBIP repo's existing pages, bookmarks, and data source
connections outside the overview page are unchanged.

**Scoring:**
- 100 — No untargeted files modified
- 0   — At least one untargeted file was modified

---

## Pass Threshold
**70 / 100** weighted aggregate score.

## Notes
- The PBIP repo is targeted by path (`$pbip_path`); it is never recreated.
- If the overview page does not yet exist in the PBIP repo, criterion 7 is not
  applicable (score 100 by default).
