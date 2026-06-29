---
name: skill-improve
description: Weekly self-improvement loop. Reads eval logs, finds repeated failures, proposes a human-approved skill PR, and appends a dated entry to learnings.md. Use weekly or after a pass-rate drop.
---

# skill-improve (Level 6 — skills that improve themselves)

## When
Weekly batch review, or when overview-page pass-rate < 90%.

## Steps
1. Scan `logs/eval-*.json` for the last period; group failing rubric items + gate checks.
2. Pick the top recurring failure. Trace to the responsible wrapper (wpp-plan/model/report) or brand pack.
3. Draft a minimal fix; open a PR in the **agentic-bi-workforce** repo only (never the PBIP repo).
4. On human approval, merge and append a dated entry to `../learnings.md`:
   `yyyy-mm-dd: <failure> → <fix> → <wrapper updated>`.
5. Re-run the 3 evals; confirm pass-rate up. No silent edits; no auto-merge.

## Guardrails
- Tier-1 gates never weakened to pass — fix the generator, not the test.
- One change per PR; keep diffs reviewable.
