<#
.SYNOPSIS
    Deterministic gate checks for agentic-bi-workforce eval pipeline.

.DESCRIPTION
    Runs structural and brand-compliance checks against PBIP artifacts.
    Each check returns an exit code of 0 (pass) or 1 (fail) and writes a
    JSON result to stdout for ingestion by eval.ps1.

.PARAMETER Check
    Which check group to run: Model | Brand | All (default: All)

.PARAMETER PbipPath
    Absolute path to the PBIP repo root. Defaults to $env:VOLVO_PBIP_PATH.

.PARAMETER BrandFile
    Path to the brand.json to validate against. Defaults to clients/volvo/brand.json.

.EXAMPLE
    .\gates.ps1 -Check All -PbipPath C:\repos\volvo-ddm
#>

[CmdletBinding()]
param(
    [ValidateSet('Model', 'Brand', 'All')]
    [string]$Check = 'All',

    [string]$PbipPath  = $env:VOLVO_PBIP_PATH,
    [string]$BrandFile = (Join-Path $PSScriptRoot '..\clients\volvo\brand.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$results = [System.Collections.Generic.List[hashtable]]::new()

function Add-Result {
    param([string]$name, [bool]$passed, [string]$detail = '')
    $results.Add(@{
        check   = $name
        result  = if ($passed) { 'pass' } else { 'fail' }
        detail  = $detail
        ts      = (Get-Date -Format 'o')
    })
}

# ---------------------------------------------------------------------------
# MODEL CHECKS
# ---------------------------------------------------------------------------
function Invoke-ModelChecks {
    if (-not $PbipPath) {
        Add-Result 'model.path_configured' $false 'VOLVO_PBIP_PATH not set and -PbipPath not provided'
        return
    }

    $datasetPath = Get-ChildItem -Path $PbipPath -Recurse -Filter '*.Dataset' -Directory |
        Select-Object -First 1

    # M1 — Dataset folder exists
    Add-Result 'model.dataset_folder_exists' ($null -ne $datasetPath) `
        (if ($datasetPath) { $datasetPath.FullName } else { 'No .Dataset folder found' })

    if (-not $datasetPath) { return }

    $tmdlFiles = Get-ChildItem -Path $datasetPath.FullName -Recurse -Filter '*.tmdl'

    # M2 — No TMDL comments
    $commentPattern = [regex]'(//|/\*)'
    $filesWithComments = $tmdlFiles | Where-Object {
        $content = Get-Content $_.FullName -Raw
        $commentPattern.IsMatch($content)
    }
    Add-Result 'model.no_tmdl_comments' ($filesWithComments.Count -eq 0) `
        (if ($filesWithComments.Count -gt 0) { "Files with comments: $($filesWithComments.Name -join ', ')" } else { '' })

    # M3 — No greedy <= token regex in DAX
    $greedyPattern = [regex]'<=\s*"[^"]+"'
    $filesWithGreedy = $tmdlFiles | Where-Object {
        $content = Get-Content $_.FullName -Raw
        $greedyPattern.IsMatch($content)
    }
    Add-Result 'model.no_greedy_le_regex' ($filesWithGreedy.Count -eq 0) `
        (if ($filesWithGreedy.Count -gt 0) { "Files with greedy <=: $($filesWithGreedy.Name -join ', ')" } else { '' })

    # M4 — All lineageTag values are valid UUID v4
    $uuidPattern = [regex]'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    $badLineage  = @()
    foreach ($f in $tmdlFiles) {
        $content = Get-Content $f.FullName -Raw
        $matches = [regex]::Matches($content, 'lineageTag:\s*([^\s]+)')
        foreach ($m in $matches) {
            $tag = $m.Groups[1].Value.Trim('"').Trim("'")
            if (-not $uuidPattern.IsMatch($tag)) {
                $badLineage += "$($f.Name): $tag"
            }
        }
    }
    Add-Result 'model.uuid_v4_lineage_tags' ($badLineage.Count -eq 0) `
        (if ($badLineage.Count -gt 0) { "Bad tags: $($badLineage -join '; ')" } else { '' })
}

# ---------------------------------------------------------------------------
# BRAND CHECKS
# ---------------------------------------------------------------------------
function Invoke-BrandChecks {
    if (-not $PbipPath) {
        Add-Result 'brand.path_configured' $false 'VOLVO_PBIP_PATH not set and -PbipPath not provided'
        return
    }
    if (-not (Test-Path $BrandFile)) {
        Add-Result 'brand.brand_file_exists' $false "Brand file not found: $BrandFile"
        return
    }

    $brand = Get-Content $BrandFile -Raw | ConvertFrom-Json

    $reportJsonFiles = Get-ChildItem -Path $PbipPath -Recurse -Filter 'report.json'

    # B1 — report.json exists
    Add-Result 'brand.report_json_exists' ($reportJsonFiles.Count -gt 0) `
        (if ($reportJsonFiles.Count -eq 0) { 'No report.json found' } else { '' })

    foreach ($rj in $reportJsonFiles) {
        $report = Get-Content $rj.FullName -Raw | ConvertFrom-Json
        $rName  = $rj.Directory.Name

        # B2 — Canvas dimensions match brand
        $widthOk  = $report.config.canvasWidth  -eq $brand.canvas.width
        $heightOk = $report.config.canvasHeight -eq $brand.canvas.height
        Add-Result "brand.canvas_dimensions[$rName]" ($widthOk -and $heightOk) `
            "Expected $($brand.canvas.width)x$($brand.canvas.height); got $($report.config.canvasWidth)x$($report.config.canvasHeight)"

        # B3 — Primary colour present in at least one visual
        $reportJson  = Get-Content $rj.FullName -Raw
        $primaryUsed = $reportJson -match [regex]::Escape($brand.colors.primary)
        Add-Result "brand.primary_color_used[$rName]" $primaryUsed `
            (if (-not $primaryUsed) { "Primary $($brand.colors.primary) not found in report.json" } else { '' })

        # B4 — Font family referenced
        $fontFamily  = $brand.typography.fontFamily.Split(',')[0].Trim()
        $fontUsed    = $reportJson -match [regex]::Escape($fontFamily)
        Add-Result "brand.font_family_used[$rName]" $fontUsed `
            (if (-not $fontUsed) { "Font '$fontFamily' not found in report.json" } else { '' })
    }
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
switch ($Check) {
    'Model' { Invoke-ModelChecks }
    'Brand' { Invoke-BrandChecks }
    'All'   { Invoke-ModelChecks; Invoke-BrandChecks }
}

$output = @{
    runId     = [System.Guid]::NewGuid().ToString()
    timestamp = (Get-Date -Format 'o')
    check     = $Check
    results   = $results
    summary   = @{
        total  = $results.Count
        passed = ($results | Where-Object { $_.result -eq 'pass' }).Count
        failed = ($results | Where-Object { $_.result -eq 'fail' }).Count
    }
}

$json = $output | ConvertTo-Json -Depth 10
Write-Output $json

$failCount = $output.summary.failed
if ($failCount -gt 0) {
    Write-Error "$failCount gate(s) failed" -ErrorAction Continue
    exit 1
}
exit 0
