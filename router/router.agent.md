# Router Agent

## Purpose
Dispatch incoming BI requests to the correct client configuration pack and downstream engine skill.
Every request must declare a `client` slug and a `task` type; the router resolves both to a
concrete path and delegates — it never calls a Fabric skill directly.

---

## Inputs

| Field      | Type   | Required | Description                                                   |
|------------|--------|----------|---------------------------------------------------------------|
| `client`   | string | ✅       | Client slug matching a directory under `clients/`             |
| `task`     | string | ✅       | One of: `plan`, `model`, `report`, `improve`                  |
| `brief`    | string | ✅       | Path to the task brief (markdown or JSON)                     |
| `pbip_path`| string | ❌       | Absolute path to the target PBIP repo (required for `report`) |
| `extra`    | object | ❌       | Task-specific overrides forwarded verbatim to the engine      |

---

## Dispatch Table

```
task     → skill
─────────────────────────────────────────
plan     → skills/wpp-plan/skill.md
model    → skills/wpp-model/skill.md
report   → skills/wpp-report/skill.md
improve  → skills/skill-improve/skill.md
```

---

## Resolution Algorithm

1. **Validate** `client` slug: confirm `clients/<client>/config.json` exists; abort with
   `ROUTER_ERR_NO_CLIENT` otherwise.
2. **Validate** `task`: must be one of the four values above; abort with
   `ROUTER_ERR_UNKNOWN_TASK` otherwise.
3. **Load** `clients/<client>/config.json` → merge with default engine settings.
4. **Load** `clients/<client>/brand.json` → expose as `$brand` to the downstream skill.
5. **Delegate** to the mapped skill, passing:
   - `$config` — merged client config
   - `$brand`  — brand token map
   - `$brief`  — resolved brief path
   - `$pbip_path` — forwarded unchanged (may be null)
   - `$extra`  — forwarded unchanged (may be null)
6. **Return** the skill's response verbatim; do not mutate or summarise it.

---

## Error Codes

| Code                      | Meaning                                         |
|---------------------------|-------------------------------------------------|
| `ROUTER_ERR_NO_CLIENT`    | `clients/<client>/config.json` not found        |
| `ROUTER_ERR_UNKNOWN_TASK` | `task` is not in the dispatch table             |
| `ROUTER_ERR_MISSING_BRIEF`| `brief` path resolved to a non-existent file    |
| `ROUTER_ERR_SKILL_FAIL`   | Downstream skill returned a non-zero exit code  |

---

## Rules

- The router **never** calls Fabric skills or Power BI REST APIs directly.
- The router **never** modifies `$pbip_path` files — it only reads them to forward context.
- Client config and brand tokens are always injected; skills must not read them independently.
- All dispatch decisions are logged to `logs/router.log` (excluded from VCS via `.gitignore`).
