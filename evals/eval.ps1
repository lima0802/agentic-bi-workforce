<#
.SYNOPSIS  Run Tier-1 gates then Tier-2 judge; write a timestamped log for the PR loop.
#>
param(
  [Parameter(Mandatory)] [string] $ReportDir,
  [string] $Brand = "clients/volvo/brand.json",
  [string] $Eval = "overview-page",
  [string] $SemanticModelDir = ""
)
$ErrorActionPreference = "Stop"
$Brief = "evals/briefs/$Eval.md"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force -Path logs | Out-Null
$gatesOut = "logs/gates-$ts.json"
pwsh ./evals/gates.ps1 -ReportDir $ReportDir -BrandPath $Brand -SemanticModelDir $SemanticModelDir > $gatesOut
$gate = Get-Content $gatesOut -Raw | ConvertFrom-Json
if (-not $gate.pass) { Write-Host "Tier-1 FAIL — fix before judge"; $gate.checks | Where-Object {-not $_.pass}; exit 1 }
python ./evals/judge.py --brief $Brief --gates $gatesOut --out "logs/eval-$ts.json"
Write-Host "Eval logged: logs/eval-$ts.json"
