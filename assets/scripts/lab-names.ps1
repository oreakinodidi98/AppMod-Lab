#requires -Version 7.4

function Get-LabResourceNames {
    [CmdletBinding()]
    param(
        [ValidatePattern('(?-i)^[a-z][a-z0-9]{0,7}$')]
        [string] $Application = 'hol',
        [ValidatePattern('(?-i)^[a-z][a-z0-9]{0,7}$')]
        [string] $Environment = 'dev',
        [ValidatePattern('(?-i)^[a-z][a-z0-9]{0,7}$')]
        [string] $RegionCode = 'sc',
        [ValidatePattern('(?-i)^[a-z][a-z0-9]{0,7}$')]
        [string] $Owner = 'oa',
        [ValidatePattern('^(0[1-9]|[1-9][0-9])$')]
        [string] $Instance = '01',
        [ValidatePattern('(?-i)^[a-z][a-z0-9]+$')]
        [string] $Location = 'swedencentral'
    )

    $knownLocations = @{ sc = 'swedencentral'; we = 'westeurope' }
    if ($knownLocations.ContainsKey($RegionCode) -and $Location -cne $knownLocations[$RegionCode]) {
        throw "The region code $RegionCode must match the Azure location $($knownLocations[$RegionCode])."
    }
    $stem = "$Environment-$RegionCode-$Application-$Owner-$Instance"
    $compact = "$Environment$RegionCode$Application$Owner$Instance"
    $names = [ordered]@{
        Stem = $stem
        CompactStem = $compact
        Location = $Location
        ResourceGroup = "rg-$stem"
        Aks = "aks-$stem"
        Acr = "cr$compact"
        Storage = "st$compact"
        PostgresServer = "psql-$stem"
        Database = "db$compact"
        Identity = "id-$stem"
        Federation = "fic-$stem"
        Namespace = "ns-$stem"
        ServiceAccount = "sa-$stem"
        Api = "api-$stem"
        Web = "web-$stem"
        Config = "cfg-$stem"
        SourceApi = "apisrc-$stem"
        SourceWeb = "websrc-$stem"
        SourceConfig = "cfgsrc-$stem"
        KeyVault = "kv-$stem"
        LogAnalytics = "log-$stem"
        Monitor = "amw-$stem"
        AppInsights = "appi-$stem"
        Gateway = "gw-$stem"
        Connection = "sc-$stem"
        ClientFirewall = "fwclient-$stem"
        PetClinicDatabase = "dbpc$compact"
        PetClinicNamespace = "nspc-$stem"
        PetClinicIdentity = "idpc-$stem"
        PetClinicServiceAccount = "sapc-$stem"
        PetClinicFederation = "ficpc-$stem"
        PetClinicApp = "apppc-$stem"
        PetClinicConfig = "cfgpc-$stem"
        SystemPool = "sys$Instance"
        UserPool = "usr$Instance"
        Tags = @(
            "application=$Application", "environment=$Environment",
            "region=$RegionCode", "owner=$Owner", "instance=$Instance"
        )
    }
    if ($names.KeyVault.Length -gt 24 -or $names.Storage.Length -gt 24) {
        throw 'The combined naming values are too long. Use shorter application, environment, region, or owner codes; Key Vault and storage names must fit within 24 characters.'
    }
    [pscustomobject] $names
}
