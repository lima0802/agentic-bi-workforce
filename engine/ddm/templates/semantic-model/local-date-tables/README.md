# LocalDateTable template

> **Invoked by:** `semantic-model-authoring` skill, orchestrated from `AGENT.md`.
> Read `AGENT.md → Phase 2` and the parent `README.md` (`<=` hazard) before editing.

`LocalDateTable.template.tmdl` is the single template for every auto `LocalDateTable`
variation — one file per date-typed column that has a `variation` block in `dimCalendar`
/ `dimCalendarBM`.

All eight LocalDateTables in `setup_1` are structurally identical; only three things
change per file — generate fresh values for each:

| Token | Meaning |
|---|---|
| `<LDT-GUID>` | A new UUID. Used in the table name **and** the filename (`LocalDateTable_<LDT-GUID>.tmdl`). |
| `<UUID-*>` | A fresh UUID for every `lineageTag` in the file. |
| `<SOURCE_TABLE>` | The calendar table the variation lives on — `dimCalendar` or `dimCalendarBM`. |
| `<SOURCE_COLUMN>` | The calendar column this LDT pads — e.g. `Date`, `YearMonth (date format)`, `YearWeek (date format)`, `Start of month`, `New Date`, `DateBM`. |

After creating each file:

1. Point the matching `variation` in the calendar table at:
   - `relationship: <REL-...>` (defined in `relationships-additions.tmdl`)
   - `defaultHierarchy: LocalDateTable_<LDT-GUID>.'Date Hierarchy'`
2. Add `ref table LocalDateTable_<LDT-GUID>` to `model.tmdl`.
