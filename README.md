# agentic-bi-workforce

> **Internal use only — not for external distribution.**
> This repository does not use an MIT or any other open-source licence.
> All content is proprietary to WPP and its clients.

Reusable, eval-graded Copilot skills that automate Power BI (PBIP/PBIR) dashboard
delivery across WPP client streams.

```
router → WPP skill wrappers (plan / model / report / improve)
       → 3-tier evals (deterministic gates + LLM rubric)
       → self-improving PR loop
```

POC: **Volvo DDM overview page** — 9 KPIs (3×3), mixed charts, BM slicers, 1280×1300 px,
restyled to **Volvo Centum**.

---

## Repository structure

```
.
├── router/
│   └── router.agent.md          # Dispatch by client + task → skill
├── skills/
│   ├── wpp-plan/
│   │   └── skill.md             # WPP wrapper over powerbi-report-planning
│   ├── wpp-model/
│   │   └── skill.md             # WPP wrapper over semantic-model-authoring
│   ├── wpp-report/
│   │   └── skill.md             # WPP wrapper over powerbi-report-authoring
│   └── skill-improve/
│       └── skill.md             # Weekly self-improvement loop
├── clients/
│   └── volvo/
│       ├── config.json          # Client paths, locale, eval pointers
│       └── brand.json           # Volvo Centum design tokens
├── evals/
│   ├── gates.ps1                # Deterministic PowerShell gate checks
│   ├── judge.py                 # LLM rubric scorer (OpenAI / Azure OpenAI)
│   ├── eval.ps1                 # Orchestrator: gates → judge → log
│   └── briefs/
│       ├── model-integrity.md   # TMDL structural correctness rubric
│       ├── brand-frame.md       # Brand token compliance rubric
│       └── overview-page.md     # Volvo DDM overview page POC rubric
├── learnings.md                 # Accumulated lessons (append-only)
├── .gitignore
└── README.md
```

---

## How it works

### 1. Router
Every request enters via `router/router.agent.md`. Provide:
- `client` — a slug matching a directory under `clients/` (e.g., `volvo`)
- `task` — one of `plan`, `model`, `report`, `improve`
- `brief` — path to the task brief
- `pbip_path` — absolute path to the PBIP repo (required for `model` and `report`)

The router loads `clients/<client>/config.json` and `brand.json`, then delegates to the
appropriate skill. It **never** calls Fabric APIs directly.

### 2. Skills
Each skill is a thin WPP wrapper over a pinned Fabric skill:

| Skill           | Pinned Fabric skill              | Purpose                         |
|-----------------|----------------------------------|---------------------------------|
| `wpp-plan`      | `powerbi-report-planning`        | Brief → structured report plan  |
| `wpp-model`     | `semantic-model-authoring`       | Plan → TMDL semantic model      |
| `wpp-report`    | `powerbi-report-authoring`       | Plan → `report.json` delta      |
| `skill-improve` | *(internal)*                     | Eval logs → PRs + learnings     |

All skills inject brand tokens and enforce the four safety rules below before delegating.

### 3. Safety rules (non-negotiable across all skills)
1. **No greedy `<=` token regex** — DAX `<=` comparisons must be column-scoped.
2. **No TMDL comments** — `//` and `/* */` break the Fabric TMDL parser.
3. **Non-destructive writes** — only write files explicitly named as targets.
4. **Fresh UUIDs** — every new artifact object gets a freshly generated UUID v4.

### 4. Evals
Run the full eval pipeline:

```powershell
# From repo root (PowerShell 7+)
.\evals\eval.ps1 -Client volvo -PbipPath C:\repos\volvo-ddm

# Gates only (no LLM)
.\evals\eval.ps1 -Client volvo -PbipPath C:\repos\volvo-ddm -SkipLLM

# Specific gate group
.\evals\gates.ps1 -Check Brand -PbipPath C:\repos\volvo-ddm
```

LLM judge requires an OpenAI or Azure OpenAI key:

```bash
# OpenAI
export OPENAI_API_KEY=sk-...
python evals/judge.py --brief evals/briefs/overview-page.md \
                      --artifact /path/to/report.json \
                      --client volvo

# Azure OpenAI
export AZURE_OPENAI_ENDPOINT=https://<resource>.openai.azure.com
export AZURE_OPENAI_API_KEY=...
export AZURE_OPENAI_DEPLOYMENT=gpt-4o
python evals/judge.py --brief evals/briefs/overview-page.md \
                      --artifact /path/to/report.json \
                      --client volvo
```

Eval logs are written to `logs/eval-<runId>.json` (excluded from VCS).

### 5. Self-improvement
`skill-improve` runs weekly (Monday 06:00 UTC) or on demand via the router with
`task=improve`. It reads `logs/eval-*.json`, identifies checks with > 20 % failure rate,
drafts fixes, opens a human-gated draft PR, and appends bullets to `learnings.md`.

---

## Adding a new client

1. Create `clients/<slug>/config.json` — copy `clients/volvo/config.json` and adjust paths.
2. Create `clients/<slug>/brand.json` — populate all required tokens (see Volvo example).
3. Add client-specific eval briefs to `evals/briefs/` if needed.
4. Test with `.\evals\eval.ps1 -Client <slug> -PbipPath <path>`.

---

## Environment variables

| Variable                  | Used by         | Description                              |
|---------------------------|-----------------|------------------------------------------|
| `VOLVO_PBIP_PATH`         | gates.ps1, eval.ps1 | Default PBIP repo path for Volvo     |
| `OPENAI_API_KEY`          | judge.py        | OpenAI API key                           |
| `AZURE_OPENAI_ENDPOINT`   | judge.py        | Azure OpenAI endpoint URL                |
| `AZURE_OPENAI_API_KEY`    | judge.py        | Azure OpenAI API key                     |
| `AZURE_OPENAI_DEPLOYMENT` | judge.py        | Azure OpenAI deployment name             |
| `AZURE_OPENAI_API_VERSION`| judge.py        | Azure OpenAI API version (default: 2024-02-01) |
| `JUDGE_MODEL`             | judge.py        | OpenAI model for judging (default: gpt-4o) |

---

## Licence

**Proprietary — internal use only.**
This repository and all its contents are the confidential property of WPP plc and its
subsidiaries. Distribution outside WPP and its authorised client engagements is
prohibited. This project is not open-source and carries no MIT or other open-source licence.

