# semantic-model templates — token substitution warning

> **Invoked by:** `semantic-model-authoring` skill, orchestrated from `AGENT.md`.
> Read `SKILL.md → Token Table → Token substitution rules` **and** `AGENT.md → Phase 2`
> before editing these files.

## The `<=` hazard (this is what corrupts the calendar tables)

Tokens use angle brackets (`<UUID-...>`, `<FACT_TABLE>`, `<HEX32-...>`, …), **but the
template DAX also uses the `<=` operator**:

- `dimCalendar.tmdl` / `dimCalendarBM.tmdl` partitions: `if(MONTH([Date])<=6,"H1","H2")`
- `dimCalendar.tmdl` measures: `MonthEnd <= [Last Fact Date]`,
  `WeekEnd <= [Last Fact Date]`

A greedy substitution like `<[^>]+>` (or "replace everything in angle brackets") will match
from a `<=` to the **next real token's** closing `>` and delete all the DAX in between. The
result imports without error (TMDL does not validate DAX) but Power BI Desktop then shows a
DAX syntax error, and the `ADDCOLUMNS(...)` body / measures are gone.

## Do this instead

- Replace **only the exact, known tokens**, one literal string at a time. Never sweep.
- If you must regex-detect leftover tokens, exclude operators:
  `<(?![=>])[A-Za-z0-9_\- ]+>`.
- Do **not** add `//` comments inside `.tmdl` templates — a comment placed between a
  column block and a `partition` (or similar spots) makes TMDL import fail with
  `InvalidLineType / Unexpected line type: Other`.

## `V_DIM_SFMC_METADATA_JOB_BM` columns

The template lists the core columns only. The full `setup_1` view also carries `email_*`,
`has_*` model flags, `send_type`, `geographic_scope`, `compliant`, etc. Add the remaining
columns verbatim from the source view as needed — each as a `string` column with its own
freshly regenerated `lineageTag`. Add them as normal column blocks; do **not** leave a
comment placeholder in the `.tmdl` file.

## Validate after substituting

1. `database_operations ImportFromTmdlFolder` on `<Name>.SemanticModel/definition`.
2. `measure_operations Get` for `Last Fact Date`, `Is Full Month`, `Is Full Week` —
   each must report `state: "Ready"` with the `<= [Last Fact Date]` logic intact.
3. Confirm both calendar partitions still contain the full
   `ADDCOLUMNS ( CALENDAR( … ) … )` body, including `if(MONTH([Date])<=6,...)`.

> **Note on live changes:** Semantic model (TMDL) changes are **not** picked up by a
> running Desktop instance via `reload` — the AS engine compiles the model once at open
> time. After all TMDL edits are complete, the user must **close and reopen** the PBIP
> for Desktop to reflect the new tables and relationships.
