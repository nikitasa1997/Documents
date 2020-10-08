Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$DefaultLUID = '00000000'
[string]$Encoding = 'UTF8'
[string]$Pattern = '^(.+)_[0-9a-f]{4,8}$'

function Export-Service {
    [CmdletBinding()]
    param(
        [string]$Path
    )
    process {
        [hashtable]$PerUserService = @{}
        [PSCustomObject[]]$Service = Get-Service |
            Select-Object -Property @{'Name' = 'Name'; 'Expression' = {
                if ($_.ServiceType -in @(224, 240)) {
                    $PerUserService[$_.Name -replace $Pattern, '$1'] = $null
                    $_.Name -replace $Pattern, "`$1_$DefaultLUID"
                } else {$_.Name}
            }}, StartType
        $Service += $PerUserService.Keys |
            Get-Service |
            Select-Object -Property Name, StartType

        $Service |
            Sort-Object -Property Name |
            Foreach-Object -Begin {$Ordered = [ordered]@{}} -Process {
                $Ordered.Add($_.Name, $_.StartType)
            } -End {$Ordered} |
            ConvertTo-Json -Depth 1 |
            Set-Content -Path $Path -Encoding $Encoding
    }
}

function Import-Service {
    param(
        [string]$Path
    )
    process {
        $Object = Get-Content -Path $Path -Encoding $Encoding |
            ConvertFrom-Json
        $ht2 = @{}
        $theObject.psobject.properties | Foreach { $ht2[$_.Name] = $_.Value }
    }
}

$Path = '\Users\nikit\Downloads\Documents\Windows 10\Services\services.json'
Export-Service -Path $Path
