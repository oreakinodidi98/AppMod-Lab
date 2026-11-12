#requires -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$global:LabTestRoot = Split-Path -Parent $PSScriptRoot
$global:LabTestCorrupt = $false
$setup = Join-Path $global:LabTestRoot 'assets/scripts/get-lab-files.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "appmod-lab-test-$([guid]::NewGuid().ToString('N'))"

function global:Invoke-WebRequest {
    param([string] $Uri, [string] $OutFile)
    if ($Uri -notmatch '^https://raw\.githubusercontent\.com/oreakinodidi98/AppMod-Lab/[^/]+/(.+)$') {
        throw "Unexpected URL: $Uri"
    }
    $path = $Matches[1]
    Copy-Item -LiteralPath (Join-Path $global:LabTestRoot $path) -Destination $OutFile
    if ($global:LabTestCorrupt -and $path -eq 'assets/src/pom.xml') {
        Add-Content -LiteralPath $OutFile -Value 'corrupted'
    }
}

function Assert($condition, [string] $message) {
    if (-not $condition) { throw $message }
}

try {
    $instructions = Get-Content -LiteralPath (Join-Path $global:LabTestRoot 'appmod-lab/0-prerequisites/prerequisite-0-1-technical.md') -Raw
    $expectedHash = [regex]::Match($instructions, "(?m)^\`$expected = '([a-f0-9]{64})'").Groups[1].Value
    Assert ($expectedHash -and (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -eq $expectedHash) 'Setup script hash in prerequisites is out of date'
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $repo = Join-Path $testRoot 'repo'
    New-Item -ItemType Directory -Path $repo | Out-Null
    git init --quiet $repo
    Push-Location $repo
    try {
        foreach ($module in @('todo', 'environment', 'python', 'java', 'automation', 'caldova-source')) {
            & $setup -Module $module
        }
        foreach ($path in @(
            'src/pom.xml',
            'src/src/test/java/com/example/todo/todo/TodoControllerTest.java',
            'Python_app/CaldovaClinicalApi/db/init.sql',
            'Python_app/CaldovaClinicalApi/main.py',
            'Python_app/CaldovaClinicalWeb/caldova_home.py',
            'Java_app/CaldovaClinicalApiJava/pom.xml',
            'Java_app/CaldovaClinicalWebJava/src/main/resources/templates/inventory.html',
            'assets/k8s/caldova.yaml',
            'assets/scripts/lab-names.ps1',
            'Scenario1App/.gitignore',
            'Scenario1App/CaldovaClinicalApi/main.py',
            'Scenario1App/CaldovaClinicalApi/db/init.sql',
            'Scenario1App/CaldovaClinicalWeb/app.py'
        )) {
            Assert (Test-Path -LiteralPath $path -PathType Leaf) "Missing $path"
        }
        foreach ($workflow in @('ci.yml', 'modernise.yml')) {
            $content = Get-Content -LiteralPath ".github/workflows/$workflow" -Raw
            $trigger = [regex]::Match($content, '(?ms)^on:\r?\n.*?(?=^permissions:)').Value
            Assert ($trigger -match 'workflow_dispatch:' -and $trigger -notmatch '(?m)^  (push|pull_request|schedule):') "Unsafe trigger in $workflow"
        }
        Assert ((Get-Content -LiteralPath '.github/workflows/modernise.yml' -Raw) -match 'upgrade_target:') 'Missing upgrade target input'
        Assert (-not (Test-Path -LiteralPath '.github/workflows/sign-image.yaml')) 'Unexpected workflow copied'
        Assert (-not (Test-Path -LiteralPath 'Java_app/CaldovaClinicalApiJava/target')) 'Build artifacts copied'
        Assert (-not (Test-Path -LiteralPath 'Scenario1App/CaldovaClinicalApi/Dockerfile')) 'Module 06 should start without generated Dockerfiles'
        Assert (-not (Test-Path -LiteralPath 'assets/scripts/AutomaticSetup.ps1')) 'Demo setup script copied'
        foreach ($path in @('Scenario1App/CaldovaClinicalApi/.venv/test', 'Scenario1App/.env', 'Scenario1App/database.dump')) {
            git check-ignore --quiet -- $path
            Assert ($LASTEXITCODE -eq 0) "Local files should be ignored: $path"
        }
        $sourceBefore = (Get-FileHash -LiteralPath 'Scenario1App/CaldovaClinicalApi/main.py').Hash
        $failed = $false
        try { & $setup -Module caldova-source } catch { $failed = $_.Exception.Message -match 'Already exists' }
        Assert $failed 'A repeated source download should preserve modernization changes'
        Assert ((Get-FileHash -LiteralPath 'Scenario1App/CaldovaClinicalApi/main.py').Hash -eq $sourceBefore) 'Source application was changed'
        $before = (Get-FileHash -LiteralPath 'src/pom.xml').Hash
        $failed = $false
        try { & $setup -Module todo } catch { $failed = $_.Exception.Message -match 'Already exists' }
        Assert $failed 'A repeated download should reject existing files'
        Assert ((Get-FileHash -LiteralPath 'src/pom.xml').Hash -eq $before) 'Existing file was changed'

        . (Join-Path $repo 'assets/scripts/lab-names.ps1')
        $defaultNames = Get-LabResourceNames
        Assert ($defaultNames.ResourceGroup -ceq 'rg-dev-sc-hol-oa-01') 'The default resource group does not follow the naming convention'
        Assert ($defaultNames.Storage -ceq 'stdevscholoa01') 'The default storage name should not have dashes'
        $namingPage = Get-Content -LiteralPath (Join-Path $global:LabTestRoot 'appmod-lab/0-prerequisites/prerequisite-0-2-naming.md') -Raw
        $documented = @{}
        foreach ($match in [regex]::Matches($namingPage, "(?m)^\s+(LAB_[A-Z_]+) = '([a-z0-9]+)'")) {
            $documented[$match.Groups[1].Value] = $match.Groups[2].Value
        }
        $documentedNames = Get-LabResourceNames -Application $documented.LAB_APPLICATION -Environment $documented.LAB_ENVIRONMENT `
            -RegionCode $documented.LAB_REGION_CODE -Owner $documented.LAB_OWNER -Instance $documented.LAB_INSTANCE -Location $documented.LAB_LOCATION
        Assert ($documentedNames.ResourceGroup -ceq $defaultNames.ResourceGroup -and $documentedNames.Location -ceq $defaultNames.Location) 'Documented naming defaults and script defaults differ'
        $chosenNames = Get-LabResourceNames -Owner ab -Instance 02
        Assert ($chosenNames.ResourceGroup -ceq 'rg-dev-sc-hol-ab-02') 'Participant naming values were not applied'
        Assert ($chosenNames.Acr -ceq 'crdevscholab02' -and $chosenNames.KeyVault -ceq 'kv-dev-sc-hol-ab-02') 'Service naming rules were not applied'
        Assert ($chosenNames.Tags -contains 'owner=ab' -and $chosenNames.Tags -contains 'instance=02') 'Naming tags do not match the selected values'
        foreach ($invalid in @(
            @{ Owner = 'AB' }, @{ Application = 'bad-name' }, @{ Instance = '1' },
            @{ Owner = 'longcode'; Application = 'longcode'; Environment = 'longcode' },
            @{ RegionCode = 'sc'; Location = 'westeurope' }
        )) {
            $failed = $false
            try { Get-LabResourceNames @invalid | Out-Null } catch { $failed = $true }
            Assert $failed 'Invalid naming values should be rejected'
        }

        $global:LabTestGroupExists = 'true'
        function global:az {
            switch ("$($args[0]) $($args[1])") {
                'account show' { 'test-subscription' }
                'group exists' { $global:LabTestGroupExists }
                'acr check-name' { 'false' }
                default { throw 'Azure writes are blocked by the test' }
            }
        }
        function global:Read-Host { throw 'Interactive prompts are blocked by the test' }
        try {
            foreach ($script in @('AutomaticSetup.ps1', 'ClassicSetup.ps1')) {
                $failed = $false
                try { & (Join-Path $global:LabTestRoot "assets/scripts/$script") -Owner ab -Instance 02 }
                catch { $failed = $_.Exception.Message -match 'resource group already exists' }
                Assert $failed "Setup should reject an existing group before creating resources: $script"
                Assert ($env:RG_NAME -ceq $chosenNames.ResourceGroup -and $env:AKS_NAME -ceq $chosenNames.Aks -and $env:ACR_NAME -ceq $chosenNames.Acr) "Setup script ignored shared names: $script"
            }
            $global:LabTestGroupExists = 'false'
            $failed = $false
            try { & (Join-Path $global:LabTestRoot 'assets/scripts/AutomaticSetup.ps1') -Owner ab -Instance 02 }
            catch { $failed = $_.Exception.Message -match 'registry name is unavailable' }
            Assert $failed 'Setup should reject an unavailable registry before creating resources'
            $env:RG_NAME = 'unrelated-resource-group'
            $failed = $false
            try { & (Join-Path $global:LabTestRoot 'assets/scripts/cleanup.ps1') -Owner ab -Instance 02 }
            catch { $failed = $_.Exception.Message -match 'does not match the recorded naming values' }
            Assert $failed 'Cleanup should reject a group outside the selected naming convention before calling Azure'
        }
        finally {
            Remove-Item Function:\az, Function:\Read-Host
            Remove-Variable LabTestGroupExists -Scope Global
        }

        git config user.name 'Workshop test'
        git config user.email 'workshop-test@example.invalid'
        git add -- src Python_app Java_app
        git commit --quiet -m 'Add sample files'
        $buildRoot = Join-Path $testRoot 'build'
        New-Item -ItemType Directory -Path $buildRoot | Out-Null
        $pythonPaths = @(
            'Python_app/CaldovaClinicalApi/Dockerfile', 'Python_app/CaldovaClinicalApi/main.py',
            'Python_app/CaldovaClinicalApi/requirements.txt', 'Python_app/CaldovaClinicalWeb/Dockerfile',
            'Python_app/CaldovaClinicalWeb/app.py', 'Python_app/CaldovaClinicalWeb/caldova_home.py',
            'Python_app/CaldovaClinicalWeb/requirements.txt'
        )
        $javaPaths = @(
            'Java_app/CaldovaClinicalApiJava/Dockerfile', 'Java_app/CaldovaClinicalApiJava/pom.xml',
            'Java_app/CaldovaClinicalApiJava/src', 'Java_app/CaldovaClinicalWebJava/Dockerfile',
            'Java_app/CaldovaClinicalWebJava/pom.xml', 'Java_app/CaldovaClinicalWebJava/src'
        )
        foreach ($group in @(@{ Name = 'python'; Paths = $pythonPaths }, @{ Name = 'java'; Paths = $javaPaths })) {
            $archive = Join-Path $buildRoot "$($group.Name).tar"
            git -C $repo archive --format=tar --output $archive HEAD -- $group.Paths
            tar -xf $archive -C $buildRoot
            Remove-Item -LiteralPath $archive
        }
        Assert (Test-Path -LiteralPath (Join-Path $buildRoot 'Python_app/CaldovaClinicalApi/main.py')) 'Missing Python build context'
        Assert (Test-Path -LiteralPath (Join-Path $buildRoot 'Java_app/CaldovaClinicalApiJava/src/main/resources/application.yml')) 'Missing Java build context'
        Assert (-not (Test-Path -LiteralPath (Join-Path $buildRoot 'Python_app/CaldovaClinicalApi/db/init.sql'))) 'Unexpected database seed in Python build context'
    }
    finally { Pop-Location }

    $badRepo = Join-Path $testRoot 'bad-repo'
    New-Item -ItemType Directory -Path $badRepo | Out-Null
    git init --quiet $badRepo
    Push-Location $badRepo
    try {
        $global:LabTestCorrupt = $true
        $failed = $false
        try { & $setup -Module todo } catch { $failed = $_.Exception.Message -match 'did not match' }
        Assert $failed 'A corrupted download should fail its hash check'
        Assert (-not (Test-Path -LiteralPath 'src')) 'Files were added after a failed hash check'

        function global:Remove-Item {
            param([string] $LiteralPath, [switch] $Recurse, [switch] $Force)
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $LiteralPath -Recurse:$Recurse -Force:$Force
            throw 'Simulated cleanup failure'
        }
        try {
            $message = ''
            try { & $setup -Module todo } catch { $message = $_.Exception.Message }
            Assert ($message -match 'did not match' -and $message -match 'Simulated cleanup failure') 'Both download and cleanup errors should be reported'
        }
        finally { Microsoft.PowerShell.Management\Remove-Item -LiteralPath Function:\Remove-Item -ErrorAction SilentlyContinue }
    }
    finally { Pop-Location }
    Write-Host 'Workshop downloader tests passed.'
}
finally {
    Remove-Item Function:\Invoke-WebRequest -ErrorAction SilentlyContinue
    Remove-Variable LabTestRoot, LabTestCorrupt -Scope Global -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
