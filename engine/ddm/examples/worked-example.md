# Worked Example — Digital Marketing Dashboard Start applied to `DDM dashboard initial_1.pbip`

This mirrors the structure of the Media Analytics stream's `worked-example.md`, but
records a real DDM run: turning `DDM dashboard initial_1` into `DDM dashboard setup_1`.

## Token substitutions (team defaults)

| Token | Value |
|---|---|
| `<FACT_TABLE>` | `V_FACT_SEND_PERFORMANCE_TRACKING` |
| `<FACT_DATE_COLUMN>` | `SEND_DATE` |
| `<FACT_COUNTRY_COLUMN>` | `BUSINESS_UNIT` |
| `<FACT_COMPKEY_COLUMN>` | `COMP_KEY` |
| `<COUNTRY_DIM>` | `V_DIM_COUNTRY` |
| `<METADATA_DIM>` | `V_DIM_SFMC_METADATA_JOB` |
| `<DASHBOARD_TITLE>` | `Name For The Dashboard` |
| `<ENABLE_BM>` | `true` |

## Pre-flight answers given by the user

- Full-period logic: **accepted** (`Is Full Month` / `Is Full Week`).
- Benchmark star: **yes** — build all three BM tables and inactive relationships.

## Starting state (`initial_1`)

- Tables: `V_FACT_SEND_PERFORMANCE_TRACKING`, `V_DIM_COUNTRY`, `V_DIM_SFMC_METADATA_JOB`,
  one `DateTableTemplate_*`, and two auto `LocalDateTable_*`.
- `relationships.tmdl`: **2** relationships (auto date only).
- `model.tmdl` `PBI_QueryOrder`: params + 3 tables; 6 `ref table` lines.

## Files written / edited

### 1. `…SemanticModel/definition/tables/dimCalendar.tmdl` (new)
Custom calculated calendar. Partition source:
```dax
ADDCOLUMNS(
  CALENDAR(
    DATE(YEAR(MIN(V_FACT_SEND_PERFORMANCE_TRACKING[SEND_DATE])), MONTH(MIN(...)), DAY(MIN(...))),
    DATE(YEAR(MAX(V_FACT_SEND_PERFORMANCE_TRACKING[SEND_DATE])), MONTH(MAX(...)), DAY(MAX(...)))),
  "DateKey", FORMAT([Date],"YYYYMMDD"), "Year", FORMAT([Date],"yyyy"),
  "YearMonth (date format)", DATE(YEAR([Date]),MONTH([Date]),1),
  "YearWeek (date format)", [Date]-WEEKDAY([Date],2)+1, … )
```
Measures added: `Last Fact Date`, `Is Full Month`, `Is Full Week`. Date-typed columns
(`Date`, `YearMonth (date format)`, `YearWeek (date format)`, `Start of month`,
`New Date`) each got a `variation` pointing at a fresh `LocalDateTable_*`.

### 2. Benchmark star (because `<ENABLE_BM> = true`)
- `tables/dimCalendarBM.tmdl` — same `CALENDAR(...)` source, key column `DateBM`.
- `tables/V_DIM_COUNTRY_BM.tmdl` — M query over the `V_DIM_COUNTRY` Snowflake view, adds
  `Region_Name_Transformed` (`LATAM → GILA`) and `SOURCE_COUNTRY_CODE`.
- `tables/V_DIM_SFMC_METADATA_JOB_BM.tmdl` — M query over `V_DIM_SFMC_METADATA_JOB`
  (demote/transpose/lowercase headers, rename `program_or_compaign → program_or_campaign`).

### 3. LocalDateTables (new)
Eight new `LocalDateTable_*` created (5 for `dimCalendar` variations, 3 for
`dimCalendarBM`), each with a freshly generated GUID kept in sync with the `variation`
references in the calendar tables.

### 4. `relationships.tmdl` (appended — 2 → 16)
**Active:**
```tmdl
relationship 782eebb4-…  fromColumn: V_FACT_SEND_PERFORMANCE_TRACKING.SEND_DATE     toColumn: dimCalendar.Date
relationship 411bb1f4-…  fromColumn: V_FACT_SEND_PERFORMANCE_TRACKING.BUSINESS_UNIT toColumn: V_DIM_COUNTRY.'Country SFMC name'
relationship f16aca28-…  fromColumn: V_FACT_SEND_PERFORMANCE_TRACKING.COMP_KEY      toColumn: V_DIM_SFMC_METADATA_JOB.comp_key
```
**Inactive (BM):**
```tmdl
relationship 1d338129-…  isActive: false  …BUSINESS_UNIT → V_DIM_COUNTRY_BM.'Country SFMC name'
relationship 9243fda8-…  isActive: false  …SEND_DATE     → dimCalendarBM.DateBM
relationship 0c481d0a-…  isActive: false  …COMP_KEY      → V_DIM_SFMC_METADATA_JOB_BM.comp_key
```
**Inactive bidirectional:**
```tmdl
relationship AutoDetected_8c8d3559-…  isActive: false  crossFilteringBehavior: bothDirections  fromCardinality: one
    fromColumn: V_DIM_COUNTRY_BM.SOURCE_COUNTRY_CODE  toColumn: V_DIM_COUNTRY.SOURCE_COUNTRY_CODE
```
Plus the eight `dimCalendar.* / dimCalendarBM.* → LocalDateTable_*.Date` variation joins
(`joinOnDateBehavior: datePartOnly`), and the two original auto relationships retained.

### 5. `model.tmdl`
- `PBI_QueryOrder = [ …params…, "V_DIM_COUNTRY","V_DIM_COUNTRY_BM","V_DIM_SFMC_METADATA_JOB","V_DIM_SFMC_METADATA_JOB_BM","V_FACT_SEND_PERFORMANCE_TRACKING" ]`
- Added `ref table` lines: `dimCalendar`, `dimCalendarBM`,
  `V_DIM_COUNTRY_BM`, `V_DIM_SFMC_METADATA_JOB_BM`, and all eight new `LocalDateTable_*`.

### 6. Report
Standard Volvo frame + `Name For The Dashboard` title applied to the target page, reusing
`templates/report/` assets.

## Validation observed

- `V_FACT_SEND_PERFORMANCE_TRACKING` shows three active relationships (`dimCalendar`,
  `V_DIM_COUNTRY`, `V_DIM_SFMC_METADATA_JOB`) and three inactive BM relationships plus the
  inactive bidirectional `V_DIM_COUNTRY ↔ V_DIM_COUNTRY_BM` link.
- `dimCalendar[Last Fact Date]` = max `SEND_DATE`; `Is Full Month` / `Is Full Week`
  return `TRUE` only for completed periods.
- All 16 relationships and every new `LocalDateTable_*` have matching `ref table` lines;
  the model loads cleanly — matching `DDM dashboard setup_1`.
