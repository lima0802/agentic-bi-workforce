# Learnings

Accumulated lessons from eval runs and self-improvement cycles.
Each bullet is appended by `skill-improve`; entries are never edited or deleted.

---

- [2026-06-29] model.no_tmdl_comments: Fabric TMDL parser silently rejects files
  containing `//` or `/* */` comments → strip all comments before writing TMDL output.

- [2026-06-29] model.no_greedy_le_regex: Unanchored `<= "Z"` in DAX returns wrong
  results when dimension values expand beyond the intended range → always scope `<=`
  comparisons to a specific column reference (e.g., `'Table'[Status] <= "Active"`).

- [2026-06-29] report.non_destructive_write: Replacing the entire `report.json` with a
  skeleton silently removes bookmarks, drill-through config, and RLS roles → always load
  the existing file, apply only the targeted delta, and write it back.

- [2026-06-29] model.uuid_v4_lineage_tags: Copying `lineageTag` values from existing
  artifacts corrupts the model's dependency graph → generate a fresh UUID v4 for every
  new table, partition, measure, and relationship.
