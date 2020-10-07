param(
    $Command = $(throw "Command parameter is required.")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Encoding = 'UTF8'
$Pattern = '^(.+)_[0-9a-f]{4,8}$'
$DefaultLUID = '00000000'

function Export-Service {
    param(
        [string]$Path
    )
    process {
        [hashtable]$Service96 = @{}
        $Service = Get-Service |
            Select-Object -Property @{'Name' = 'Name'; 'Expression' = {
                if ($_.ServiceType -in @(224, 240)) {
                    $Service96[$_.Name -replace $Pattern, '$1'] = $null
                    $_.Name -replace $Pattern, "`$1_$DefaultLUID"
                } else {$_.Name}
            }}, StartType
        $Service += $Service96.Keys |
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
# Import-Service -Path $Path
