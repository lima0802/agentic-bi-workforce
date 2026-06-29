# relationships-additions

Relationships to **append** to `relationships.tmdl` (keep the two pre-existing auto
relationships from `initial_1`). Substitute the tokens and regenerate **every**
relationship GUID. The `<REL-...>` GUIDs must match the `relationship:` references in the
calendar `variation` blocks and each LocalDateTable. The five (or eight, with BM) LDT
GUIDs must match the LocalDateTable file names.

## Active fact relationships

```tmdl
relationship <REL-fact-dimCalendar>
	fromColumn: <FACT_TABLE>.<FACT_DATE_COLUMN>
	toColumn: dimCalendar.Date

relationship <REL-fact-country>
	fromColumn: <FACT_TABLE>.<FACT_COUNTRY_COLUMN>
	toColumn: <COUNTRY_DIM>.'Country SFMC name'

relationship <REL-fact-metadata>
	fromColumn: <FACT_TABLE>.<FACT_COMPKEY_COLUMN>
	toColumn: <METADATA_DIM>.comp_key
```

## dimCalendar variation → LocalDateTable joins (datePartOnly)

```tmdl
relationship <REL-dimCalendar-Date>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendar.Date
	toColumn: <LDT-Date>.Date

relationship <REL-dimCalendar-YearMonth>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendar.'YearMonth (date format)'
	toColumn: <LDT-YearMonth>.Date

relationship <REL-dimCalendar-YearWeek>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendar.'YearWeek (date format)'
	toColumn: <LDT-YearWeek>.Date

relationship <REL-dimCalendar-StartOfMonth>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendar.'Start of month'
	toColumn: <LDT-StartOfMonth>.Date

relationship <REL-dimCalendar-NewDate>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendar.'New Date'
	toColumn: <LDT-NewDate>.Date
```

## Benchmark — only append when `<ENABLE_BM>` = true

### Inactive benchmark fact relationships

```tmdl
relationship <REL-fact-country-BM>
	isActive: false
	fromColumn: <FACT_TABLE>.<FACT_COUNTRY_COLUMN>
	toColumn: V_DIM_COUNTRY_BM.'Country SFMC name'

relationship <REL-fact-dimCalendarBM>
	isActive: false
	fromColumn: <FACT_TABLE>.<FACT_DATE_COLUMN>
	toColumn: dimCalendarBM.DateBM

relationship <REL-fact-metadata-BM>
	isActive: false
	fromColumn: <FACT_TABLE>.<FACT_COMPKEY_COLUMN>
	toColumn: V_DIM_SFMC_METADATA_JOB_BM.comp_key
```

### Inactive bidirectional bridge between base and benchmark country dims

Kept **inactive** (`isActive: false`) — activate it per-measure with `USERELATIONSHIP`
when a calculation needs the base⇄benchmark country bridge.

```tmdl
relationship <REL-country-bridge>
	isActive: false
	crossFilteringBehavior: bothDirections
	fromCardinality: one
	fromColumn: V_DIM_COUNTRY_BM.SOURCE_COUNTRY_CODE
	toColumn: <COUNTRY_DIM>.SOURCE_COUNTRY_CODE
```

### dimCalendarBM variation → LocalDateTable joins (datePartOnly)

```tmdl
relationship <REL-dimCalendarBM-DateBM>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendarBM.DateBM
	toColumn: <LDT-BM-Date>.Date

relationship <REL-dimCalendarBM-YearMonth>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendarBM.'YearMonth (date format)'
	toColumn: <LDT-BM-YearMonth>.Date

relationship <REL-dimCalendarBM-YearWeek>
	joinOnDateBehavior: datePartOnly
	fromColumn: dimCalendarBM.'YearWeek (date format)'
	toColumn: <LDT-BM-YearWeek>.Date
```
