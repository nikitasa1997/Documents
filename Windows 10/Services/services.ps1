param(
    $Command = $(throw "Command parameter is required.")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Encoding = 'UTF8'
$DefaultLUID = '00000000'

function Export-Service {
    param(
        [string]$Path
    )
    process {
        $Service = Get-Service |
            Select-Object -Property Name, ServiceType, StartType
        $PerUserService = $Service |
            Where-Object -Property ServiceType -In -Value @(224, 240) |
            Select-Object -ExpandProperty Name
        [string]$LUID = $PerUserService |
            Foreach-Object -Process {$_ -replace '^.+_([0-9a-f]{4,8})$', '$1'} |
            Select-Object -Unique
        $Service = $Service |
            Select-Object -Property @{'Name' = 'Name'; 'Expression' = {
                if ($_.ServiceType -in @(224, 240)) {
                    $_.Name -replace "^(.+)_$LUID`$", "`$1_$DefaultLUID"
                } else {$_.Name}
            }}, StartType
        $Service += $PerUserService |
            Foreach-Object -Process {$_ -replace "^(.+)_$LUID`$", '$1'} |
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
