#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('todo', 'automation', 'environment', 'python', 'java', 'caldova-source')]
    [string] $Module
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$baseUrl = 'https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/main'
$manifestHash = '30bc5d53d0fa3036a94a4106a81026210ad000e38f2d5af97318ea3fcf0ea926'
$workflowRevision = '58368c8c04f1b9517af8d51fde140d7102069aed'
$repoRoot = (git rev-parse --show-toplevel).Trim()
if ((Get-Location).Provider.Name -ne 'FileSystem' -or
    [IO.Path]::GetFullPath((Get-Location).Path).TrimEnd('\', '/') -ne
    [IO.Path]::GetFullPath($repoRoot).TrimEnd('\', '/')) {
    throw 'Run this command from the root of your own workshop repository.'
}

$staging = Join-Path ([IO.Path]::GetTempPath()) "appmod-lab-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $staging | Out-Null
$created = [System.Collections.Generic.List[string]]::new()
$failure = $null
try {
    $files = @()
    if ($Module -eq 'automation') {
        foreach ($name in @('ci.yml', 'modernise.yml')) {
            $files += [pscustomobject]@{
                source = ".github/workflows/$name"
                destination = ".github/workflows/$name"
                sha256 = $null
                url = "https://raw.githubusercontent.com/oreakinodidi98/AppMod-Lab/$workflowRevision/.github/workflows/$name"
            }
        }
    }
    else {
        $manifestPath = Join-Path $staging 'manifest.json'
        Invoke-WebRequest -Uri "$baseUrl/assets/scripts/lab-files.json" -OutFile $manifestPath
        if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ne $manifestHash) {
            throw 'The starter manifest does not match this setup script. Download the matching script from the workshop instructions.'
        }
        $manifest = @(Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json)
        $files = @($manifest | Where-Object {
            $source = $_.source
            switch ($Module) {
                'todo' { $source.StartsWith('assets/src/', [StringComparison]::Ordinal) }
                'environment' { $source -in @('assets/Python_app/CaldovaClinicalApi/db/init.sql', 'assets/k8s/caldova.yaml', 'assets/scripts/lab-names.ps1') }
                'python' { $source.StartsWith('assets/Python_app/', [StringComparison]::Ordinal) -and $source -ne 'assets/Python_app/CaldovaClinicalApi/db/init.sql' }
                'java' { $source.StartsWith('assets/Java_app/', [StringComparison]::Ordinal) }
                'caldova-source' { $source.StartsWith('assets/Scenario1App/', [StringComparison]::Ordinal) }
            }
        })
    }
    if (-not $files.Count) { throw "No files were selected for $Module." }
    foreach ($file in $files) {
        if ($file.destination -notmatch '^[A-Za-z0-9._/-]+$' -or
            @($file.destination.Split('/') | Where-Object { $_ -in @('', '.', '..') }).Count -gt 0) {
            throw "Unsafe destination: $($file.destination)"
        }
        $destination = Join-Path $repoRoot $file.destination
        if (Test-Path -LiteralPath $destination) {
            throw "Already exists: $($file.destination). No files were added; review it before retrying."
        }
        $parent = Split-Path -Parent $destination
        while ($parent -and $parent -ne $repoRoot) {
            if (Test-Path -LiteralPath $parent) {
                $item = Get-Item -LiteralPath $parent -Force
                if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                    throw "Cannot write through a file or link: $parent"
                }
            }
            $parent = Split-Path -Parent $parent
        }
    }
    foreach ($file in $files) {
        $stagedFile = Join-Path $staging $file.destination
        New-Item -ItemType Directory -Path (Split-Path -Parent $stagedFile) -Force | Out-Null
        $url = if ($Module -eq 'automation') { $file.url } else { "$baseUrl/$($file.source)" }
        Invoke-WebRequest -Uri $url -OutFile $stagedFile
        if ($file.sha256 -and (Get-FileHash -LiteralPath $stagedFile -Algorithm SHA256).Hash -ne $file.sha256) {
            throw "The downloaded file did not match the reviewed version: $($file.source). No files were added."
        }
        if ($Module -eq 'automation') {
            $text = [IO.File]::ReadAllText($stagedFile).Replace("`r`n", "`n")
            $pattern = '(?ms)^on:\n.*?(?=^permissions:)'
            if ([regex]::Matches($text, $pattern).Count -ne 1) {
                throw "Cannot safely restrict triggers in $($file.destination). No files were added."
            }
            $trigger = if ($file.destination -eq '.github/workflows/modernise.yml') {
                "on:`n  workflow_dispatch:`n    inputs:`n      upgrade_target:`n        description: 'Upgrade target (e.g., Java 21); latest uses CLI defaults'`n        required: false`n        default: latest`n        type: string`n`n"
            }
            else { "on:`n  workflow_dispatch:`n`n" }
            $text = [regex]::Replace($text, $pattern, $trigger)
            [IO.File]::WriteAllText($stagedFile, $text, [Text.UTF8Encoding]::new($false))
        }
    }
    foreach ($file in $files) {
        $destination = Join-Path $repoRoot $file.destination
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        $inputStream = [IO.File]::OpenRead((Join-Path $staging $file.destination))
        try {
            $outputStream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew)
            $created.Add($file.destination)
            try { $inputStream.CopyTo($outputStream) }
            finally { $outputStream.Dispose() }
        }
        finally { $inputStream.Dispose() }
    }
}
catch {
    $failure = $_.Exception.Message
    if ($created.Count) {
        $failure += "`nSome files were added before the error: $($created -join ', '). Review them before removing or retrying."
    }
}
finally {
    try {
        if (Test-Path -LiteralPath $staging) {
            Remove-Item -LiteralPath $staging -Recurse -Force
        }
    }
    catch {
        $cleanupFailure = "Could not remove temporary files at ${staging}: $($_.Exception.Message)"
        if ($failure) { $failure += "`n$cleanupFailure" }
        else { $failure = $cleanupFailure }
    }
}
if ($failure) { throw $failure }
Write-Host "Added $($files.Count) files for $Module. Review the files and git status before committing."
