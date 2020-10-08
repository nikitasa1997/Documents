Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$Encoding = 'UTF8'

function Get-ServiceAsHashtable {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param()
    begin {
        [string]$DefaultLUID = '00000000'
        [string]$Pattern = '^(.+)_[0-9a-f]{4,8}$'
    }
    process {
        [hashtable]$Service96 = @{}
        [PSCustomObject[]]$Service = Get-Service |
            Select-Object -Property @{Name = 'Name'; Expression = {
                if ($_.ServiceType -in @(224, 240)) {
                    $Service96.Add(($_.Name -replace $Pattern, '$1'), $null)
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
            } -End {$Ordered}
    }
}

function Read-HashtableFromJson {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true, Positional = )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_ -Include '*.json' -PathType Leaf})]
        [string]
        $Path
    )
    process {
        $Object = Get-Content -Path $Path -Encoding $Encoding |
            ConvertFrom-Json
        $ht2 = @{}
        $theObject.psobject.properties |
            Foreach { $ht2[$_.Name] = $_.Value }
    }
}

function Set-ServiceFromHashtable {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param(
        [Parameter(Mandatory=$true, Positional = )]
        [hashtable]
        $Hashtable
    )
    process {
        Write-Host $Hashtable.Count
    }
}

function Write-HashtableToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Positional = )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("*.json")]
        [ValidateScript({Test-Path -Path $_ -Filter '*.json' -PathType Leaf -IsValid})]
        [string]
        $Path
    )
    process {
    ConvertTo-Json -Depth 1 |
    Set-Content -Path $Path -Encoding $Encoding
}

$Path = '\Users\nikit\Downloads\Documents\Windows 10\Services\services.json'
# Export-Service -Path $Path
Set-ServiceFromHashtable(Get-ServiceAsHashtable)
