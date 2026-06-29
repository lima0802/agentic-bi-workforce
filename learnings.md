# Workforce Learnings — accumulated from existing workflows

Durable knowledge base. WPP wrappers READ this before acting; the weekly PR loop WRITES
new entries from eval-log failures. Source of truth that survives across runs.

## From existing DDM workflow (repo memory + SKILL.md)
- **Token `<=` corruption** — never greedy `<[^>]+>`; DAX has `<=` (Is Full Month/Week, `MONTH<=6`). Replace known tokens literally. TMDL import won't catch it; Desktop errors.
- **No `//` in `.tmdl`** — comment before `partition` = InvalidLineType crash.
- **report.json overwrite is destructive** — drops filters/resources/theme. Merge + new page.
- **Fresh UUIDs each run** — lineageTag/relationship/LDT GUIDs or tables collide.
- **TMDL not live** — close+reopen PBIP after model edits; reload only for report.
- Project: fact `V_FACT_SEND_PERFORMANCE_TRACKING`, dims `V_DIM_COUNTRY`/`V_DIM_SFMC_METADATA_JOB`.
- Golden uses Segoe/Arial → restyle to Volvo Centum.

## New entries (PR-loop appends, dated)
<!-- yyyy-mm-dd: failure → fix → wrapper updated -->
