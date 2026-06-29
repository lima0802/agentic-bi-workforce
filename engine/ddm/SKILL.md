---
name: digital-direct-marketing-dashboard-start
description: Bootstrap a Volvo Digital Marketing (DDM) dashboard on an existing SFMC-sourced PBIP. Adds a custom dimCalendar with full-period logic, a parallel benchmark (BM) star (dimCalendarBM, V_DIM_COUNTRY_BM, V_DIM_SFMC_METADATA_JOB_BM), all required relationships and LocalDateTables, and the model.tmdl wiring. Based on the Media Analytics "marketing-analytics-dashboard-start" skill, adapted for the Digital Marketing stream.
---

# Digital Marketing Dashboard Start

This skill transforms a project from `DDM dashboard initial` into `DDM dashboard setup`
by orchestrating three Fabric skills with DDM-specific templates, brand assets, and
domain knowledge.

## Skill Routing

> For automated agent execution, read **`AGENT.md`** — it contains the full
> three-phase execution plan, hand-off contracts, and Desktop behaviour quick
> reference. The sections below summarise the routing for human readers.

This skill is an orchestration layer. Each phase delegates to the appropriate Fabric skill:

| Phase | Steps | Fabric skill to invoke |
|---|---|---|
| Requirements & spec | Pre-flight questions, page plan, approval | `powerbi-report-planning` |
| Semantic model setup | A – D (calendar, BM star, relationships, model wiring) | `semantic-model-authoring` |
| Report frame + pages | E (theme, logo, frame visuals) + all dashboard pages | `powerbi-report-authoring` |

### How to use this skill

1. **Invoke `powerbi-report-planning`** — gather pre-flight answers (§ Pre-flight Questions
   below), produce a locked spec with page plan and approval before touching any file.
2. **Invoke `semantic-model-authoring`** — execute steps A–D using the templates in
   `templates/semantic-model/`. Pass the DDM-specific overrides in § Semantic Model
   Overrides below to that skill's agent.
3. **Invoke `powerbi-report-authoring`** — execute step E using the assets in
   `templates/report/`. Then build each approved dashboard page (Campaign Overview, Store
   Details, etc.) following the Volvo brand rules in § Report Overrides below.

### DDM-specific overrides — read before delegating

These rules apply regardless of which Fabric skill is executing:

- **Token substitution safety** — NEVER use greedy regex (`<[^>]+>`) to replace tokens.
  Template DAX contains `<=` operators (`if(MONTH([Date])<=6,"H1","H2")`,
  `MonthEnd <= [Last Fact Date]`). A greedy sweep matches from `<=` to the next `>` and
  silently deletes the DAX. Replace only exact, known tokens by literal string match, one
  at a time. See `templates/semantic-model/README.md` for the full hazard description.
- **Fresh UUIDs every run** — regenerate every `lineageTag`, relationship GUID, and
  LocalDateTable filename GUID. Never copy GUIDs from `setup` or the templates verbatim.
- **No TMDL comments** — do not add `//` comments inside `.tmdl` files. A comment between
  a column block and `partition` causes `InvalidLineType / Unexpected line type: Other`.
- **Validate DAX after substitution** — after `semantic-model-authoring` creates the
  calendar tables, confirm `Is Full Month` / `Is Full Week` still contain
  `<= [Last Fact Date]` logic and the calendar partition still has
  `ADDCOLUMNS ( CALENDAR( … ) … )` intact (the `<=6` half-year test must survive).

## Prerequisites
- PBIP in TMDL format with an SFMC fact table `<FACT_TABLE>` containing a date column
  `<FACT_DATE_COLUMN>`, a country/business-unit column `<FACT_COUNTRY_COLUMN>`, and a
  metadata join key `<FACT_COMPKEY_COLUMN>`.
- A `V_DIM_COUNTRY` dimension and a `V_DIM_SFMC_METADATA_JOB` dimension already present
  (as in `initial`). The BM variants are created by this skill from the same Snowflake
  views.
- Snowflake connection parameters already defined in `expressions.tmdl`
  (`param_database_prod`, `param_warehouse_analyst`, `param_role_analyst`,
  `param_schema_dm`, …). This skill does not create them.
- At least one report page exists, or the agent creates one. The agent resolves
  `<PAGE_ID>` from the page display name — never ask for the raw id.

## Token Table

| Token | Description |
|---|---|
| `<FACT_TABLE>` | SFMC fact table name (e.g. `V_FACT_SEND_PERFORMANCE_TRACKING`) |
| `<FACT_DATE_COLUMN>` | Send-date column on the fact (e.g. `SEND_DATE`) |
| `<FACT_COUNTRY_COLUMN>` | Business-unit / country column (e.g. `BUSINESS_UNIT`) |
| `<FACT_COMPKEY_COLUMN>` | Join key to the metadata dim (e.g. `COMP_KEY`) |
| `<COUNTRY_DIM>` | Country dimension table name (default `V_DIM_COUNTRY`) |
| `<METADATA_DIM>` | SFMC metadata dimension table name (default `V_DIM_SFMC_METADATA_JOB`) |
| `<PAGE_ID>` | Page folder id — agent-resolved from display name, never asked verbatim |
| `<DASHBOARD_TITLE>` | Title textbox text |
| `<ENABLE_BM>` | Whether to build the benchmark star (`true`/`false`) |

> All new `lineageTag` values and relationship GUIDs must be freshly generated UUID v4 —
> never copy the GUIDs from `setup`/templates verbatim, or two tables will collide.

### Token substitution rules (read before editing any template)

The placeholder syntax (`<TOKEN>`) deliberately uses angle brackets, **but the template
DAX also uses the `<=` operator** — e.g. `if(MONTH([Date])<=6,"H1","H2")` in the calendar
partitions and `MonthEnd <= [Last Fact Date]` / `WeekEnd <= [Last Fact Date]` in the
`Is Full Month` / `Is Full Week` measures. Because of this collision:

- **NEVER substitute tokens with a greedy/sweeping regex** such as `<[^>]+>` or
  "replace anything in angle brackets". It will match from a `<=` all the way to the next
  real token's closing `>`, silently deleting the DAX in between. TMDL import does **not**
  validate DAX, so the model imports "successfully" and the corruption only surfaces as a
  syntax error inside Power BI Desktop.
- **Replace only the exact, known tokens** from the lists below — by literal string match,
  one token at a time. If you must use a regex to detect *leftover* tokens, anchor it so it
  cannot match an operator, e.g. `<(?![=>])[A-Za-z0-9_\- ]+>`.
- The complete token set is: `<FACT_TABLE>`, `<FACT_DATE_COLUMN>`,
  `<FACT_COUNTRY_COLUMN>`, `<FACT_COMPKEY_COLUMN>`, `<COUNTRY_DIM>`, `<METADATA_DIM>`,
  `<PAGE_ID>`, `<DASHBOARD_TITLE>`, `<ENABLE_BM>`, every `<UUID-*>` (fresh UUID v4),
  every `<HEX32-*>` (fresh 32-char hex), every `<REL-*>` (relationship GUID), every
  `<LDT-*>` (LocalDateTable name), and `<SOURCE_TABLE>` / `<SOURCE_COLUMN>` in the
  LocalDateTable template. Nothing else in the templates is a token.
- **After substituting, validate the DAX, not just the parse.** Import the folder with the
  Power BI MCP (`database_operations ImportFromTmdlFolder`), then `measure_operations Get`
  the three `dimCalendar` measures and confirm each reports `state: "Ready"` and the
  partitions still contain the full `ADDCOLUMNS ( CALENDAR( … ) … )` body with `<=6` intact.

## Pre-flight Questions

> Delegate this phase to **`powerbi-report-planning`**. That skill gathers requirements,
> builds a locked spec, and gets user approval before any file is touched. Use the
> questions below as the DDM-specific input to that skill's requirements workflow.

Ask all of these before touching any file.

1. **Fact table & columns** — confirm `<FACT_TABLE>`, `<FACT_DATE_COLUMN>`,
   `<FACT_COUNTRY_COLUMN>`, `<FACT_COMPKEY_COLUMN>` by reading the fact `.tmdl`. Default
   to the SFMC names above.
2. **Calendar range** — the calendar is data-driven (`CALENDAR(MIN(fact[date]),
   MAX(fact[date]))`), so there is no start-year prompt. Confirm the fact's date column
   is a real date/datetime.
3. **Full-period behaviour** — `dimCalendar` ships `Is Full Month` and `Is Full Week`
   (flag whether a period is complete up to the last fact date). Confirm the team wants
   this default.
4. **Benchmark star (`<ENABLE_BM>`)** — default `true`. If yes, build `dimCalendarBM`,
   `V_DIM_COUNTRY_BM`, `V_DIM_SFMC_METADATA_JOB_BM` and their inactive relationships
   (used for period-over-period / cross-market benchmarking). If no, skip section C.
5. **Dashboard title** — default `Name For The Dashboard`.
6. **Target page** — list pages by `displayName` (read each `pages/*/page.json`; mark the
   active page from `pages.json` as recommended). User picks a display name or
   `Create a new page`.

## Ordered File Map

Paths relative to PBIP root (`<Name>.SemanticModel/` / `<Name>.Report/`).

### A. Core calendar → `semantic-model-authoring`

> Invoke **`semantic-model-authoring`** for steps A–D. Pass the templates from
> `templates/semantic-model/` and the overrides in § DDM-specific overrides above.
> Use `database_operations ImportFromTmdlFolder` (Modeling MCP) to validate after each
> logical batch, then run `measure_operations Get` for the three `dimCalendar` measures.

1. **Create** `SemanticModel/definition/tables/dimCalendar.tmdl` from
   `templates/semantic-model/dimCalendar.tmdl`. Substitute `<FACT_TABLE>` and
   `<FACT_DATE_COLUMN>` inside the `CALENDAR(...)` partition. Regenerate every
   `lineageTag`. This table carries the three measures: `Last Fact Date`,
   `Is Full Month`, `Is Full Week`.
2. **Create** the `dimCalendar` LocalDateTable variations (one per date-typed column with
   a `variation`: `Date`, `YearMonth (date format)`, `YearWeek (date format)`,
   `Start of month`, `New Date`) from `templates/semantic-model/local-date-tables/`.
   Regenerate the GUID in each filename and its `lineageTag`, and keep the
   `relationship:` / `defaultHierarchy:` references in `dimCalendar` in sync with the new
   GUIDs.

### B. Fact wiring + active relationships

4. **Edit** `SemanticModel/definition/tables/<FACT_TABLE>.tmdl` only if the fact's
   `<FACT_DATE_COLUMN>` still has an auto `variation Variation` you want replaced by the
   `dimCalendar` join — otherwise leave it.
5. **Edit** `SemanticModel/definition/relationships.tmdl` — append, from
   `templates/semantic-model/relationships-additions.md` (substituting tokens and
   regenerating GUIDs):
   - **Active:** `<FACT_TABLE>.<FACT_DATE_COLUMN>` → `dimCalendar.Date`.
   - **Active:** `<FACT_TABLE>.<FACT_COUNTRY_COLUMN>` → `<COUNTRY_DIM>.'Country SFMC name'`.
   - **Active:** `<FACT_TABLE>.<FACT_COMPKEY_COLUMN>` → `<METADATA_DIM>.comp_key`.
   - The five `dimCalendar.* → LocalDateTable_*.Date` variation relationships
     (`joinOnDateBehavior: datePartOnly`).
   - Keep the two pre-existing auto relationships from `initial`.

### C. Benchmark star — only if `<ENABLE_BM>` is `true`

6. **Create** `tables/dimCalendarBM.tmdl` from template (same `CALENDAR(...)` source as
   `dimCalendar`, key column `DateBM`). Regenerate GUIDs.
7. **Create** `tables/V_DIM_COUNTRY_BM.tmdl` and `tables/V_DIM_SFMC_METADATA_JOB_BM.tmdl`
   from templates — these are M-partition copies of the base dims pointed at the same
   Snowflake views (`V_DIM_COUNTRY`, `V_DIM_SFMC_METADATA_JOB`) with the BM-specific
   transforms (e.g. `V_DIM_COUNTRY_BM` adds `Region_Name_Transformed` / `LATAM→GILA`).
8. **Create** the BM LocalDateTable variations (`DateBM`, BM `YearMonth`, BM `YearWeek`).
9. **Append** the BM relationships to `relationships.tmdl`:
   - **Inactive:** `<FACT_TABLE>.<FACT_COUNTRY_COLUMN>` → `V_DIM_COUNTRY_BM.'Country SFMC name'`.
   - **Inactive:** `<FACT_TABLE>.<FACT_DATE_COLUMN>` → `dimCalendarBM.DateBM`.
   - **Inactive:** `<FACT_TABLE>.<FACT_COMPKEY_COLUMN>` → `V_DIM_SFMC_METADATA_JOB_BM.comp_key`.
   - **Inactive (bidirectional):** `V_DIM_COUNTRY_BM.SOURCE_COUNTRY_CODE` ↔ `<COUNTRY_DIM>.SOURCE_COUNTRY_CODE`
     (`isActive: false`, `crossFilteringBehavior: bothDirections`, `fromCardinality: one`).
   - The three `dimCalendarBM.* → LocalDateTable_*.Date` variation relationships.

### D. model.tmdl

10. **Edit** `SemanticModel/definition/model.tmdl`:
    - Update `annotation PBI_QueryOrder` to interleave the BM tables next to their base
      counterparts: `… "<COUNTRY_DIM>","V_DIM_COUNTRY_BM","<METADATA_DIM>",
      "V_DIM_SFMC_METADATA_JOB_BM","<FACT_TABLE>"`.
    - Insert `ref table` lines for **every** new table — `dimCalendar`, `dimCalendarBM`,
      `V_DIM_COUNTRY_BM`, `V_DIM_SFMC_METADATA_JOB_BM`, and each new
      `LocalDateTable_*` — after the existing `ref table` block and before
      `ref cultureInfo en-US`. A missing `ref table LocalDateTable_*` line causes a load
      failure.

### E. Report → `powerbi-report-authoring`

> Invoke **`powerbi-report-authoring`** for step E and all subsequent dashboard pages.
> Pass the assets from `templates/report/` and the Volvo brand rules below.
>
> **Volvo brand constants for `powerbi-report-authoring`:**
> - Page size: `width: 1280, height: 1300, displayOption: ActualSize` (golden overview)
> - Page background: `#F2F4F6` (light gray canvas)
> - Header rect: `x: 0, y: 0, w: 1280, h: 172, fill: #001C30` (navy band, logo + title)
> - Section dividers: line shapes `h: 16` between KPI rows (y≈332 / y≈492)
> - KPI grid: 3×3 cards ≈144×144 at cols x=16/432/856, rows y=188/348/508
> - Two slicer rows top; benchmark (BM) slicers: Date/DateBM, REGION_NAME_GROUP/Region\u00b7Market BM
> - Font: **Volvo Centum** (replaces Segoe UI/Arial) on all text visuals
> - Section headers: navy rectangle `#001C30` + white text (Segoe UI 11 pt, minimum h: 36 px)
> - KPI cards: white background, value `#001C30` (`fontColor`), label `#003760` (`fontColor`)
> - Chart bars primary: `#001C30`, secondary: `#66869E`; gridlines `#E0E5EA`
> - After every batch: run `powerbi-report-author validate <path-to-.Report-dir>` — fix
>   all errors before Desktop reload. See `powerbi-report-authoring` skill for the full
>   Edit → Validate → Reload → Screenshot loop.

11. **Copy** `templates/report/RegisteredResources/Volvo_logo.png` →
    `Report/StaticResources/RegisteredResources/Volvo_logo4091686909364213.png`.
12. **Create** `Report/StaticResources/RegisteredResources/Custom6442828407345462.json`
    from `templates/report/RegisteredResources/Custom6442828407345462.json` (the Volvo
    Centum theme).
13. **Overwrite** `Report/definition/report.json` from `templates/report/report.json` (this
    registers both the logo and theme resources).
14. **Create** five frame visuals under `Report/definition/pages/<PAGE_ID>/visuals/`:

    | Folder | Source | Purpose |
    |---|---|---|
    | `7ac9fb140ad0a3d9d46b/visual.json` | `visuals/left-margin.visual.json` | Left margin rect `#001C30` |
    | `0fc4d132d0d6e85c8798/visual.json` | `visuals/top-line.visual.json` | Top accent line |
    | `6f30b9bd469c6d43d25d/visual.json` | `visuals/bottom-line.visual.json` | Bottom accent line |
    | `8c814ed08c93e9b65cc7/visual.json` | `visuals/volvo-logo.visual.json` | Volvo logo |
    | `84107724b59a1061b948/visual.json` | `visuals/dashboard-title.visual.json` | Title textbox — substitute `<DASHBOARD_TITLE>` |

15. **Confirm** `Report/definition/pages/<PAGE_ID>/page.json` has
    `"width":1300,"height":1400,"displayOption":"FitToPage"`; update only those three keys
    if needed.

## Validation

### Semantic model (`semantic-model-authoring`)
- Model has `dimCalendar` and (if `<ENABLE_BM>`) `dimCalendarBM`,
  `V_DIM_COUNTRY_BM`, `V_DIM_SFMC_METADATA_JOB_BM`.
- `<FACT_TABLE>` has **three active** relationships: → `dimCalendar.Date`,
  → `<COUNTRY_DIM>`, → `<METADATA_DIM>`; and (if BM) three **inactive** BM relationships
  plus the inactive bidirectional country↔country_BM link.
- `dimCalendar[Last Fact Date]` returns the max fact send date; `Is Full Month` /
  `Is Full Week` evaluate `TRUE`/`FALSE` correctly.
- Every new `LocalDateTable_*` has a matching `ref table` line in `model.tmdl`; the model
  loads without error.
- Use `database_operations ImportFromTmdlFolder` then `measure_operations Get` for
  `Last Fact Date`, `Is Full Month`, `Is Full Week` — each must report `state: "Ready"`.

### Report (`powerbi-report-authoring`)
- `powerbi-report-author validate <path-to-.Report-dir>` returns **0 errors, 0 warnings**.
- Page shows the standard Volvo frame and `<DASHBOARD_TITLE>`.
- Desktop reload + screenshot confirms rendered output matches the Volvo brand rules in
  § E above. Use the `powerbi-report-authoring` Edit → Validate → Reload → Screenshot loop.
