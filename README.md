# Agentic BI Workforce

Standalone, reusable skills repo. PBIP projects live elsewhere (e.g. sibling
`../Testing DDM/`); the workforce targets them by path — never bundles them.

Reusable, eval-graded, self-improving agentic workforce for Power BI dashboard
delivery. POC #1: Volvo Cars Digital Direct Marketing (DDM). Designed to expand to
any client stream via config packs. Coding agent: **GitHub Copilot**.

## Layout

```
workforce/
  README.md                ← this file
  router/
    router.agent.md        ← BI Workforce router: dispatch by client + task
  skills/
    wpp-plan/   wpp-model/   wpp-report/   skill-improve/  ← WPP wrappers + self-improve
  fixtures/                ← golden refs live in sibling `../Testing DDM/Reference`
  logs/                    ← eval-*.json runs feed weekly skill-PR loop
  clients/
    volvo/
      config.json          ← tokens, paths, ENABLE_BM
      brand.json           ← Volvo Centum + colors + frame geometry
  evals/
    gates.ps1              ← Tier-1 deterministic gates (PowerShell)
    judge.py               ← Tier-2 LLM-judge vs brief rubric (Python)
    eval.ps1               ← runs gates then invokes judge, writes logs
    briefs/
      ddm-overview.md      ← spec-as-truth for POC overview page
  fixtures/
    ddm-summary/           ← golden reference (Reference/DDM Summary dashboard) for calibration
  logs/                    ← eval-*.json runs feed weekly skill-PR loop
```

## Flow

1. **Router** picks client (`volvo`) + task (`ddm-start`) → loads config + brand pack.
2. **DDM skill** (the engine, one level up) runs planning → semantic model → report.
3. **Evals** grade output vs `briefs/ddm-overview.md` (truth = approved brief, prod-applicable).
4. **Self-improve** weekly: read `logs/` failures → human-approved skill PR → append to `learnings.md`.

> **Learnings** (`learnings.md`) is the durable lesson base from existing workflows. Every
> WPP wrapper reads it first; the PR loop writes new entries. This is where prior knowledge
> lives — the `<=` token hazard, TMDL comment crash, destructive overwrite, Centum restyle.

## Run evals

```powershell
./evals/eval.ps1 -ReportDir "<path>.Report" -Eval overview-page
```

Eval set: `model-integrity`, `brand-frame`, `overview-page`. Tier-1 (PowerShell) must pass
before Tier-2 (Python judge) scores the rubric.
