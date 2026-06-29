<#
.SYNOPSIS
    Orchestrates the full eval pipeline for agentic-bi-workforce.

.DESCRIPTION
    Runs deterministic gate checks (gates.ps1) then LLM rubric scoring (judge.py)
    for every brief in evals/briefs/. Writes a consolidated JSON run log to logs/.

.PARAMETER Client
    Client slug. Defaults to 'volvo'.

.PARAMETER PbipPath
    Absolute path to the PBIP repo root. Defaults to $env:VOLVO_PBIP_PATH.

.PARAMETER BriefsDir
    Directory containing eval briefs. Defaults to evals/briefs.

.PARAMETER SkipLLM
    Skip the LLM judge step and run deterministic gates only.

.EXAMPLE
    .\eval.ps1 -Client volvo -PbipPath C:\repos\volvo-ddm
#>

[CmdletBinding()]
param(
    [string]$Client    = 'volvo',
    [string]$PbipPath  = $env:VOLVO_PBIP_PATH,
    [string]$BriefsDir = (Join-Path $PSScriptRoot 'briefs'),
    [switch]$SkipLLM
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path $PSScriptRoot -Parent
$LogsDir   = Join-Path $RepoRoot 'logs'
$GatesScript = Join-Path $PSScriptRoot 'gates.ps1'
$JudgeScript = Join-Path $PSScriptRoot 'judge.py'

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

$runId    = [System.Guid]::NewGuid().ToString()
$runStart = Get-Date -Format 'o'
$allResults = @()

Write-Host "=== agentic-bi-workforce eval run $runId ===" -ForegroundColor Cyan
Write-Host "Client: $Client | PBIP: $PbipPath" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Step 1: Deterministic gates
# ---------------------------------------------------------------------------
Write-Host "`n[1/2] Running deterministic gates..." -ForegroundColor Yellow

$gatesJson = & pwsh -NoProfile -File $GatesScript -Check All `
    -PbipPath $PbipPath `
    -BrandFile (Join-Path $RepoRoot "clients/$Client/brand.json") 2>&1

$gatesExitCode = $LASTEXITCODE
try {
    $gatesResult = $gatesJson | ConvertFrom-Json
} catch {
    $gatesResult = @{ error = "Failed to parse gates output: $_"; results = @() }
}

$allResults += $gatesResult

$gatesPassed = ($gatesExitCode -eq 0)
$statusColor = if ($gatesPassed) { 'Green' } else { 'Red' }
Write-Host "Gates: $(if ($gatesPassed) {'PASS'} else {'FAIL'})" -ForegroundColor $statusColor

# ---------------------------------------------------------------------------
# Step 2: LLM rubric scoring
# ---------------------------------------------------------------------------
if (-not $SkipLLM) {
    Write-Host "`n[2/2] Running LLM judge..." -ForegroundColor Yellow

    $briefs = Get-ChildItem -Path $BriefsDir -Filter '*.md'
    $reportJsonFiles = if ($PbipPath) {
        Get-ChildItem -Path $PbipPath -Recurse -Filter 'report.json' |
            Select-Object -First 1
    } else { $null }

    $artifactPath = if ($reportJsonFiles) { $reportJsonFiles.FullName } else { $null }

    foreach ($brief in $briefs) {
        Write-Host "  Brief: $($brief.Name)" -NoNewline

        if (-not $artifactPath) {
            Write-Host " [SKIPPED — no artifact]" -ForegroundColor DarkYellow
            continue
        }

        $judgeOutput = & python $JudgeScript `
            --brief $brief.FullName `
            --artifact $artifactPath `
            --client $Client 2>&1

        $judgeExitCode = $LASTEXITCODE
        try {
            $judgeResult = $judgeOutput | ConvertFrom-Json
        } catch {
            $judgeResult = @{ error = "Failed to parse judge output: $_"; pass = $false }
        }

        $allResults += $judgeResult
        $judgeColor = if ($judgeExitCode -eq 0) { 'Green' } else { 'Red' }
        Write-Host " [$(if ($judgeExitCode -eq 0) {'PASS'} else {'FAIL'})] score=$($judgeResult.overallScore)" `
            -ForegroundColor $judgeColor
    }
} else {
    Write-Host "`n[2/2] LLM judge skipped (-SkipLLM)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------------
# Consolidate and write run log
# ---------------------------------------------------------------------------
$runEnd = Get-Date -Format 'o'
$consolidatedLog = @{
    runId     = $runId
    client    = $Client
    pbipPath  = $PbipPath
    startedAt = $runStart
    endedAt   = $runEnd
    results   = $allResults
    overallPass = ($allResults | Where-Object {
        ($_.result -eq 'fail') -or ($_.pass -eq $false)
    }).Count -eq 0
}

$logFile = Join-Path $LogsDir "eval-$runId.json"
$consolidatedLog | ConvertTo-Json -Depth 15 | Set-Content -Path $logFile -Encoding UTF8

$overallColor = if ($consolidatedLog.overallPass) { 'Green' } else { 'Red' }
Write-Host "`n=== Overall: $(if ($consolidatedLog.overallPass) {'PASS'} else {'FAIL'}) ===" `
    -ForegroundColor $overallColor
Write-Host "Log written to: $logFile"

exit (if ($consolidatedLog.overallPass) { 0 } else { 1 })
