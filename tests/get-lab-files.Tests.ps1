#requires -Version 7.4
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$global:LabTestRoot = Split-Path -Parent $PSScriptRoot
$global:LabTestCorrupt = $false
$setup = Join-Path $global:LabTestRoot 'assets/scripts/get-lab-files.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "appmod-lab-test-$([guid]::NewGuid().ToString('N'))"
$originalLabAppRepo = $env:LAB_APP_REPO

function global:Invoke-WebRequest {
    param([string] $Uri, [string] $OutFile)
    if ($Uri -notmatch '^https://raw\.githubusercontent\.com/oreakinodidi98/AppMod-Lab/[^/]+/(.+)$') {
        throw "Unexpected URL: $Uri"
    }
    $path = $Matches[1]
    if ($path -eq 'assets/k8s/caldova.yaml') {
        # Use the published Git bytes, even if a worktree has different line endings.
        git -C $global:LabTestRoot cat-file blob "HEAD:$path" > $OutFile
    }
    else {
        Copy-Item -LiteralPath (Join-Path $global:LabTestRoot $path) -Destination $OutFile
    }
    if ($global:LabTestCorrupt -and $path -eq 'assets/src/pom.xml') {
        Add-Content -LiteralPath $OutFile -Value 'corrupted'
    }
}

function Assert($condition, [string] $message) {
    if (-not $condition) { throw $message }
}

try {
    $environmentGuide = Get-Content -LiteralPath (Join-Path $global:LabTestRoot 'appmod-lab/3-deploy-to-azure/deploy-to-azure-3-1-environment.md') -Raw
    $namingBlock = [regex]::Match($environmentGuide, '(?s)## 2\. Set the location and resource names.*?```powershell\r?\n(.*?)\r?\n```').Groups[1].Value
    $keyVaultName = [regex]::Match($environmentGuide, '(?m)^\$env:KV_NAME = "kv-\$env:NAME_PREFIX"').Value
    Assert ($namingBlock -and $keyVaultName) 'Manual naming commands were not found'
    foreach ($code in @('oa-dev-sc', 'mw-dev-usw')) {
        $commands = $namingBlock.Replace('oa-dev-sc-', "$code-")
        & ([scriptblock]::Create("$commands`n$keyVaultName")) | Out-Null
        Assert ($env:NAME_SUFFIX -match '^[1-9][0-9]{5}$') 'The random suffix should contain six digits'
        Assert ($env:NAME_PREFIX -ceq "$code-$env:NAME_SUFFIX") 'The chosen naming codes were not applied'
        Assert ($env:RG_NAME -ceq "rg-$env:NAME_PREFIX" -and $env:AKS_NAME -ceq "aks-$env:NAME_PREFIX") 'Resource names do not use the chosen prefix'
        Assert ($env:POSTGRES_SERVER_NAME -ceq "pg-$env:NAME_PREFIX") 'PostgreSQL name does not use the chosen prefix'
        Assert ($env:ACR_NAME -cmatch '^[a-z0-9]{5,50}$') 'The registry name has an invalid format'
        Assert ($env:KV_NAME.Length -le 24 -and $env:KV_NAME -cmatch '^[a-z][a-z0-9-]+[a-z0-9]$') 'The Key Vault name has an invalid format'
    }
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $manifest = Get-Content -LiteralPath (Join-Path $global:LabTestRoot 'assets/scripts/lab-files.json') -Raw | ConvertFrom-Json
    $downloadCases = @(
        @{ Module = 'todo'; Page = '1-interactive-modernization/interactive-modernization-1-1-upgrade.md' },
        @{ Module = 'todo'; Page = '2-automated-modernization/automated-modernization-2-1-workflow.md' },
        @{ Module = 'environment'; Page = '3-deploy-to-azure/deploy-to-azure-3-1-environment.md' },
        @{ Module = 'python'; Page = '3-deploy-to-azure/deploy-to-azure-3-2-python.md' },
        @{ Module = 'java'; Page = '3-deploy-to-azure/deploy-to-azure-3-3-java.md' },
        @{ Module = 'caldova-source'; Page = '5-caldova-source-modernization/caldova-source-modernization-5-1-migrate.md' }
    )
    $caseNumber = 0
    foreach ($case in $downloadCases) {
        $page = Get-Content -LiteralPath (Join-Path $global:LabTestRoot "appmod-lab/$($case.Page)") -Raw
        Assert ($page -notmatch 'LAB_SETUP|get-lab-files\.ps1') "Student instructions still require the setup script: $($case.Page)"
        $blocks = @([regex]::Matches($page, '(?s)```powershell\r?\n(.*?)\r?\n```') |
            Where-Object { $_.Groups[1].Value -match 'https://raw\.githubusercontent\.com/oreakinodidi98/AppMod-Lab/' })
        Assert ($blocks.Count -eq 1) "Expected one direct download block: $($case.Page)"
        $env:LAB_APP_REPO = Join-Path $testRoot "direct-$caseNumber"
        $caseNumber++
        New-Item -ItemType Directory -Path $env:LAB_APP_REPO | Out-Null
        git init --quiet $env:LAB_APP_REPO
        Push-Location $env:LAB_APP_REPO
        try {
            & ([scriptblock]::Create($blocks[0].Groups[1].Value)) | Out-Null
            $expectedFiles = @($manifest | Where-Object {
                $sourcePath = $_.source
                switch ($case.Module) {
                    'todo' { $sourcePath.StartsWith('assets/src/') }
                    'environment' { $sourcePath -in @('assets/Python_app/CaldovaClinicalApi/db/init.sql', 'assets/k8s/caldova.yaml') }
                    'python' { $sourcePath.StartsWith('assets/Python_app/') -and $sourcePath -ne 'assets/Python_app/CaldovaClinicalApi/db/init.sql' }
                    'java' { $sourcePath.StartsWith('assets/Java_app/') }
                    'caldova-source' { $sourcePath.StartsWith('assets/Scenario1App/') }
                }
            })
            foreach ($file in $expectedFiles) {
                Assert (Test-Path -LiteralPath $file.destination -PathType Leaf) "Direct download is missing $($file.destination): $($case.Page)"
                Assert ((Get-FileHash -LiteralPath $file.destination -Algorithm SHA256).Hash -eq $file.sha256) "Direct download has incorrect contents: $($file.destination)"
            }
            $downloadedFiles = @(Get-ChildItem -File -Recurse -Force |
                Where-Object { $_.FullName -notlike "$env:LAB_APP_REPO\.git\*" })
            Assert ($downloadedFiles.Count -eq $expectedFiles.Count) "Unexpected files downloaded by $($case.Page)"
        }
        finally { Pop-Location }
    }
    $databaseSection = [regex]::Match($environmentGuide, '(?s)## 12\..*?(?=## 13\.)').Value
    $databaseBlocks = @([regex]::Matches($databaseSection, '(?s)```powershell\r?\n(.*?)\r?\n```'))
    $sqlBlock = @($databaseBlocks | Where-Object { $_.Groups[1].Value -match '\$databaseRoleSql = ' })
    $executeBlock = @($databaseBlocks | Where-Object { $_.Groups[1].Value -match '\$roleFile = \$null' })
    Assert ($sqlBlock.Count -eq 1 -and $executeBlock.Count -eq 1) 'Database setup blocks were not found'
    $env:USER_ASSIGNED_IDENTITY_NAME = 'mi-example'
    $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID = 'example-object-id'
    $env:POSTGRES_DATABASE_NAME = 'caldova'
    $env:POSTGRES_SERVER_NAME = 'example-server'
    $env:USER_PRINCIPAL_NAME = 'test@example.invalid'
    $databaseBootstrapFile = Join-Path $global:LabTestRoot 'assets/Python_app/CaldovaClinicalApi/db/init.sql'
    . ([scriptblock]::Create($sqlBlock[0].Groups[1].Value))
    function global:az {
        if ("$($args[0]) $($args[1])" -eq 'account get-access-token') {
            $global:LASTEXITCODE = 0
            return 'test-access-token'
        }
        if ("$($args[0]) $($args[1]) $($args[2])" -ne 'postgres flexible-server execute') {
            throw 'Unexpected Azure command'
        }
        $file = $args[[array]::IndexOf($args, '--file-path') + 1]
        $database = $args[[array]::IndexOf($args, '--database-name') + 1]
        $global:LabTestSqlCalls.Add([pscustomobject]@{
            File = $file
            Sql = Get-Content -LiteralPath $file -Raw
            Database = $database
        })
        $global:LASTEXITCODE = if ($global:LabTestSqlCalls.Count -eq $global:LabTestFailAt) { 1 } else { 0 }
    }
    try {
        foreach ($failAt in @(0, 1, 2, 3)) {
            $global:LabTestSqlCalls = [System.Collections.Generic.List[object]]::new()
            $global:LabTestFailAt = $failAt
            $failure = ''
            try { & ([scriptblock]::Create($executeBlock[0].Groups[1].Value)) }
            catch { $failure = $_.Exception.Message }
            $count = if ($failAt -eq 0) { 3 } else { $failAt }
            Assert ($global:LabTestSqlCalls.Count -eq $count) 'Database setup did not stop after the failed operation'
            Assert (-not (Test-Path Env:PGPASSWORD)) 'Database token was not removed'
            Assert (-not (Test-Path -LiteralPath $global:LabTestSqlCalls[0].File)) 'Temporary role SQL was not removed'
            if ($failAt -eq 0) {
                Assert (-not $failure) "Database setup failed unexpectedly: $failure"
                $calls = $global:LabTestSqlCalls
                Assert ($calls[0].Database -ceq 'postgres' -and $calls[0].Sql.TrimEnd() -ceq $databaseRoleSql) 'Principal SQL or database was changed'
                Assert ($calls[1].Database -ceq 'caldova' -and $calls[1].File -ceq $databaseBootstrapFile) 'Seed was not executed in the application database'
                Assert ($calls[2].Database -ceq 'caldova' -and $calls[2].Sql.TrimEnd() -ceq $databaseGrantSql) 'Grant SQL or database was changed'
                Assert (-not (Test-Path -LiteralPath $calls[2].File)) 'Temporary grant SQL was not removed'
            }
            else {
                Assert ($failure -match @('', 'PostgreSQL principal', 'initialize the PostgreSQL schema', 'grant the workload identity')[$failAt]) 'Failure was not reported'
            }
        }
    }
    finally {
        Remove-Item Function:\az
        Remove-Variable LabTestSqlCalls, LabTestFailAt -Scope Global
    }
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
        Assert (-not (Test-Path -LiteralPath 'assets/scripts/lab-names.ps1')) 'The manual environment should not download the reference naming script'
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

        . (Join-Path $global:LabTestRoot 'assets/scripts/lab-names.ps1')
        $defaultNames = Get-LabResourceNames
        Assert ($defaultNames.ResourceGroup -ceq 'rg-dev-sc-hol-oa-01') 'The default resource group does not follow the naming convention'
        Assert ($defaultNames.Storage -ceq 'stdevscholoa01') 'The default storage name should not have dashes'
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
            $env:LAB_APP_REPO = $originalLabAppRepo
            Remove-Item Function:\az, Function:\Read-Host
            Remove-Variable LabTestGroupExists -Scope Global
        }

        git config user.name 'Workshop test'
        git config user.email 'workshop-test@example.invalid'
        git add -- src Python_app Java_app
        git commit --quiet -m 'Add sample files'
        $buildRoot = Join-Path $testRoot 'build'
        New-Item -ItemType Directory -Path $buildRoot | Out-Null
        $pythonGuide = Get-Content -LiteralPath (Join-Path $global:LabTestRoot 'appmod-lab/3-deploy-to-azure/deploy-to-azure-3-2-python.md') -Raw
        $buildBlock = [regex]::Match($pythonGuide, '(?s)```powershell\r?\n((?:(?!```).)*?git archive --format=tar HEAD.*?)(?:\r?\n)```').Groups[1].Value
        Assert $buildBlock 'Python build instructions were not found'
        $env:LAB_APP_REPO = $repo
        $env:BUILD_ROOT = $buildRoot
        $env:NAME_PREFIX = 'test'
        $committedHash = (Get-FileHash -LiteralPath 'Python_app/CaldovaClinicalApi/main.py').Hash
        Add-Content -LiteralPath 'Python_app/CaldovaClinicalApi/main.py' -Value '# uncommitted change'
        & ([scriptblock]::Create($buildBlock))
        Assert ((Get-FileHash -LiteralPath (Join-Path $env:API_BUILD_CONTEXT 'main.py')).Hash -eq $committedHash) 'Python build did not use committed files'
        Assert (Test-Path -LiteralPath (Join-Path $env:WEB_BUILD_CONTEXT 'app.py')) 'Missing Python web build context'
        Assert (-not (Test-Path -LiteralPath (Join-Path $env:API_BUILD_CONTEXT 'db/init.sql'))) 'Unexpected database seed in Python build context'
        $failed = $false
        try { & ([scriptblock]::Create($buildBlock)) } catch { $failed = $_.Exception.Message -match 'already exist' }
        Assert $failed 'Python build contexts should not be overwritten on retry'
        $javaPaths = @(
            'Java_app/CaldovaClinicalApiJava/Dockerfile', 'Java_app/CaldovaClinicalApiJava/pom.xml',
            'Java_app/CaldovaClinicalApiJava/src', 'Java_app/CaldovaClinicalWebJava/Dockerfile',
            'Java_app/CaldovaClinicalWebJava/pom.xml', 'Java_app/CaldovaClinicalWebJava/src'
        )
        $archive = Join-Path $buildRoot 'java.tar'
        git -C $repo archive --format=tar --output $archive HEAD -- $javaPaths
        tar -xf $archive -C $buildRoot
        Remove-Item -LiteralPath $archive
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
