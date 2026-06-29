<#
.SYNOPSIS  Render a human-readable markdown eval report from the latest eval JSON log.
.OUTPUTS   logs/eval-<ts>.md and prints overall verdict.
#>
param([string] $Log = "")
$ErrorActionPreference = "Stop"
if (-not $Log) { $Log = (Get-ChildItem logs/eval-*.json | Sort-Object LastWriteTime | Select-Object -Last 1).FullName }
$e = Get-Content $Log -Raw | ConvertFrom-Json
$g = if ($e.gates) { $e.gates } else { $e }
$tier1 = $e.tier1_pass
$rows = ($g.checks | ForEach-Object { "| {0} | {1} | {2} |" -f $_.name, ($(if($_.pass){"PASS"}else{"FAIL"})), $_.detail }) -join "`n"
$rubric = if ($e.tier2) { ($e.tier2.items | ForEach-Object { "| {0} | {1} | {2} |" -f $_.item, ($(if($_.pass){"PASS"}else{"FAIL"})), $_.evidence }) -join "`n" } else { "_Tier-2 pending agent scoring_" }
$pct = if ($e.tier2) { $e.tier2.score } else { "n/a" }
$md = @"
# Eval Report
Tier-1: $(if($tier1){"PASS"}else{"FAIL"}) | Tier-2: $pct
## Tier-1 gates
| check | result | detail |
|---|---|---|
$rows
## Tier-2 rubric
| item | result | evidence |
|---|---|---|
$rubric
"@
$out = [IO.Path]::ChangeExtension($Log, ".md")
$md | Set-Content $out
Write-Host "Report: $out"; $md
