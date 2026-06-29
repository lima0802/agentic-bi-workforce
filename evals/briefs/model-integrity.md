# Eval Brief: Model Integrity

## Purpose
Verify that the semantic model (TMDL) produced by `wpp-model` is structurally sound,
safe from known failure patterns, and compatible with the Fabric TMDL parser.

## Ground Truth
This brief defines the rubric; there is no golden file. The model is evaluated against
the rules below. A score ≥ 70 is required to pass.

---

## Criteria

### 1. No TMDL Comments  (weight: 0.25)
**What to check:** Every `.tmdl` file in the model folder must contain zero comment lines.
A comment line starts with `//` or contains `/* ... */`.

**Why:** The Fabric TMDL parser silently rejects or misparses files that contain comments,
causing unpredictable import failures.

**Scoring:**
- 100 — No comments found in any TMDL file
- 0   — One or more comments found

---

### 2. No Greedy `<=` Token Regex  (weight: 0.20)
**What to check:** DAX measure expressions must not contain an unanchored `<=` comparison
against a bare string token (e.g., `[Status] <= "Z"`). Every comparison must be scoped to
a specific column reference.

**Why:** Greedy string comparisons return incorrect results when values are added to the
dimension table that sort lexicographically outside the intended range.

**Scoring:**
- 100 — No unanchored `<=` string comparisons found
- 50  — Comparisons are scoped but use string literals instead of column values
- 0   — Unanchored `<=` string comparisons found

---

### 3. Fresh UUID v4 lineageTags  (weight: 0.20)
**What to check:** Every `lineageTag` in newly written TMDL files is a valid UUID v4
(format `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`). No `lineageTag` is duplicated within
the model.

**Why:** Duplicate or invalid lineage tags corrupt the model's dependency graph and
break incremental refresh.

**Scoring:**
- 100 — All lineage tags are valid, unique UUID v4 values
- 50  — All valid UUID v4 but one duplicate exists
- 0   — Invalid format or duplicates > 1

---

### 4. Non-Destructive Writes  (weight: 0.20)
**What to check:** The set of TMDL files written must be a subset of files explicitly
named in the brief or plan. No existing file outside the target set has been deleted
or truncated.

**Why:** Destructive writes can silently remove measures or tables relied on by other
reports sharing the same model.

**Scoring:**
- 100 — Only targeted files were written; no unintended deletions
- 0   — At least one file outside the target set was modified or deleted

---

### 5. DAX Measure Completeness  (weight: 0.15)
**What to check:** Every measure listed in the plan JSON appears in the written TMDL
with a non-empty expression. Expressions must terminate with an explicit value or
`RETURN` statement.

**Scoring:**
- 100 — All planned measures present and syntactically complete
- 75  — All present; one measure has an empty expression
- 50  — One measure from the plan is missing
- 0   — Two or more measures missing

---

### 6. Relationship Definitions Complete  (weight: 0.10)
**What to check:** Every relationship defined in the model specifies both
`crossFilteringBehavior` and `joinOnDateBehavior` (if date tables are involved).

**Scoring:**
- 100 — All relationships fully specified
- 50  — One relationship missing `crossFilteringBehavior`
- 0   — Multiple relationships with missing properties

---

## Pass Threshold
**70 / 100** weighted aggregate score.
