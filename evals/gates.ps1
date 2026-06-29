<#
.SYNOPSIS
  Tier-1 deterministic gates for a generated Power BI report (spec-as-truth).
  No golden-file diff: validates structure against client brand + brief facts.
.OUTPUTS
  JSON {pass: bool, checks: [{name, pass, detail}]} on stdout.
#>
param(
  [Parameter(Mandatory)] [string] $ReportDir,
  [Parameter(Mandatory)] [string] $BrandPath,        # path to clients/<c>/brand.json
  [string] $SemanticModelDir = ""                # optional, for relationship count
)

$ErrorActionPreference = "Stop"
$brand = Get-Content $BrandPath -Raw | ConvertFrom-Json
$checks = @()
function Add-Check($name, $pass, $detail) {
  $script:checks += [pscustomobject]@{ name = $name; pass = [bool]$pass; detail = "$detail" }
}

# 1. PBIR present
$pages = Join-Path $ReportDir "definition\pages"
Add-Check "report.exists" (Test-Path $pages) $pages

# 2. page size matches brand (1280x1300, ActualSize)
$pageJsons = Get-ChildItem $pages -Recurse -Filter page.json -ErrorAction SilentlyContinue
$ok = $false
foreach ($p in $pageJsons) {
  $j = Get-Content $p.FullName -Raw | ConvertFrom-Json
  if ($j.width -eq $brand.page.width -and $j.height -eq $brand.page.height) { $ok = $true }
}
Add-Check "page.size" $ok "expect $($brand.page.width)x$($brand.page.height)"

# 3-4. brand font + navy color present in visuals
$vis = Get-ChildItem (Join-Path $pages "*\visuals\*\visual.json") -ErrorAction SilentlyContinue
$fam = $brand.font.family; $navyHex = $brand.colors.navy
$fontHit = $vis | Select-String -Pattern $fam -SimpleMatch -ErrorAction SilentlyContinue
Add-Check "brand.font" ($null -ne $fontHit) "fontFamily '$fam' found"
$navyHit = $vis | Select-String -Pattern $navyHex -SimpleMatch -ErrorAction SilentlyContinue
Add-Check "brand.navy" ($null -ne $navyHit) $navyHex

# 5. relationship count (optional)
if ($SemanticModelDir) {
  $rel = Join-Path $SemanticModelDir "definition\relationships.tmdl"
  if (Test-Path $rel) {
    $n = (Select-String -Path $rel -Pattern "^\s*relationship " ).Count
    Add-Check "rel.count" ($n -ge 16) "found $n (expect >=16)"
  }
}

$pass = -not ($checks | Where-Object { -not $_.pass })
[pscustomobject]@{ pass = $pass; checks = $checks } | ConvertTo-Json -Depth 5
