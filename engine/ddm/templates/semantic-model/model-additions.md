# model-additions

Edits to `model.tmdl`. This is **not** a standalone file — apply these two changes to the
existing `model.tmdl`.

## 1) Replace the `PBI_QueryOrder` annotation

Interleave the BM tables next to their base counterparts (drop the `*_BM` entries if
`<ENABLE_BM>` = false):

```tmdl
annotation PBI_QueryOrder = ["param_database_prod","param_warehouse_analyst","param_warehouse_app_directmarketing","param_schema_dm","param_schema_app_directmarketing","param_role_analyst","param_role_app_directmarketing_analyst","<COUNTRY_DIM>","V_DIM_COUNTRY_BM","<METADATA_DIM>","V_DIM_SFMC_METADATA_JOB_BM","<FACT_TABLE>"]
```

## 2) Insert `ref table` lines

Insert these after the existing `ref table` block and **before** `ref cultureInfo en-US`.
Replace each `LocalDateTable_<...>` with the actual GUIDs you generated. Omit every `*_BM`
and BM LocalDateTable line if `<ENABLE_BM>` = false. A missing `ref table LocalDateTable_*`
line causes a load failure.

```tmdl
ref table dimCalendar
ref table dimCalendarBM
ref table V_DIM_COUNTRY_BM
ref table V_DIM_SFMC_METADATA_JOB_BM
ref table LocalDateTable_<LDT-Date>
ref table LocalDateTable_<LDT-YearMonth>
ref table LocalDateTable_<LDT-YearWeek>
ref table LocalDateTable_<LDT-StartOfMonth>
ref table LocalDateTable_<LDT-NewDate>
ref table LocalDateTable_<LDT-BM-Date>
ref table LocalDateTable_<LDT-BM-YearMonth>
ref table LocalDateTable_<LDT-BM-YearWeek>
```
