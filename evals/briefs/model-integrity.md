# Brief — Model Integrity (spec-as-truth)

Graded after wpp-model. Truth = DDM model contract; prod-applicable.

## Tier-1 gates
- Tables exist: dimCalendar; if ENABLE_BM: dimCalendarBM, V_DIM_COUNTRY_BM, V_DIM_SFMC_METADATA_JOB_BM.
- ≥16 relationships in relationships.tmdl.
- Every LocalDateTable_* has a `ref table` line in model.tmdl.
- Import via ImportFromTmdlFolder = success.

## Tier-2 rubric
1. 3 active fact rels: → dimCalendar.Date, → V_DIM_COUNTRY, → V_DIM_SFMC_METADATA_JOB.
2. If BM: 3 inactive BM rels + inactive bidirectional country↔country_BM.
3. dimCalendar measures Last Fact Date / Is Full Month / Is Full Week state=Ready, `<=` intact.
4. No greedy-token DAX corruption; no `//` in tmdl.

## Pass = gates 0 fail + rubric ≥ 90%.
