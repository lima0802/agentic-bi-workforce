# SKILL-DDM — Agent Orchestration

This file is the **entry point for automated agents** running the
`digital-direct-marketing-dashboard-start` skill. It defines the three-phase
execution plan, which Fabric skill to invoke for each phase, and the hand-off
contracts between them.

For domain content (token table, template details, brand rules) read `SKILL.md`.
For template-level hazards (the `<=` DAX collision) read
`templates/semantic-model/README.md`.

---

## Execution Plan

```
Phase 1 — Plan & Approve      →  powerbi-report-planning
Phase 2 — Semantic Model      →  semantic-model-authoring
Phase 3 — Report & Pages      →  powerbi-report-authoring
```

Phases are sequential. Do **not** start Phase 2 until the spec from Phase 1 is
approved. Do **not** start Phase 3 until Phase 2 validation passes.

---

## Phase 1 — Plan & Approve (`powerbi-report-planning`)

**Goal:** gather DDM-specific requirements, lock a report spec, and get user
approval before any file is touched.

**Input to give `powerbi-report-planning`:**
- The six pre-flight questions from `SKILL.md → Pre-flight Questions`
- The resolved token values (read from the fact `.tmdl` to confirm column names)
- The page list from `pages/*/page.json` (so the user can pick a target page or
  request a new one)

**Output expected:**
- Approved token map: `<FACT_TABLE>`, `<FACT_DATE_COLUMN>`, `<FACT_COUNTRY_COLUMN>`,
  `<FACT_COMPKEY_COLUMN>`, `<COUNTRY_DIM>`, `<METADATA_DIM>`, `<ENABLE_BM>`,
  `<DASHBOARD_TITLE>`, `<PAGE_ID>` (resolved from display name)
- Approved page plan: which dashboard pages to build after the frame (e.g.
  Campaign Performance Overview, Store Details)
- Locked `_brief/report-spec.md` (or inline spec block) signed off by the user

**Hand-off to Phase 2:** pass the approved token map.

---

## Phase 2 — Semantic Model (`semantic-model-authoring`)

**Goal:** create all TMDL tables, relationships, and model wiring (SKILL.md steps A–D).

**Critical overrides — pass these to `semantic-model-authoring` verbatim:**

> 1. **Token substitution safety** — NEVER use greedy regex (`<[^>]+>`) on template
>    files. DAX in the templates contains `<=` operators that will be silently deleted
>    by a sweep. Replace only the exact tokens from the token map, one literal string
>    at a time. See `templates/semantic-model/README.md`.
> 2. **Fresh UUIDs every run** — regenerate every `lineageTag`, relationship GUID,
>    and LocalDateTable filename GUID. Never reuse GUIDs from `setup_1` or templates.
> 3. **No TMDL comments** — do not insert `//` comments inside `.tmdl` files.
> 4. **TMDL changes are not live** — Desktop's AS engine compiles the model once at
>    open time. After all TMDL edits are complete the user must close and reopen the
>    PBIP. Do not attempt `powerbi-desktop reload` for semantic model changes.

**Steps (from `SKILL.md → Ordered File Map`):**

| Step | Action | Template |
|------|--------|----------|
| A1 | Create `dimCalendar.tmdl` | `templates/semantic-model/dimCalendar.tmdl` |
| A2 | Create 5 `dimCalendar` LocalDateTables | `templates/semantic-model/local-date-tables/` |
| B | Append active relationships to `relationships.tmdl` | `templates/semantic-model/relationships-additions.md` |
| C | Create BM star (`dimCalendarBM`, `V_DIM_COUNTRY_BM`, `V_DIM_SFMC_METADATA_JOB_BM`) + 3 BM LocalDateTables + inactive relationships | Same templates folder |
| D | Edit `model.tmdl` — `PBI_QueryOrder` + `ref table` lines | Direct edit |

**Validation (before hand-off):**
1. `database_operations ImportFromTmdlFolder` on `<Name>.SemanticModel/definition`
2. `measure_operations Get` for `Last Fact Date`, `Is Full Month`, `Is Full Week`
   — each must report `state: "Ready"` with `<= [Last Fact Date]` logic intact
3. Confirm 16 relationships total; all new `LocalDateTable_*` have `ref table` lines

**Hand-off to Phase 3:** semantic model passes validation; user has closed and
reopened the PBIP to load the new tables.

---

## Phase 3 — Report & Pages (`powerbi-report-authoring`)

**Goal:** apply the Volvo frame (SKILL.md step E) and build all approved dashboard
pages from the Phase 1 spec.

**Volvo brand constants (pass to `powerbi-report-authoring`):**

| Property | Value |
|---|---|
| Page size | `width: 1300, height: 1400, displayOption: FitToPage` |
| Page background | `#F2F4F6` |
| Left margin rect | `x:0 y:0 w:8 h:1400 fill:#001C30` |
| Top separator | `x:8 y:35 w:1292 h:2 fill:#003760` |
| Bottom separator | `x:8 y:1390 w:1292 h:2 fill:#003760` |
| Slicer sidebar x | `1060` (240 px wide) |
| Section header | `#001C30` rect + white text, Segoe UI 11 pt, min height 36 px |
| KPI value color | `#001C30` (use `fontColor`, not `color`) |
| KPI label color | `#003760` (use `fontColor`, not `color`) |
| Chart bars primary | `#001C30` |
| Chart bars secondary | `#66869E` |
| Gridlines | `#E0E5EA` |

**Steps (from `SKILL.md → Ordered File Map § E`):**
1. Copy Volvo logo → `RegisteredResources/`
2. Create Volvo Centum theme JSON → `RegisteredResources/`
3. Overwrite `report.json` from template
4. Create 5 frame visuals on `<PAGE_ID>`
5. Confirm `page.json` dimensions
6. Build each approved dashboard page from the Phase 1 spec

**Validation loop (after every batch of visual changes):**
```
powerbi-report-author validate <path-to-.Report-dir>
```
- Fix all errors before Desktop reload
- `reload` is sufficient for report/visual changes — no reopen needed
- Screenshot each page; review against Volvo brand constants above
- Do not report completion until validation returns 0 errors, 0 warnings

---

## Desktop Behaviour Quick Reference

| Change type | How to pick it up in Desktop |
|---|---|
| Report JSON / visuals / pages | `powerbi-desktop reload --pid <pid>` |
| Theme JSON (same filename) | Close + reopen PBIP (Desktop caches by filename) |
| TMDL / semantic model | Close + reopen PBIP (AS engine compiles at open time) |
