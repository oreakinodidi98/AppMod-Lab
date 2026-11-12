#requires -Version 7.4
[CmdletBinding()]
param(
    [string] $Application = 'hol',
    [string] $Environment = 'dev',
    [string] $RegionCode = 'sc',
    [string] $Owner = 'oa',
    [string] $Instance = '01',
    [string] $Location = 'swedencentral'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
. (Join-Path $PSScriptRoot 'lab-names.ps1')

Write-Output "=========================================="
Write-Output "Workshop reference environment cleanup"
Write-Output "=========================================="
Write-Output ""

# Check if .envrc file exists to load resource names
if (Test-Path ".envrc") {
    Write-Output "Found .envrc file. Loading resource names..."
    Get-Content ".envrc" | ForEach-Object {
        if ($_ -match "^export\s+(\w+)=(.+)$") {
            $varName = $matches[1]
            $varValue = $matches[2]
            Set-Item -Path "env:$varName" -Value $varValue
            Write-Output "  Loaded setting: $varName"
        }
    }
    Write-Output ""
}

$options = @{
    Application = $Application; Environment = $Environment; RegionCode = $RegionCode
    Owner = $Owner; Instance = $Instance; Location = $Location
}
$settings = @{
    Application = 'LAB_APPLICATION'; Environment = 'LAB_ENVIRONMENT'; RegionCode = 'LAB_REGION_CODE'
    Owner = 'LAB_OWNER'; Instance = 'LAB_INSTANCE'; Location = 'LAB_LOCATION'
}
foreach ($key in $settings.Keys) {
    $recorded = [Environment]::GetEnvironmentVariable($settings[$key])
    if (-not $PSBoundParameters.ContainsKey($key) -and $recorded) {
        $options[$key] = $recorded
    }
}
$names = Get-LabResourceNames @options

# Prompt for resource group name if not loaded from .envrc
if (-not $env:RG_NAME) {
    $env:RG_NAME = Read-Host "Enter the recorded resource group name (expected $($names.ResourceGroup))"
    if ([string]::IsNullOrWhiteSpace($env:RG_NAME)) {
        Write-Error "Resource group name is required. Exiting."
        exit 1
    }
}
if ($env:RG_NAME -cne $names.ResourceGroup) {
    throw 'The resource group does not match the recorded naming values. Restore the original values and confirm ownership before deleting anything.'
}
$currentSubscription = (az account show --query id --output tsv).Trim()
if (-not $currentSubscription) { throw 'Could not verify the active subscription.' }
if ($env:AZURE_SUBSCRIPTION_ID -and $env:AZURE_SUBSCRIPTION_ID -ne $currentSubscription) {
    throw 'The active subscription does not match the recorded setup subscription.'
}
$env:AZURE_SUBSCRIPTION_ID = $currentSubscription
Write-Output "Subscription: $env:AZURE_SUBSCRIPTION_ID"

# Confirm deletion
Write-Output ""
Write-Output "WARNING: This will delete the following:"
Write-Output "  - Resource Group: $env:RG_NAME"
Write-Output "  - All resources within the resource group including:"
Write-Output "    * AKS Cluster"
Write-Output "    * PostgreSQL Flexible Server"
Write-Output "    * Azure Container Registry"
Write-Output "    * Log Analytics Workspace"
Write-Output "    * Azure Monitor Workspace"
Write-Output "    * Application Insights"
Write-Output "    * Key Vault"
Write-Output "    * User Assigned Managed Identity"
Write-Output ""

$confirmation = Read-Host "Type the exact resource group name to confirm deletion"
if ($confirmation -cne $env:RG_NAME) {
    Write-Output "Cleanup cancelled."
    exit 0
}

Write-Output ""
Write-Output "Starting cleanup process..."
Write-Output ""

# Check if resource group exists
$rgExists = az group exists --subscription $env:AZURE_SUBSCRIPTION_ID --name $env:RG_NAME --output tsv
if ($rgExists -eq "true") {
    Write-Output "Deleting resource group: $env:RG_NAME"
    Write-Output "This may take several minutes..."
    
    # Delete the resource group (this will delete all resources within it)
    az group delete --subscription $env:AZURE_SUBSCRIPTION_ID --name $env:RG_NAME --yes --no-wait
    
    Write-Output "✅ Resource group deletion initiated (running in background)"
    Write-Output ""
    Write-Output "Note: The deletion is running asynchronously. You can check the status with:"
    Write-Output "  az group show --name $env:RG_NAME"
    Write-Output ""
} elseif ($rgExists -eq "false") {
    Write-Output "⚠️  Resource group '$env:RG_NAME' not found. It may have already been deleted."
} else {
    throw 'The resource group existence could not be verified. No cleanup was performed.'
}

# Clean up local files
Write-Output "Cleaning up local files..."

if (Test-Path ".envrc") {
    Remove-Item ".envrc" -Force
    Write-Output "✅ Removed .envrc file"
}

# Remove kubeconfig file if it exists
if ($env:AKS_CLUSTER_NAME) {
    $kubeconfigFile = "$env:AKS_CLUSTER_NAME.config"
    if (Test-Path $kubeconfigFile) {
        Remove-Item $kubeconfigFile -Force
        Write-Output "✅ Removed kubeconfig file: $kubeconfigFile"
    }
}

# Remove service connector log if it exists
if (Test-Path "sc.log") {
    Remove-Item "sc.log" -Force
    Write-Output "✅ Removed sc.log file"
}

# Remove setup-local-lab-infra.sh if it exists
if (Test-Path "setup-local-lab-infra.sh") {
    Remove-Item "setup-local-lab-infra.sh" -Force
    Write-Output "✅ Removed setup-local-lab-infra.sh file"
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Cleanup Complete!"
Write-Output "=========================================="
Write-Output ""
Write-Output "Summary:"
Write-Output "  - Resource group deletion initiated: $env:RG_NAME"
Write-Output "  - Local configuration files removed"
Write-Output ""
Write-Output "To verify deletion completed, run:"
Write-Output "  az group show --name $env:RG_NAME"
Write-Output ""
Write-Output "Expected result when deletion is complete: 'ResourceGroupNotFound'"
Write-Output ""
