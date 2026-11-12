#requires -Version 7.4
[CmdletBinding()]
param(
    [string] $SitePath = (Join-Path (Split-Path -Parent $PSScriptRoot) '_site'),
    [AllowEmptyString()]
    [string] $BaseUrl = '/AppMod-Lab',
    [uri] $SiteUrl = 'https://oreakinodidi98.github.io/'
)

$ErrorActionPreference = 'Stop'
if ($BaseUrl -and ($BaseUrl -notmatch '^/' -or $BaseUrl.EndsWith('/'))) {
    throw 'BaseUrl must be empty or a path starting with / and without a trailing /.'
}
$siteRoot = (Resolve-Path -LiteralPath $SitePath).Path
$pages = @(Get-ChildItem -LiteralPath $siteRoot -Filter *.html -File -Recurse)
if (-not $pages.Count) { throw "No generated HTML pages found in $siteRoot. Build the site first." }

$failures = [System.Collections.Generic.List[string]]::new()
$linkCount = 0
foreach ($page in $pages) {
    $relativePage = [IO.Path]::GetRelativePath($siteRoot, $page.FullName).Replace('\', '/')
    $pageUrl = [uri]::new($SiteUrl, "$BaseUrl/$relativePage")
    $html = Get-Content -LiteralPath $page.FullName -Raw
    foreach ($match in [regex]::Matches($html, '(?is)<a\b[^>]*\bhref\s*=\s*["''](?<href>[^"'']+)["'']')) {
        $href = [Net.WebUtility]::HtmlDecode($match.Groups['href'].Value)
        if ($href.StartsWith('#')) { continue }
        $target = [uri]::new($pageUrl, $href)
        if ($target.Scheme -notin @('http', 'https') -or $target.Authority -ne $SiteUrl.Authority) {
            continue
        }
        $linkCount++
        $path = [uri]::UnescapeDataString($target.AbsolutePath)
        if ($BaseUrl -and $path -cne $BaseUrl -and
            -not $path.StartsWith("$BaseUrl/", [StringComparison]::Ordinal)) {
            $failures.Add("${relativePage}: $href is missing the project path $BaseUrl.")
            continue
        }
        $relativeTarget = $path.Substring($BaseUrl.Length).TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
        $destination = if ($relativeTarget) { Join-Path $siteRoot $relativeTarget } else { $siteRoot }
        if (Test-Path -LiteralPath $destination -PathType Container) {
            $destination = Join-Path $destination 'index.html'
        }
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $failures.Add("${relativePage}: $href points to a missing generated page or file.")
        }
    }
}
if ($failures.Count) {
    throw ("Broken site links:`n" + ($failures -join "`n"))
}
if (-not $linkCount) { throw 'No internal page links were found in the generated site.' }
Write-Output "Checked $linkCount internal links across $($pages.Count) generated HTML pages."
